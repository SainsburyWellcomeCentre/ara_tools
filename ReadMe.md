# ARA Tools

<img src="https://github.com/BaselLaserMouse/ara_tools/wiki/images/RegSchematicAssembled.png" />


### What does it do?
This is a collection of MATLAB functions for handling mouse whole-brain imaging data and associated "sparse" point data such as cell locations, traced neurite trees, or traced projections from a bulk injection. 
This package provides functions for relating these sparse data to the Allen Reference Atlas (ARA):

1. Downsampling full-resolution brain volumes to the ARA voxel size. 
2. Downsampling associated sparse data to the ARA voxel size and exporting of these data to a csv file.
3. Registering the sample brain and sparse data to the ARA: both sample -> ARA and ARA -> sample transformations.
4. Determining the ARA brain area associated with each sparse point.
5. Extracting area outlines from the reference atlas that you can use for plotting. 

### Who is it for?
*ARA Tools* is written in the [Mrsic-Flogel lab](http://mouse.vision) with our data in mind.
In places it might expect the raw data were stitched using [StitchIt](https://github.com/BaselLaserMouse/StitchIt), so you may need to adapt our code for your own work.

### Installation

1. Clone the repository in a Git client like [SmartGit](http://www.syntevo.com/smartgit/) or [SourceTree](https://www.sourcetreeapp.com).
2. You will need some or all of the dependencies listed below. Which ones you need depends on what you're doing. 
e.g. you won't need the registration stuff to plot cells. 
3. You will need a copy of the Allen Atlas and the template brain in MHD format. One is included on [this page](http://mouse.vision/han2017). 
5. Add the contents of the `code` directory to your MATLAB path. 

### Dependencies
ARA tools depends on the following MATLAB packages and requires at least R2016b. 
Clone them and add to your path.

- [Allen API](https://github.com/BaselLaserMouse/AllenBrainAPI)
- [JSONlab](http://www.mathworks.com/matlabcentral/fileexchange/33381-jsonlab--a-toolbox-to-encode-decode-json-files-in-matlab-octave)
- [settings handler](https://github.com/raacampbell/settings_handler)
- [yaml matlab](https://github.com/raacampbell/yamlmatlab)
- [stitchit](https://github.com/BaselLaserMouse/StitchIt)
- [MelastiX](https://github.com/raacampbell/matlab_elastix) (if you need to register brains to the ARA)
- [matlab-tree](https://github.com/raacampbell/matlab-tree)


### Using the toolbox
See the [Wiki](https://github.com/BaselLaserMouse/ara_tools/wiki) for documentation on using the tools. 


### Related projects

* [ClearMap](https://github.com/ChristophKirst/ClearMap)
* [aMAP](https://github.com/SainsburyWellcomeCentre/aMAP/wiki)


### Further info
* [ARA white paper from the Allen Institute](http://help.brain-map.org/download/attachments/2818171/MouseCCF.pdf)
* [The latest CCF](http://download.alleninstitute.org/informatics-archive/current-release/)
