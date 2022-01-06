%% simple app to show an and be able to chose a voxel in the image and show the corresponding IVIM curve as a function of b.
%input f, D, D*, the folder to the sorted dcm files, the slice of interest.
%displays a slider to choose range of values of reference image, the reference image, and then the curve on the left
%starts with 100,100, but after that should live update location of cursor. 
%runs on Matlab 2021b
% an example command line input is "PlotIVIMCurve(f,D,Dstar,'/Users/neuroimaging/Desktop/DATA/IVIM_Pulsatility/2021_12_21_IVIM_TIM/DICOM_sorted',24)"
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
        ShowPlotButton  matlab.ui.control.Button
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
        FitVariableLength %if there are the 3 fit coefficients
        f
        D
        Dstar
        slice
    end

    % Callbacks that handle component events
    methods (Access = private)

%% set up initial GUI
        %code that executes after component creation.
        function startupFcn(app,varargin)
            if isempty(varargin)
                error('No input image')
            elseif length(varargin)==3
                app.FitVariableLength = 2;
                error('still in progress, please put in f, D, and D*')
            elseif length(varargin)==4
                %this would be for one matlab file (f,D*,D) and then 2 directories for 0-300 and 0-1000 and slice number respectively
                app.FitVariableLength = 3;
                error('havent yet developed this, sorry.')
            elseif length(varargin)== 5
                %this would be for 3 matlab files (f, D*, and D) and then one directory for 0 -1000 and the slice number respectively
                % get variables and images of each variable
                app.FitVariableLength = 5;
                app.slice = varargin{5};
                app.f = squeeze(varargin{1}(app.slice,:,:)); %get the slice of interest for f, D, and Dstar
                app.D = squeeze(varargin{2}(app.slice,:,:));
                app.Dstar = squeeze(varargin{3}(app.slice,:,:));

                %get IVIM qCBF image of that slice of interest
                app.InputImage = squeeze(varargin{1}(app.slice,:,:).*varargin{3}(app.slice,:,:)).*102270; %quantitative scale factor with IVIM, to get qCBF image
                app.MaxValue = max(app.InputImage,[],'all');
                app.Num_Bvalues = 10;
                app.Bvalues  = [0 111 222 333 444 556 667 778 889 1000];

                Image_Directory=varargin{4}; %the last variable input
                dat_list = dir(fullfile(Image_Directory,'IM*'));
                datnames = {dat_list.name}; %read them in the correct order
                datnames = natsortfiles(datnames);
                fname  = fullfile(Image_Directory,dat_list(1).name); %get size of first dicom for reference.
                header = dicominfo(fname);
                nx = header.Height;
                ny = header.Width;
                Images_Per_Slice = 37;
                Start_Index = 28;
                
            else
                error('wrong input; must be an image variable (for example fDstar), and full directory to folderN with corresponding b value dicom images')
            end

            %now show the loaded matlab image (fDstar) on the left panel
            colormapname = 'jet'; %set colormap
            data = squeeze(app.InputImage);

            %app.UIAxes.reset
            imshow(data,[0,250],'parent',app.UIAxes)
            title('Reference Figure','parent',app.UIAxes)
            colormap(app.UIAxes,colormapname),colorbar(app.UIAxes);
            
            % make datacursor usable, but DONT GET INFORMATION because that delays so much. 
            datacursormode(app.UIFigure, 'on')
            app.dcm = datacursormode(app.UIFigure);

            % get data for b value curve
                Image_Directory=varargin{4}; %the last variable input
                dat_list = dir(fullfile(Image_Directory,'IM*'));
                datnames = {dat_list.name}; %read them in the correct order
                datnames = natsortfiles(datnames);
                fname  = fullfile(Image_Directory,dat_list(1).name); %get size of first dicom for reference.
                header = dicominfo(fname);
                nx = header.Height;
                ny = header.Width;
                Images_Per_Slice = 37;
                Start_Index = 28;

            % set up the image of the slice of interest across all b-values (i.e. Images_T from Reconstruction.mat)
                i1 = Images_Per_Slice*(app.slice-1)+Start_Index; %37*(1-1)+28 = 28, get starting index
                i2 = i1 + app.Num_Bvalues-1; %get end index
                app.ImageStack = zeros(app.Num_Bvalues,nx,ny); %because this is one slice, it's a stack [slice, nx,ny] matching the variable images (f, D, etc)
                
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
                    app.ImageStack(jj,:,:)= w2*double(dicomread(fname_im2)) +           ...   
                                    w1*double(dicomread(fname_im1)) +           ... 
                                    w0*double(dicomread(fname_im0)) +           ... 
                                    w1*double(dicomread(fname_ip1)) +           ... 
                                    w2*double(dicomread(fname_ip2));
                    jj= jj+1;
                end

            %now plot the first IVIM Curve (set arbitrarily to the center).
            app.Signal= double(app.ImageStack(1:app.Num_Bvalues,round(nx/2),round(ny/2)));
            scatter(app.Bvalues,app.Signal/app.Signal(1),'parent',app.UIAxes2,markerfacecolor='black') %normalized to b0 (like IVIM fit algorithm)
            title('IVIM Curve','parent',app.UIAxes2)
            hold (app.UIAxes2, 'on');
            
            %if there are also all fit variables, plot the fit on top of the signal
            if app.FitVariableLength == 5
                %plot Diffusion regime
                Dfit = (1-app.f(round(nx/2),round(ny/2)))*exp(-app.Bvalues*app.D(round(nx/2),round(ny/2))); 
                plot(app.Bvalues,Dfit,'color',[0 0.4470 0.7410],'parent',app.UIAxes2)
                hold (app.UIAxes2, 'on');

                %plot perfusion regime
                CBFfit = (app.f(round(nx/2),round(ny/2)))*exp(-app.Bvalues*app.Dstar(round(nx/2),round(ny/2)))+(1-app.f(round(nx/2),round(ny/2)))*exp(-app.Bvalues*app.D(round(nx/2),round(ny/2)));
                plot(app.Bvalues,CBFfit,'color', [0.6350 0.0780 0.1840],'parent',app.UIAxes2)

            end
            hold (app.UIAxes2, 'off');
        end
%% Callback Functions (i.e. functions that run when a user interacts with the GUI... hopefully)
% this is outside of the startFnc, so it is operating on the WINDOW not on a plot. %
        
        %change the image range based on the slider
        function SliderColorValueChanged(app,event)
            caxis(app.UIAxes, [double(0) double(app.Slider.Value)])
        end

        % Button pushed function: ShowPlotButton
        function ShowPlotButtonPushed(app, event)
            MakeIVIMCurve(app)
        end
      
        %update the IVIM Curve to be of the voxel the cursor is on, AFTER CLICK
        function MakeIVIMCurve(app)
            info = getCursorInfo(app.dcm);
            if isfield(info,'Position')
                %get the current pointer coordinates
                y=info.Position(1); %????? are they switched? are theY THAT ANNOYING     YEP THEY ARE.
                x=info.Position(2); %[X,Y] ON DATA TIPS IS [Y,X] IN BASIC LINEAR ALG. so annoying my god why.
            else
                x=100;  
                y=100;
            end

            %make the signal curve from the voxel at those coordinates, using the movement of the mouse.
            app.Signal= double(app.ImageStack(1:app.Num_Bvalues,x,y));
            scatter(app.Bvalues,app.Signal/app.Signal(1),'parent',app.UIAxes2, markerfacecolor = 'black')
            titlename=strcat("IVIM Curve: [" ,num2str(x), '-',num2str(y), "]");
            title(titlename,'parent',app.UIAxes2)
            hold (app.UIAxes2, 'on');
            %if there are also all fit variables, plot the fit on top of the signal
            if app.FitVariableLength == 5

                %plot Diffusion regime
                Dfit = (1-app.f(x,y))*exp(-app.Bvalues*app.D(x,y)); 
                plot(app.Bvalues,Dfit,'color',[0 0.4470 0.7410],'parent',app.UIAxes2)
                hold (app.UIAxes2, 'on');

                %plot perfusion regime
                CBFfit = (app.f(x,y))*exp(-app.Bvalues*app.Dstar(x,y))+(1-app.f(x,y))*exp(-app.Bvalues*app.D(x,y));
                plot(app.Bvalues,CBFfit,'color', [0.6350 0.0780 0.1840],'parent',app.UIAxes2)   
                hold(app.UIAxes2,'on');

                %display the residual 
                IVIM = app.Signal/app.Signal(1);
                Residual =  sum(sqrt(abs(IVIM'-CBFfit)));
                text(600,.95,strcat("Residual = ", num2str(Residual,3)),'parent',app.UIAxes2)
                text(600,.92,strcat("f = ", num2str(app.f(x,y),3)),'parent',app.UIAxes2)
                text(600,.89,strcat("Dstar = ", num2str(app.Dstar(x,y),2)),'parent',app.UIAxes2)
                text(600,.86,strcat("D = ", num2str(app.D(x,y),3)),'parent',app.UIAxes2)
                text(600,.80,strcat("qCBF = ", num2str(app.f(x,y).*app.Dstar(x,y).*102270,3)),'parent',app.UIAxes2)

            end

            hold (app.UIAxes2, 'off');
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

        %% Create UIFigure and components
        function createComponents(app,varargin)
            %starting with the basics
            if length(varargin)== 5 %if given f, D, and Dstar, to make qCBF image, get fD*star * 102270
                app.InputImage = varargin{1}.*varargin{3}.*102270;
            else
                app.InputImage = varargin{1};
            end
            app.MaxValue = max(app.InputImage,[],'all');

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.AutoResizeChildren = 'off';
            app.UIFigure.Position = [100 100 728 480];
            app.UIFigure.Name = 'IVIM Curve test App';
            app.UIFigure.SizeChangedFcn = createCallbackFcn(app, @myupdateAppLayout, true); %changed to have equal change in width adjustment
            %app.UIFigure.KeyPressFcn = createCallbackFcn(app, @MakeIVIMCurve_key, true);
            %app.UIFigure.WindowButtonDownFcn = createCallbackFcn(app, @MakeIVIMCurve, true); %changed from WindowbuttonMotionFcn to WindowButtonDownFcn


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

            % Create UIAxes (Reference Image)
            app.UIAxes = uiaxes(app.LeftPanel);
            app.UIAxes.Position = [58 6 327 466];

            % Create Slider
            app.Slider = uislider(app.LeftPanel);
            app.Slider.Orientation = 'vertical';
            app.Slider.Limits = [0 app.MaxValue];
            app.Slider.Value= app.MaxValue/2; %just standard fDstar
            app.Slider.Position = [16 59 3 392];
            app.Slider.MinorTicks = [];
            app.Slider.ValueChangedFcn = createCallbackFcn(app, @SliderColorValueChanged, true);

             % Create ShowPlotButton
            app.ShowPlotButton = uibutton(app.LeftPanel, 'push');
            app.ShowPlotButton.Position = [18 6 100 22];
            app.ShowPlotButton.Text = 'Show Plot';
            app.ShowPlotButton.ButtonPushedFcn = createCallbackFcn(app, @ShowPlotButtonPushed, true);


            % Create RightPanel
            app.RightPanel = uipanel(app.GridLayout);
            app.RightPanel.Layout.Row = 1;
            app.RightPanel.Layout.Column = 2;

            % Create UIAxes2 (Data Fit plot)
            app.UIAxes2 = uiaxes(app.RightPanel);
            %title(app.UIAxes2, 'Title')
            %xlabel(app.UIAxes2, 'X')
            %ylabel(app.UIAxes2, 'Y')
            %zlabel(app.UIAxes2, 'Z')
            app.UIAxes2.YLim = [0 1];
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