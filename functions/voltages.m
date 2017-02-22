function [results_lf, fail_ltc] = voltages(results_lf, info_dn, non_dn, non_split, tap_info, oversize, pf_setpoint)
% Make sure that the voltage at the first node of the DN is around pf_setpoint

define_constants;
range = size(info_dn,1) - non_split;
tap_voltage = zeros(range,1);
x = tap_info(:,1) == 0;
tap_info(x,:) = [];
y = find(tap_info(:,1) > 1000);
trfo_tn = zeros(length(y),1);
if(oversize == 1)
    voltage_uplim = pf_setpoint + 0.015;
    voltage_max = pf_setpoint + 0.005;
    voltage_min = pf_setpoint - 0.005;
    voltage_downlim = pf_setpoint - 0.015;
else
    voltage_uplim = pf_setpoint + 0.01;
    voltage_max = pf_setpoint;
    voltage_min = pf_setpoint - 0.03;
    voltage_downlim = pf_setpoint - 0.04;    
end
tap_max = 1./(tap_info(length(trfo_tn):length(trfo_tn)+1,2)/100);
tap_min = 1./(tap_info(length(trfo_tn):length(trfo_tn)+1,3)/100);

iterations = 0;
fail_ltc = false;

% First, check the tap-changing transformers of the TN
while(sum(trfo_tn) ~= length(trfo_tn))
    for i=1:length(trfo_tn)
        if(mod(i,2) == 0)
            k = find(results_lf.branch(:,F_BUS) == tap_info(i,1),1,'last');
        else
            k = find(results_lf.branch(:,F_BUS) == tap_info(i,1),1,'first');
        end
        l = find(results_lf.bus(:,BUS_I) == tap_info(i,1),1);
        v_ideal = tap_info(i,6);
        
        if(results_lf.bus(l,VM) <= v_ideal-0.02)
            if(results_lf.branch(k,TAP) < tap_max(1))
                results_lf.branch(k,TAP) = results_lf.branch(k,TAP) + 0.01;
            else
                results_lf.branch(k,TAP) = tap_max(1);
                trfo_tn(i) = true;
            end
        elseif(results_lf.bus(l,VM) <= v_ideal-0.01) 
            if(results_lf.branch(k,TAP) < tap_max(1))
                results_lf.branch(k,TAP) = results_lf.branch(k,TAP) + 0.005;
            else
                results_lf.branch(k,TAP) = tap_max(1);
                trfo_tn(i) = true;
            end
        elseif(results_lf.bus(l,VM) >= v_ideal+0.02)
            if(results_lf.branch(k,TAP) > tap_min(1))
                results_lf.branch(k,TAP) = results_lf.branch(k,TAP) - 0.01;
            else
                results_lf.branch(k,TAP) = tap_min(1);
                trfo_tn(i) = true;
            end
        elseif(results_lf.bus(l,VM) >= v_ideal+0.01)
            if(results_lf.branch(k,TAP) > tap_min(1))
                results_lf.branch(k,TAP) = results_lf.branch(k,TAP) - 0.005;
            else
                results_lf.branch(k,TAP) = tap_min(1);
                trfo_tn(i) = true;
            end
        else
            trfo_tn(i) = true;
        end       
    end 
    evalc('results_lf = runpf(results_lf);');
    iterations = iterations + 1;
end

% Change the turns ratio until the voltage is around pf_setpoint
while(sum(tap_voltage) ~= length(tap_voltage))
    for i=1:range
        l = find(results_lf.branch(:,F_BUS) == results_lf.bus(non_dn+i,BUS_I),1);
        results_lf.bus(non_dn+i,VMAX) = voltage_max;
        if(results_lf.bus(non_dn+i,VM) <= voltage_downlim)
            if(results_lf.branch(l,TAP) < tap_max(2))
                results_lf.branch(l,TAP) = results_lf.branch(l,TAP) + 0.01;
            else
                results_lf.branch(l,TAP) = tap_max(2);
                tap_voltage(i) = true;
            end
        elseif(results_lf.bus(non_dn+i,VM) <= voltage_min) 
            if(results_lf.branch(l,TAP) < tap_max(2))
                results_lf.branch(l,TAP) = results_lf.branch(l,TAP) + 0.005;
            else
                results_lf.branch(l,TAP) = tap_max(2);
                tap_voltage(i) = true;
            end
        elseif(results_lf.bus(non_dn+i,VM) >= voltage_uplim)
            if(results_lf.branch(l,TAP) > tap_min(2))
                results_lf.branch(l,TAP) = results_lf.branch(l,TAP) - 0.01;
            else
                results_lf.branch(l,TAP) = tap_min(2);
                tap_voltage(i) = true;
            end
        elseif(results_lf.bus(non_dn+i,VM) >= voltage_max)
            if(results_lf.branch(l,TAP) > tap_min(2))
                results_lf.branch(l,TAP) = results_lf.branch(l,TAP) - 0.005;
            else
                results_lf.branch(l,TAP) = tap_min(2);
                tap_voltage(i) = true;
            end
        else
            tap_voltage(i) = true;
        end
    end
    evalc('results_lf = runpf(results_lf);');
    iterations = iterations + 1;

    if(iterations > 50)
        fail_ltc = true;
        break;
    end
end

end