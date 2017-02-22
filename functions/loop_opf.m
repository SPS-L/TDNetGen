function results_opf = loop_opf(results_opf, mpopt, info_dn, non_split, non_dn, verbose, opf_setpoint)
% Solves the OPF step-by-step to meet the voltage limits

define_constants;
range = size(info_dn,1) - non_split;
tap_voltage = zeros(range,1);
voltage_uplim = opf_setpoint + 0.15;
voltage_max = opf_setpoint + 0.05;
voltage_min = opf_setpoint - 0.05;
voltage_downlim = opf_setpoint - 0.1;

for index=1:5
    for i=1:range
        l = find(results_opf.branch(:,F_BUS) == results_opf.bus(non_dn+i,BUS_I),1);
        if(results_opf.bus(non_dn+i,VM) <= voltage_downlim)
            results_opf.branch(l,TAP) = results_opf.branch(l,TAP) + 0.01;
        elseif(results_opf.bus(non_dn+i,VM) <= voltage_min)            
            results_opf.branch(l,TAP) = results_opf.branch(l,TAP) + 0.005;
        elseif(results_opf.bus(non_dn+i,VM) >= voltage_uplim)
            results_opf.branch(l,TAP) = results_opf.branch(l,TAP) - 0.01;
        elseif(results_opf.bus(non_dn+i,VM) >= voltage_max)
            results_opf.branch(l,TAP) = results_opf.branch(l,TAP) - 0.005;
        else
            tap_voltage(i) = true;
        end
    end
    
    if(verbose)
        results_opf = runopf(results_opf, mpopt);
    else
        evalc('results_opf = runopf(results_opf, mpopt);');
    end
    
    if(results_opf.success == 1 && max(results_opf.bus(:,MU_VMIN) < 1000))
        break;
    end
end

end