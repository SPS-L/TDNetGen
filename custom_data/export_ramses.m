function export_ramses(filename, constant_load, penetration_level, generation_weight, run_opf, results_lf, tap_info, pv, mt, pv_power, mt_power)
% Export data into RAMSES format for dynamic simulations

define_constants;

% Read the dynamic info from the reference file
to_read = 'custom_data/dynamic_data.txt';
fid = fopen(to_read);
tline = fgets(fid);

i = 1;
while ischar(tline)
    template{i} = tline;
    tline = fgets(fid);
    i = i+1;
end
fclose(fid);

fileID = fopen(filename,'w');
fprintf(fileID,'%s\n','#T&D test system');
fprintf(fileID,'%s %u\n','#Constant Load = ', constant_load);
fprintf(fileID,'%s %.2f\n','#Penetration Level = ', penetration_level);
fprintf(fileID,'%s %.2f\n\n','#Generation Weight = ', generation_weight);

% Copy the generator information
i = 1;
line = template{i};
while(~strcmp(line(1),'D'))
    fprintf(fileID,'%s',line);
    i = i+1;
    line = template{i};
end
fprintf(fileID,'\n');

% Get the LTC dynamic info
j = 1;
while(strcmp(line(1),'D'))
    line_split = strsplit(line,' ');
    ltc_dyn(j,1:3) = [dnbus2int(str2double(line_split(5)),0) str2double(line_split(end-2)) str2double(line_split(end-1))];
    i = i+1;
    j = j+1;
    line = template{i};
end

% Get the tap information from ARTERE in the right format
index_trfo = results_lf.branch(:,TAP) ~= 0;
trfo = results_lf.branch(index_trfo,:);
index_trfo_dn = results_lf.branch(index_trfo,F_BUS) > 50000;
trfo_dn = trfo(index_trfo_dn,:);
for j=1:size(tap_info,1)
    if(tap_info(j,1) < 1000)
        tap_info(j,1) = dnbus2int(tap_info(j,1),0);
    end
end

% Write the LTC info
for j=1:size(trfo_dn,1)
    bus_name = num2str(trfo_dn(j,F_BUS));
    
    find_tap = zeros(size(tap_info,1),1);
    for h=1:size(tap_info,1)
        temp = num2str(tap_info(h,1));
        find_tap(h) = str2double(temp(1:3));
    end
    
    find_ltc = zeros(size(ltc_dyn,1),1);
    for h=1:size(ltc_dyn,1)
        temp = num2str(ltc_dyn(h,1));
        find_ltc(h) = str2double(temp(1:3));
    end
    
    index_tap = find(find_tap == str2double(bus_name(1:3)),1);
    index_ltc = find(find_ltc == str2double(bus_name(1:3)),1);
    ltc_name = strcat(bus_name,'-',num2str(trfo_dn(j,T_BUS)));
    if(index_tap)
        fprintf(fileID,'%s %s %s %s %s %d %.0f %.0f %u %.2f %.2f %u %u;\n','DLTC', 'LTC2', ltc_name,...
            ltc_name, bus_name, -1, tap_info(index_tap,2), tap_info(index_tap,3), tap_info(index_tap,4), ...
            tap_info(index_tap,5), tap_info(index_tap,6), ltc_dyn(index_ltc,2), ltc_dyn(index_ltc,3));
    end
end
fprintf(fileID,'\n');

% Write the load info
index_load = results_lf.bus(:,PD) ~= 0;
load = results_lf.bus(index_load,:);

for j=1:size(load,1)
    str_load = num2str(load(j,BUS_I));
    load_name = strcat('L_',str_load);
    
    ind = find(pv(:,1) == load(j,BUS_I));
    if(ind)
        load(j,PD) = load(j,PD) + pv(ind,2);
    end    
    fprintf(fileID,'%s %s %u %.0f %.0f %.4f %.4f %.0f %.0f %.1f %.0f %.0f %.0f %.0f %.0f %.1f %.0f %.0f %.0f;\n',...
        'LOAD', load_name, load(j,BUS_I), 0, 0, -1.0*load(j,PD), -1.0*load(j,QD), 0, 1, 1, 0, 0, 0, 0, 1, 2, 0, 0, 0);
end
fprintf(fileID,'\n');

% Write the PV info (if there is any)
if(penetration_level ~= 0)
    temp = template{end-1};
    pv_info = temp(35:end);
    for j=1:size(pv,1)
        str_pv = num2str(pv(j,1));
        pv_name = strcat('PV',str_pv);
        index_dn = str2double(str_pv(2:3));
        fprintf(fileID,'%s %s %s %u %.0f %.0f %.4f %s',...
            'INJEC', 'PVD',pv_name, pv(j,1), 0, 0, pv_power(index_dn), pv_info);
    end
    fprintf(fileID,'\n');
end

% Write the MT info (if there is any)
if(penetration_level ~= 0)
    temp = template{end};
    mt_info = temp(36:end);
    for j=1:size(mt,1)
        str_mt = num2str(mt(j,1));
        mt_name = strcat('MT',str_mt);
        if(run_opf)
            index_mt = find(results_lf.gen(:,1) == mt(j,1),1);
            fprintf(fileID,'%s %s %u %.0f %.0f %.4f %.4f %s\n',...
                'SYNC_MACH', mt_name, mt(j,1), 0, 0, results_lf.gen(index_mt,PG), results_lf.gen(index_mt,QG), mt_info);
        else
            index_mt = str2double(str_mt(2:3));
            fprintf(fileID,'%s %s %u %.0f %.0f %.4f %.0f %s\n',...
                'SYNC_MACH', mt_name, mt(j,1), 0, 0, mt_power(index_mt), 0, mt_info);
        end
    end
end
fprintf(fileID,'\n');
fclose(fileID);
end