matlab file: imagestack

written in matlab 2021b. Contains slider with a set max and min, and a larger image. Colormap is assumed to be 'jet', can set it to what you want but was lazy so have to replace in the code not GUI. Slider limits are set to the maximum value in the image/4. (line 184)
The 3D image stack is expected to be [x,y, SLICE]. If it is [SLICE,x,y], include 'permute' as a second input. 
must use squeeze for a 3D image (remove all extra 1D)
e.g. if the image is A
size(A)=[50,256,256]
run 
>> imagestack(A,'permute')

if size(A) = [1,50,256,256] 
run 
>> imagestack(squeeze(A),'permute')

- Mira Liu - 1/11/22

matlabfile: PlotIVIMCurve

Written in Matlab 2021b. simple app to show and and be able to chose a voxel in the image and show the corresponding IVIM curve and fit as a function of b value. Input the variables f, D, D*, the folder to the sorted dcm files, the slice of interest. Displays a slider to choose range of values of reference image, the reference image (102270fD*) on the left the scatter plot of the values with the diffusion and total tri-exponential fit on the right. Also the values of f, D, D*, qCBF (102270fD*) and the residual should appear on the left plot. Starts with the center pixel but after that should live update location of cursor which will then show the plot and fit when you click the button on the bottom left.
e.g. 
 >> PlotIVIMCurve(f,D,Dstar,'/Users/USERNAME/Desktop/DICOMFOLDER',slice of interest)
 >> 
1/11/22 Mira Liu





matlab file: imagestack_old

quick matlab code designed to show 3D stacks of 2D images and scroll through. 
Expects 3D volume with dimensions of [x,y,slices]
Assumed colormap of 'jet', can adjust max and min, automatic is 0 1
input the 3D vlume of interest:

>> V = dicomreadVolume('../Vol')
>> 
>> V = squeeze(V)
>> 
>> imagestack_old(V)

output matlab figure with scroll for number of slices 
- Mira Liu - 07/20/21

Any questions can be directed to me at liusarkarm@uchicago.edu
