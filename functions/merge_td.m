function [results_td, pv, mt] = merge_td(resultslf_tn, resultslf_dn, pv_buses, non_dn, non_split, penetration_level, constant_load, pv_power, mt_power)
% Creates the final topology including every node of the T&D system

define_constants;
number_pv = length(pv_buses)-4;
pv = zeros(size(resultslf_dn,1)*number_pv,2);
mt = zeros(size(resultslf_dn,1)*4,2);
results_td = resultslf_tn;
shunt = zeros(size(resultslf_dn,1),1);

for i=1:size(resultslf_dn,1)
    % Put all the buses together
    shunt(i) = resultslf_dn{i,1}.bus(2,BS);
    resultslf_dn{i,1}.bus(1:2,:) = [];
    main = resultslf_tn.bus(non_dn+i,BUS_I);

    for j=1:size(resultslf_dn{i,1}.bus,1)
        resultslf_dn{i,1}.bus(j,BUS_I) = internal_dn_node(main,j);
    end
    
    for j=1:4
        index = int2str(resultslf_dn{i,1}.gen(j+1,GEN_BUS));
        name = internal_dn_node(main,str2double(index(3:4)));
        resultslf_dn{i,1}.gen(j+1,GEN_BUS) = name;
        mt((i-1)*4+j,1) = name;
        mt((i-1)*4+j,2) = mt_power(i);
    end
    
    for k=1:number_pv
        index = int2str(pv_buses(k+4));
    	pv((i-1)*number_pv+k,1) = internal_dn_node(main, str2double(index(3:4)));
        pv((i-1)*number_pv+k,2) = pv_power(i);
    end
  
    % Put all the branches together
    resultslf_dn{i,1}.branch(1:2,:) = [];
    for j=1:size(resultslf_dn{i,1}.branch,1)
        fbus = num2str(resultslf_dn{i,1}.branch(j,F_BUS));
        findex = str2double(fbus(3:4));
        resultslf_dn{i,1}.branch(j,F_BUS) = internal_dn_node(main,findex);
        
        tbus = num2str(resultslf_dn{i,1}.branch(j,T_BUS));
        tindex = str2double(tbus(3:4));        
        resultslf_dn{i,1}.branch(j,T_BUS) = internal_dn_node(main,tindex);
    end 
    
    if(i==1)
        merge_dn.bus = resultslf_dn{i,1}.bus;
        merge_dn.gen = resultslf_dn{i,1}.gen(2:5,:);
        merge_dn.branch = resultslf_dn{i,1}.branch;
    else
        merge_dn.bus = [merge_dn.bus; resultslf_dn{i,1}.bus];
        merge_dn.gen = [merge_dn.gen; resultslf_dn{i,1}.gen(2:5,:)];
        merge_dn.branch = [merge_dn.branch; resultslf_dn{i,1}.branch];
    end   
    
end

range = size(resultslf_tn.bus,1) - non_split;
resultslf_tn.bus(1:range,PD:QD) = zeros();
results_td.bus = [resultslf_tn.bus; merge_dn.bus];
results_td.gen = [resultslf_tn.gen; merge_dn.gen];
results_td.branch = [resultslf_tn.branch; merge_dn.branch];

% Shunts added
if(constant_load == true || penetration_level == 0)
    for i=1:length(shunt)
        results_td.bus(non_dn+i,BS) = shunt(i);
    end
end

end