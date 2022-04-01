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
        RangeSlider_3             matlab.ui.control.Slider
        RangeSlider_3Label        matlab.ui.control.Label
        ViewOverlayButton         matlab.ui.control.Button
        UIAxes3   
        dsc
        spect
        colormapname
        dsc_slicenum
        spect_slicenum
        
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
            %{
            if nargin<2
                error('Please put in 2 images')
            end
            %}

            if nargin > 0
                % read in DSC perfusion 
                %dscpath = varargin{1};
                dscpath = '/Users/neuroimaging/Desktop/DATA/ASVD/Pt6/pt6_DSC_sorted/Result_MSwcf2/P001GE_M.mat';
                load(dscpath, 'images')
                app.dsc = images{15};
    
                % read in the spect perfusion
                %spectpath = varargin{2};
                spectpath ='/Users/neuroimaging/Desktop/DATA/ASVD/Pt6/pt6_SPECT/HIR 14524/ICAD_UC007/study_20220315_0f141984e808c10c_UC-BRAIN/NM8_NM_-_Transaxials_AC_97c46a18/00001_077bbd7177b022b5.dcm';
                app.spect = squeeze(dicomread(spectpath));

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
            hdsc=imshow(app.dsc(:,:,round(app.dsc_slicenum)), [], 'parent', app.UIAxes3); %right panel
            hdsc;
            title('overlay of perfusion','parent',app.UIAxes3)
            hold (app.UIAxes3,'on');
            hspect = imshow(app.spect(:,:,round(app.spect_slicenum/2)), [], 'parent', app.UIAxes3);
            hspect.AlphaData = .4;
            colormap(app.UIAxes3,app.colormapname),colorbar(app.UIAxes3);

        end
%% Callback functions

        % Button pushed function: ShowPlotButton
        function ViewOverlayButtonPushed(app, event)
            %show overlay of the two on right panel WITH SLICE ON RESPECTIVE SLIDERS
            %get DSC
            dscimage = squeeze(app.dsc(:,:,round(double(app.SliceSlider.Value)))); %get correct slice
            rmpixels = round(app.ZoomSlider.Value/2);
            dscimage = dscimage(rmpixels:end-rmpixels,rmpixels:end-rmpixels); %crop to correct zoom (which is removing 1/2 zoom number of pixels from all directions)
            hdsc=imshow(dscimage/max(max(dscimage)), [], 'parent', app.UIAxes3); %dsc, normalized to max :/ 
            hdsc;
            title('overlay of perfusion','parent',app.UIAxes3)
            hold (app.UIAxes3,'on');
            
            %overlay SPECT
            spectimage = squeeze(app.spect(:,:,round(double(app.SliceSlider_2.Value)))); %get correct slice
            rmpixels = round(app.ZoomSlider_2.Value/2);
            spectimage = spectimage(rmpixels:end-rmpixels,rmpixels:end-rmpixels); %crop to correct zoom (which is removing 1/2 zoom number of pixels from all directions)
            
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
            imshow(dscimage,[],'parent',app.UIAxes)
            colormap(app.UIAxes,app.colormapname),colorbar(app.UIAxes);
            app.SliceSliderLabel.Text = string('# ' + string(round(double(app.SliceSlider.Value))));
        end

        function SliderValueChanged_2(app, event)
            spectimage = squeeze(app.spect(:,:,round(double(app.SliceSlider_2.Value)))); %get correct slice
            rmpixels = round(app.ZoomSlider_2.Value/2);
            spectimage = spectimage(rmpixels:end-rmpixels,rmpixels:end-rmpixels); %crop to correct zoom (which is removing 1/2 zoom number of pixels from all directions)
            imshow(spectimage,[],'parent',app.UIAxes2)
            colormap(app.UIAxes2,app.colormapname),colorbar(app.UIAxes2);
            app.SliceSlider_2Label.Text = string('# ' + string(round(double(app.SliceSlider_2.Value))));
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
            if nargin > 0
                % read in DSC perfusion 
                %dscpath = varargin{1};
                dscpath = '/Users/neuroimaging/Desktop/DATA/ASVD/Pt6/pt6_DSC_sorted/Result_MSwcf2/P001GE_M.mat';
                load(dscpath, 'images')
                app.dsc = images{15};
    
                % read in the spect perfusion
                %spectpath = varargin{2};
                spectpath ='/Users/neuroimaging/Desktop/DATA/ASVD/Pt6/pt6_SPECT/HIR 14524/ICAD_UC007/study_20220315_0f141984e808c10c_UC-BRAIN/NM8_NM_-_Transaxials_AC_97c46a18/00001_077bbd7177b022b5.dcm';
                app.spect = squeeze(dicomread(spectpath));

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

            % Create RotationdegLabel
            app.RotationdegLabel = uilabel(app.LeftPanel);
            app.RotationdegLabel.HorizontalAlignment = 'right';
            app.RotationdegLabel.Position = [17 127 54 28];
            app.RotationdegLabel.Text = {'Rotation '; '(deg)'};

            % Create RotationdegSlider
            app.RotationdegSlider = uislider(app.LeftPanel);
            app.RotationdegSlider.Limits = [-15 15];
            app.RotationdegSlider.Position = [84 146 150 3];

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

            % Create RotationdegSlider_2Label
            app.RotationdegSlider_2Label = uilabel(app.CenterPanel);
            app.RotationdegSlider_2Label.HorizontalAlignment = 'right';
            app.RotationdegSlider_2Label.Position = [16 129 51 28];
            app.RotationdegSlider_2Label.Text = {'Rotation'; '(deg)'};

            % Create RotationdegSlider_2
            app.RotationdegSlider_2 = uislider(app.CenterPanel);
            app.RotationdegSlider_2.Position = [88 144 150 3];

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

            % Create RangeSlider_3Label
            app.RangeSlider_3Label = uilabel(app.RightPanel);
            app.RangeSlider_3Label.HorizontalAlignment = 'right';
            app.RangeSlider_3Label.Position = [43 81 40 22];
            app.RangeSlider_3Label.Text = 'Range';

            % Create RangeSlider_3
            app.RangeSlider_3 = uislider(app.RightPanel);
            app.RangeSlider_3.Position = [104 90 150 3];


             %% Create ViewOverlayButton
            app.ViewOverlayButton = uibutton(app.RightPanel, 'push');
            app.ViewOverlayButton.Position = [1 1 100 22];
            app.ViewOverlayButton.Text = 'View Overlay';
            app.ViewOverlayButton.ButtonPushedFcn = createCallbackFcn(app, @ViewOverlayButtonPushed, true);

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