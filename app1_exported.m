classdef app1_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure             matlab.ui.Figure
        GridLayout           matlab.ui.container.GridLayout
        SelectImageButton    matlab.ui.control.Button
        SelectImageButton_2  matlab.ui.control.Button
        CompareButton        matlab.ui.control.Button
        label                matlab.ui.control.Label
        SaveButton           matlab.ui.control.Button
        UIAxes               matlab.ui.control.UIAxes
        UIAxes2              matlab.ui.control.UIAxes
        UIAxes3              matlab.ui.control.UIAxes
    end

    
    properties (Access = private)
        
        im_area_1 % Description
        im_area_2
        lefttop =[37.0000  448.2000  647.2000  329.6000];
        leftdown =[33.0000   45.0000  656.8000  317.6000];
        rightup =[851.4000  449.8000  670.4000  323.2000];
        rightdown =[849.8000   50.6000  695.2000  312.8000];
        center_up =[498.6000  506.6000  572.0000  273.6000];
        center_down =[496.2000   31.4000  567.2000  270.4000];
        save_cnt=0;
        saved=0;
    end
    
    methods (Access = private)
        
        function updateimage(app,ax,imagefile)
            
            
            try
                im = imread(imagefile);
            catch ME
                % If problem reading image, display error message
                uialert(app.UIFigure, ME.message, 'Image Error');
                return;
            end
            ax.XLim=[0,size(im,2)];
            ax.YLim=[0,size(im,1)];
            imagesc(ax,im);
            
            if ax.Title.String=="Clean"
                app.im_area_1=im;
                assignin('base', 'area1', app.im_area_1);
            end
            
            if ax.Title.String=="Dirty"
                app.im_area_2=im;
                assignin('base', 'area2', app.im_area_2)
            end
            
            if ~isempty(app.im_area_1) && ~isempty(app.im_area_2)
                app.CompareButton.Enable=1;
                app.label.Text="Click the Compare Button";
            end
            
            
        end
        function  filters(app,im,kernel,NGB_size,sigma,pos)
            %FİLTERS [im_gray,im_median,im_bilateral,im_gauss]=filters(im,kernel,NGB_size,sigma);
            
            %[im_gray,im_median,im_bilateral,im_gauss]=filters(im,7,13,1.2);
            
            
            
            im_gray = rgb2gray(im);
            im_median =medfilt2(im_gray,[kernel kernel]);
            im_bilateral=imbilatfilt(im_gray, NGB_size);
            im_gauss= imgaussfilt(im_gray,sigma);
            
            gr_gray=insertText(im_gray,[size(im_gray,2)/2,100],"Gray Image",'AnchorPoint','CenterBottom',"FontSize",50);
            gr_median=insertText(im_median,[size(im_median,2)/2,100],"Median Filter",'AnchorPoint','CenterBottom',"FontSize",50);
            gr_bilateral=insertText(im_bilateral,[size(im_bilateral,2)/2,100],"Bilateral Filter",'AnchorPoint','CenterBottom',"FontSize",50);
            gr_gauss=insertText(im_gauss,[size(im_gauss,2)/2,100],'Gaussian Filter','AnchorPoint','CenterBottom',"FontSize",50);
            
            fig=figure;
            fig.Position=pos;
            fig.Name="filters";
            montage({gr_gray,gr_median,gr_bilateral,gr_gauss});
            fig.Position=pos;
        end
        
        
        function  edgedetect(app,im,pos)
            %EDGEDETECT Summary of this function goes here
            %   Detailed explanation goes here
            im_gray=rgb2gray(im);
            im_median =medfilt2(im_gray,[13 13]);
            
            im_sobel =edge(im_median,"Sobel");
            im_prewitt = edge(im_median,'Prewitt');
            im_canny = edge(im_median,"Canny",[0.13 0.27]);
            im_aproxcanny = edge(im_median,'approxcanny',[0.13 .27]);
            
            gr_sobel=insertText(double(im_sobel),[size(im,2)/2,100],"Sobel",'AnchorPoint','CenterBottom',"FontSize",50);
            gr_prewitt=insertText(double(im_prewitt),[size(im,2)/2,100],"Prewitt",'AnchorPoint','CenterBottom',"FontSize",50);
            gr_canny=insertText(double(im_canny),[size(im,2)/2,100],"Canny",'AnchorPoint','CenterBottom',"FontSize",50);
            gr_aproxcanny=insertText(double(im_aproxcanny),[size(im,2)/2,100],"AproxCanny",'AnchorPoint','CenterBottom',"FontSize",50);
            
            fig=figure;
            fig.Position=pos;
            fig.Name="Edge Detection Algorithms : Apply into Median Filter";
            montage({gr_sobel,gr_prewitt,gr_canny,gr_aproxcanny});
            fig.Position=pos;
            
        end
        function features(~,im,strongest,pos_up,pos_down)
            im_gray=rgb2gray(im);
            im_median =medfilt2(im_gray,[13 13]);
            
            regions_mserf=detectMSERFeatures(im_median,"MaxAreaVariation",0.25,"ThresholdDelta",2);
            points_surf=detectSURFFeatures(im_median,"NumOctaves",7,"NumScaleLevels",5);
            %points_kaze = detectKAZEFeatures(im_median,"NumOctaves",4.2,"NumScaleLevels",5.3);
            
            gr_mserf=insertText(im,[size(im,2)/2,100],"MSERF FEATURES","AnchorPoint","CenterBottom","FontSize",50);
            gr_surf=insertText(im,[size(im,2)/2,100],"SURFFeatures","AnchorPoint","CenterBottom","FontSize",50);
            
            fig_mserf=figure;
            fig_mserf.Position=pos_up;
            fig_mserf.Name="MSERF FEATURES  - gray+median+mserf";
            imshow(gr_mserf);
            hold on;
            plot(regions_mserf);
            fig_mserf.Position=pos_up;
            hold off;
            
            fig_surf=figure;
            fig_surf.Position=pos_down;
            fig_surf.Name="SURF FEATURES  - gray+median+surf";
            imshow(gr_surf);
            hold on;
            plot(points_surf.selectStrongest(strongest));
            fig_surf.Position=pos_down;
            hold off;
            
            
            
            
            
        end
        
        
        function selected_process(app,im,ax)
            im_gray=rgb2gray(im);
            im_median=medfilt2(im_gray,[13 13]);
            
            regions_mserf=detectMSERFeatures(im_median,"MaxAreaVariation",0.25,"ThresholdDelta",2);
            [~ , points_mserf] = extractFeatures(im_median,regions_mserf);
            %axes(ax);
            ax.XLim=[0,size(im,2)*2];
            ax.YLim=[0,size(im,1)];
            %imagesc(ax,im);
            axes(ax);
            hold(ax,"on");
            points=selectStrongest(points_mserf,40);
            showMatchedFeatures(app.im_area_1,app.im_area_2,points,points,"montage","Parent",ax);
            plot(points,ax);
            points.Location(:,1)=points.Location(:,1)+size(im,2);
            %hold on
            plot(points,ax);
            
        end
        
    end
    
    
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            app.UIAxes.Visible=0;
            app.UIAxes2.Visible=0;
            app.UIAxes3.Visible=0;
            app.SaveButton.Enable=0;
            app.UIAxes.Title.Visible=1;
            app.UIAxes2.Title.Visible=1;
            
            app.im_area_1=[];
            app.im_area_2=[];
            app.CompareButton.Enable=0;
            
            
            
        end

        % Button pushed function: SelectImageButton
        function SelectImageButtonPushed(app, event)
            % Display uigetfile dialog
            filterspec = {'*.jpg;*.jpeg;*.tif;*.png;*.gif','All Image Files'};
            [f, p] = uigetfile(filterspec);
            
            % Make sure user didn't cancel uigetfile dialog
            if (ischar(p))
                fname = [p f];
                updateimage(app,app.UIAxes, fname);
            end
        end

        % Button pushed function: SelectImageButton_2
        function SelectImageButton_2Pushed(app, event)
            % Display uigetfile dialog
            filterspec = {'*.jpg;*.jpeg;*.tif;*.png;*.gif','All Image Files'};
            [f, p] = uigetfile(filterspec);
            
            % Make sure user didn't cancel uigetfile dialog
            if (ischar(p))
                fname = [p f];
                updateimage(app,app.UIAxes2, fname);
            end
        end

        % Button pushed function: CompareButton
        function CompareButtonPushed(app, event)
            filters(app,app.im_area_1,13,5,2,app.lefttop);
            filters(app,app.im_area_2,13,5,2,app.rightup);
            edgedetect(app,app.im_area_1,app.leftdown);
            edgedetect(app,app.im_area_2,app.rightdown);
            features(app,app.im_area_2,30,app.center_up,app.center_down);
            
            selected_process(app,app.im_area_2,app.UIAxes3);
            app.label.Text="Done";
            app.saved=0;
            app.SaveButton.Enable=1;
        end

        % Button pushed function: SaveButton
        function SaveButtonPushed(app, event)
            if app.saved==0
                app.save_cnt=app.save_cnt+1;
                save_tag="comparison result "+app.save_cnt+".jpg";
                exportgraphics(app.UIAxes3,save_tag)
                app.SaveButton.Enable=0;
                app.SaveButton.Text="Saved";
            end
                
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 640 480];
            app.UIFigure.Name = 'MATLAB App';
            app.UIFigure.WindowState = 'maximized';

            % Create GridLayout
            app.GridLayout = uigridlayout(app.UIFigure);
            app.GridLayout.ColumnWidth = {'1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x'};
            app.GridLayout.RowHeight = {'1x', '1x', '1x', '0.6x', '0.6x', '1x', '1x', '1x'};

            % Create SelectImageButton
            app.SelectImageButton = uibutton(app.GridLayout, 'push');
            app.SelectImageButton.ButtonPushedFcn = createCallbackFcn(app, @SelectImageButtonPushed, true);
            app.SelectImageButton.Layout.Row = 4;
            app.SelectImageButton.Layout.Column = [2 3];
            app.SelectImageButton.Text = 'Select Image';

            % Create SelectImageButton_2
            app.SelectImageButton_2 = uibutton(app.GridLayout, 'push');
            app.SelectImageButton_2.ButtonPushedFcn = createCallbackFcn(app, @SelectImageButton_2Pushed, true);
            app.SelectImageButton_2.Layout.Row = 4;
            app.SelectImageButton_2.Layout.Column = [6 7];
            app.SelectImageButton_2.Text = 'Select Image';

            % Create CompareButton
            app.CompareButton = uibutton(app.GridLayout, 'push');
            app.CompareButton.ButtonPushedFcn = createCallbackFcn(app, @CompareButtonPushed, true);
            app.CompareButton.Layout.Row = 4;
            app.CompareButton.Layout.Column = [4 5];
            app.CompareButton.Text = 'Compare';

            % Create label
            app.label = uilabel(app.GridLayout);
            app.label.HorizontalAlignment = 'center';
            app.label.Layout.Row = 5;
            app.label.Layout.Column = [2 7];
            app.label.Text = 'Please Select a Clean Area for the left and a Dirty Area for the right.';

            % Create SaveButton
            app.SaveButton = uibutton(app.GridLayout, 'push');
            app.SaveButton.ButtonPushedFcn = createCallbackFcn(app, @SaveButtonPushed, true);
            app.SaveButton.Layout.Row = 8;
            app.SaveButton.Layout.Column = 8;
            app.SaveButton.Text = 'Save';

            % Create UIAxes
            app.UIAxes = uiaxes(app.GridLayout);
            title(app.UIAxes, 'Clean')
            xlabel(app.UIAxes, 'X')
            ylabel(app.UIAxes, 'Y')
            zlabel(app.UIAxes, 'Z')
            app.UIAxes.Layout.Row = [1 3];
            app.UIAxes.Layout.Column = [1 4];

            % Create UIAxes2
            app.UIAxes2 = uiaxes(app.GridLayout);
            title(app.UIAxes2, 'Dirty')
            xlabel(app.UIAxes2, 'X')
            ylabel(app.UIAxes2, 'Y')
            zlabel(app.UIAxes2, 'Z')
            app.UIAxes2.Layout.Row = [1 3];
            app.UIAxes2.Layout.Column = [5 8];

            % Create UIAxes3
            app.UIAxes3 = uiaxes(app.GridLayout);
            title(app.UIAxes3, 'Comparison Result')
            xlabel(app.UIAxes3, {''; ''})
            app.UIAxes3.Layout.Row = [6 8];
            app.UIAxes3.Layout.Column = [2 7];

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = app1_exported

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

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