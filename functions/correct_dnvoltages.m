function results_lf = correct_dnvoltages(mpc, tap_info)
% Returns the power flow of a DN without overvoltages or undervoltages

define_constants;

% Selection of the turns ratio of the tap_changing transformer
tap_increment = (tap_info.tap_max - tap_info.tap_min)/tap_info.tap_steps
start_tapvalue = mpc.branch(1:2,TAP);
b = 3;

mpc.branch(1:2,TAP) = start_tapvalue - b*tap_increment;

iterations = 0;
undervoltage = true;
overvoltage = true;

% Get a power flow calculation with voltages within boundaries
while(undervoltage == true || overvoltage == true)

    % Power flow calculation
    evalc('results_lf = runpf(mpc);');

    if(sum(results_lf.bus(:,VM) < results_lf.bus(:,VMIN))~=0)
        undervoltage = true;
        % Decrease load incrementally
        mpc.bus(:,PD)=0.98*mpc.bus(:,PD);
        mpc.bus(:,QD)=0.98*mpc.bus(:,QD);
    elseif(sum(results_lf.bus(:,VM) > results_lf.bus(:,VMAX))~=0)
        overvoltage = true;
        % Increase load incrementally
        mpc.bus(:,PD)=1.02*mpc.bus(:,PD);
        mpc.bus(:,QD)=1.02*mpc.bus(:,QD);
    else
        break;
    end
    
    iterations = iterations + 1;

end

end

