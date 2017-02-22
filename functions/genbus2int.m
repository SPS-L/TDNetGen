function number = genbus2int(name)
% Converts a string generator bus name into an int bus name (e.g. g18b->9181) to follow the requirements of matpower

b = false;

if(name(1) == 'g')
	name(1) = '9';

	if(name(end) == 'b')
		name = strcat(name(1:(end-1)), '1');
		b = true;
	end

	if(length(name) == 2)
		name = strcat(name(1), '0', name(2), '0');
	elseif(length(name) == 3 && b == false)
		name = strcat(name(1:3), '0');
	elseif(length(name) == 3 && b == true)
		name = strcat(name(1), '0', name(2:3));
	end

	if(ischar(name))
		number = str2double(name);
	else
		number = 0;
	end
else
	number = str2double(name);
end
end