# ARA Tools

This is a collection of generic MATLAB functions for handling whole-brain volume data and associated sparse point data.
"sparse" data are things such as clicked cell locations, traced neurite trees, or traced injections. 
In particular, this package provides functions for relating these sparse data to the Allen Reference Atlas (ARA). 
The package helps you perform the following operations:

1. Downsampling sample brain volumes to the ARA voxel size. 
2. Downsampling associated sparse data to the ARA voxel size and exporting of these data to a csv file.
3. Registering the sample brain and sparse data to the ARA: both sample -> ARA and ARA -> sample transformations.
4. Determining the ARA brain area associated with each sparse point.
5. Extracting area outlines from the reference atlas that you can use for plotting. 

Functions that are likely to be shared between all or most whole-brain anatomy projects should go here. 
More specific functions (those related to a particular project) should not be in this repository. 

**NOTE**: some examples and documentation are provided below, but not everything is documented on this page (yet). 
All functions are documented, so please go through the code to see what's available. 




## Installation

1. Either [download the zip](https://bitbucket.org/lasermouse/ara_tools/downloads) or (better) clone the repository
in a Git client like [SmartGit](http://www.syntevo.com/smartgit/) or [SourceTree](https://www.sourcetreeapp.com).
Cloning with git makes it easier to deploy updates.
2. You will need some or all of the dependencies listed at the bottom. Which ones you need depends on what you're doing. 
e.g. you won't need the registration stuff to plot cells. 
3. There has been limited testing of these tools on Windows. 
4. You will need a copy of the Allen Atlas and the template brain in MHD format. One is included in the [downloads page](https://bitbucket.org/lasermouse/ara_tools/downloads). 
Ask if you need a different version. 
5. Add the contents of the `code` directory to your path. 

## Dependencies
ARA tools depends on the following MATLAB packages. 
Clone them and add to your path.

- [Allen API](https://github.com/BaselLaserMouse/AllenBrainAPI)
- [JSONlab](http://www.mathworks.com/matlabcentral/fileexchange/33381-jsonlab--a-toolbox-to-encode-decode-json-files-in-matlab-octave)
- [settings handler](https://github.com/raacampbell/settings_handler)
- [yaml matlab](https://github.com/raacampbell/yamlmatlab)
- [stitchit](https://github.com/BaselLaserMouse/StitchIt)
- [MelastiX](https://github.com/raacampbell/matlab_elastix) (if you need to register brains to the ARA)
- [matlab-tree](https://github.com/raacampbell/matlab-tree)

## Using the toolbox
See the [Wiki](https://bitbucket.org/lasermouse/ara_tools/wiki/Home) for documentation on using the tools. 

## Further info
[ARA white paper from the Allen Institute](http://help.brain-map.org/download/attachments/2818171/MouseCCF.pdf)