function number = dnbus2int(name, index)
% Converts a (DN) aggregated bus name into several int bus names (e.g. 12->51201, 51202...)
% Nomenclature : '5' DN load, '01' Bus ID, '01' DN ID (index)

index = num2str(index);
name = num2str(name);

if(length(name) == 1)
    if(length(index) == 1)
        name = strcat('50',name, '0', index);
    else
        name = strcat('50',name, index);
    end
else
    if(length(index) == 1)
        name = strcat('5',name, '0', index);
    else
        name = strcat('5',name, index);
    end
end    
        
if(ischar(name))
    number = str2double(name);
else
    number = 0;
end

end