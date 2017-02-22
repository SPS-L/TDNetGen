function [results_default, results_lf, pv_buses, dg_powerlong, dg_powershort, fail] = get_dn(constant_load, random, penetration_level, generation_weight, oversize, pf_setpoint, dg_iterations)
% Calculate the power flow with the data from the DN and the parameters chosen by the user 

define_constants;

if(exist('input_data/dn_template.mat','file'))
    load('input_data/dn_template.mat')
else
    disp('Cannot find dn_template.mat...');
end

% Generators output put to zero
mpc.gen(:,PG) = 0;
mpc.gen(:,QG) = 0;

mpc.bus(:,PD:QD) = oversize*mpc.bus(:,PD:QD);

% Get a power flow calculation with voltages within boundaries
results_default = correct_dnvoltages(mpc, tap_info);
results_default.gen(6:end,:) = [];

if(oversize > 1.0)
    results_default.bus(:,PD:QD) = oversize*results_default.bus(:,PD:QD);
    evalc('results_default = runpf(results_default);');
end

results_lf = cell(100,1);
dg_powerlong = zeros(100,1);
dg_powershort = zeros(100,1);
mpc0 = mpc;

if(penetration_level > 0)         
    if(random)
    	for k=1:100
            mpc = mpc0;
            % Randomize the sharing weights and calculate the power for long and short
            % feeders
            r1 = -.05:.01:.05;
            r1 = r1 + generation_weight;
            rand_genweight = r1(randi(numel(r1)));

            % Randomize the penetration level
            r2 = -.05:.01:.05;
            r2 = r2 + penetration_level;
            rand_penlevel = r2(randi(numel(r2)));
            
            % Get the nodes with generation and the average power generated by PV
            pv_gen = mpc.gen(2:end,GEN_BUS);
            pv_buses = zeros(length(pv_gen),1);
            initial_power = results_default.gen(1,PG);
            distributed_generation = rand_penlevel*initial_power;

            % Get the power input for the long (PVs) and the short feeders (other DGs)
			% The share is defined through the generation_weight variable
            dg_powershort(k) = rand_genweight*distributed_generation/4;
            dg_powerlong(k) = (1-rand_genweight)*distributed_generation/(length(pv_gen)-4);

            for i=1:length(pv_gen)
                index = find(mpc.bus(:,BUS_I) == pv_gen(i));
                pv_buses(i) = mpc.bus(index,BUS_I);
                
                % The PV panels act as a negative load with unity power factor
                if(i < 5)
                    mpc.gen(i+1,PG) = dg_powershort(k);
                    mpc.gen(i+1,QMIN) = -9999;
                    mpc.gen(i+1,PMAX) = dg_powershort(k);
                    S = sqrt(mpc.gen(i+1,PMAX)^2 + mpc.gen(i+1,QMAX)^2);
                    mpc.gen(i+1,MBASE) = ceil(S*10)/10;
                    if(dg_powershort(k) > 0.1)
                        mpc.gen(i+1,PMIN) = 0.1;
                    else
                        mpc.gen(i+1,PMIN) = 0;
                    end
                    mpc.gen(6:end,:) = [];
                else
                    mpc.bus(index,PD) = mpc.bus(index,PD) - dg_powerlong(k);
                end
            end

            % If the load seen by the TN must be kept constant (parameter constant_load), 
            % we need to increase the power demand (more on short lines to prevent undervoltages)
            if(constant_load)
                while(sum(mpc.bus(:,PD)) < initial_power)
                    for i=1:size(mpc.bus(:,PD),1)
                        if(mpc.bus(i,PD) > 0)
                            if(i<11)
                                mpc.bus(i,PD) = 1.1*mpc.bus(i,PD);
                            else
                                mpc.bus(i,PD) = 1.02*mpc.bus(i,PD);
                            end
                        else
                            if(i<11)
                                mpc.bus(i,PD) = 0.9*mpc.bus(i,PD);
                            else
                                mpc.bus(i,PD) = 0.98*mpc.bus(i,PD);
                            end      
                        end
                    end
                end
            end

            % Recalculate the power flow with the distributed generation
            if(oversize == 1)
                [results_lf{k}, fail] = pf_withpv(mpc, pf_setpoint, dg_iterations);
            else
                evalc('results_lf{k} = runpf(mpc);');
                if(results_lf{k}.success)
                    fail = false;
                else
                    fail = true;
                end
            end
    	end
    else  
        % Get the nodes with generation and the average power generated by PV
        pv_gen = mpc.gen(2:end,GEN_BUS);
        pv_buses = zeros(length(pv_gen),1);
        initial_power = results_default.gen(1,PG);
        distributed_generation = penetration_level*initial_power;

        % Get the power input for the long (PVs) and the short feeders (other DGs)
		% The share is defined through the generation_weight variable
        dg_powershort(:) = generation_weight*distributed_generation/4;
        dg_powerlong(:) = (1-generation_weight)*distributed_generation/(length(pv_gen)-4);

        for i=1:length(pv_gen)
            index = find(mpc.bus(:,BUS_I) == pv_gen(i));
            pv_buses(i) = mpc.bus(index,BUS_I);

            % The DGs in the short feeders are considered as normal generators
            if(i < 5)
                mpc.gen(i+1,PG) = dg_powershort(1);
                mpc.gen(i+1,QMIN) = -9999;
                mpc.gen(i+1,MBASE) = dg_powershort(1);
                mpc.gen(i+1,PMAX) = dg_powershort(1);
                if(dg_powershort(1) > 0.1)
                    mpc.gen(i+1,PMIN) = 0.1;
                else
                    mpc.gen(i+1,PMIN) = 0;
                end
                mpc.gen(6:end,:) = [];
            else
				% The PV panels act as a negative load with unity power factor
                mpc.bus(index,PD) = mpc.bus(index,PD) - dg_powerlong(1);
            end
        end

        % If the load in the TN must be kept constant, we need to increase the
        % power demand (more on short lines to prevent undervoltages)
        if(constant_load)
            while(sum(mpc.bus(:,PD)) < initial_power)
                for i=1:size(mpc.bus(:,PD),1)
                    if(mpc.bus(i,PD) > 0)
                        if(i<11)
                            mpc.bus(i,PD) = 1.1*mpc.bus(i,PD);
                        else
                            mpc.bus(i,PD) = 1.02*mpc.bus(i,PD);
                        end
                    else
                        if(i<11)
                            mpc.bus(i,PD) = 0.9*mpc.bus(i,PD);
                        else
                            mpc.bus(i,PD) = 0.98*mpc.bus(i,PD);
                        end      
                    end
                end
            end
        end

        % Recalculate the power flow with the distributed generation
        if(oversize == 1)
            [results, fail] = pf_withpv(mpc, pf_setpoint, dg_iterations);
        else
            evalc('results = runpf(mpc);');
            if(results.success)
                fail = false;
            else
                fail = true;
            end
        end
        for k=1:100
            results_lf{k} = results;
        end
    end
else
    for k=1:100
        results_lf{k} = results_default;
    end
    fail = false;
    pv_buses = [];
end

end
