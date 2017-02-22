function [results_lf, fail] = pf_withpv(mpc, pf_setpoint, dg_iterations)
% Returns the power flow from a DN with a certain penetration level of renewables 

define_constants;
tap_voltage = false;
voltage_max = pf_setpoint + 0.003;
voltage_min = pf_setpoint - 0.003;
undervoltage = true;
overvoltage = true;
fail = true;
iterations = 0;

% Get a power flow calculation with voltages within boundaries
while(undervoltage == true || overvoltage == true)

    % Power flow calculation
    evalc('results_lf = runpf(mpc);');
    
    if(sum(results_lf.bus(:,VM) > results_lf.bus(:,VMAX))~=0)
        overvoltage = true;
        % Increase load incrementally (more on the short lines)
        for i=1:size(mpc.bus,1)
            if(mpc.bus(i,PD) > 0)
                if(i <= 16)
                    mpc.bus(i,PD)=1.1*mpc.bus(i,PD);
                    mpc.bus(i,QD)=1.1*mpc.bus(i,QD);
                else
                    mpc.bus(i,PD)=1.02*mpc.bus(i,PD);
                    mpc.bus(i,QD)=1.02*mpc.bus(i,QD);                    
                end
            else
                if(i <= 16)
                    mpc.bus(i,PD)=0.9*mpc.bus(i,PD);
                    mpc.bus(i,QD)=1.1*mpc.bus(i,QD);
                else
                    mpc.bus(i,PD)=0.98*mpc.bus(i,PD);
                    mpc.bus(i,QD)=1.02*mpc.bus(i,QD);                    
                end
            end
        end
    elseif(sum(results_lf.bus(:,VM) < results_lf.bus(:,VMIN))~=0)
        undervoltage = true;
        % Decrease load incrementally (more on the long lines)
        mpc.bus(3:16,PD)=0.98*mpc.bus(3:16,PD);
        mpc.bus(3:16,QD)=0.98*mpc.bus(3:16,QD);
        
        mpc.bus(17:end,PD)=0.95*mpc.bus(17:end,PD);
        mpc.bus(17:end,QD)=0.95*mpc.bus(17:end,QD);
    else
        fail = false;
        break;
    end
    
    % If it does not converge in one second, try other parameters
    if(iterations > dg_iterations)
        fail = true;
        disp('No solution found, try to change the parameters');
        break;
    end
    iterations = iterations + 1;
end

iterations = 0;
% Make sure that the voltage at the first node of the DN is around pf_setpoint
while(tap_voltage == false)
    if(results_lf.bus(2,VM) <= voltage_min)        
        mpc.branch(1:2,TAP) = mpc.branch(1:2,TAP) - 0.005;
    elseif(results_lf.bus(2,VM) >= voltage_max)
        mpc.branch(1:2,TAP) = mpc.branch(1:2,TAP) + 0.005;
    else
        tap_voltage = true;
    end

    % Power flow calculation
    evalc('results_lf = runpf(mpc);');
    
    % If it does not converge in one second, try other parameters
    if(iterations > dg_iterations)
        fail = true;
        disp('No solution found, try to change the parameters (oversize)');
        break;
    end
    iterations = iterations + 1;
end

end