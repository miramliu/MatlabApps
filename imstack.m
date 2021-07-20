%% Basic Image viewer started by Mira July 2019
%  current functions: include 'permute' as input if the stack is of
% the form [slice, x,y]. if it is of the form [x,y,slice] 'permute' is not
% needed. 
% can include name as second input to put a name of the stack of images
%sets to middle slice, able to scroll or click through. select image to be able to use arrow keys to move through. 
% able to change the minimum and maximum pixel value
%figure scales with window size
%can zoom in and out 

% to be added: be able to flip and rotate images, be able to see outlines
% of ROIs while scrolling through stack, be able to change the colormap.

%any questions direct to liusarkarm@uchicago.edu

classdef imstack < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure           matlab.ui.Figure
        MaxEditFieldLabel  matlab.ui.control.Label
        MaxColor           matlab.ui.control.NumericEditField
        MinEditFieldLabel  matlab.ui.control.Label
        MinColor           matlab.ui.control.NumericEditField
        SliceSliderLabel   matlab.ui.control.Label
        Slice              matlab.ui.control.Slider
        UIAxes             matlab.ui.control.UIAxes
    end

    
    properties (Access = private)
        InputImage % Input stack of images
        Ss
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app, varargin)
            if isempty(varargin)
                error('No input images')
            elseif length(size(varargin{1})) ==3
                app.InputImage = varargin{1};
                name = 'Figure';
                if size(varargin,2) ==2
                    if strcmp(string(varargin{2}),'permute')
                        app.InputImage = permute(varargin{1},[2 3 1]); %if it is given as [slice,x,y]
                    else
                        %name = varargin{2}(82:end-4);
                        %name=strrep(name,'_','-');
                        name = varargin{2};
                    end
                end
            else
                error('Wrong Image Input: data must be 3d image [x,y,slice] or input [slice,x,y], "permute"')
            end
            
            data = app.InputImage(:,:,round(app.Ss/2));
            app.UIAxes.reset
            imshow(data,[],'parent',app.UIAxes)
            title(name,'parent',app.UIAxes)
            colormap(app.UIAxes,'jet'),colorbar(app.UIAxes);
        end

        % Value changed function: MaxColor
        function MaxColorValueChanged(app, event)
            caxis(app.UIAxes, [double(app.MinColor.Value) double(app.MaxColor.Value)])
        end

        % Value changed function: MinColor
        function MinColorValueChanged(app, event)
            caxis(app.UIAxes, [double(app.MinColor.Value) double(app.MaxColor.Value)])
        end

        % Value changed function: Slice
        function SliceValueChanged(app, event)
            data = app.InputImage(:,:,round(double(app.Slice.Value)));
            imshow(data,[double(app.MinColor.Value) double(app.MaxColor.Value)],'parent',app.UIAxes)
            colormap(app.UIAxes,'jet'),colorbar(app.UIAxes);
            app.SliceSliderLabel.Text = string('Slice ' + string(round(double(app.Slice.Value))));
        end

        function SliceValueChangedKey(app,event)
            if strcmp(event.Key, 'leftarrow')
                if round(app.Slice.Value)~= 1
                    app.Slice.Value = round(app.Slice.Value) - 1;
                    app.SliceSliderLabel.Text = ['Slice' ' ' num2str(round(app.Slice.Value))];
                    data = app.InputImage(:,:,round(double(app.Slice.Value)));
                    imshow(data,[double(app.MinColor.Value) double(app.MaxColor.Value)],'parent',app.UIAxes)
                    colormap(app.UIAxes,'jet'),colorbar(app.UIAxes);
                end
            end
            if strcmp(event.Key, 'rightarrow')
                if round(app.Slice.Value)~= app.Ss
                    app.Slice.Value = round(app.Slice.Value) + 1;
                    app.SliceSliderLabel.Text = ['Slice' ' ' num2str(round(app.Slice.Value))];
                    data = app.InputImage(:,:,round(double(app.Slice.Value)));
                    imshow(data,[double(app.MinColor.Value) double(app.MaxColor.Value)],'parent',app.UIAxes)
                    colormap(app.UIAxes,'jet'),colorbar(app.UIAxes);
                end
            end
            if strcmp(event.Key,'v') % vertical flip (over horizontal axis)
                app.InputImage = flip(app.InputImage,1);
                data = app.InputImage(:,:,round(double(app.Slice.Value)));
                imshow(data,[double(app.MinColor.Value) double(app.MaxColor.Value)],'parent',app.UIAxes)
                colormap(app.UIAxes,'jet'),colorbar(app.UIAxes);
            end
            if strcmp(event.Key, 'h')
                app.InputImage = flip(app.InputImage,2); % horizontal flip (over vertical axis)
                data = app.InputImage(:,:,round(double(app.Slice.Value)));
                imshow(data,[double(app.MinColor.Value) double(app.MaxColor.Value)],'parent',app.UIAxes)
                colormap(app.UIAxes,'jet'),colorbar(app.UIAxes);
            end
            
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app,varargin)
            app.Ss = size(varargin{1},3); % number of slices (assuming x,y,slice)
            if size(varargin,2) ==2 %checking order of matrix
                if strcmp(string(varargin{2}),'permute')
                	app.Ss = size(varargin{1},1); %if it is given as [slice,x,y]
                end
            end
            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [300 300 550 400];
            app.UIFigure.Name = 'imstack';
            app.UIFigure.KeyPressFcn = createCallbackFcn(app, @SliceValueChangedKey, true);
            %app.UIFigure.KeyPressFcn = createCallbackFcn(app, @Flip, true);

            % Create MaxColor
            app.MaxColor = uieditfield(app.UIFigure, 'numeric');
            app.MaxColor.ValueChangedFcn = createCallbackFcn(app, @MaxColorValueChanged, true);
            app.MaxColor.Position = [40 215 40 22];
            app.MaxColor.Value = 1;

            % Create MaxEditFieldLabel
            app.MaxEditFieldLabel = uilabel(app.UIFigure);
            app.MaxEditFieldLabel.HorizontalAlignment = 'right';
            app.MaxEditFieldLabel.Position = [3 215 30 22];
            app.MaxEditFieldLabel.Text = 'Max';

            % Create MinColor
            app.MinColor = uieditfield(app.UIFigure, 'numeric');
            app.MinColor.ValueChangedFcn = createCallbackFcn(app, @MinColorValueChanged, true);
            app.MinColor.Position = [40 180 40 22];
            
            % Create MinEditFieldLabel
            app.MinEditFieldLabel = uilabel(app.UIFigure);
            app.MinEditFieldLabel.HorizontalAlignment = 'right';
            app.MinEditFieldLabel.Position = [3 180 30 22];
            app.MinEditFieldLabel.Text = 'Min';

            % Create UIAxes
            app.UIAxes = uiaxes(app.UIFigure);
            app.UIAxes.Position = [90 50 421 300 ];
            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';

            % Create Slice
            app.Slice = uislider(app.UIFigure);
            app.Slice.Limits = [1 app.Ss];
            app.Slice.MinorTicks = [];
            app.Slice.ValueChangedFcn = createCallbackFcn(app, @SliceValueChanged, true);
            if app.Ss> 5
                app.Slice.MajorTicks = [1 round(app.Ss/4) round(app.Ss/2) round(app.Ss*3/4) app.Ss];
                app.Slice.Position = [141 48 330 3];
                app.Slice.Value = round(app.Ss/2);
            else
                app.Slice.MajorTicks = [1 2 3 4 5];
                app.Slice.Position = [141 48 330 3];
                app.Slice.Value = round(app.Ss/2);
            end
                

            % Create SliceSliderLabel
            app.SliceSliderLabel = uilabel(app.UIFigure);
            app.SliceSliderLabel.HorizontalAlignment = 'right';
            app.SliceSliderLabel.Position = [275 1 50 22];
            app.SliceSliderLabel.Text = ['Slice' ' ' num2str(round(app.Slice.Value))];

            
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = imstack(varargin)

            % Create UIFigure and components
            createComponents(app,varargin{:})

            % Execute the startup function
            runStartupFcn(app, @(app)startupFcn(app, varargin{:}))
            app.UIFigure.Visible = 'on';

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