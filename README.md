[![DOI](https://zenodo.org/badge/85711602.svg)](https://zenodo.org/badge/latestdoi/85711602)

# TDNetGen: An open-source, parametrizable, large-scale, combined, transmission and distribution test system
## Power Systems Laboratory, ETH Zürich

### About
 
TDNetGen is an open-source MATLAB toolbox that is able to generate synthetic, combined transmission and distribution network models. These can be used to analyze the interactions between transmission and multiple distribution systems, such as the provision of ancillary services by active distribution grids, the co-optimization of planning and operation, the development of emergency control and protection schemes spanning over different voltage levels, the analysis of combined market aspects, etc. The generated test-system models are highly customizable, providing the user with the flexibility to easily choose the desired characteristics, such as the level of renewable energy penetration, the size of final system, etc.

Please check XYZ link to paper for more information and better explanation of the parameters.

### Setup and use

1. Before using the toolbox, it is necessary to download Matpower from http://www.pserc.cornell.edu/matpower/

2. In the file 'parameters.m', change the parameter 'matpower_path' to direct to the downloaded matpower folder (absolute or relative path). This tool has been tested with Matpower 6.0, newer versions should be compatible but not tested

3. Change the other parameters in 'parameters.m' according to the system that you want to generate

4. Run 'main.m'

5. Find the T&D system exported in the desired format in the folder 'output_data' 


### System requirements

TDNetGen has been tested with MATLAB 2015b, MATPOWER 5.1 and 6.0, under Windows 7, Windows 10, Linux Debian Wheezy, and MAC OSX.

### License and disclaimer

The code of TDNetGen to generate the combined TN and DN systems is provided under MIT License (see LICENSE file). However, the toolbox requires MATPOWER and MATLAB to be executed. These are not included in this repository and the user should download them separately and refer to their respective licenses.

