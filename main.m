% Generates the T&D test system (only run this file)

tic

% Add the functions folder to the path
addpath functions;
addpath custom_data;

% Get the TN topology
if(exist('input_data/tn_template.mat','file'))
    load('input_data/tn_template.mat')
else
    disp('Cannot find tn_template.mat...');
end

% Retrieve the parameters set by the user
[matpower_path, constant_load, random, penetration_level, generation_weight, large_system, oversize, verbose, export_format, run_opf, pf_setpoint, opf_setpoint, dg_iterations] = parameters;

% To be able to use matpower functions
addpath(genpath(matpower_path));
% To be able to use the parameters by name (found in matpower's manual.pdf)
define_constants;


% List of the TN nodes NOT to be split into DN (check figure in accompanying paper)
% The first is for the large-scale system. The second for the medium-scale.
if(large_system)
    forbidden_nodes = [71,72];
else
    forbidden_nodes = [11,12,13,22,31,32,61,62,63,71,72];
end
non_split = length(forbidden_nodes);

% Calculate the power flow of the original TN with aggregated loads
disp('Initial transmission network...');
if(verbose)
    mpopt = mpoption('out.all', 1);
    resultslf_tn1 = runpf(mpc, mpopt);
else
    evalc('resultslf_tn1 = runpf(mpc);');
end

% Calculate the power flow of the template DN
disp('Setting up distribution networks...');
[results_default, resultslf_dn0, pv_buses, pv_powerlong, pv_powershort, fail] = get_dn(constant_load, random, penetration_level, generation_weight, oversize, pf_setpoint, dg_iterations);

if(~fail)
    % Identify the aggregated loads in the TN corresponding to DNs
    dn_buses = resultslf_tn1.bus(resultslf_tn1.bus(:,PD) ~= 0,:);
    
    % Adopt the new terminology for DN buses in the TN (see dnbus2int.m)
    for i=1:size(resultslf_tn1.branch,1)
        if(length(num2str(resultslf_tn1.branch(i,F_BUS))) == 1 || length(num2str(resultslf_tn1.branch(i,F_BUS))) == 2)
            resultslf_tn1.branch(i,F_BUS) = dnbus2int(resultslf_tn1.branch(i,F_BUS), 0);
        end
    end    
    
    % Exclude the forbidden nodes
    bus_nonsplit = zeros(non_split,size(dn_buses,2));
    branch_nonsplit = zeros(non_split,size(mpc.branch,2));
    
    for i=1:non_split
        forbidden_index = find(dn_buses(:,BUS_I) == forbidden_nodes(i));       
        bus_nonsplit(i,:) = dn_buses(forbidden_index,:);
        j = find(resultslf_tn1.branch(:,F_BUS) == dnbus2int(bus_nonsplit(i,1),0));
        branch_nonsplit(i,:) = resultslf_tn1.branch(j,1:ANGMAX);
        dn_buses(forbidden_index,:) = [];
    end
    
    % Calculates the number of DN needed to replace every aggregated node
    number_dn = floor(dn_buses(:,PD)./results_default.gen(1,PG));

    % Update the topology of the TN with the DNs
    disp('Integrating the DNs into the TN...');
    [info_dn, dn_branch, resultslf_dn1, pv_power, mt_power] = td_topology(constant_load, dn_buses, bus_nonsplit, branch_nonsplit, number_dn, resultslf_dn0, resultslf_tn1, base_MVA, results_default, penetration_level, pv_powerlong, pv_powershort, oversize);

    mpc2 = mpc;
    non_dn = (size(resultslf_tn1.bus,1) - size(dn_buses,1) - size(bus_nonsplit,1));
    mpc2.bus = [resultslf_tn1.bus(1:non_dn,:); info_dn];
    k = find(resultslf_tn1.branch(:,F_BUS) > 50000);
    mpc2.branch = [resultslf_tn1.branch(1:k-1,1:ANGMAX); dn_branch];

    % Calculate the power flow of the TN with DNs instead of aggregated loads
    evalc('resultslf_tn2 = runpf(mpc2);');
    
    % Make sure that the voltage at the first node of the DN is around pf_setpoint
    [resultslf_tn3, fail_ltc] = voltages(resultslf_tn2, info_dn, non_dn, non_split, tap_info, oversize, pf_setpoint);
    if(fail_ltc)
       disp('Process ended with one error (LTC)');
       return; 
    end   
    
    if(constant_load)
        % Recalculate the power flow of the DNs
        disp('Final transmission network...');
        if(verbose)
            mpopt = mpoption('out.all',1);
            resultslf_tn4 = runpf(resultslf_tn3, mpopt);
        else
            evalc('resultslf_tn4 = runpf(resultslf_tn3);');
        end
        % Recalculate the power flow of the DNs
        disp('Solving final distribution networks...');
        resultslf_dn2 = final_dn(number_dn, non_dn, resultslf_dn1, resultslf_tn4);
    else
        % Update the DN power demand (adding pv generation -> lower P,Q demand)
        ending = size(resultslf_tn3.bus,1) - non_split;
        
        for j=1:ending-non_dn
            resultslf_tn3.bus(j+non_dn, PD) = resultslf_dn1{j}.gen(1,PG);
            resultslf_tn3.bus(j+non_dn, QD) = resultslf_dn1{j}.gen(1,QG);
        end
        ratio = sum(resultslf_tn3.bus(:, PD))/sum(resultslf_tn3.gen(:, PG));            
        resultslf_tn3.gen(:, PG) = ratio*resultslf_tn3.gen(:, PG);
        resultslf_tn3.gen(:, QG) = ratio*resultslf_tn3.gen(:, QG);
        
        evalc('resultslf_tn3 = runpf(resultslf_tn3);');
        
        % Make sure that the voltage at the first node of the DN is around pf_setpoint
        [resultslf_tn4, fail_ltc] = voltages(resultslf_tn3, info_dn, non_dn, non_split, tap_info, oversize, pf_setpoint);
        if(fail_ltc)
           disp('Process ended with one error (LTC)');
           return; 
        end
        
        disp('Final transmission network...');
        if(verbose)
            mpopt = mpoption('out.all',1);
            resultslf_tn4 = runpf(resultslf_tn4, mpopt);
        else
            evalc('resultslf_tn4 = runpf(resultslf_tn4);');
        end
        % Recalculate the power flow of the DNs
        disp('Solving final distribution networks...');
        resultslf_dn2 = final_dn(number_dn, non_dn, resultslf_dn1, resultslf_tn4);
    end
    
    % Check if overvoltages in the TN
    disp('Checking overvoltages...');
    over = find(resultslf_tn4.bus(1:non_dn,VM) >= 1.2);
    
    if(sum(over) ~= 0)
        disp('WARNING! Overvoltages in the following nodes:');
        text = cell(length(over),1);
        for i=1:length(over)
           text{i} = resultslf_tn4.bus(over(i),BUS_I);
           fprintf('%d \t',text{i});
        end
        fprintf('\n');
    end
    
    % Build the full T&D model
    disp('Building the full T&D model...');
    [results_td, pv, mt] = merge_td(resultslf_tn4, resultslf_dn2, pv_buses, non_dn, non_split, penetration_level, constant_load, pv_power, mt_power);
   
    evalc('results_td = runpf(results_td);');
    if(oversize == 1)
        [results_td, fail_ltc] = voltages(results_td, info_dn, non_dn, non_split, tap_info, oversize, pf_setpoint);
        if(fail_ltc)
           disp('Process ended with one error (LTC)');
           return; 
        end          
    end
    
    if(run_opf && results_td.success)
        % Add cost functions and run OPF
        mpopt = mpoption('opf.ac.solver','MIPS','mips.step_control',1,'opf.init_from_mpc',1);
        results_td = add_gen_costs_for_OPF(results_td, number_dn);
        [results_opf, fail_opf] = calc_opf(results_td, mpopt, number_gen, info_dn, non_split, non_dn, verbose, opf_setpoint);
    else
        fail_opf = false;
    end
    
    if(~strcmp(export_format,'none') && results_td.success)
        % Export the data in the desired format
        if(run_opf == true && fail_opf == false)
            results_lf = export_data(export_format, results_opf, tap_info, penetration_level, generation_weight, run_opf, fail_opf, constant_load, pv, mt, pv_power, mt_power);
        else
            results_lf = export_data(export_format, results_td, tap_info, penetration_level, generation_weight, run_opf, fail_opf, constant_load, pv, mt, pv_power, mt_power);
        end     
    end
    
    if(run_opf == false)
        if(~results_td.success)
            disp('Process ended with one error (PF)');
        elseif(sum(over) ~= 0)
            disp('Process ended correctly (1 warning)');
        else
            disp('Process ended correctly');
        end
    else
        if(fail_opf == true)
            disp('Process ended with one error (OPF)');
        else
            disp('Process ended correctly');
        end
    end
end

toc