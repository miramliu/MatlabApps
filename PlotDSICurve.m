%% simple app to show and and be able to chose a voxel in the image and show the corresponding IVIM curve as a function of b.
%input the variables f, D, D*, the folder to the sorted dcm files, the slice of interest.
%displays a slider to choose range of values of reference image, the reference image (102270fD*) on the left the scatter plot of the values with the diffusion and total tri-exponential fit on the right. Also the values of f, D, D*, qCBF (102270fD*) and the residual should appear on the left plot.
%starts with the center pixel but after that should live update location of cursor which will then show the plot and fit when you click the button on the bottom left.
%runs on Matlab 2021b
% an example command line input is "PlotIVIMCurve(f,D,Dstar,'/Users/neuroimaging/Desktop/DATA/IVIM_Pulsatility/2021_12_21_IVIM_TIM/DICOM_sorted',24)"
%1/11/22 Mira Liu

classdef PlotDSICurve < matlab.apps.AppBase

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
        slice
        FitBvalues
        fD_maps
        SpectralVolume
        OutputSpectrum
        ADCBasis
        Resorted_spectralmap
    end

    % Callbacks that handle component events
    methods (Access = private)

%% set up initial GUI
        %code that executes after component creation.
        function startupFcn(app,varargin)
            if isempty(varargin)
                error('No input image')
            elseif length(varargin)>=2

                %try 
                addpath /Users/miramliu/Desktop/Work/PhD/MR-Code/Applied_NNLS_neural/Neural_ContinuousSpectra
                %catch
                addpath /Users/miraliu/Desktop/PostDocCode/Neural_ContinuousSpectra
                %end
                app.FitVariableLength = 2;
                %this would be for 1 matlab file (SCan Name_2step.mat) which has f, Dstar, and D, 1 folder, and 1 slice
                % get variables and images of each variable
                load(varargin{1}, 'IVIM_DSI')
                Parameter_Volume = IVIM_DSI.Parameter_Volume;
                Spectral_Volume = IVIM_DSI.Spectral_Volume;
                if ndims(Parameter_Volume)==4
                    app.slice = varargin{2};
                    
                elseif ndims(Parameter_Volume)==3 % it is only one slice so... 
                    [nx,ny,nz] = size(Parameter_Volume);
                    test = zeros(1,nx,ny,nz);
                    test(1,:,:,:) = Parameter_Volume; %make it 3D
                    Parameter_Volume = test;
                    app.slice = 1;


                    [nx,ny,nz] = size(Spectral_Volume);
                    test = zeros(1,nx,ny,nz);
                    test(1,:,:,:) = Spectral_Volume; %make it 3D
                    Spectral_Volume = test;
                    app.slice = 1;
                end

                app.SpectralVolume = squeeze(Spectral_Volume(app.slice,:,:,:));

                [app.Resorted_spectralmap] = Resort_Spectral_DSI_Map(Parameter_Volume,app.slice);
                [app.Resorted_spectralmap] = Resort_Spectral_DSI_Map_20240620(Parameter_Volume,app.slice);

                [nx, ny, ~]=size(squeeze(app.Resorted_spectralmap(1,:,:,:)));
                app.fD_maps=zeros(nx, ny, 3);
                app.fD_maps(:,:,1)=app.Resorted_spectralmap(app.slice,:,:,1).*app.Resorted_spectralmap(app.slice,:,:,4)*93;
                app.fD_maps(:,:,2)=app.Resorted_spectralmap(app.slice,:,:,2).*app.Resorted_spectralmap(app.slice,:,:,5)*93;
                app.fD_maps(:,:,3)=app.Resorted_spectralmap(app.slice,:,:,3).*app.Resorted_spectralmap(app.slice,:,:,6)*93;

                %get IVIM qCBF image of that slice of interest
                %app.InputImage = imresize(squeeze(app.fD_maps(:,:, 2)),[176 176],'bicubic'); %quantitative scale factor with IVIM, to get qCBF image
                if length(varargin)==2
                    app.InputImage = squeeze(app.fD_maps(:,:, 2));
                    app.MaxValue = max(app.InputImage,[],'all');
                elseif length(varargin)==3
                    if strcmpi(varargin{3},'CSFmap')
                        app.InputImage = squeeze(app.fD_maps(:,:, 1));
                        app.MaxValue = max(app.InputImage,[],'all');
                    elseif strcmpi(varargin{3},'Tissuemap')
                        app.InputImage = squeeze(app.fD_maps(:,:, 3));
                        app.MaxValue = max(app.InputImage,[],'all');
                    elseif strcmpi(varargin{3},'CBFmap')
                        app.InputImage = squeeze(app.fD_maps(:,:, 2));
                        app.MaxValue = max(app.InputImage,[],'all');
                    %elseif strcmpi(varargin{3},'fmap')
                        %app.InputImage = squeeze(app.Resorted_spectralmap(app.slice,:,:,3));
                        %app.MaxValue = .5;
                    end
                end


                %app.Num_Bvalues = 10;
                %app.Bvalues  = [0 111 222 333 444 556 667 778 889 1000];
                %app.FitBvalues = linspace(0,1000); %b values for smooth fit of f and D and Dstar, 100 points from 0 to 1000 evenly spaces

                

                %app.MaxSpecValue = max(app.Spectral_Volume,[],'all');
                
            else
                error('wrong input; must be full path to directory with the matlab file with parmeter volume and spectral volume, and slice of interest')
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


            %now plot the DSI peaks (set arbitrarily to the center).
            ADCBasisSteps = 300; %(??)
            app.ADCBasis = logspace( log10(5), log10(2200), ADCBasisSteps);
            app.OutputSpectrum = double(squeeze(app.SpectralVolume(round(nx/2),round(ny/2),:)));
            semilogx((1./app.ADCBasis)*1000, app.OutputSpectrum,'parent',app.UIAxes2)
            %app.Signal= double(app.ImageStack(1:app.Num_Bvalues,round(nx/2),round(ny/2)));
            %sz = 70;
            %scatter(app.Bvalues,app.Signal/app.Signal(1),sz,'parent',app.UIAxes2,markerfacecolor='black') %normalized to b0 (like IVIM fit algorithm)
            title('Diffusion Spectrum','parent',app.UIAxes2)
            hold (app.UIAxes2, 'on');
           
            
            xline(50,'parent',app.UIAxes2)%,markerfacecolor='black')
            hold (app.UIAxes2, 'on');
            xline(1,'parent',app.UIAxes2)%,markerfacecolor='black')
            %if there are also all fit variables, plot the fit on top of the signal
          
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
            MakeDSICurve(app)
        end
      
        %update the IVIM Curve to be of the voxel the cursor is on, AFTER CLICK
        function MakeDSICurve(app)
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
            app.OutputSpectrum = double(squeeze(app.SpectralVolume(x,y,:)));
            semilogx((1./app.ADCBasis)*1000, app.OutputSpectrum, 'parent',app.UIAxes2)
            %sz = 70;
            hold (app.UIAxes2, 'on');
            
            xline(50,'parent',app.UIAxes2)%,markerfacecolor='black')
            hold (app.UIAxes2, 'on');
            xline(1,'parent',app.UIAxes2)%,markerfacecolor='black')
            %scatter(app.Bvalues,app.Signal/app.Signal(1),sz,'parent',app.UIAxes2, markerfacecolor = 'black')
            titlename=strcat("Diffusion Spectrum: [" ,num2str(x), '-',num2str(y), "]");
            title(titlename,'parent',app.UIAxes2)
            hold (app.UIAxes2, 'on');

            figtext = strcat("f = " , num2str(squeeze(app.Resorted_spectralmap(app.slice,x,y,1)),3) , ", D = " , num2str(squeeze(app.Resorted_spectralmap(app.slice,x,y,4)),3));
            text(2,.18,figtext,'parent',app.UIAxes2)

            figtext = strcat("f = " , num2str(squeeze(app.Resorted_spectralmap(app.slice,x,y,2)),3) , ", D = " , num2str(squeeze(app.Resorted_spectralmap(app.slice,x,y,5)),3));
            text(2,.15,figtext,'parent',app.UIAxes2)

            figtext = strcat("f = " , num2str(squeeze(app.Resorted_spectralmap(app.slice,x,y,3)),3) , ", D = " , num2str(squeeze(app.Resorted_spectralmap(app.slice,x,y,6)),3));
            text(2,.12,figtext,'parent',app.UIAxes2)
            

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
            app.Slider.Limits = [0 250]; %changed to 250 because was being weird if it was app.MaxValue
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
            xlabel(app.UIAxes2, 'Diffusion Coefficient (mm^2/s)',FontSize=16)
            %ylabel(app.UIAxes2, 'Y')
            %zlabel(app.UIAxes2, 'Z')
            app.UIAxes2.YLim = [0 0.2];
            app.UIAxes2.Position = [9 6 322 466];

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = PlotDSICurve(varargin)

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