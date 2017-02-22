function mpc = add_gen_costs_for_OPF(mpc, number_dn)
% Adds the cost coefficients to the T&D model to run an OPF
% Check the paper for more details

gen_size = size(mpc.gen,1);
dg_size = sum(number_dn);

gen_cost(:,1) = 2*ones(gen_size,1);
gen_cost(:,2:3) = zeros(gen_size,2);
gen_cost(:,4) = 3*ones(gen_size,1);

gen_cost(1,5:7) = [0.0026 15.4 809];
gen_cost(2,5:7) = [0.0026 20.5 1079];
gen_cost(3,5:7) = [0.0026 17.6 925];
gen_cost(4,5:7) = [0.0026 20.5 1076];
gen_cost(5,5:7) = [0.0026 30.8 1619];
gen_cost(6,5:7) = [0.0225 49.2 2226];
gen_cost(7,5:7) = [0.0225 54.8 2477];
gen_cost(8,5:7) = [0.0026 15.4 809];
gen_cost(9,5:7) = [0.0026 12.3 647];
gen_cost(10,5:7) = [0.0026 15.4 809];
gen_cost(11,5:7) = [0.0026 24.7 1439];
gen_cost(12,5:7) = [0.0026 25.7 1349];
gen_cost(13,5:7) = [0.0048 40.9 2070];
gen_cost(14,5:7) = [0.0048 40.9 2070];
gen_cost(15,5:7) = [0.0048 44.0 2229];
gen_cost(16,5:7) = [0.0048 44.0 2229];
gen_cost(17,5:7) = [0.0048 40.9 2070];
gen_cost(18,5:7) = [0.0048 40.9 2070];
gen_cost(19,5:7) = [0.0297 72.2 3264];
gen_cost(20,5:7) = [0.0297 72.2 3264];
gen_cost(21,5:7) = [0.0297 72.2 3264];
gen_cost(22,5:7) = [0.0026 20.5 1076];
gen_cost(23,5:7) = [0.0026 15.4 809];

dg_cost = [0 .13 30;0 .35 50;0 .13 30;0 .35 50];

gen_cost(24:23+4*dg_size,5:7) = repmat(dg_cost,dg_size,1); 

mpc.gencost = gen_cost;

end