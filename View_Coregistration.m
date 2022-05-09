%% App for coregistration by eye

% this is an app to overlay two images/volumes and be able to zoom, rotate, and 
% move through slices of both and see the overlay on the right. 
% Mira liu march 2022 


% input: path to image 1 (or preloaded variable), path to image 2 (or preloaded variable), comparison type (see list of options), and options
% output: image viewer with 3 images, sliding scales for zoom, rotation, image range, slices, and the overlay of them on the right. 

%assumes it is comparison of two qCBF images unless you include the comparison type as 'pfa'. if 'pfa', it is assumed that the second image is an ADC/DWI image. 

%updated and neatened up Mira Liu May 2022

classdef View_Coregistration < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                  matlab.ui.Figure
        GridLayout                matlab.ui.container.GridLayout
        LeftPanel                 matlab.ui.container.Panel
        SliceSlider               matlab.ui.control.Slider
        SliceSliderLabel          matlab.ui.control.Label
        ZoomSlider                matlab.ui.control.Slider
        ZoomSliderLabel           matlab.ui.control.Label
        RotationdegSlider         matlab.ui.control.Slider
        RotationdegLabel          matlab.ui.control.Label
        RangeSlider               matlab.ui.control.Slider
        RangeSliderLabel          matlab.ui.control.Label
        UIAxes                    matlab.ui.control.UIAxes
        CenterPanel               matlab.ui.container.Panel
        SliceSlider_2             matlab.ui.control.Slider
        SliceSlider_2Label        matlab.ui.control.Label
        ZoomSlider_2              matlab.ui.control.Slider
        ZoomSlider_2Label         matlab.ui.control.Label
        RotationdegSlider_2       matlab.ui.control.Slider
        RotationdegSlider_2Label  matlab.ui.control.Label
        RangeSlider_2             matlab.ui.control.Slider
        RangeSlider_2Label        matlab.ui.control.Label
        UIAxes2                   matlab.ui.control.UIAxes
        RightPanel                matlab.ui.container.Panel
        ViewOverlayButton         matlab.ui.control.Button
        leftButton                matlab.ui.control.Button
        rightButton               matlab.ui.control.Button
        downButton                matlab.ui.control.Button
        upButton                  matlab.ui.control.Button
        ShiftLabel                matlab.ui.control.Label
        UIAxes3   
        image1
        image2
        colormapname1
        colormapname2
        image1_slicenum
        image2_slicenum
        updowncount
        leftrightcount
        ComparisonType
    end

%% Properties that correspond to apps with auto-reflow
    properties (Access = private)
        onePanelWidth = 576;
        twoPanelWidth = 768;
    end

    % Callbacks that handle component events
    methods (Access = private)
        %% startup function
        function startupFcn(app, varargin)

            %set colormap for left and middle respectively
            app.colormapname1 = 'jet';
            app.colormapname2 = 'jet'; %gray or jet
            
            %set up different comparisons based on the types of file you are comparing: 
            app.ComparisonType = varargin{3};

            %'qCBF matdcm' compares a matfile (DSC qCBF) to a dicom file (SPECT qCBF)
            if strcmp(app.ComparisonType,'qCBF matdcm')
                % read in DSC perfusion as post-processed mat file
                image1path = varargin{1};
                %dscpath = '/Users/neuroimaging/Desktop/DATA/ASVD/Pt6/pt6_DSC_sorted/Result_MSwcf2/P001GE_M.mat';
                load(image1path, 'images', 'image_names')
                app.image1 = images{strcmp('qCBF_nSVD',image_names)};
    
                % read in the spect perfusion
                image2path = varargin{2};
                %spectpath ='/Users/neuroimaging/Desktop/DATA/ASVD/Pt6/pt6_SPECT/HIR 14524/ICAD_UC007/study_20220315_0f141984e808c10c_UC-BRAIN/NM8_NM_-_Transaxials_AC_97c46a18/00001_077bbd7177b022b5.dcm';
                app.image2 = squeeze(dicomread(image2path));

                %check slice numbers
                app.image1_slicenum = size(app.image1,3); % number of slices (assuming x,y,slice)
                app.image2_slicenum = size(app.image2,3); % number of slices (assuming x,y,slice)

            %'qCBF niinii' comparespost-co-registered images (nifti and nifti)
            elseif strcmp(app.ComparisonType,'qCBF niinii')
                %read in perufusion nifti
                image1_niftipath = varargin{1};%'/Users/neuroimaging/Desktop/DATA/ASVD/Pt6/pt6_niftis/DSCPerf/pt6_dsc.nii';
                app.image1 = niftiread(image1_niftipath);

                %read in the co-registered (in theory) spect 
                image2_niftipath = varargin{2};%'/Users/neuroimaging/Desktop/DATA/ASVD/Pt6/pt6_niftis/SPECT/rpt6_spect.nii';
                app.image2 = niftiread(image2_niftipath);

                %check slice numbers
                app.image1_slicenum = size(app.image1,3); % number of slices (assuming x,y,slice)
                app.image2_slicenum = size(app.image2,3); % number of slices (assuming x,y,slice)

            %'qCBF 4Dnii' compares one 4D nifti at different times (comparing  time 0 to time n, requires 4th input of the timpoint, say time 51.)
            elseif strcmp(app.ComparisonType,'qCBF 4Dnii')
                % this is for looking at dsc motion correction... just being lazy.
                %read in one 4d nifti (but make 3d volume)
                image1_niftipath = varargin{1};%'/Users/neuroimaging/Desktop/DATA/ASVD/Pt2/pt2_niftis/DSCPerf/pt2_dsc4d.nii';
                im1 = niftiread(image1_niftipath);
                app.image1 = squeeze(im1(:,:,:,1)); %first time point

                %read in the co-registered (in theory) nifti (again 3d volume) 
                image2_niftipath = varargin{2};%'/Users/neuroimaging/Desktop/DATA/ASVD/Pt2/pt2_niftis/DSCPerf/r51pt2_dsc4d.nii';
                im2 = niftiread(image2_niftipath);
                if ~varargin{4}
                    error('no time point input')
                end
                app.image2 = squeeze(im2(:,:,:,varargin{4})); %51st time point, after movement

                %check slice numbers
                app.image1_slicenum = size(app.image1,3); % number of slices (assuming x,y,slice)
                app.image2_slicenum = size(app.image2,3); % number of slices (assuming x,y,slice)
                
            %'T1 nii' compares  pre and post T1, ONCE IN NIFTI FORMAT (4d volume and all)
            elseif strcmp(app.ComparisonType,'T1 nii')
                %read in one 4d nifti (but make 3d volume)
                LLPre_niftipath = varargin{1}; %'/Users/neuroimaging/Desktop/DATA/ASVD/Pt2/pt2_niftis/LLPre/pt2_LLPre4d.nii';
                im1 = niftiread(LLPre_niftipath);
                app.image1 = squeeze(im1(:,:,1,:)); %one slice, but scroll throgh time points

                %read in the co-registered (in theory) nifti (again 3d volume) 
                LLPost_niftipath = varargin{2}; %'/Users/neuroimaging/Desktop/DATA/ASVD/Pt2/pt2_niftis/LLPost/pt2_LLPost4d.nii';
                im2 = niftiread(LLPost_niftipath);
                app.image2 = squeeze(im2(:,:,1,:)); %one slice, but scroll through time points

                %check slice numbers
                app.image1_slicenum = size(app.image1,3); % number of slices (assuming x,y,slice)
                app.image2_slicenum = size(app.image2,3); % number of slices (assuming x,y,slice)

            % 'matmat' compares two matlab files.
            elseif strcmp(app.ComparisonType,'matmat') || strcmp(app.ComparisonType,'pfa') || strcmp(app.ComparisonType,'matmat difference')
                %these matalb files are preloaded in workspace (can you do that lol)
                % read in image 1
                app.image1 = varargin{1};
    
                % read in the spect perfusion
                %spectpath = varargin{2};
                %spectpath ='/Users/neuroimaging/Desktop/DATA/ASVD/Pt6/pt6_SPECT/HIR 14524/ICAD_UC007/study_20220315_0f141984e808c10c_UC-BRAIN/NM8_NM_-_Transaxials_AC_97c46a18/00001_077bbd7177b022b5.dcm';
                app.image2 = varargin{2};%load(spectpath);

                %check slice numbers
                app.image1_slicenum = size(app.image1,3); % number of slices (assuming x,y,slice)
                app.image2_slicenum = size(app.image2,3); % number of slices (assuming x,y,slice)
            else
                error('input comparison type not recognized')
            end

            % show image 1 on left panel
            imshow(app.image1(:,:,round(app.image1_slicenum/2)), [], 'parent', app.UIAxes) %left panel
            if strcmp(app.ComparisonType,'matmat difference')
                title('Without correction', 'parent', app.UIAxes)
            else
                title('Image 1', 'parent', app.UIAxes)
            end
            colormap(app.UIAxes,app.colormapname1),colorbar(app.UIAxes);

            % show image 2 on center panel
            imshow(app.image2(:,:,round(app.image2_slicenum/2)), [], 'parent', app.UIAxes2) %center panel
            if strcmp(app.ComparisonType,'matmat difference')
                title('With DD correction', 'parent', app.UIAxes2)
            else
                title('Image 2', 'parent', app.UIAxes2)
            end
            colormap(app.UIAxes2,app.colormapname2),colorbar(app.UIAxes2);

            %show overlay of the two on right panel
            himage1=imshow(app.image1(:,:,round(app.image1_slicenum/2)), [], 'parent', app.UIAxes3); %right panel
            himage1;
            title('overlay of perfusion','parent',app.UIAxes3)
            hold (app.UIAxes3,'on');
            himage2 = imshow(app.image2(:,:,round(app.image2_slicenum/2)), [], 'parent', app.UIAxes3);
            himage2.AlphaData = .4;
            colormap(app.UIAxes3,app.colormapname1),colorbar(app.UIAxes3);

            app.updowncount = 0;
            app.leftrightcount = 0;

        end
%% Callback functions

        % Button pushed function: ShowPlotButton
        function ViewOverlayButtonPushed(app, event)
            if strcmp(app.ComparisonType,'matmat difference')
                %get image1
                image1image = squeeze(app.image1(:,:,round(double(app.SliceSlider.Value)))); %get correct slice
                rmpixels = round(app.ZoomSlider.Value/2);
                image1image = image1image(rmpixels:end-rmpixels,rmpixels:end-rmpixels); %crop to correct zoom (which is removing 1/2 zoom number of pixels from all directions)
                image1image = imrotate(image1image,app.RotationdegSlider.Value);
                
                %get image2
                image2image = squeeze(app.image2(:,:,round(double(app.SliceSlider_2.Value)))); %get correct slice
                rmpixels = round(app.ZoomSlider_2.Value/2);
                image2image = image2image(rmpixels:end-rmpixels,rmpixels:end-rmpixels); %crop to correct zoom (which is removing 1/2 zoom number of pixels from all directions)
                image2image = imrotate(image2image,app.RotationdegSlider_2.Value);
    
                %now gotta resize to match in case they don't
                [image1x, image1y, image1z] = size(image1image);
                [image2x,image2y,image2z] = size(image2image);
    
                if image1x~= image2x || image1y~=image2y
                    image2image = imresize(image2image, [image1x,image1y]);
                end

                image_difference = imabsdiff(image2image, image1image); %absolute difference between the two element-by-element
                imshow(image_difference, [0 50], 'parent', app.UIAxes3); %dsc, not normalized
                title('Absolute Difference','parent',app.UIAxes3)
                colormap(app.UIAxes3,app.colormapname1),colorbar(app.UIAxes3);

            else
                %show overlay of the two on right panel WITH SLICE ON RESPECTIVE SLIDERS
                %get image1
                image1image = squeeze(app.image1(:,:,round(double(app.SliceSlider.Value)))); %get correct slice
                rmpixels = round(app.ZoomSlider.Value/2);
                image1image = image1image(rmpixels:end-rmpixels,rmpixels:end-rmpixels); %crop to correct zoom (which is removing 1/2 zoom number of pixels from all directions)
                image1image = imrotate(image1image,app.RotationdegSlider.Value);
                himage1=imshow(image1image/app.RangeSlider.Value, [0 1], 'parent', app.UIAxes3); %dsc, normalized to max :/ 
                %hdsc=imshow(dscimage, [0,app.RangeSlider.Value], 'parent', app.UIAxes3); %dsc, not normalized
    
                himage1;
                title('overlay of perfusion','parent',app.UIAxes3)
                hold (app.UIAxes3,'on');
                
                %overlay image2
                image2image = squeeze(app.image2(:,:,round(double(app.SliceSlider_2.Value)))); %get correct slice
                rmpixels = round(app.ZoomSlider_2.Value/2);
                image2image = image2image(rmpixels:end-rmpixels,rmpixels:end-rmpixels); %crop to correct zoom (which is removing 1/2 zoom number of pixels from all directions)
                image2image = imrotate(image2image,app.RotationdegSlider_2.Value);
    
                %now gotta resize to match 
                [image1x, image1y, image1z] = size(image1image);
                [image2x,image2y,image2z] = size(image2image);
    
                if image1x~= image2x || image1y~=image2y
                    image2image = imresize(image2image, [image1x,image1y]);
                end
                himage2 = imshow(image2image/app.RangeSlider_2.Value, [0 1], 'parent', app.UIAxes3);% spect, numberalized to max :/ 
                %hspect = imshow(spectimage, [0,app.RangeSlider_2.Value], 'parent', app.UIAxes3);% spect, numberalized to max :/ 
    
                himage2.AlphaData = .4;
                colormap(app.UIAxes3,app.colormapname1),colorbar(app.UIAxes3);
            end
        end

        %  ANY OF THE slider value changed (update ALL PARAMETERS: slice, zoom, rotation, range)
        function SliderValueChanged_1(app, event)
            image1image = squeeze(app.image1(:,:,round(double(app.SliceSlider.Value)))); %get correct slice
            rmpixels = round(app.ZoomSlider.Value/2);
            image1image = image1image(rmpixels:end-rmpixels,rmpixels:end-rmpixels); %crop to correct zoom (which is removing 1/2 zoom number of pixels from all directions)
            image1image = imrotate(image1image,app.RotationdegSlider.Value);
            maxslider1 = app.RangeSlider.Value;
            imshow(image1image,[0,maxslider1],'parent',app.UIAxes)
            colormap(app.UIAxes,app.colormapname1),colorbar(app.UIAxes);
            app.RangeSliderLabel.Text = string(round(double(maxslider1)));
            app.RotationdegLabel.Text = string('deg: ' + string(round(double(app.RotationdegSlider.Value))));
            app.SliceSliderLabel.Text = string('# ' + string(round(double(app.SliceSlider.Value))));
            app.ZoomSliderLabel.Text = string('Z: ' + string(round(double(app.ZoomSlider.Value))));
        end

        function SliderValueChanged_2(app, event)
            image2image = squeeze(app.image2(:,:,round(double(app.SliceSlider_2.Value)))); %get correct slice
            rmpixels = round(app.ZoomSlider_2.Value/2);
            image2image = image2image(rmpixels:end-rmpixels,rmpixels:end-rmpixels); %crop to correct zoom (which is removing 1/2 zoom number of pixels from all directions)
            image2image = imrotate(image2image,app.RotationdegSlider_2.Value);
            maxslider2 = app.RangeSlider_2.Value;
            if strcmp(app.ComparisonType,'pfa')
                imshow(image2image,[-2,maxslider2],'parent',app.UIAxes2)
            else
                imshow(image2image,[0,maxslider2],'parent',app.UIAxes2)
            end
            colormap(app.UIAxes2,app.colormapname2),colorbar(app.UIAxes2);
            app.RangeSlider_2Label.Text = string(round(double(maxslider2)));
            app.RotationdegSlider_2Label.Text = string('deg: ' + string(round(double(app.RotationdegSlider_2.Value))));
            app.SliceSlider_2Label.Text = string('# ' + string(round(double(app.SliceSlider_2.Value))));
            app.ZoomSlider_2Label.Text = string('Z: ' + string(round(double(app.ZoomSlider_2.Value))));
        end

        %if the buttons to shift the image2 image up down left and right. 
        function LeftButtonClick(app,event)
            [image2x,image2y,image2z] = size(app.image2);
            newim = app.image2(:, 2:end, :);
            zeropad = zeros(image2x,1,image2z); %assuming 128 x 128 x 25 image
            newim = [newim zeropad];
            app.image2 = newim; %remove leftmost column and replace with row of zeros on right
            SliderValueChanged_2(app, event)
            ViewOverlayButtonPushed(app, event)
            app.leftrightcount = app.leftrightcount - 1;
            app.ShiftLabel.Text = ['Shift: [' num2str(app.leftrightcount) ',' num2str(app.updowncount), ']'];
        end

        function RightButtonClick(app,event)
            [image2x,image2y,image2z] = size(app.image2);
            newim = app.image2(:, 1:end-1, :);
            zeropad = zeros(image2x,1,image2z); %assuming 128 x 128 x 25 image
            newim = [zeropad newim];
            app.image2 = newim; %remove leftmost column and replace with row of zeros on right
            SliderValueChanged_2(app, event)
            ViewOverlayButtonPushed(app, event)
            app.leftrightcount = app.leftrightcount + 1;
            app.ShiftLabel.Text = ['Shift: [' num2str(app.leftrightcount) ',' num2str(app.updowncount), ']'];
        end

        function UpButtonClick(app,event)
            [image2x,image2y,image2z] = size(app.image2);
            newim = app.image2(2:end, :, :);
            zeropad = zeros(1,image2y,image2z); %assuming 128 x 128 x 25 image
            newim = [newim ;zeropad];
            app.image2 = newim;
            SliderValueChanged_2(app, event)
            ViewOverlayButtonPushed(app, event)
            app.updowncount = app.updowncount + 1;
            app.ShiftLabel.Text = ['Shift: [' num2str(app.leftrightcount) ',' num2str(app.updowncount), ']'];
        end

        function DownButtonClick(app,event)
            [image2x,image2y,image2z] = size(app.image2);
            newim = app.image2(1:end-1, :, :);
            zeropad = zeros(1,image2y,image2z); %assuming 128 x 128 x 25 image
            newim = [zeropad;newim];
            app.image2 = newim;
            SliderValueChanged_2(app, event)
            ViewOverlayButtonPushed(app, event)
            app.updowncount = app.updowncount - 1;
            app.ShiftLabel.Text = ['Shift: [' num2str(app.leftrightcount) ',' num2str(app.updowncount), ']'];
        end
        
%% app layuot update

        % Changes arrangement of the app based on UIFigure width
        function updateAppLayout(app, event)
            currentFigureWidth = app.UIFigure.Position(3);
            if(currentFigureWidth <= app.onePanelWidth)
                % Change to a 3x1 grid
                app.GridLayout.RowHeight = {480, 480, 480};
                app.GridLayout.ColumnWidth = {'1x'};
                app.CenterPanel.Layout.Row = 1;
                app.CenterPanel.Layout.Column = 1;
                app.LeftPanel.Layout.Row = 2;
                app.LeftPanel.Layout.Column = 1;
                app.RightPanel.Layout.Row = 3;
                app.RightPanel.Layout.Column = 1;
            elseif (currentFigureWidth > app.onePanelWidth && currentFigureWidth <= app.twoPanelWidth)
                % Change to a 2x2 grid
                app.GridLayout.RowHeight = {480, 480};
                app.GridLayout.ColumnWidth = {'1x', '1x'};
                app.CenterPanel.Layout.Row = 1;
                app.CenterPanel.Layout.Column = [1,2];
                app.LeftPanel.Layout.Row = 2;
                app.LeftPanel.Layout.Column = 1;
                app.RightPanel.Layout.Row = 2;
                app.RightPanel.Layout.Column = 2;
            else
                % Change to a 1x3 grid
                app.GridLayout.RowHeight = {'1x'};
                app.GridLayout.ColumnWidth = {'1x', '1x', '1x'};
                app.LeftPanel.Layout.Row = 1;
                app.LeftPanel.Layout.Column = 1;
                app.CenterPanel.Layout.Row = 1;
                app.CenterPanel.Layout.Column = 2;
                app.RightPanel.Layout.Row = 1;
                app.RightPanel.Layout.Column = 3;
            end
        end
    end

%% Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app, varargin)
            %set default values
            %set up different comparisons based on the types of file you are comparing: 
            app.ComparisonType = varargin{3};

            %set up different comparisons based on the types of file you are comparing: 
            app.ComparisonType = varargin{3};

            %'qCBF matdcm' compares a matfile (DSC qCBF) to a dicom file (SPECT qCBF)
            if strcmp(app.ComparisonType,'qCBF matdcm')
                % read in DSC perfusion as post-processed mat file
                image1path = varargin{1};
                %dscpath = '/Users/neuroimaging/Desktop/DATA/ASVD/Pt6/pt6_DSC_sorted/Result_MSwcf2/P001GE_M.mat';
                load(image1path, 'images', 'image_names')
                app.image1 = images{strcmp('qCBF_nSVD',image_names)};
    
                % read in the spect perfusion
                image2path = varargin{2};
                %spectpath ='/Users/neuroimaging/Desktop/DATA/ASVD/Pt6/pt6_SPECT/HIR 14524/ICAD_UC007/study_20220315_0f141984e808c10c_UC-BRAIN/NM8_NM_-_Transaxials_AC_97c46a18/00001_077bbd7177b022b5.dcm';
                app.image2 = squeeze(dicomread(image2path));

                %check slice numbers
                app.image1_slicenum = size(app.image1,3); % number of slices (assuming x,y,slice)
                app.image2_slicenum = size(app.image2,3); % number of slices (assuming x,y,slice)

            %'qCBF niinii' comparespost-co-registered images (nifti and nifti)
            elseif strcmp(app.ComparisonType,'qCBF niinii')
                %read in perufusion nifti
                image1_niftipath = varargin{1};%'/Users/neuroimaging/Desktop/DATA/ASVD/Pt6/pt6_niftis/DSCPerf/pt6_dsc.nii';
                app.image1 = niftiread(image1_niftipath);

                %read in the co-registered (in theory) spect 
                image2_niftipath = varargin{2};%'/Users/neuroimaging/Desktop/DATA/ASVD/Pt6/pt6_niftis/SPECT/rpt6_spect.nii';
                app.image2 = niftiread(image2_niftipath);

                %check slice numbers
                app.image1_slicenum = size(app.image1,3); % number of slices (assuming x,y,slice)
                app.image2_slicenum = size(app.image2,3); % number of slices (assuming x,y,slice)

            %'qCBF 4Dnii' compares one 4D nifti at different times (comparing  time 0 to time n, requires 4th input of the timpoint, say time 51.)
            elseif strcmp(app.ComparisonType,'qCBF 4Dnii')
                % this is for looking at dsc motion correction... just being lazy.
                %read in one 4d nifti (but make 3d volume)
                image1_niftipath = varargin{1};%'/Users/neuroimaging/Desktop/DATA/ASVD/Pt2/pt2_niftis/DSCPerf/pt2_dsc4d.nii';
                apple = niftiread(image1_niftipath);
                app.image1 = squeeze(apple(:,:,:,1)); %first time point

                %read in the co-registered (in theory) nifti (again 3d volume) 
                image2_niftipath = varargin{2};%'/Users/neuroimaging/Desktop/DATA/ASVD/Pt2/pt2_niftis/DSCPerf/r51pt2_dsc4d.nii';
                orange = niftiread(image2_niftipath);
                if ~varargin{4}
                    error('no time point input')
                end
                app.image2 = squeeze(orange(:,:,:,varargin{4})); %51st time point, after movement

                %check slice numbers
                app.image1_slicenum = size(app.image1,3); % number of slices (assuming x,y,slice)
                app.image2_slicenum = size(app.image2,3); % number of slices (assuming x,y,slice)
                
            %'T1 nii' compares  pre and post T1, ONCE IN NIFTI FORMAT (4d volume and all)
            elseif strcmp(app.ComparisonType,'T1 nii')
                %read in one 4d nifti (but make 3d volume)
                LLPre_niftipath = varargin{1}; %'/Users/neuroimaging/Desktop/DATA/ASVD/Pt2/pt2_niftis/LLPre/pt2_LLPre4d.nii';
                apple = niftiread(LLPre_niftipath);
                app.image1 = squeeze(apple(:,:,1,:)); %one slice, but scroll throgh time points

                %read in the co-registered (in theory) nifti (again 3d volume) 
                LLPost_niftipath = varargin{2}; %'/Users/neuroimaging/Desktop/DATA/ASVD/Pt2/pt2_niftis/LLPost/pt2_LLPost4d.nii';
                orange = niftiread(LLPost_niftipath);
                app.image2 = squeeze(orange(:,:,1,:)); %one slice, but scroll through time points

                %check slice numbers
                app.image1_slicenum = size(app.image1,3); % number of slices (assuming x,y,slice)
                app.image2_slicenum = size(app.image2,3); % number of slices (assuming x,y,slice)

            % 'matmat' compares two matlab files.
            elseif strcmp(app.ComparisonType,'matmat') || strcmp(app.ComparisonType,'pfa') || strcmp(app.ComparisonType,'matmat difference')
                %these matalb files are preloaded in workspace (can you do that lol)
                % read in image 1
                app.image1 = varargin{1};
    
                % read in the spect perfusion
                %spectpath = varargin{2};
                %spectpath ='/Users/neuroimaging/Desktop/DATA/ASVD/Pt6/pt6_SPECT/HIR 14524/ICAD_UC007/study_20220315_0f141984e808c10c_UC-BRAIN/NM8_NM_-_Transaxials_AC_97c46a18/00001_077bbd7177b022b5.dcm';
                app.image2 = varargin{2};%load(spectpath);

                %check slice numbers
                app.image1_slicenum = size(app.image1,3); % number of slices (assuming x,y,slice)
                app.image2_slicenum = size(app.image2,3); % number of slices (assuming x,y,slice)
            else
                error('input comparison type not recognized')
            end


            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.AutoResizeChildren = 'off';
            app.UIFigure.Position = [100 100 860 480];
            app.UIFigure.Name = 'Coregistration Viewer';
            app.UIFigure.SizeChangedFcn = createCallbackFcn(app, @updateAppLayout, true);

            % Create GridLayout
            app.GridLayout = uigridlayout(app.UIFigure);
            app.GridLayout.ColumnWidth = {'1x', '1x', '1x'};
            app.GridLayout.RowHeight = {'1x'};
            app.GridLayout.ColumnSpacing = 0;
            app.GridLayout.RowSpacing = 0;
            app.GridLayout.Padding = [0 0 0 0];
            app.GridLayout.Scrollable = 'on';

            %% Create LeftPanel
            app.LeftPanel = uipanel(app.GridLayout);
            app.LeftPanel.Layout.Row = 1;
            app.LeftPanel.Layout.Column = 1;

            % Create UIAxes
            app.UIAxes = uiaxes(app.LeftPanel);
            title(app.UIAxes, 'Title')
            app.UIAxes.Position = [6 231 264 230];

            % Create RangeSliderLabel
            app.RangeSliderLabel = uilabel(app.LeftPanel);
            app.RangeSliderLabel.HorizontalAlignment = 'right';
            app.RangeSliderLabel.Position = [24 187 40 22];
            app.RangeSliderLabel.Text = 'Range';

            % Create RangeSlider
            app.RangeSlider = uislider(app.LeftPanel);
            app.RangeSlider.Position = [85 196 150 3];
            app.RangeSlider.Limits = [1,250];
            app.RangeSlider.Value = 120;
            app.RangeSlider.ValueChangedFcn = createCallbackFcn(app, @SliderValueChanged_1, true);

            % Create RotationdegLabel
            app.RotationdegLabel = uilabel(app.LeftPanel);
            app.RotationdegLabel.HorizontalAlignment = 'right';
            app.RotationdegLabel.Position = [17 127 54 28];
            app.RotationdegLabel.Text = {'Rotation '; '(deg)'};

            % Create RotationdegSlider
            app.RotationdegSlider = uislider(app.LeftPanel);
            app.RotationdegSlider.Limits = [-30 30];
            app.RotationdegSlider.Position = [84 146 150 3];
            app.RotationdegSlider.ValueChangedFcn = createCallbackFcn(app, @SliderValueChanged_1, true);


            % Create ZoomSliderLabel
            app.ZoomSliderLabel = uilabel(app.LeftPanel);
            app.ZoomSliderLabel.HorizontalAlignment = 'right';
            app.ZoomSliderLabel.Position = [24 81 37 22];
            app.ZoomSliderLabel.Text = 'Zoom';

            % Create ZoomSlider
            app.ZoomSlider = uislider(app.LeftPanel);
            app.ZoomSlider.Position = [82 90 150 3];
            app.ZoomSlider.Limits = [1 100];
            app.ZoomSlider.ValueChangedFcn = createCallbackFcn(app, @SliderValueChanged_1, true);


             % Create SliceSliderLabel
            app.SliceSliderLabel = uilabel(app.LeftPanel);
            app.SliceSliderLabel.HorizontalAlignment = 'right';
            app.SliceSliderLabel.Position = [29 29 31 22];
            app.SliceSliderLabel.Text = 'Slice';

            % Create SliceSlider
            app.SliceSlider = uislider(app.LeftPanel);
            app.SliceSlider.Limits = [1 app.image1_slicenum];
            app.SliceSlider.Position = [81 38 150 3];
            app.SliceSlider.Value = round(app.image1_slicenum/2);
            app.SliceSlider.ValueChangedFcn = createCallbackFcn(app, @SliderValueChanged_1, true);

            %% Create CenterPanel
            app.CenterPanel = uipanel(app.GridLayout);
            app.CenterPanel.Layout.Row = 1;
            app.CenterPanel.Layout.Column = 2;

            % Create UIAxes2
            app.UIAxes2 = uiaxes(app.CenterPanel);
            title(app.UIAxes2, 'Title')
            app.UIAxes2.Position = [6 231 264 230];

            % Create RangeSlider_2Label
            app.RangeSlider_2Label = uilabel(app.CenterPanel);
            app.RangeSlider_2Label.HorizontalAlignment = 'right';
            app.RangeSlider_2Label.Position = [27 187 40 22];
            app.RangeSlider_2Label.Text = 'Range';

            % Create RangeSlider_2
            app.RangeSlider_2 = uislider(app.CenterPanel);
            app.RangeSlider_2.Position = [88 196 150 3];
            %this is for ADC... 
            if nargin == 7 && strcmp(app.ComparisonType, 'pfa')
                app.RangeSlider_2.Limits = [-2,4];
                app.RangeSlider_2.Value = 1;
            else
            app.RangeSlider_2.Limits = [1,2000];
            app.RangeSlider_2.Value = 1200;
            end
            app.RangeSlider_2.ValueChangedFcn = createCallbackFcn(app, @SliderValueChanged_2, true);

            % Create RotationdegSlider_2Label
            app.RotationdegSlider_2Label = uilabel(app.CenterPanel);
            app.RotationdegSlider_2Label.HorizontalAlignment = 'right';
            app.RotationdegSlider_2Label.Position = [16 129 51 28];
            app.RotationdegSlider_2Label.Text = {'Rotation'; '(deg)'};

            % Create RotationdegSlider_2
            app.RotationdegSlider_2 = uislider(app.CenterPanel);
            app.RotationdegSlider_2.Limits = [-30 30];
            app.RotationdegSlider_2.Position = [88 144 150 3];
            app.RotationdegSlider_2.ValueChangedFcn = createCallbackFcn(app, @SliderValueChanged_2, true);

            % Create ZoomSlider_2Label
            app.ZoomSlider_2Label = uilabel(app.CenterPanel);
            app.ZoomSlider_2Label.HorizontalAlignment = 'right';
            app.ZoomSlider_2Label.Position = [30 81 37 22];
            app.ZoomSlider_2Label.Text = 'Zoom';

            % Create ZoomSlider_2
            app.ZoomSlider_2 = uislider(app.CenterPanel);
            app.ZoomSlider_2.Position = [88 90 150 3];
            app.ZoomSlider_2.Limits = [1 100];
            app.ZoomSlider_2.ValueChangedFcn = createCallbackFcn(app, @SliderValueChanged_2, true);

            % Create SliceSlider_2Label
            app.SliceSlider_2Label = uilabel(app.CenterPanel);
            app.SliceSlider_2Label.HorizontalAlignment = 'right';
            app.SliceSlider_2Label.Position = [35 29 31 22];
            app.SliceSlider_2Label.Text = 'Slice';
            
            % Create SliceSlider_2
            app.SliceSlider_2 = uislider(app.CenterPanel);
            app.SliceSlider_2.Position = [87 38 150 3];
            app.SliceSlider_2.Limits = [1 app.image2_slicenum];
            app.SliceSlider_2.Value = round(app.image2_slicenum/2);
            app.SliceSlider_2.ValueChangedFcn = createCallbackFcn(app, @SliderValueChanged_2, true);


            %% Create RightPanel
            app.RightPanel = uipanel(app.GridLayout);
            app.RightPanel.Layout.Row = 1;
            app.RightPanel.Layout.Column = 3;

            % Create UIAxes3
            app.UIAxes3 = uiaxes(app.RightPanel);
            title(app.UIAxes3, 'Title')
            app.UIAxes3.Position = [6 231 264 230];

            % Create ViewOverlayButton
            app.ViewOverlayButton = uibutton(app.RightPanel, 'push');
            app.ViewOverlayButton.Position = [7 90 100 22];
            app.ViewOverlayButton.Text = 'View Overlay';
            app.ViewOverlayButton.ButtonPushedFcn = createCallbackFcn(app, @ViewOverlayButtonPushed, true);
            
            % Create rightButton
            app.rightButton = uibutton(app.RightPanel, 'push');
            app.rightButton.Position = [44 154 39 28];
            app.rightButton.Text = {'right'; ''};
            app.rightButton.ButtonPushedFcn = createCallbackFcn(app, @RightButtonClick, true);

            % Create leftButton
            app.leftButton = uibutton(app.RightPanel, 'push');
            app.leftButton.Position = [7 154 38 28];
            app.leftButton.Text = 'left';
            app.leftButton.ButtonPushedFcn = createCallbackFcn(app, @LeftButtonClick, true);

            % Create upButton
            app.upButton = uibutton(app.RightPanel, 'push');
            app.upButton.Position = [26 183 36 22];
            app.upButton.Text = 'up';
            app.upButton.ButtonPushedFcn = createCallbackFcn(app, @UpButtonClick, true);

            % Create downButton
            app.downButton = uibutton(app.RightPanel, 'push');
            app.downButton.Position = [21 133 45 22];
            app.downButton.Text = 'down';
            app.downButton.ButtonPushedFcn = createCallbackFcn(app, @DownButtonClick, true);

            % Create ShiftLabel
            app.ShiftLabel = uilabel(app.RightPanel);
            app.ShiftLabel.Position = [101 157 37 22];
            app.ShiftLabel.Text = 'Shift: ';


            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

%% App creation and deletion
    methods (Access = public)

        % Construct app
        function app = View_Coregistration(varargin)

            % Create UIFigure and components
            createComponents(app,varargin{:})

            % Execute the startup function
            runStartupFcn(app, @(app)startupFcn(app, varargin{:}))
            app.UIFigure.Visible = 'on';

            % Register the app with App Designer
            %registerApp(app, app.UIFigure)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end