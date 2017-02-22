function number = internal_dn_node(name, index)
% To represent the 75 nodes of each DN uniquelly, we add 2 digits to the name of the main bus

index = num2str(index);
name = num2str(name);

if(index == '0')
    number = str2double(name);
else
    if(length(index) == 1)
        name = strcat(name, '0', index);
    else
        name = strcat(name, index);
    end    

    if(ischar(name))
        number = str2double(name);
    else
        number = 0;
    end
end
end