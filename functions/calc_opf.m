function [results_opf, fail] = calc_opf(results_td, mpopt, number_gen, info_dn, non_split, non_dn, verbose, opf_setpoint)
% Runs an OPF algorithm on the T&D system

define_constants;

% First try
tn_limit = non_dn + size(info_dn,1);
gen_limit = find(results_td.bus(:,BUS_TYPE) == 3);
results_td.bus(1:tn_limit,VMAX) = opf_setpoint + 0.15;
results_td.bus(1:tn_limit,VMIN) = opf_setpoint - 0.1;
results_td.bus(tn_limit+1:end,VMAX) = opf_setpoint + 0.1;
results_td.bus(tn_limit+1:end,VMIN) = opf_setpoint - 0.1;
results_td.gen(1:number_gen,PMIN) = 0.1*results_td.gen(1:number_gen,PG);

% Voltage limits of 0.9-1.15pu for the TN nodes and 0.9-1.1pu for the DN nodes
disp('Calculating OPF (1/4)...');
if(verbose)
    results_opf = runopf(results_td, mpopt);
else
    evalc('results_opf = runopf(results_td, mpopt);');
end

% Voltage limits of 0.9-1.05pu for the generator nodes in the TN 
% and 0.9-1.1pu for the other TN nodes (DN unchanged)
if(results_opf.success)
    % Second try
    results_opf.bus(1:gen_limit,VMAX) = opf_setpoint + 0.05; 
    results_opf.bus(gen_limit+1:tn_limit,VMAX) = opf_setpoint + 0.1; 
    disp('Calculating OPF (2/4)...');
    results_opf = loop_opf(results_opf, mpopt, info_dn, non_split, non_dn, verbose, opf_setpoint);

    % Voltage limits of 0.9-1.05pu for the DN nodes (TN unchanged)
    if(results_opf.success)
        % Third try
        results_opf.bus(tn_limit+1:end,VMAX) = opf_setpoint + 0.05;
        disp('Calculating OPF (3/4)...');
        results_opf = loop_opf(results_opf, mpopt, info_dn, non_split, non_dn, verbose, opf_setpoint);
        
        % Voltage limits of 0.92-1.05pu for all the T&D nodes
        if(results_opf.success)
            % Fourth try
            results_opf.bus(1:end,VMIN) = opf_setpoint - 0.08;
            disp('Calculating OPF (4/4)...');
            range = size(info_dn,1) - non_split;
            for i=1:range
                l = find(results_opf.branch(:,F_BUS) == results_opf.bus(non_dn+i,BUS_I),1);
                results_opf.branch(l,TAP) = results_opf.branch(l,TAP) + 0.01;
            end
            results_opf = loop_opf(results_opf, mpopt, info_dn, non_split, non_dn, verbose, opf_setpoint);
             
            if(results_opf.success)   
                fail = false;
            else
                disp('OPF failed...');
                fail = true;    
            end
        else
            disp('OPF failed...');
            fail = true;
        end 
    else
        disp('OPF failed...');
        fail = true;
    end    
else
    disp('OPF failed...');
    fail = true;
end
end