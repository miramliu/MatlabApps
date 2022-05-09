This contains final versions of image viewing and sorting apps written in Matlab. 

# Imagestack
This is a basic image viewer.\
Input: 3D volume to view.\
Output: image stack along thrid dimension.

Assumes input of a 3D volume with the dimensions [X,Y,slice]. If the 3D volume is [slice, X,Y], include 'permute' as the second input.\
It sets automatically to the middle slices, and allows scrolling through the volume. Can change minimum an dmaximum pixel value, and figure scales with window size. Can zoom in and out with normal figure function. 

## Example:
    >> load ('/Debugging/P001GE_M.mat', images)
    >> imagestack(images{19})


# View_Coregistration
This is an image viewer to compare two different 3D volumes. You can overlay two images/volumes and zoom, rotate, and move through slices of both volumes and view the overlay on the right hand side.\
Input: path to image 1(or a preloaded variable), path to image 2(or a preloaded variable) , the type of comparison (see list of options), and some extra options.\
Output: image viewer with three images, sliding zcales for zoom, rotation, image range, shift, slice, and overlay of them on the righthand side. Click 'view overlay' button to view the overlay of the current left and dmiddle image. 

To note: it does assume it is a comparison of two qCBF images unless you input the comparison type as 'pfa'. If 'pfa', it assumes that the second image is an ADC/DWI image. Colormap name can be changed in the app, it is not yet an option.  

Comparison types:
1) 'qCBF matdcm': this assumes the first input is a path to DSC matfile and the second input is a path to a dicom. 
2) 'qCBF niinii': this assumes that both inputs are paths to nifti files.
3) 'qCBF 4Dnii': this assumes that the first input is to a 4D nii file (so 3D volumes taken over time), and that the second input is to a specific time point nifti file. There is a require fourth input which is the timepoint of interest. 
4) 'T1 nii': this assumes that the first input is a nifti of T1 pre and that the second input is a nifti of T1 post. 
5) 'matmat': this assumes it is a comparison of two preloaded mat files. 
6) 'pfa': this assumes it is a comparison of two preloaded matfiles, and that the first is a qCBF image and the second is a DWI image.


## Example of different runs: 
    >> View_Coregistration('pathtomatfil/P001GE_M.mat','pathtodicom/spect.dcm','qCBF matdcm')
    >> View_Coregistration('pathtonii1/pt_dsc.nii','pathtonii2/pt_spect.nii','qCBF niinii')
    >> View_Coregistration('pathtonii1/pt_dsc4d.nii', 'pathtonii1/r10pt_dsc4d.nii', 'qCBF 4Dnii', 10)
    >> View_Coregistration('pathtoLLprenii/pt_LLPre4d.nii', 'pathtoLLpostnii/pt_LLPost4d.nii','T1 nii')
    >> View_Coregistration(infarctData.pfa{1},  infarctData.masks{1},'matmat')
    >> View_Coregistration(qCBF, MD.masks, 'pfa')

# PlotIVIMCurve
This is an image viewer to see the IVIM curve for a certain pixel and view it side by side with the image. It displays the IVIM qCBF image on the left, and the curve for the chosen pixel on the right. It starts at the center pixel, but after movement of the mouse should update upon location of cursor which will show the plot and biexponential curve fit on the left when the button  'Show Plot' is clicked.\
Input: path to matfile with variables f, D, D*, pathtofolder of sorted dcm files, slice of interest. Or pre-loaded variables f, D, D*, and pathtofolder of sorted dcmfiles, slice of interest\
Output: image of slice, slider for pixel intensity range, reference image, and biexponential data, curvefit, and parameters.

## Example: 
    >> PlotIVIMCurve('pathtomatfile/Scan_sorted_2step.mat','pathtodcms/')
    >> PlotIVIMCurve(f,D,Dstar,'pathtodcms/')
    

# Average IVIM Curve
This is an image viewing function (not app) for getting the average IVIM biexponential curve for multiple ROIs and overlaying them. It can also be called to draw one ROI and save it.
Input: IVIMfile,IVIM dimage directory, slice, ROI name to draw and save. Or IVIIM file, Image directory, slice, three ROIs to show.
Output: ROI average biexponential curve (not fit). Or all three ROI average biexponential curves (not fit) overlaid for comparison, with three different figures with different normalizations (standardized across all three ROIs within each image). 

## Example: 
    >> GMROI= 'pathtoGM/GM.mat'
    >> WMROI = 'pathtoWM/WM.mat'
    >> CSFROI = 'pathtoCSF/CSF.mat'
    >> IVIMfile = 'pathtoivim/Scan_sorted_2step.mat'
    >> Imagedirectory = 'pathtoIMimages/Scan_sorted'
    >> slice = 20
    >> AverageIVIMCurve(IVIMfile,Imagedirectory,slice,CSFROI,WMROI,GMROI)

# DicomSort
Function to sort dicoms into new folders based on sequence. This version uses dicominfo on every scan. it makes it slow, but reduces error that can be found when sorting specifically processed images (WIP).
## Example: 
    >> DicomSort('/Users/neuroimaging/Desktop/DATA/DDcorr/Collat_27/Day2/')

# DicomSort_AcqNNumber
Function to sort dicoms into new folders based on acquisition number. Changed from series in case multiple sequences are taken without series name being changed.

## Example: 
    >> DicomSort_AcqNNumber('/Users/neuroimaging/Desktop/DATA/DDcorr/Collat_27/Day2/')
