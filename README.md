# Appls
imstack/imagestack
quick matlab code designed to show 3D stacks of 2D images and scroll through. 
Expects 3D volume with dimensions of [x,y,stack]
Assumed colormap of 'jet', can adjust max and min, automatic is 0 1
input the 3D vlume of interest:

V = dicomreadVolume('../Vol')
V = squeeze(V)
imstack(V)

output matlab figure with scroll for number of slices 

still a work in progress, initial code from july 2019. 
Any questions can be directed to Mira at liusarkarm@uchicago.edu

07/20/21


plotivimcurve
quick matlab code designed to show b-value decay as a function of voxel. 
voxel is chosen based on location of data cursor in reference image on the left. 

