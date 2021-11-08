%% simple app to show an and be able to chose a voxel in the image and show the corresponding IVIM curve as a function of b.
%input fDstar, and the folder to the sorted dcm files.
%displays a slider to choose range of values of reference image, the reference image, and then the curve on the left
%starts with 100,100, but after that should live update location of cursor. 
%runs on Matlab 2021b
%11/3/21 Mira Liu

classdef PlotIVIMCurve < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure     matlab.ui.Figure
        GridLayout   matlab.ui.container.GridLayout
        LeftPanel    matlab.ui.container.Panel
        Slider       matlab.ui.control.Slider
        SliderLabel  matlab.ui.control.Label
        UIAxes       matlab.ui.control.UIAxes
        RightPanel   matlab.ui.container.Panel
        UIAxes2      matlab.ui.control.UIAxes
    end

    % Properties that correspond to apps with auto-reflow
    properties (Access = private)
        InputImage
        onePanelWidth = 576;
        MaxValue %highest pixel value to create limit
        dcm %location of pointer
        Bvalues
        Signal
        ImageStack
        Num_Bvalues
    end

    % Callbacks that handle component events
    methods (Access = private)

        %code that executes after component creation.
        function startupFcn(app,varargin)
            if isempty(varargin)
                error('No input image')
            elseif length(varargin)==2
                %this would be for one matlab file (f,D*,D) and then 1 directory for 0-1000
                app.InputImage = varargin{1};
                app.MaxValue = max(app.InputImage,[],'all');
                app.Num_Bvalues = 10;
                app.Bvalues  = [0 111 222 333 444 556 667 778 889 1000];
                ImageDirectory=varargin{2};
                dat_list = dir(fullfile(ImageDirectory,'IM*'));
                datnames = {dat_list.name}; %read them in the correct order
                datnames = natsortfiles(datnames);
                fname  = fullfile(ImageDirectory,dat_list(1).name); %get size of first dicom for reference.
                header = dicominfo(fname);
                nx = header.Height;
                ny = header.Width;
                Images_Per_Slice = 37;
                Start_Index = 28;
                
            elseif length(varargin)==3
                %this would be for one matlab file (f,D*,D) and then 2 directories for 0-300 and 0-1000 respectively
                error('havent yet developed this, sorry.')
            else
                error('wrong input; must be an image variable (for example fDstar), and full directory to folderN with corresponding b value dicom images')
            end
            
            %now show the loaded matlab image (fDstar) on the left panel
            colormapname = 'jet'; %set colormap
            data = app.InputImage;
            %app.UIAxes.reset
            imshow(data,[0,250],'parent',app.UIAxes)
            title('Reference Figure','parent',app.UIAxes)
            colormap(app.UIAxes,colormapname),colorbar(app.UIAxes);
            
            
            % make datacursor usable
            datacursormode(app.UIFigure, 'on')
            app.dcm = datacursormode(app.UIFigure);
            info = getCursorInfo(app.dcm);
            

            %now make the corresponding stack of b-value images
            %assuming just one slice, so Islice=1
            Islice=1;
            i1 = Images_Per_Slice*(Islice-1)+Start_Index; %37*(1-1)+28 = 28
            i2 = i1 + app.Num_Bvalues-1;
            app.ImageStack = zeros(app.Num_Bvalues,nx,ny);
            jj = 1; %which b value
            for i= i1:i2
                fname_1 = fullfile(ImageDirectory,char(datnames(i)));
                %header1 = dicominfo(fname_1);
                app.ImageStack(jj,:,:)= double(dicomread(fname_1));
                jj= jj+1;
            end
            
            %now plot the first IVIM Curve (set arbitrarily to 100,100, near the center.
            app.Signal= double(app.ImageStack(1:app.Num_Bvalues,100,100));
            plot(app.Bvalues,app.Signal,'parent',app.UIAxes2)
            hold (app.UIAxes2, 'on');
            scatter(app.Bvalues,app.Signal,'parent',app.UIAxes2)
            title('IVIM Curve','parent',app.UIAxes2)
            hold (app.UIAxes2, 'off');
            
            
        end

        %change the image range based on the slider
        function SliderColorValueChanged(app,event)
            caxis(app.UIAxes, [double(0) double(app.Slider.Value)])
        end
      
        %update the IVIM Curve to be of the voxel the cursor is on. 
        function MakeIVIMCurve(app,event)
            info = getCursorInfo(app.dcm);
            if isfield(info,'Position')
                %get the current pointer coordinates
                x=info.Position(1);
                y=info.Position(2);
            else
                x=100;
                y=100;
            end

            %make the signal curve from the voxel at those coordinates, using the movement of the mouse.
            app.Signal= double(app.ImageStack(1:app.Num_Bvalues,x,y));
            plot(app.Bvalues,app.Signal,'parent',app.UIAxes2)
            hold (app.UIAxes2, 'on');
            scatter(app.Bvalues,app.Signal,'parent',app.UIAxes2)
            titlename=strcat('IVIM Curve:' ,num2str(x), '-',num2str(y));
            title(titlename,'parent',app.UIAxes2)
            hold (app.UIAxes2, 'off');
        end
        
        %Update the IVIM Curve to be of the voxel the cursor is on, using the left, right, up, down arrow keys
        function MakeIVIMCurve_key(app,event)
            fprintf('ok it got this far')
            if strcmp(event.Key,'leftarrow') || strcmp(event.Key,'rightarrow') || strcmp(event.Key,'uparrow') || strcmp(event.Key,'downarrow') 
                info = getCursorInfo(app.dcm);
                if isfield(info,'Position')
                    %get the current pointer coordinates
                    x=info.Position(1);
                    y=info.Position(2);
                else
                    x=100;
                    y=100;
                end
    
                %make the signal curve from the voxel at those coordinates
                app.Signal= double(app.ImageStack(1:app.Num_Bvalues,x,y));
                plot(app.Bvalues,app.Signal,'parent',app.UIAxes2)
                hold (app.UIAxes2, 'on');
                scatter(app.Bvalues,app.Signal,'parent',app.UIAxes2)
                titlename=strcat('IVIM Curve:' ,num2str(x), '-',num2str(y));
                title(titlename,'parent',app.UIAxes2)
                hold (app.UIAxes2, 'off');
            end
        end
        
        % Changes arrangement of the app based on UIFigure width, both of them equally... hopefully
        function myupdateAppLayout(app, event)
            currentFigureWidth = app.UIFigure.Position(3);
            if(currentFigureWidth <= app.onePanelWidth)
                % Change to a 2x1 grid
                app.GridLayout.RowHeight = {480, 480};
                app.GridLayout.ColumnWidth = {'1x'};
                app.RightPanel.Layout.Row = 2;
                app.RightPanel.Layout.Column = 1;
            else
                % Change to a 1x2 grid
                app.GridLayout.RowHeight = {'1x'};
                app.GridLayout.ColumnWidth = {'1x','1x'}; %have both of them change
                app.RightPanel.Layout.Row = 1;
                app.RightPanel.Layout.Column = 2;
            end
        end

    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app,varargin)
            %starting with the basics
            app.InputImage = varargin{1};
            app.MaxValue = max(app.InputImage,[],'all');

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.AutoResizeChildren = 'off';
            app.UIFigure.Position = [100 100 728 480];
            app.UIFigure.Name = 'IVIM Curve test App';
            app.UIFigure.SizeChangedFcn = createCallbackFcn(app, @myupdateAppLayout, true); %changed to have equal change in width adjustment
            app.UIFigure.WindowKeyPressFcn = createCallbackFcn(app, @MakeIVIMCurve_key, true);
            app.UIFigure.WindowButtonMotionFcn = createCallbackFcn(app, @MakeIVIMCurve, true);


            % Create GridLayout
            app.GridLayout = uigridlayout(app.UIFigure);
            app.GridLayout.ColumnWidth = {391, '1x'};
            app.GridLayout.RowHeight = {'1x'};
            app.GridLayout.ColumnSpacing = 0;
            app.GridLayout.RowSpacing = 0;
            app.GridLayout.Padding = [0 0 0 0];
            app.GridLayout.Scrollable = 'on';

            % Create LeftPanel
            app.LeftPanel = uipanel(app.GridLayout);
            app.LeftPanel.Layout.Row = 1;
            app.LeftPanel.Layout.Column = 1;

            % Create UIAxes
            app.UIAxes = uiaxes(app.LeftPanel);
            app.UIAxes.Position = [58 6 327 466];

            % Create Slider
            app.Slider = uislider(app.LeftPanel);
            app.Slider.Orientation = 'vertical';
            app.Slider.Limits = [0 app.MaxValue/4];
            app.Slider.Value= 250; %just standard fDstar
            app.Slider.Position = [16 59 3 392];
            app.Slider.MinorTicks = [];
            app.Slider.ValueChangedFcn = createCallbackFcn(app, @SliderColorValueChanged, true);

            % Create RightPanel
            app.RightPanel = uipanel(app.GridLayout);
            app.RightPanel.Layout.Row = 1;
            app.RightPanel.Layout.Column = 2;

            % Create UIAxes2
            app.UIAxes2 = uiaxes(app.RightPanel);
            %title(app.UIAxes2, 'Title')
            %xlabel(app.UIAxes2, 'X')
            %ylabel(app.UIAxes2, 'Y')
            %zlabel(app.UIAxes2, 'Z')
            app.UIAxes2.Position = [9 6 322 466];

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = PlotIVIMCurve(varargin)

            % Create UIFigure and components
            createComponents(app,varargin{:})
            % Execute the startup function
            runStartupFcn(app, @(app)startupFcn(app, varargin{:}))
            app.UIFigure.Visible = 'on';


            %now keep updating 

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