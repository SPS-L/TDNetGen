function results_lf = export_data(export_format, results_lf, tap_info, penetration_level, generation_weight, run_opf, fail_opf, constant_load, pv, mt, distributed_generation, mt_power)
% Export data in the desired format

    % Check if the folders exist
    if(~exist('output_data/','dir'))
        mkdir('output_data/');
    end
    if(~exist(['output_data/' export_format '/'],'dir'))
        mkdir(['output_data/' export_format '/']);
    end
    
    if(run_opf == true && fail_opf == false)
        disp(['Exporting the OPF-based data (' export_format ')...']);
    else
        disp(['Exporting the data (' export_format ')...']);
    end
    
    if(strcmp(export_format,'matpower'))
        mpopt = mpoption('out.all', 0);
        td_data = ['output_data/' export_format '/cl' num2str(constant_load) '_pl' num2str(penetration_level) '_gw' num2str(generation_weight) '.mat'];
        evalc('results_lf = runpf(results_lf, mpopt, td_data);');
    end
    
	% Custom exporters
	
    if(strcmp(export_format,'artere') || strcmp(export_format,'ramses'))
        filename = ['output_data/' export_format '/cl' num2str(constant_load) '_pl' num2str(penetration_level) '_gw' num2str(generation_weight) '.dat'];
        for i=1:size(tap_info,1)
            if(tap_info(i,1) < 100 && tap_info(i,1) ~= 0)
                tap_info(i,1) = dnbus2int(tap_info(i,1),0);
            end
        end
        tap_info = sortrows(tap_info);
        export_artere(filename, results_lf, results_lf.baseMVA, constant_load, penetration_level, generation_weight, tap_info);
    end
    
    if(strcmp(export_format,'ramses'))
        filename = ['output_data/' export_format '/cl' num2str(constant_load) '_pl' num2str(penetration_level) '_gw' num2str(generation_weight) '.dat'];
        export_ramses(filename, constant_load, penetration_level, generation_weight, run_opf, results_lf, tap_info, pv, mt, distributed_generation, mt_power);
    end

end