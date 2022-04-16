%% Coregistration by hand

% this is an app to overlay SPECT and MRI and be able to zoom, rotate, and 
% move through slices of both and see the overlay on the right. 
% this is to be able to crop and rotate the data to then covert to nifti
% for SPM coregistration 
% Mira liu march 2022 


classdef coregistration_setup < matlab.apps.AppBase

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
        dsc
        spect
        colormapname
        dsc_slicenum
        spect_slicenum
        updowncount
        leftrightcount
        
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
            %this startup is hardocded, this is in progress...
            %if coregistration_setup(path1,path2) that's for pre-co-registered images (mat file and spect dcm)
            if nargin == 3 
                % read in DSC perfusion as post-processed mat file
                dscpath = varargin{1};
                %dscpath = '/Users/neuroimaging/Desktop/DATA/ASVD/Pt6/pt6_DSC_sorted/Result_MSwcf2/P001GE_M.mat';
                load(dscpath, 'images')
                app.dsc = images{15};
    
                % read in the spect perfusion
                spectpath = varargin{2};
                %spectpath ='/Users/neuroimaging/Desktop/DATA/ASVD/Pt6/pt6_SPECT/HIR 14524/ICAD_UC007/study_20220315_0f141984e808c10c_UC-BRAIN/NM8_NM_-_Transaxials_AC_97c46a18/00001_077bbd7177b022b5.dcm';
                app.spect = squeeze(dicomread(spectpath));

                %check slice numbers
                app.dsc_slicenum = size(app.dsc,3); % number of slices (assuming x,y,slice)
                app.spect_slicenum = size(app.spect,3); % number of slices (assuming x,y,slice)
            %if coregistration_setup(path1,path2,1) thats for post-co-registered images (nifti and nifti)
            elseif nargin ==4
                %read in perufusion nifti
                dsc_niftipath = varargin{1};%'/Users/neuroimaging/Desktop/DATA/ASVD/Pt6/pt6_niftis/DSCPerf/pt6_dsc.nii';
                app.dsc = niftiread(dsc_niftipath);

                %read in the co-registered (in theory) spect 
                spect_niftipath = varargin{2};%'/Users/neuroimaging/Desktop/DATA/ASVD/Pt6/pt6_niftis/SPECT/rpt6_spect.nii';
                app.spect = niftiread(spect_niftipath);

                %check slice numbers
                app.dsc_slicenum = size(app.dsc,3); % number of slices (assuming x,y,slice)
                app.spect_slicenum = size(app.spect,3); % number of slices (assuming x,y,slice)
            %if coregistration_setup(1,2,3,4) that's for one 4D nifti at different times (comparing some time n to time0)
            elseif nargin == 5 %
                % this is for looking at dsc motion correction... just being lazy.
                %read in one 4d nifti (but make 3d volume)
                dsc_niftipath = '/Users/neuroimaging/Desktop/DATA/ASVD/Pt2/pt2_niftis/DSCPerf/pt2_dsc4d.nii';
                apple = niftiread(dsc_niftipath);
                app.dsc = squeeze(apple(:,:,:,1)); %first time point

                %read in the co-registered (in theory) nifti (again 3d volume) 
                spect_niftipath = '/Users/neuroimaging/Desktop/DATA/ASVD/Pt2/pt2_niftis/DSCPerf/r51pt2_dsc4d.nii';
                orange = niftiread(spect_niftipath);
                app.spect = squeeze(orange(:,:,:,51)); %51st time point, after movement

                %check slice numbers
                app.dsc_slicenum = size(app.dsc,3); % number of slices (assuming x,y,slice)
                app.spect_slicenum = size(app.spect,3); % number of slices (assuming x,y,slice)
            %if coregistration_setup(1,2,3,4,5) that's for pre and post T1, ONCE IN NIFTI FORMAT (4d volume and all)
            elseif nargin == 6 %
                % this is for looking at dsc motion correction... just being lazy.
                %read in one 4d nifti (but make 3d volume)
                LLPre_niftipath = '/Users/neuroimaging/Desktop/DATA/ASVD/Pt2/pt2_niftis/LLPre/pt2_LLPre4d.nii';
                apple = niftiread(LLPre_niftipath);
                app.dsc = squeeze(apple(:,:,1,:)); %one slice, but scroll throgh time points

                %read in the co-registered (in theory) nifti (again 3d volume) 
                LLPost_niftipath = '/Users/neuroimaging/Desktop/DATA/ASVD/Pt2/pt2_niftis/LLPost/pt2_LLPost4d.nii';
                orange = niftiread(LLPost_niftipath);
                app.spect = squeeze(orange(:,:,1,:)); %one slice, but scroll through time points

                %check slice numbers
                app.dsc_slicenum = size(app.dsc,3); % number of slices (assuming x,y,slice)
                app.spect_slicenum = size(app.spect,3); % number of slices (assuming x,y,slice)
            else
                error('havent gotten that far yet')
            end

            % show dsc on left panel
            app.colormapname = 'jet';
            imshow(app.dsc(:,:,round(app.dsc_slicenum/2)), [], 'parent', app.UIAxes) %left panel
            title('DSC perfusion', 'parent', app.UIAxes)
            colormap(app.UIAxes,app.colormapname),colorbar(app.UIAxes);

            % show spect on center panel
            imshow(app.spect(:,:,round(app.spect_slicenum/2)), [], 'parent', app.UIAxes2) %center panel
            title('spect perfusion', 'parent', app.UIAxes2)
            colormap(app.UIAxes2,app.colormapname),colorbar(app.UIAxes2);

            %show overlay of the two on right panel
            hdsc=imshow(app.dsc(:,:,round(app.dsc_slicenum/2)), [], 'parent', app.UIAxes3); %right panel
            hdsc;
            title('overlay of perfusion','parent',app.UIAxes3)
            hold (app.UIAxes3,'on');
            hspect = imshow(app.spect(:,:,round(app.spect_slicenum/2)), [], 'parent', app.UIAxes3);
            hspect.AlphaData = .4;
            colormap(app.UIAxes3,app.colormapname),colorbar(app.UIAxes3);

            app.updowncount = 0;
            app.leftrightcount = 0;

        end
%% Callback functions

        % Button pushed function: ShowPlotButton
        function ViewOverlayButtonPushed(app, event)
            %show overlay of the two on right panel WITH SLICE ON RESPECTIVE SLIDERS
            %get DSC
            dscimage = squeeze(app.dsc(:,:,round(double(app.SliceSlider.Value)))); %get correct slice
            rmpixels = round(app.ZoomSlider.Value/2);
            dscimage = dscimage(rmpixels:end-rmpixels,rmpixels:end-rmpixels); %crop to correct zoom (which is removing 1/2 zoom number of pixels from all directions)
            dscimage = imrotate(dscimage,app.RotationdegSlider.Value);
            hdsc=imshow(dscimage/max(max(dscimage)), [], 'parent', app.UIAxes3); %dsc, normalized to max :/ 
            hdsc;
            title('overlay of perfusion','parent',app.UIAxes3)
            hold (app.UIAxes3,'on');
            
            %overlay SPECT
            spectimage = squeeze(app.spect(:,:,round(double(app.SliceSlider_2.Value)))); %get correct slice
            rmpixels = round(app.ZoomSlider_2.Value/2);
            spectimage = spectimage(rmpixels:end-rmpixels,rmpixels:end-rmpixels); %crop to correct zoom (which is removing 1/2 zoom number of pixels from all directions)
            spectimage = imrotate(spectimage,app.RotationdegSlider_2.Value);

            %now gotta resize to match 
            [dscx, dscy, dscz] = size(dscimage);
            [spectx,specty,spectz] = size(spectimage);

            if dscx~= spectx || dscy~=specty
                spectimage = imresize(spectimage, [dscx,dscy]);
            end
            hspect = imshow(spectimage/max(max(spectimage)), [], 'parent', app.UIAxes3);% spect, numberalized to max :/ 
            hspect.AlphaData = .4;
            colormap(app.UIAxes3,app.colormapname),colorbar(app.UIAxes3);
        end

        %  ANY OF THE slider value changed (update ALL PARAMETERS: slice, zoom, rotation, range)
        function SliderValueChanged_1(app, event)
            dscimage = squeeze(app.dsc(:,:,round(double(app.SliceSlider.Value)))); %get correct slice
            rmpixels = round(app.ZoomSlider.Value/2);
            dscimage = dscimage(rmpixels:end-rmpixels,rmpixels:end-rmpixels); %crop to correct zoom (which is removing 1/2 zoom number of pixels from all directions)
            dscimage = imrotate(dscimage,app.RotationdegSlider.Value);
            maxslider1 = app.RangeSlider.Value;
            imshow(dscimage,[0,maxslider1],'parent',app.UIAxes)
            colormap(app.UIAxes,app.colormapname),colorbar(app.UIAxes);
            app.RotationdegSlider_2Label.Text = string('deg: ' + string(round(double(app.RotationdegSlider.Value))));
            app.SliceSliderLabel.Text = string('# ' + string(round(double(app.SliceSlider.Value))));
            app.ZoomSliderLabel.Text = string('Z: ' + string(round(double(app.ZoomSlider.Value))));
        end

        function SliderValueChanged_2(app, event)
            spectimage = squeeze(app.spect(:,:,round(double(app.SliceSlider_2.Value)))); %get correct slice
            rmpixels = round(app.ZoomSlider_2.Value/2);
            spectimage = spectimage(rmpixels:end-rmpixels,rmpixels:end-rmpixels); %crop to correct zoom (which is removing 1/2 zoom number of pixels from all directions)
            spectimage = imrotate(spectimage,app.RotationdegSlider_2.Value);
            maxslider2 = app.RangeSlider_2.Value;
            imshow(spectimage,[0,maxslider2],'parent',app.UIAxes2)
            colormap(app.UIAxes2,app.colormapname),colorbar(app.UIAxes2);
            app.RotationdegSlider_2Label.Text = string('deg: ' + string(round(double(app.RotationdegSlider_2.Value))));
            app.SliceSlider_2Label.Text = string('# ' + string(round(double(app.SliceSlider_2.Value))));
            app.ZoomSlider_2Label.Text = string('Z: ' + string(round(double(app.ZoomSlider_2.Value))));
        end

        %if the buttons to shift the SPECT image up down left and right. 
        function LeftButtonClick(app,event)
            [spectx,specty,spectz] = size(app.spect);
            newim = app.spect(:, 2:end, :);
            zeropad = zeros(spectx,1,spectz); %assuming 128 x 128 x 25 image
            newim = [newim zeropad];
            app.spect = newim; %remove leftmost column and replace with row of zeros on right
            SliderValueChanged_2(app, event)
            ViewOverlayButtonPushed(app, event)
            app.leftrightcount = app.leftrightcount - 1;
            app.ShiftLabel.Text = ['Shift: [' num2str(app.leftrightcount) ',' num2str(app.updowncount), ']'];
        end

        function RightButtonClick(app,event)
            [spectx,specty,spectz] = size(app.spect);
            newim = app.spect(:, 1:end-1, :);
            zeropad = zeros(spectx,1,spectz); %assuming 128 x 128 x 25 image
            newim = [zeropad newim];
            app.spect = newim; %remove leftmost column and replace with row of zeros on right
            SliderValueChanged_2(app, event)
            ViewOverlayButtonPushed(app, event)
            app.leftrightcount = app.leftrightcount + 1;
            app.ShiftLabel.Text = ['Shift: [' num2str(app.leftrightcount) ',' num2str(app.updowncount), ']'];
        end

        function UpButtonClick(app,event)
            [spectx,specty,spectz] = size(app.spect);
            newim = app.spect(2:end, :, :);
            zeropad = zeros(1,specty,spectz); %assuming 128 x 128 x 25 image
            newim = [newim ;zeropad];
            app.spect = newim;
            SliderValueChanged_2(app, event)
            ViewOverlayButtonPushed(app, event)
            app.updowncount = app.updowncount + 1;
            app.ShiftLabel.Text = ['Shift: [' num2str(app.leftrightcount) ',' num2str(app.updowncount), ']'];
        end

        function DownButtonClick(app,event)
            [spectx,specty,spectz] = size(app.spect);
            newim = app.spect(1:end-1, :, :);
            zeropad = zeros(1,specty,spectz); %assuming 128 x 128 x 25 image
            newim = [zeropad;newim];
            app.spect = newim;
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
            %if coregistration_setup(path1,path2) that's for pre-co-registered images (mat file and spect dcm)
            if nargin == 3 
                % read in DSC perfusion as post-processed mat file
                dscpath = varargin{1};
                %dscpath = '/Users/neuroimaging/Desktop/DATA/ASVD/Pt6/pt6_DSC_sorted/Result_MSwcf2/P001GE_M.mat';
                load(dscpath, 'images')
                app.dsc = images{15};
    
                % read in the spect perfusion
                spectpath = varargin{2};
                %spectpath ='/Users/neuroimaging/Desktop/DATA/ASVD/Pt6/pt6_SPECT/HIR 14524/ICAD_UC007/study_20220315_0f141984e808c10c_UC-BRAIN/NM8_NM_-_Transaxials_AC_97c46a18/00001_077bbd7177b022b5.dcm';
                app.spect = squeeze(dicomread(spectpath));

                %check slice numbers
                app.dsc_slicenum = size(app.dsc,3); % number of slices (assuming x,y,slice)
                app.spect_slicenum = size(app.spect,3); % number of slices (assuming x,y,slice)
            %if coregistration_setup(path1,path2,1) thats for post-co-registered images (nifti and nifti)
            elseif nargin ==4
                %read in perufusion nifti
                dsc_niftipath = varargin{1};%'/Users/neuroimaging/Desktop/DATA/ASVD/Pt6/pt6_niftis/DSCPerf/pt6_dsc.nii';
                app.dsc = niftiread(dsc_niftipath);

                %read in the co-registered (in theory) spect 
                spect_niftipath = varargin{2};%'/Users/neuroimaging/Desktop/DATA/ASVD/Pt6/pt6_niftis/SPECT/rpt6_spect.nii';
                app.spect = niftiread(spect_niftipath);

                %check slice numbers
                app.dsc_slicenum = size(app.dsc,3); % number of slices (assuming x,y,slice)
                app.spect_slicenum = size(app.spect,3); % number of slices (assuming x,y,slice)
            %if coregistration_setup(1,2,3,4) that's for one 4D nifti at different times (comparing some time n to time0)
            elseif nargin == 5 %
                % this is for looking at dsc motion correction... just being lazy.
                %read in one 4d nifti (but make 3d volume)
                dsc_niftipath = '/Users/neuroimaging/Desktop/DATA/ASVD/Pt2/pt2_niftis/DSCPerf/pt2_dsc4d.nii';
                apple = niftiread(dsc_niftipath);
                app.dsc = squeeze(apple(:,:,:,1)); %first time point

                %read in the co-registered (in theory) nifti (again 3d volume) 
                spect_niftipath = '/Users/neuroimaging/Desktop/DATA/ASVD/Pt2/pt2_niftis/DSCPerf/r51pt2_dsc4d.nii';
                orange = niftiread(spect_niftipath);
                app.spect = squeeze(orange(:,:,:,51)); %51st time point, after movement

                %check slice numbers
                app.dsc_slicenum = size(app.dsc,3); % number of slices (assuming x,y,slice)
                app.spect_slicenum = size(app.spect,3); % number of slices (assuming x,y,slice)
            %if coregistration_setup(1,2,3,4,5) that's for pre and post T1, ONCE IN NIFTI FORMAT (4d volume and all)
            elseif nargin == 6 %
                % this is for looking at dsc motion correction... just being lazy.
                %read in one 4d nifti (but make 3d volume)
                LLPre_niftipath = '/Users/neuroimaging/Desktop/DATA/ASVD/Pt2/pt2_niftis/LLPre/pt2_LLPre4d.nii';
                apple = niftiread(LLPre_niftipath);
                app.dsc = squeeze(apple(:,:,1,:)); %one slice, but scroll throgh time points

                %read in the co-registered (in theory) nifti (again 3d volume) 
                LLPost_niftipath = '/Users/neuroimaging/Desktop/DATA/ASVD/Pt2/pt2_niftis/LLPost/pt2_LLPost4d.nii';
                orange = niftiread(LLPost_niftipath);
                app.spect = squeeze(orange(:,:,1,:)); %one slice, but scroll through time points

                %check slice numbers
                app.dsc_slicenum = size(app.dsc,3); % number of slices (assuming x,y,slice)
                app.spect_slicenum = size(app.spect,3); % number of slices (assuming x,y,slice)
            else
                error('havent gotten that far yet')
            end

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.AutoResizeChildren = 'off';
            app.UIFigure.Position = [100 100 860 480];
            app.UIFigure.Name = 'MATLAB App';
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
            app.UIAxes.Position = [6 217 264 230];

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
            app.SliceSlider.Limits = [1 app.dsc_slicenum];
            app.SliceSlider.Position = [81 38 150 3];
            app.SliceSlider.Value = round(app.dsc_slicenum/2);
            app.SliceSlider.ValueChangedFcn = createCallbackFcn(app, @SliderValueChanged_1, true);

            %% Create CenterPanel
            app.CenterPanel = uipanel(app.GridLayout);
            app.CenterPanel.Layout.Row = 1;
            app.CenterPanel.Layout.Column = 2;

            % Create UIAxes2
            app.UIAxes2 = uiaxes(app.CenterPanel);
            title(app.UIAxes2, 'Title')
            app.UIAxes2.Position = [6 217 269 230];

            % Create RangeSlider_2Label
            app.RangeSlider_2Label = uilabel(app.CenterPanel);
            app.RangeSlider_2Label.HorizontalAlignment = 'right';
            app.RangeSlider_2Label.Position = [27 187 40 22];
            app.RangeSlider_2Label.Text = 'Range';

            % Create RangeSlider_2
            app.RangeSlider_2 = uislider(app.CenterPanel);
            app.RangeSlider_2.Position = [88 196 150 3];
            app.RangeSlider_2.Limits = [1,2000];
            app.RangeSlider_2.Value = 1200;
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
            app.SliceSlider_2.Limits = [1 app.spect_slicenum];
            app.SliceSlider_2.Value = round(app.spect_slicenum/2);
            app.SliceSlider_2.ValueChangedFcn = createCallbackFcn(app, @SliderValueChanged_2, true);


            %% Create RightPanel
            app.RightPanel = uipanel(app.GridLayout);
            app.RightPanel.Layout.Row = 1;
            app.RightPanel.Layout.Column = 3;

            % Create UIAxes3
            app.UIAxes3 = uiaxes(app.RightPanel);
            title(app.UIAxes3, 'Title')
            app.UIAxes3.Position = [5 102 295 371];


            % Create ViewOverlayButton
            app.ViewOverlayButton = uibutton(app.RightPanel, 'push');
            app.ViewOverlayButton.Position = [1 1 100 22];
            app.ViewOverlayButton.Text = 'View Overlay';
            app.ViewOverlayButton.ButtonPushedFcn = createCallbackFcn(app, @ViewOverlayButtonPushed, true);
            
            % Create rightButton
            app.rightButton = uibutton(app.RightPanel, 'push');
            app.rightButton.Position = [43 73 39 28];
            app.rightButton.Text = {'right'};
            app.rightButton.ButtonPushedFcn = createCallbackFcn(app, @RightButtonClick, true);

            % Create leftButton
            app.leftButton = uibutton(app.RightPanel, 'push');
            app.leftButton.Position = [6 73 38 28];
            app.leftButton.Text = 'left';
            app.leftButton.ButtonPushedFcn = createCallbackFcn(app, @LeftButtonClick, true);

            
            % Create upButton
            app.upButton = uibutton(app.RightPanel, 'push');
            app.upButton.Position = [25 102 36 22];
            app.upButton.Text = 'up';
            app.upButton.ButtonPushedFcn = createCallbackFcn(app, @UpButtonClick, true);
            

            % Create downButton
            app.downButton = uibutton(app.RightPanel, 'push');
            app.downButton.Position = [20 52 45 22];
            app.downButton.Text = 'down';
            app.downButton.ButtonPushedFcn = createCallbackFcn(app, @DownButtonClick, true);

            % Create ShiftLabel
            app.ShiftLabel = uilabel(app.RightPanel);
            app.ShiftLabel.Position = [100 90 84 22];
            app.ShiftLabel.Text = 'Shift: [0,0]';


            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

%% App creation and deletion
    methods (Access = public)

        % Construct app
        function app = coregistration_setup(varargin)

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