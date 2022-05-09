%% Code to get average IVIM curve, and fit, for ROIs.

% Example Run: 
%GMroi = '/Users/neuroimaging/Desktop/DATA/IVIM_TimTests/MIRA_IVIM/gmROItest.mat';
%WMroi = '/Users/neuroimaging/Desktop/DATA/IVIM_TimTests/MIRA_IVIM/wmROItest.mat';
%CSFroi = '/Users/neuroimaging/Desktop/DATA/IVIM_TimTests/MIRA_IVIM/csfROItest.mat';
%IVIMfile = '/Users/neuroimaging/Desktop/DATA/IVIM_TimTests/MIRA_IVIM/Scan 02 IVIM_S0D3_sorted_2step.mat';
%ImageDirectory = '/Users/neuroimaging/Desktop/DATA/IVIM_TimTests/MIRA_IVIM/Scan 02 IVIM_S0D3_sorted';
%Slice = 20;
%ROIdirect = '/Users/neuroimaging/Desktop/DATA/IVIM_TimTests/MIRA_IVIM/csfROItest.mat';
%>> AverageIVIMCurve(IVIMfile,ImageDirectory,Slice,CSFroi,WMroi,GMroi)
%mira liu 04/11/2022

function AverageIVIMCurve(varargin)

ivimfilepath = varargin{1};
load(ivimfilepath, 'f', 'D', 'Dstar') %this is the IVIM file
Image_Directory=varargin{2}; %the path to the directory
slice = varargin{3};
ROI_directory = varargin{4}; 
f = squeeze(f(slice,:,:)); %get the slice of interest for f, D, and Dstar
D = squeeze(D(slice,:,:));
Dstar = squeeze(Dstar(slice,:,:));

Image = squeeze(f.*Dstar).*102270;
Num_Bvalues = 10;
Bvalues = [0 111 222 333 444 556 667 778 889 1000];


dat_list = dir(fullfile(Image_Directory,'IM*'));
datnames = {dat_list.name}; %read them in the correct order
datnames = natsortfiles(datnames);
fname  = fullfile(Image_Directory,dat_list(1).name); %get size of first dicom for reference.
header = dicominfo(fname);
nx = header.Height;
ny = header.Width;
Images_Per_Slice = 37;
Start_Index = 28;


%this is path to either 1) roi saved as mat file that you want you want 
% or 2) roi that you're going to draw and save here.
%The input would be AverageIVIMCurve(IVIMfile,ImageDirectory,Slice,ROI_Name)
if nargin == 4
    if ~exist(ROI_directory,'file')
        figure,imshow(Image,[0 120]),colormap(gca,'jet'),colorbar,truesize([300 300])
        ROI = roipoly;
        save(ROI_directory,'ROI')
    else
        load(ROI_directory,'ROI')
    end

    Signal = getAvergeROI(Image_Directory,Images_Per_Slice,Start_Index,nx,ny,Num_Bvalues,datnames,slice,ROI); %nested function
    %plot (normalized)
    figure,
    plot(Bvalues,Signal/Signal(1),LineWidth=3.0)
    hold on
    scatter(Bvalues,Signal/Signal(1),70,"black","filled")
    hold off

    CSF_sig = 0;
    WM_sig = 0;
    GM_sig = 0;
end


%The input would be AverageIVIMCurve(IVIMfile,ImageDirectory,Slice,CSF_path, WM_path, GM_path)
if nargin == 6
    CSF_roi = varargin{4};
    load(CSF_roi,'ROI') %load
    CSF = ROI; %rename
    WM_roi = varargin{5};
    load(WM_roi,'ROI') %load
    WM = ROI; %rename
    GM_roi = varargin{6};
    load(GM_roi,'ROI') %load
    GM = ROI; %rename
    CSF_sig = getAvergeROI(Image_Directory,Images_Per_Slice,Start_Index,nx,ny,Num_Bvalues,datnames,slice,CSF);
    WM_sig = getAvergeROI(Image_Directory,Images_Per_Slice,Start_Index,nx,ny,Num_Bvalues,datnames,slice,WM);
    GM_sig = getAvergeROI(Image_Directory,Images_Per_Slice,Start_Index,nx,ny,Num_Bvalues,datnames,slice,GM);

    %plots (normalized)
    norm_to = 1; %( normalized to b0)
    figure,
    plot(Bvalues,CSF_sig/CSF_sig(norm_to),LineWidth=3.0,Color=[0.9290 0.6940 0.1250]) %CSF is yelow
    hold on
    scatter(Bvalues,CSF_sig/CSF_sig(norm_to),70,markerfacecolor = "black")
    hold on
    plot(Bvalues,WM_sig/WM_sig(norm_to),LineWidth=3.0,Color=[0.4660 0.6740 0.1880]) %WM is green
    hold on
    scatter(Bvalues,WM_sig/WM_sig(norm_to),70,markerfacecolor = "black")
    hold on
    plot(Bvalues,GM_sig/GM_sig(norm_to),LineWidth=3.0,Color=[0 0.4470 0.7410]) %GM is purple
    hold on
    scatter(Bvalues,GM_sig/GM_sig(norm_to),70,markerfacecolor = "black")
    hold off
    legend('CSF','','WM','','GM','')

    norm_to = 10; %normalize to b1000=10
    figure,
    plot(Bvalues,CSF_sig/CSF_sig(norm_to),LineWidth=3.0,Color=[0.9290 0.6940 0.1250]) %CSF is yelow
    hold on
    scatter(Bvalues,CSF_sig/CSF_sig(norm_to),70,markerfacecolor = "black")
    hold on
    plot(Bvalues,WM_sig/WM_sig(norm_to),LineWidth=3.0,Color=[0.4660 0.6740 0.1880]) %WM is green
    hold on
    scatter(Bvalues,WM_sig/WM_sig(norm_to),70,markerfacecolor = "black")
    hold on
    plot(Bvalues,GM_sig/GM_sig(norm_to),LineWidth=3.0,Color=[0 0.4470 0.7410]) %GM is purple
    hold on
    scatter(Bvalues,GM_sig/GM_sig(norm_to),70,markerfacecolor = "black")
    hold off
    legend('CSF','','WM','','GM','')

    %no nonrm
    figure,
    plot(Bvalues,CSF_sig,LineWidth=3.0,Color=[0.9290 0.6940 0.1250]) %CSF is yelow
    hold on
    scatter(Bvalues,CSF_sig,70,markerfacecolor = "black")
    hold on
    plot(Bvalues,WM_sig,LineWidth=3.0,Color=[0.4660 0.6740 0.1880]) %WM is green
    hold on
    scatter(Bvalues,WM_sig,70,markerfacecolor = "black")
    hold on
    plot(Bvalues,GM_sig,LineWidth=3.0,Color=[0 0.4470 0.7410]) %GM is purple
    hold on
    scatter(Bvalues,GM_sig,70,markerfacecolor = "black")
    hold off
    legend('CSF','','WM','','GM','')
    xlabel('b-value (s/mm^2)',FontSize=25)
end


end


%nested function below
function Signal = getAvergeROI(Image_Directory,Images_Per_Slice,Start_Index,nx,ny,Num_Bvalues,datnames,slice,ROI)
    %now having loaded (or drawn) an ROI, get average IVIM curve of that ROI
    i1 = Images_Per_Slice*(slice-1)+Start_Index; %37*(1-1)+28 = 28, get starting index
    i2 = i1 + Num_Bvalues-1; %get end index
    ImageStack = zeros(Num_Bvalues,nx,ny);
    %now create the entire stack of images (one one slice) stacked across all b values
    jj = 1; %which b value
    %assuming Zfilter = 1
    w2 = 0.20; 
    w1 = 0.20; 
    w0 = 0.20; 
    for i= i1:i2
        fname_im2 = fullfile(Image_Directory,char(datnames(i-2*(Images_Per_Slice))));
        fname_im1 = fullfile(Image_Directory,char(datnames(i-1*(Images_Per_Slice))));
        fname_im0 = fullfile(Image_Directory,char(datnames(i-0*(Images_Per_Slice)))); % center slice
        fname_ip1 = fullfile(Image_Directory,char(datnames(i+1*(Images_Per_Slice))));
        fname_ip2 = fullfile(Image_Directory,char(datnames(i+2*(Images_Per_Slice))));
        ImageStack(jj,:,:)= w2*double(dicomread(fname_im2)) +           ...   
                        w1*double(dicomread(fname_im1)) +           ... 
                        w0*double(dicomread(fname_im0)) +           ... 
                        w1*double(dicomread(fname_ip1)) +           ... 
                        w2*double(dicomread(fname_ip2));
        jj= jj+1;
    end
    
    %get average of ROI for each b-value
    Signal = zeros(Num_Bvalues,1);
    for i = 1:Num_Bvalues
        BvalImage = squeeze(ImageStack(i,:,:));
        ROId_average = mean(BvalImage(logical(ROI)));
        Signal(i) = ROId_average;
    end
end

