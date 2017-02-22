function resultslf_dn = final_dn(number_dn, non_dn, resultslf_dn0, resultslf_tn)
% Recalculates the power flow of the DNs to match the angles and the
% voltages for the T&D system

define_constants;
index = 0;
resultslf_dn = cell(sum(number_dn), 1);

for i=1:length(number_dn) 
    for j=1:number_dn(i)+1
        index = index + 1; 
        delta_dn = resultslf_tn.bus(non_dn+index,VA) - resultslf_dn0{index}.bus(2,VA); 
        resultslf_dn0{index}.bus(:, VA) = resultslf_dn0{index}.bus(:, VA) + delta_dn;
        evalc('resultslf_dn{index} = runpf(resultslf_dn0{index});');
    end
end
end