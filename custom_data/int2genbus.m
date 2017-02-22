function name = int2genbus(number)
% Converts an int bus name into a string bus name (e.g. 9181->g18b) to follow the requirements of artere

if(number < 50000 && number > 9000)
	name = int2str(number);

	if(name(1) == '9')
		name(1) = 'g';

		if(name(2) == '0')
			name = strcat(name(1), name(3:end));
		end

		if(name(end) == '0')
			name = strcat(name(1:(end-1)));
		elseif(name(end) == '1')
			name = strcat(name(1:(end-1)), 'b');
		end
	end
else
	name = int2str(number);
end
end