function results_lf = correct_dnvoltages(mpc)
% It scales the load demand inside the DN to alleviate overvoltages or undervoltages
% Then it returns the power flow result

define_constants;

% Selection of the turns ratio of the tap_changing transformer
%tap_increment = (tap_info.tap_max - tap_info.tap_min)/tap_info.tap_steps;
%start_tapvalue = mpc.branch(1:2,TAP);

iterations = 0;
undervoltage = true;
overvoltage = true;

% Get a power flow calculation with voltages within boundaries
while(undervoltage == true || overvoltage == true)

    % Power flow calculation
    evalc('results_lf = runpf(mpc);');

    if(sum(results_lf.bus(:,VM) < results_lf.bus(:,VMIN))~=0)
        undervoltage = true;
        % Decrease load incrementally by 2%
        mpc.bus(:,PD)=0.98*mpc.bus(:,PD);
        mpc.bus(:,QD)=0.98*mpc.bus(:,QD);
    elseif(sum(results_lf.bus(:,VM) > results_lf.bus(:,VMAX))~=0)
        overvoltage = true;
        % Increase load incrementally by 2%
        mpc.bus(:,PD)=1.02*mpc.bus(:,PD);
        mpc.bus(:,QD)=1.02*mpc.bus(:,QD);
    else
        break;
    end
    iterations = iterations + 1;
	if(iterations > 200)
        fail = true;
        disp('No solution found in correct_dnvoltages, try to change the parameters  (oversize). The script will continue but possible voltage problems in DNs.');
        break;
    end
end
end

