function export_artere(filename, results_lf, base_MVA, constant_load, penetration_level, generation_weight, tap_info)
% Export data into ARTERE format for power flow

define_constants;

fileID = fopen(filename,'w');
fprintf(fileID,'%s\n','#T&D test system');
fprintf(fileID,'%s %u\n','#Constant Load = ', constant_load);
fprintf(fileID,'%s %.2f\n','#Penetration Level = ', penetration_level);
fprintf(fileID,'%s %.2f\n\n','#Generation Weight = ', generation_weight);

for i=1:size(results_lf.bus,1)
    fprintf(fileID,'%s %s %u %.4f %.4f %.1f %.4f ;\n','BUS', ... 
        int2genbus(results_lf.bus(i,BUS_I)), results_lf.bus(i,BASE_KV), ...
        results_lf.bus(i,PD), results_lf.bus(i,QD), results_lf.bus(i,BS), results_lf.bus(i,GS));
end
fprintf(fileID,'\n');

for i=1:size(results_lf.gen,1)
    if(results_lf.gen(i,GEN_BUS) > 5000000)
    fprintf(fileID,'%s %s %s %s %.2f %.2f %.2f %.2f %d %.2f %u;\n','GENER', ... 
            int2genbus(results_lf.gen(i,GEN_BUS)), int2genbus(results_lf.gen(i,GEN_BUS)), ...
            int2genbus(results_lf.gen(i,GEN_BUS)), results_lf.gen(i,PG), results_lf.gen(i,QG), ...
            0, results_lf.gen(i,MBASE), results_lf.gen(i,QMIN), ...
            results_lf.gen(i,QMAX), results_lf.gen(i,GEN_STATUS));        
    else
        fprintf(fileID,'%s %s %s %s %.2f %.2f %.2f %u %d %.2f %u;\n','GENER', ... 
            int2genbus(results_lf.gen(i,GEN_BUS)), int2genbus(results_lf.gen(i,GEN_BUS)), ...
            int2genbus(results_lf.gen(i,GEN_BUS)), results_lf.gen(i,PG), results_lf.gen(i,QG), ...
            results_lf.gen(i,VG), results_lf.gen(i,MBASE), results_lf.gen(i,QMIN), ...
            results_lf.gen(i,QMAX), results_lf.gen(i,GEN_STATUS));
    end
end

k = results_lf.bus(:,BUS_TYPE) == 3;
fprintf(fileID,'%s %s;\n', 'SLACK', int2genbus(results_lf.bus(k,BUS_I)));
fprintf(fileID,'\n');

l = results_lf.branch(:,TAP) == 0;
line = results_lf.branch(l,:);

for i=1:size(line,1)
    if(i~=1)
        name_previous = name;
    end
    name = strcat(int2str(line(i,F_BUS)), '-', int2str(line(i,T_BUS)));
    if(i~=1)
        if(strcmp(name,name_previous))
            name = strcat(name, '-2');
        end
    end
    % pu -> ohms
    m = results_lf.bus(:,BUS_I) == line(i,F_BUS);
    z_base =results_lf.bus(m,BASE_KV)^2/base_MVA;
    
    fprintf(fileID,'%s %s %u %u %.3f %.3f %.3f %.1f %u ;\n','LINE', ... 
        name, line(i,F_BUS), line(i,T_BUS), line(i,BR_R)*z_base, ...
        line(i,BR_X)*z_base, line(i,BR_B)/(2*10^(-6)*z_base), ...
        line(i, RATE_A), line(i,BR_STATUS));
end
fprintf(fileID,'\n');

n = results_lf.branch(:,TAP) ~= 0;
trfo = results_lf.branch(n,:);

for i=1:size(trfo,1)
    if(i~=1)
        name_previous = name;
    end
    name = strcat(int2genbus(trfo(i,F_BUS)), '-', int2str(trfo(i,T_BUS)));
    if(i~=1)
        if(strcmp(name,name_previous))
            name = strcat(name, '-2');
        end
    end
    
    quote = '''';
    n = 1/trfo(i,TAP);
    S = trfo(i, RATE_A);
    
    o = find(tap_info(:,1) == 0, 1, 'last');
    
    if(i > o)
        if(strncmpi(num2str(trfo(i,F_BUS)),'5',1))
            fbus = num2str(trfo(i,F_BUS));
            main_bus = str2double(strcat(fbus(1:(end-2)),'00'));
            x = find(tap_info(:,1) == main_bus);
            
            fprintf(fileID,'%s %s %s %u %u %.1f %.1f %.1f %.0f %.1f %u %u %u %.2f %.2f %u;\n','TRFO', ... 
                name, int2genbus(trfo(i,F_BUS)), trfo(i,T_BUS), trfo(i,F_BUS), ...
                trfo(i,BR_R)*(100*S)/(n^2*base_MVA), trfo(i,BR_X)*(100*S)/(n^2*base_MVA), ...
                trfo(i,BR_B)*(100*base_MVA)/(n^2*S), n*100, S, tap_info(x,2), tap_info(x,3), ...
                tap_info(x,4), tap_info(x,5), tap_info(x,6), trfo(i,BR_STATUS));
        else
            x = find(tap_info(:,1) == trfo(i,F_BUS),1);
            fprintf(fileID,'%s %s %s %u %u %.1f %.1f %.1f %.0f %.1f %u %u %u %.2f %.2f %u;\n','TRFO', ... 
                name, int2genbus(trfo(i,F_BUS)), trfo(i,T_BUS), trfo(i,F_BUS), ...
                trfo(i,BR_R)*(100*S)/(n^2*base_MVA), trfo(i,BR_X)*(100*S)/(n^2*base_MVA), ...
                trfo(i,BR_B)*(100*base_MVA)/(n^2*S), n*100, S, tap_info(x,2), tap_info(x,3), ...
                tap_info(x,4), tap_info(x,5), tap_info(x,6), trfo(i,BR_STATUS));
        end
    else
        fprintf(fileID,'%s %s %s %u %s %s %.1f %.1f %.1f %.0f %.1f %u %u %u %u %u %u;\n','TRFO', ... 
            name, int2genbus(trfo(i,F_BUS)), trfo(i,T_BUS), quote, quote, ...
            trfo(i,BR_R)*(100*S)/(n^2*base_MVA), trfo(i,BR_X)*(100*S)/(n^2*base_MVA), ...
            trfo(i,BR_B)*(100*base_MVA)/(n^2*S), n*100, S, 0, 0, 0, 0, 0, trfo(i,BR_STATUS));
    end
end
fprintf(fileID,'\n');

for i=1:size(results_lf.bus,1)
    fprintf(fileID,'%s %s %.3f %.3f;\n','LFRESV', ... 
        int2genbus(results_lf.bus(i,BUS_I)), results_lf.bus(i,VM), ...
        results_lf.bus(i,VA)*pi/180);
end
fprintf(fileID,'\n');

fclose(fileID); 

end