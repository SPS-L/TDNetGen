
# TDNetGen: An open-source, parametrizable, large-scale, combined, transmission and distribution test system
## Power Systems Laboratory, ETH Zürich

Please check XYZ link to paper for more information.

### Model overview
 
The transmission network is based on the well-known Nordic32 system sketched below:
![picture](images/TN_topo.png =150x)

The distribution network is based on a 75-bus radial system sketched below:
![picture](images/DN_topo.png =150x)

### Setup and use

1. Before using the toolbox, it is necessary to download Matpower from http://www.pserc.cornell.edu/matpower/

2. In the file 'parameters.m', change the parameter 'matpower_path' to direct to the downloaded matpower folder (absolute or relative path). This tool has been tested with Matpower 6.0, newer versions should be compatible but not tested

3. Change the other parameters in 'parameters.m' according to the system that you want to generate

4. Run 'main.m'

5. Find the T&D system exported in the desired format in the folder 'output_data' 


### System configuration

- Developed with Matlab 2015b and Matpower 6.0



