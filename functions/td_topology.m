function [info_dn, dn_branch, resultslf_dn, pv_power, mt_power] = td_topology(constant_load, dn_buses, bus_nonsplit, branch_nonsplit, number_dn, resultslf_dn0, resultslf_tn, base_MVA, results_default, penetration_level, pv_powerlong, pv_powershort, oversize)
% Creates a new topology with DNs replacing the aggregated loads of the TN

define_constants;
index = 0;
info_dn = zeros(sum(number_dn)+size(bus_nonsplit,1),VMIN);
dn_branch = zeros(sum(number_dn)+size(branch_nonsplit,1),ANGMAX);
resultslf_dn = cell(sum(number_dn)+length(number_dn), 1);
pv_power = zeros(sum(number_dn)+length(number_dn), 1);
mt_power = zeros(sum(number_dn)+length(number_dn), 1);
r = zeros(sum(number_dn)+length(number_dn), 2);

for i=1:size(dn_buses,1) 
    for j=1:number_dn(i)+1
        index = index + 1;         
        
        % Store the DN topology
        random_index = mod(randi(10000),99)+1;
        resultslf_dn{index} = resultslf_dn0{random_index};
        pv_power(index) = pv_powerlong(random_index);
        mt_power(index) = pv_powershort(random_index);
        
        if(j ~= number_dn(i)+1)
            % Get all the DN information in the matpower format
            info_dn(index,BUS_I) = dnbus2int(dn_buses(i,BUS_I), j);            
            info_dn(index, PD) = resultslf_dn{index}.gen(1,PG);
            power_ratio = resultslf_dn{index}.gen(1,PG)/results_default.gen(1,PG);
            info_dn(index, QD) = power_ratio*dn_buses(i, QD)/(number_dn(i)+1); 
                        
            % Add shunt elements to the DN to get the required reactive power
            delta_Q = info_dn(index, QD) - sum(resultslf_dn{index}.bus(:,QD));
            if((constant_load == true || penetration_level == 0) && oversize == 1)
                resultslf_dn{index}.bus(2, BS) = resultslf_dn{index}.bus(2, BS) - delta_Q; 
            end
        else            
            % The last DN should be defined such as the total active and
            % reactive power is the same as the aggregated load
            info_dn(index,BUS_I) = dnbus2int(dn_buses(i,BUS_I), j);        
            info_dn(index, PD) = dn_buses(i,PD) - number_dn(i)*resultslf_dn{index}.gen(1,PG);
            power_ratio = resultslf_dn{index}.gen(1,PG)/results_default.gen(1,PG);
            info_dn(index, QD) = power_ratio*dn_buses(i, QD)/(number_dn(i)+1);
            
            % Update the DN topology to comply with the power demand
            delta_Q = info_dn(index, QD) - sum(resultslf_dn{index}.bus(:,QD));
            if((constant_load == true || penetration_level == 0) && oversize == 1)
                resultslf_dn{index}.bus(2, BS) = resultslf_dn{index}.bus(2, BS) - delta_Q;
            end
        end
        
        % Get the bus info in the matpower format
        info_dn(index, BUS_TYPE) = dn_buses(i, BUS_TYPE);
        info_dn(index, GS:ZONE) = dn_buses(i, GS:ZONE);
        info_dn(index, BASE_KV) = resultslf_dn{index}.bus(2, BASE_KV);
        info_dn(index, VMAX:VMIN) = resultslf_dn{index}.bus(2, VMAX:VMIN);       
        
        % Get the branch info in the matpower format
        dn_branch(index, F_BUS) = info_dn(index,BUS_I);
        main_bus = num2str(info_dn(index,BUS_I));
        main_bus = str2double(strcat(main_bus(1:end-2), '00'));
        k = find(resultslf_tn.branch(:,F_BUS) == main_bus);
        dn_branch(index, T_BUS) = resultslf_tn.branch(k,T_BUS);
        dn_branch(index, RATE_A:RATE_C) = 10*ceil((resultslf_tn.branch(k, RATE_A:RATE_C)/(number_dn(i)+1))/10);
        dn_branch(index, BR_R:BR_B) = resultslf_tn.branch(k, BR_R:BR_B);
        dn_branch(index, BR_STATUS:ANGMAX) = resultslf_tn.branch(k, BR_STATUS:ANGMAX);
        
        % Use the power flow equations to determine the turns ratio of the
        % tap-changing transformers
        P = info_dn(index, PD)/base_MVA;
        Q = info_dn(index, QD)/base_MVA;
        X = resultslf_tn.branch(k,BR_X);
        l = find(resultslf_tn.bus(:,BUS_I) == dn_branch(index, T_BUS));
        VM1 = resultslf_tn.bus(l,VM);
        VM2 = resultslf_dn{index}.bus(2,VM);
        VA1 = resultslf_tn.bus(l,VA);

        delta = atand(P*X/(VM2^2+Q*X));
        r(index,2) = 1/(VM1*VM2*sind(delta)/(P*X));
        r(index,1) = info_dn(index, BUS_I);
        
        %P2 = VM1*VM2*sind(delta)/(r*X);
        %Q2 = VM1*VM2*cosd(delta)/(r*X)-VM2^2/X;
        
        VA2 = VA1 - delta;
        
        dn_branch(index, TAP) = r(index,2);
        info_dn(index, VM) = VM2;
        info_dn(index, VA) = VA2; 
        
        % Include the angle shift in the DN
        delta_dn = info_dn(index, VA) - resultslf_dn{index}.bus(2,VA); 
        resultslf_dn{index}.bus(:, VA) = resultslf_dn{index}.bus(:, VA) + delta_dn;  
    end
end

for k=1:size(bus_nonsplit,1)
    bus_nonsplit(k,1) = dnbus2int(bus_nonsplit(k,1),0);
    info_dn(index+k,:) = bus_nonsplit(k,:);
    
    dn_branch(index+k,:) = branch_nonsplit(k,:);
end

end