function varargout = RivuletExpDataProcessing(varargin)
%
%   function varargout = RivuletExpDataProcessing(varargin)
%
% function for GUI handling of the program for evaluation of
% experimental data obtained by measurements of the rivulet flow on
% inclined plate in TU Bergakademie Freiberg
%
%==========================================================================
% USER GUIDE:
%-preprocessing------------------------------------------------------------
% 1. Choose directory for storing output data (storDir)
% 2. Load background image and images to process
%-finding-edges-of-cuvettes-and-plate--------------------------------------
% 3. Select how much automatic should the finding of edges be
%   Automatic ... program writes out warnings but do not interact with user
%                 !! add control of standard deviation of found sizes of 
%                    the plate -> std(X) > maxTol => force user
%                    interaction !!
%   Semi-autom... if there should be warning output, asks for user
%                 interaction
%   Manual    ... asks for manual specification of edges for each plate
% 4. Optional - change default parameters for hough transform
%   Hough transform is used for finding the edges of the plate. The
%   parameters were optimized for minimial standard deviation of found
%   plate sizes on images from DC 5 measurements
% 5. Optional - set graphical output from the program execution
%   At the time, the images will be only shown as control of how
%   succesfully were found the edges)
% 6. Find edges of the plate and cuvettes (executes function findEdges with
%    collected parameters)
%-rivulet-data-processing--------------------------------------------------
% 7. Set the value of treshold to distinguish between rivulet and the rest
%   of the plate and FilterSensitivity for getting rid of the noises in
%   images.
% 8. Choose on which liquid was experiment conducted
%   This liquid has to be in database. To add it, edit file fluidDataFcn.
%   In this point are loaded liquid data from file fluidDataFcn
% 9. Optional - change optional parameters for the program execution
%   Plate Size... this shoud not be changed unless there has been major
%                 modification of experimental set up
%   Num. of Cuts. number of meaned profiles that user want get from program
%                 execution. default value is 5 which displays cut every 50
%                 mm of the plate (5/10/15/20/15 cm)
%   Parameters for conversion of grayscale values into distances
%             ... thicknesses of the film in calibration cuvettes
%             ... degree of polynomial to use in cuvette regression
%             ... width of cuvette in pixels (default 80)
%   !! If you want to change 1 of the parametres for conversion of
%   greyscale values into distances, you MUST fill out all the fields !!
%10. Optional - set which graphs should be plotted and how there should be
%    saved
%11. Calculate results (this calls function rivuletProcessing with
%   specified parameters)
%-postprocessing-----------------------------------------------------------
%12. Set defaults - sets default variable values for rivulet data
%   processing
%13. Save vars to base (calls function save_to_base)
%   Outputs all variables to base workspace (accessible from command
%   window). All user defined variables are in handles.metricdata and user
%   defined program controls (mainly graphics) are in handles.prgmcontrol
%   !! restructurilize handles.metricdata and handles.prgmcontrol with
%   better distinction between controls and data variables !!
%14. Clear vars clears all the user specified variables and reinitialize
%   GUI
%==========================================================================
% DEMANDS OF THE PROGRAM
% -Program was written in MATLAB R2010a, but shoud be variable with all
% MATLAB versions later than R2009a (implementation of ~ character)
% -Until now (17.07.2012) program was tested only on images from DC10
% measurements
% -For succesfull program execution there has to be following files in the
% root folder of the program:
% 1. RivuletExpDataProcessing.m/.fig (main program files)
% 2. findEdges.m (function for automatic edge finding in images)
% 3. rivuletProcessing.m (main function for data evaluation)
% 4. save_to_base.m (function for saving data into base workspace)
% 5. fluidDataFcn.m (database with fluid data)
%
% Author:       Martin Isoz
% Organisation: ICT Prague / TU Bergakademie Freiberg
% Date:         17. 07. 2012
%
% See also: FINDEDGES FLUIDDATAFCN RIVULETPROCESSING SAVE_TO_BASE

% Edit the above text to modify the response to help
% RivuletExpDataProcessing

% Last Modified by GUIDE v2.5 31-Jul-2012 16:22:50

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @progGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @progGUI_OutputFcn, ...
                   'gui_LayoutFcn',  [], ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before progGUI is made visible.
function progGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to progGUI (see VARARGIN)

% fill gui with defaults values
[handles.metricdata handles.prgmcontrol] =...
    initializeGUI(hObject, eventdata, handles);

% Choose default command line output for progGUI
handles.output = hObject;
set(hObject,'CloseRequestFcn',@my_closereq)

% Update handles structure
guidata(hObject, handles);


% My own closereq fcn -> to avoid closing with close command
function my_closereq(src,evnt)
% User-defined close request function 
% to display a question dialog box 
   selection = questdlg('Close Rivulet data processing program?',...
      'Close Request Function',...
      'Yes','No','Yes'); 
   switch selection, 
      case 'Yes',
         delete(gcf)
      case 'No'
      return 
   end

% UIWAIT makes progGUI wait for user response (see UIRESUME)
% uiwait(handles.MainWindow);


% --- Outputs from this function are returned to the command line.
function varargout = progGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

%% PushButtons - Preprocessing

% --- Executes on button press in PushChooseDir.
function storDir = PushChooseDir_Callback(hObject, eventdata, handles)
% hObject    handle to PushChooseDir (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% choosing directory to store outputs
start_path = '~/Documents/Freiberg/EvalExp';                                %start path for choosing directory (only for my machine)
storDir = uigetdir(start_path,'Select folder to store outputs');            %let user choose directory to store outputs

if storDir ~= 0                                                             %here i dont care about indent, its just basic input control
% create subdirectories
mkdir(storDir,'Subtracted');                                                %directory for subtracted images
mkdir(storDir,'Subtracted/Smoothed');                                       %smoothed images -> appears not to be *.tiff ?!
mkdir(storDir,'Height');                                                    %height of the rivulet
mkdir(storDir,'Profile');                                                   %vertical profiles of the rivulet
mkdir(storDir,'Speed');                                                     %mean velocity
mkdir(storDir,'Width');                                                     %width of the rivulet
mkdir(storDir,'Correlation');                                               %directory for saving data necessary for correlations
mkdir(storDir,'Plots');                                                     %directory for saving plots

%modify string to display in statusbar
statusStr = ['Data storage directory ' storDir...
    ' loaded. Subdirectories are ready.'];
% set gui visible output
if numel(storDir) <= 45
    str   = storDir;
else
    str   = ['...' storDir(end-45:end)];
end
set(handles.EditStorDir,'String',str);                                      %display only 45 last characters or the whole string;

% saving outputs
handles.metricdata.storDir = storDir;
handles.metricdata.subsImDir = [storDir '/Subtracted'];                     %directory with subtracted images
handles.statusbar = statusbar(handles.MainWindow,statusStr);
else
%modify string to display in statusbar
statusStr = 'Choosing of data storage directory cancelled.'; 
handles.statusbar = statusbar(handles.MainWindow,statusStr);
end

% Update handles structure
guidata(handles.MainWindow, handles);

% --- Executes on button press in PushLoadBg.
function PushLoadBg_Callback(hObject, eventdata, handles)
% hObject    handle to PushLoadBg (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% predefined input for uigetfile
FilterSpec  = '*.tif';
DlgTitle1   = 'Select background image';
start_path  = '~/Documents/Freiberg/Experiments/';
% choose background image
msgbox('Choose background image','modal');uiwait(gcf);
[bgName bgDir] = uigetfile(FilterSpec,DlgTitle1,start_path);
if bgDir ~= 0                                                               %basic input control
bgImage        = imread([bgDir '/' bgName]);

% updating statusbar
statusStr = ['Background image ' bgDir bgName...
    ' was succesfuly loaded.'];
handles.statusbar = statusbar(handles.MainWindow,statusStr);
% set gui visible output
if numel(bgDir) <= 45
    str   = bgDir;
else
    str   = ['...' bgDir(end-45:end)];
end
set(handles.EditBcgLoc,'String',str);                                       %display only 45 last characters or the whole string;

% save variable into handle
handles.metricdata.bgImage = bgImage;
else
%modify string to display in statusbar
statusStr = 'Choosing of Background image cancelled.'; 
handles.statusbar = statusbar(handles.MainWindow,statusStr);
end
% Update handles structure
guidata(handles.MainWindow, handles);


% --- Executes on button press in PushLoadIM.
function daten = PushLoadIM_Callback(hObject, eventdata, handles)
% hObject    handle to PushLoadIM (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% imNames   ... cell of strings, selected filenames
% imDir     ... string, path to the directory with images

% check if the directory for storing outputs is chosen
if isfield(handles.metricdata,'storDir') == 0                               %if not, force user to choose it
    msgbox('You must choose storDir before loading images','modal');
    uiwait(gcf);
    storDir = PushChooseDir_Callback(hObject, eventdata, handles);
    % set gui visible output
    if numel(storDir) <= 45
        str   = storDir;
    else
        str   = ['...' storDir(end-45:end)];
    end
    set(handles.EditStorDir,'String',str);                                  %display only 45 last characters or the whole string;
else
    storDir = handles.metricdata.storDir;
end

% clear images, if they are present
if isfield(handles.metricdata,'daten');
    handles.metricdata = rmfield(handles.metricdata,{'daten' 'imNames'});
end

% auxiliary variebles for dialogs
FilterSpec  = '*.tif';
DlgTitle1   = 'Select background image';
DlgTitle2   = 'Select images to be processed';
start_path  = '~/Documents/Freiberg/Experiments/';
selectmode  = 'on';

% load background image
if isfield(handles.metricdata,'bgImage') == 0                               %check if bgImage is already loaded, if not, choose it
    msgbox('Choose background image','modal');uiwait(gcf);
    [bgName bgDir] = uigetfile(FilterSpec,DlgTitle1,start_path);
    bgImage        = imread([bgDir '/' bgName]);
    % set gui visible output
    if numel(bgDir) <= 45
        str   = storDir;
    else
        str   = ['...' bgDir(end-45:end)];
    end
    set(handles.EditBcgLoc,'String',str);                                   %display only 45 last characters or the whole string;
else
    bgImage        = handles.metricdata.bgImage;
end
% load images
msgbox({'Background is loaded,'...
    'chose images to be processed'},'modal');uiwait(gcf)
[imNames  imDir]...                                                         %get names and path to the images that I want to load
            = uigetfile(FilterSpec,DlgTitle2,'Multiselect',selectmode,...
            start_path);
if imDir ~= 0                                                               %basic input control
    subsImDir = [storDir '/Subtracted'];                                    %directory with subtracted images
if isa(imNames,'char') == 1
    imNames = {imNames};                                                    %if only 1 is selected, convert to cell
end
for i = 1:numel(imNames)
    tmpIM = imread([imDir '/' imNames{i}]);                                 %load images from selected directory
    tmpIM = imsubtract(tmpIM,bgImage);                                      %subtract background from image
    imwrite(tmpIM,[subsImDir '/' imNames{i}]);                              %save new images into subfolder
    if handles.prgmcontrol.DNTLoadIM == 0                                   %if i dont want to have stored images in handles.metricdata
        daten{i} = tmpIM;                                                   %if i want the images to be saved into handles
    end
    handles.statusbar = statusbar(handles.MainWindow,...
        'Loading and subtracting background from image %d of %d (%.1f%%)',...%updating statusbar
        i,numel(imNames),100*i/numel(imNames));
    set(handles.statusbar.ProgressBar,...
        'Visible','on', 'Minimum',0, 'Maximum',numel(imNames), 'Value',i);
end

% modify gui visible outputs
set(handles.statusbar.ProgressBar,'Visible','off');                         %made progresbar invisible again
set(handles.statusbar,...                                                   %update statusbar
    'Text','Images were succesfully loaded and substratced');
if numel(imDir) <= 45
    str   = imDir;
else
    str   = ['...' imDir(end-45:end)];
end
set(handles.EditIMLoc,'String',str);                                        %display only 45 last characters or the whole string;

% save variables into handles
if handles.prgmcontrol.DNTLoadIM == 0
    handles.metricdata.daten   = daten;                                     %save images only if user wants to
end
handles.metricdata.imNames = imNames;                                       %names of the images (~ var. "files" in R..._A...MOD)
handles.metricdata.bgImage = bgImage;                                       %background image (dont want to load it repetedly)
handles.metricdata.storDir = storDir;                                       %need to resave also the location for storing outputs
handles.metricdata.subsImDir   = subsImDir;                                 %location with subtracted images (for later image loading)
% save information about succesfull ending of the function
handles.prgmcontrol.loadIM = 0;                                             %0 ... OK, 1 ... warnings, 2 ... errors (for now without use)
else
%modify string to display in statusbar
statusStr = 'Loading images cancelled.'; 
handles.statusbar = statusbar(handles.MainWindow,statusStr);
end
% Update handles structure
guidata(handles.MainWindow, handles);


% --- Executes on button press in PushClearIM.
function PushClearIM_Callback(hObject, eventdata, handles)
% hObject    handle to PushClearIM (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if isfield(handles.metricdata,'bgImage') == 1                               %field metricdata.bgImage exists
    handles.metricdata = rmfield(handles.metricdata,'bgImage');
    if isfield(handles.metricdata,'daten') == 1
        handles.metricdata = rmfield(handles.metricdata,'daten');           %remove data saved into handles
    end
    if isfield(handles.metricdata,'imNames') == 1
        handles.metricdata = rmfield(handles.metricdata,'imNames');         %remove names of the loaded images
    end
    % Update handles structure
    guidata(handles.MainWindow, handles);
    set(handles.statusbar,'Text','Images were cleared');                    %notify user
    % restart the fields with texts
    set(handles.EditBcgLoc,'String','No background is loaded.');
    set(handles.EditIMLoc,'String','No images are loaded.');
else
    msgbox('No images were loaded','modal');uiwait(gcf);
end
% Update handles structure
guidata(handles.MainWindow, handles);

%% Editable fields - Preprocessing


function EditStorDir_Callback(hObject, eventdata, handles)
% hObject    handle to EditStorDir (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of EditStorDir as text
%        str2double(get(hObject,'String')) returns contents of EditStorDir as a double

handles.metricdata.storDir = str2double(get(hObject,'String'));             %get value from editable textfield
% Update handles structure
guidata(handles.MainWindow, handles);


% --- Executes during object creation, after setting all properties.
function EditStorDir_CreateFcn(hObject, eventdata, handles)
% hObject    handle to EditStorDir (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function EditBcgLoc_Callback(hObject, eventdata, handles)
% hObject    handle to EditBcgLoc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of EditBcgLoc as text
%        str2double(get(hObject,'String')) returns contents of EditBcgLoc as a double

%!! this textfield is not editable !!

% Update handles structure
guidata(handles.MainWindow, handles);


% --- Executes during object creation, after setting all properties.
function EditBcgLoc_CreateFcn(hObject, eventdata, handles)
% hObject    handle to EditBcgLoc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function EditIMLoc_Callback(hObject, eventdata, handles)
% hObject    handle to EditIMLoc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of EditIMLoc as text
%        str2double(get(hObject,'String')) returns contents of EditIMLoc as a double

%!! this textfield is not editable !!


% --- Executes during object creation, after setting all properties.
function EditIMLoc_CreateFcn(hObject, eventdata, handles)
% hObject    handle to EditIMLoc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%% Checkboxes - Preprocessing

% --- Executes on button press in CheckDNL.
function CheckDNL_Callback(hObject, eventdata, handles)
% hObject    handle to CheckDNL (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of CheckDNL

handles.prgmcontrol.DNTLoadIM = get(hObject,'Value');                          %get the checkbox value

% Update handles structure
guidata(handles.MainWindow, handles);


%% Pushbuttons - Image Processing


% --- Executes on button press in PushFindEdg.
function [EdgCoord daten] =...
    PushFindEdg_Callback(hObject, eventdata, handles)
% hObject    handle to PushFindEdg (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% check if there all required data are present
stmt1 = isfield(handles.metricdata,'imNames');                              %are there loaded images?
if stmt1 == 0                                                               %if not, force user to load them
    msgbox('First, you must load images','modal');uiwait(gcf);
    return
end

% call function findEdges and save output into handles
handles.metricdata.EdgCoord = findEdges(handles);

% call control function
[state,prbMsg,sumMsg] = controlFunction(handles.metricdata.EdgCoord);

% save output parameters into handles
handles.metricdata.state = state;
handles.metricdata.prbMsg= prbMsg;
handles.metricdata.sumMsg= sumMsg;

% modify potential mistakes
handles.metricdata.EdgCoord = modifyFunction(handles.metricdata);           %call modifyFunction with handles.metricdata input
set(handles.statusbar,'Text','EdgCoord is prepared for rivulet processing');%update statusbar

% Update handles structure
guidata(handles.MainWindow, handles);


% --- Executes on button press in PushClearEdg.
function PushClearEdg_Callback(hObject, eventdata, handles)
% hObject    handle to PushClearEdg (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.metricdata = rmfield(handles.metricdata,'EdgCoord');

msgbox('Edges coordinates were cleared','modal');uiwait(gcf);

% Update handles structure
guidata(handles.MainWindow, handles);


% --- Executes on button press in PushDefEdg.
function PushDefEdg_Callback(hObject, eventdata, handles)
% hObject    handle to PushDefEdg (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% set default values for fields in Image Processing
handles.prgmcontrol.autoEdges = 2;                                          %default - completely automatic program execution
set(handles.PopupIMProc,'String',...
    {'Automatic' 'Semi-automatic' 'Manual'});
minVal = get(handles.CheckCuvettes,'Min');                                  %default - no graphic output
set(handles.CheckCuvettes,'Value',minVal);
minVal = get(handles.CheckPlate,'Min'); 
set(handles.CheckPlate,'Value',minVal);
handles.metricdata.GREdges    = [0 0];                                      %default - dont want any graphics
% default values for hough transform
handles.metricdata.hpTr     = [];                                           %do not need to set up default values - they are present in the prgm
handles.metricdata.numPeaks = [];
handles.metricdata.fG       = [];
handles.metricdata.mL       = [];

% Update handles structure
guidata(handles.MainWindow, handles);

%% Editable fields - Image Processing

function EdithpTr_Callback(hObject, eventdata, handles)
% hObject    handle to EdithpTr (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of EdithpTr as text
%        str2double(get(hObject,'String')) returns contents of EdithpTr as a double

handles.metricdata.hpTr = str2double(get(hObject,'String'));                %get value from editable textfield
% Update handles structure
guidata(handles.MainWindow, handles);


% --- Executes during object creation, after setting all properties.
function EdithpTr_CreateFcn(hObject, eventdata, handles)
% hObject    handle to EdithpTr (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function EditnumPeaks_Callback(hObject, eventdata, handles)
% hObject    handle to EditnumPeaks (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of EditnumPeaks as text
%        str2double(get(hObject,'String')) returns contents of EditnumPeaks as a double

handles.metricdata.numPeaks = str2double(get(hObject,'String'));            %get value from editable textfield
% Update handles structure
guidata(handles.MainWindow, handles);


% --- Executes during object creation, after setting all properties.
function EditnumPeaks_CreateFcn(hObject, eventdata, handles)
% hObject    handle to EditnumPeaks (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function EditfG_Callback(hObject, eventdata, handles)
% hObject    handle to EditfG (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of EditfG as text
%        str2double(get(hObject,'String')) returns contents of EditfG as a double

handles.metricdata.fG = str2double(get(hObject,'String'));                  %get value from editable textfield
% Update handles structure
guidata(handles.MainWindow, handles);


% --- Executes during object creation, after setting all properties.
function EditfG_CreateFcn(hObject, eventdata, handles)
% hObject    handle to EditfG (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function EditmL_Callback(hObject, eventdata, handles)
% hObject    handle to EditmL (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of EditmL as text
%        str2double(get(hObject,'String')) returns contents of EditmL as a double

handles.metricdata.mL = str2double(get(hObject,'String'));                  %get value from editable textfield
% Update handles structure
guidata(handles.MainWindow, handles);


% --- Executes during object creation, after setting all properties.
function EditmL_CreateFcn(hObject, eventdata, handles)
% hObject    handle to EditmL (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%% Checkbuttons - Image Processing

% --- Executes on button press in CheckCuvRegrGR.
function CheckCuvettes_Callback(hObject, eventdata, handles)
% hObject    handle to CheckCuvRegrGR (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of CheckCuvRegrGR

handles.metricdata.GREdges(1) = get(hObject,'Value');                       %see if checkbox is checked

% Update handles structure
guidata(handles.MainWindow, handles);



% --- Executes on button press in CheckPlate.
function CheckPlate_Callback(hObject, eventdata, handles)
% hObject    handle to CheckPlate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of CheckPlate

handles.metricdata.GREdges(2) = get(hObject,'Value');                       %see if checkbox is checked

% Update handles structure
guidata(handles.MainWindow, handles);

%% Popupmenu - Image Processing

% --- Executes on selection change in PopupIMProc.
function PopupIMProc_Callback(hObject, eventdata, handles)
% hObject    handle to PopupIMProc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns PopupIMProc contents as cell array
%        contents{get(hObject,'Value')} returns selected item from PopupIMProc

contents = cellstr(get(hObject,'String'));
selected = contents{get(hObject,'Value')};                                  %get selected value from popmenu

% save selected value to handles
switch selected
    case 'Force-automatic'
        handles.prgmcontrol.autoEdges = 3;                                  % 3 ... automatically skiping not specified edges
    case 'Automatic'
        handles.prgmcontrol.autoEdges = 2;                                  % 2 ... completely automatic finding
    case 'Semi-automatic'
        handles.prgmcontrol.autoEdges = 1;                                  % 1 ... ask in case of problem
    case 'Manual'
        handles.prgmcontrol.autoEdges = 0;                                  % 0 ... ask every time
end

% Update handles structure
guidata(handles.MainWindow, handles);


% --- Executes during object creation, after setting all properties.
function PopupIMProc_CreateFcn(hObject, eventdata, handles)
% hObject    handle to PopupIMProc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%% Editable fields - Rivulet processing

function EditTreshold_Callback(hObject, eventdata, handles)
% hObject    handle to EditTreshold (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of EditTreshold as text
%        str2double(get(hObject,'String')) returns contents of EditTreshold as a double

handles.metricdata.Treshold = str2double(get(hObject,'String'));            %treshold for distinguish between the rivulet and resto of the plate

% Update handles structure
guidata(handles.MainWindow, handles);


% --- Executes during object creation, after setting all properties.
function EditTreshold_CreateFcn(hObject, eventdata, handles)
% hObject    handle to EditTreshold (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function EditFSensitivity_Callback(hObject, eventdata, handles)
% hObject    handle to EditFSensitivity (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of EditFSensitivity as text
%        str2double(get(hObject,'String')) returns contents of EditFSensitivity as a double

handles.metricdata.FSensitivity = str2double(get(hObject,'String'));        %filter sensitivity for noise cancelation

% Update handles structure
guidata(handles.MainWindow, handles);


% --- Executes during object creation, after setting all properties.
function EditFSensitivity_CreateFcn(hObject, eventdata, handles)
% hObject    handle to EditFSensitivity (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%% Popup menu - Rivulet processing

% --- Executes on selection change in PopupLiqType.
function PopupLiqType_Callback(hObject, eventdata, handles)
% hObject    handle to PopupLiqType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns PopupLiqType contents as cell array
%        contents{get(hObject,'Value')} returns selected item from PopupLiqType

contents = cellstr(get(hObject,'String'));
selected = contents{get(hObject,'Value')};                                  %get selected value from popmenu

% save selected value to handles
handles.metricdata.fluidData = fluidDataFcn(selected);                      %call database function

% Update handles structure
guidata(handles.MainWindow, handles);


% --- Executes during object creation, after setting all properties.
function PopupLiqType_CreateFcn(hObject, eventdata, handles)
% hObject    handle to PopupLiqType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on selection change in PopupGrFormat.
function PopupGrFormat_Callback(hObject, eventdata, handles)
% hObject    handle to PopupGrFormat (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns PopupGrFormat contents as cell array
%        contents{get(hObject,'Value')} returns selected item from PopupGrFormat

contents = cellstr(get(hObject,'String'));
selected = contents{get(hObject,'Value')};                                  %get selected value from popmenu

handles.prgmcontrol.GR.format = selected;                                   %save selected format for later use

% Update handles structure
guidata(handles.MainWindow, handles);


% --- Executes during object creation, after setting all properties.
function PopupGrFormat_CreateFcn(hObject, eventdata, handles)
% hObject    handle to PopupGrFormat (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


%% Checkboxes - Rivulet processing

% --- Executes on button press in CheckCompProfGR.
function CheckCuvRegrGR_Callback(hObject, eventdata, handles)
% hObject    handle to CheckCuvRegrGR (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of CheckCuvRegrGR

handles.prgmcontrol.GR.regr = get(hObject,'Value');

% Update handles structure
guidata(handles.MainWindow, handles);

% --- Executes on button press in CheckRivTopGR.
function CheckRivTopGR_Callback(hObject, eventdata, handles)
% hObject    handle to CheckRivTopGR (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of CheckRivTopGR

handles.prgmcontrol.GR.contour = get(hObject,'Value');

% Update handles structure
guidata(handles.MainWindow, handles);

% --- Executes on button press in CheckCompProfGR.
function CheckCompProfGR_Callback(hObject, eventdata, handles)
% hObject    handle to CheckCompProfGR (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of CheckCompProfGR

handles.prgmcontrol.GR.profcompl = get(hObject,'Value');

% Update handles structure
guidata(handles.MainWindow, handles);

% --- Executes on button press in CheckMeanCutsGR.
function CheckMeanCutsGR_Callback(hObject, eventdata, handles)
% hObject    handle to CheckMeanCutsGR (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of CheckMeanCutsGR

handles.prgmcontrol.GR.profcut = get(hObject,'Value');

% Update handles structure
guidata(handles.MainWindow, handles);

%% Radiobuttons - Rivulets processing (uibuttongroup)
% --- Executes when selected object is changed in PlotSetts.
function PlotSetts_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in PlotSetts 
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)

switch get(eventdata.NewValue,'Tag') % Get Tag of selected object.
    case 'RadioShowPlots'
        handles.prgmcontrol.GR.regime = 0;                                  %only show plots
    case 'RadioSavePlots'
        handles.prgmcontrol.GR.regime = 1;                                  %only save plots
    case 'RadioShowSavePlots'
        handles.prgmcontrol.GR.regime = 2;                                  %show and save plots
end

% Update handles structure
guidata(handles.MainWindow, handles);


%% Pushbuttons - Rivulet processing

% --- Executes on button press in PushCalculate.
function PushCalculate_Callback(hObject, eventdata, handles)
% hObject    handle to PushCalculate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% check if there all required data are present
% I. are the edges of the plate and cuvettes found
if isfield(handles.metricdata,'EdgCoord') == 0                              %if EdgeCoord is not present, lets find it
        msgbox(['There are no edges of cuvettes'...
            ' and plate specified'],'modal');uiwait(gcf);
else                                                                        %otherwise call the rivuletProcessing function
    handles.metricdata.OUT = rivuletProcessing(handles);
    
    % set GUI
    msgbox('Program succesfully ended','modal');uiwait(gcf);                %inform user about ending
    set(handles.statusbar,'Text',['Program succesfully ended. '...          %update statusbar
        'Data for postprocessing are availible']);
    
    % create list for listboxes
    liststr = cell(1,numel(handles.metricdata.imNames));
    for i = 1:numel(liststr)
        liststr{i} = handles.metricdata.imNames{i}(1:end-4);                %I dont want the .tif extension at the end of imNames
    end
    set(handles.ListProfiles,'String',liststr);                             %for each image, there is now availible profile
    
end

% Update handles structure
guidata(handles.MainWindow, handles);



% --- Executes on button press in PushSetDefRiv.
function PushSetDefRiv_Callback(hObject, eventdata, handles)
% hObject    handle to PushSetDefRiv (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% set defaults values for fields in rivutel processing
% program controls
handles.prgmcontrol.GR.regr     = 0;                                        %no graphics at all
handles.prgmcontrol.GR.contour  = 0;
handles.prgmcontrol.GR.profcompl= 0;
handles.prgmcontrol.GR.profcut  = 0;
handles.prgmcontrol.GR.regime   = 1;                                        %want only to save images
handles.prgmcontrol.GR.format   = 'png';                                    %default format for graphics saving
set(handles.PopupLiqType,'Value',1);                                        %select 1 choice
%
minVal = get(handles.CheckCuvRegrGR,'Min');                                 %uncheck checkboxes
set(handles.CheckCuvRegrGR,'Value',minVal);
minVal = get(handles.CheckRivTopGR,'Min');                                  %uncheck checkboxes
set(handles.CheckRivTopGR,'Value',minVal);
minVal = get(handles.CheckCompProfGR,'Min');                                %uncheck checkboxes
set(handles.CheckCompProfGR,'Value',minVal);
minVal = get(handles.CheckMeanCutsGR,'Min');                                %uncheck checkboxes
set(handles.CheckMeanCutsGR,'Value',minVal);
% set default values for mandaroty variables
handles.metricdata.Treshold     = 0.1;                                      %set value
set(handles.EditTreshold, 'String', handles.metricdata.Treshold);           %fill in the field
handles.metricdata.FSensitivity = 10;
set(handles.EditFSensitivity, 'String', handles.metricdata.FSensitivity);
% default rivulet processing parameters
handles.metricdata.RivProcPars = [];
% popup menu
handles.metricdata.fluidData = fluidDataFcn('???');                         %set vaules into handles
set(handles.PopupLiqType,'Value',1);                                        %select 2 choice

handles.statusbar = statusbar(handles.MainWindow,...
        'Default rivulet processing parameters were set');

% Update handles structure
guidata(handles.MainWindow, handles);


% --- Executes on button press in PushSaveToBase.
function PushSaveToBase_Callback(hObject, eventdata, handles)
% hObject    handle to PushSaveToBase (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

save_to_base(1)                                                             %save all variables to base workspace

handles.statusbar = statusbar(handles.MainWindow,...
        'All variables were saved into base workspace');


% --- Executes on button press in PushClearALL.
function PushClearALL_Callback(hObject, eventdata, handles)
% hObject    handle to PushClearALL (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles = rmfield(handles,'metricdata');                                    %remove all user-defined data
handles = rmfield(handles,'prgmcontrol');

[handles.metricdata handles.prgmcontrol] =...                               %reinitialize GUI
    initializeGUI(hObject, eventdata, handles);

handles.statusbar = statusbar(handles.MainWindow,...
    ['All user defined variables were cleared.'...
    ' Start by loading images again']);

% Update handles structure
guidata(handles.MainWindow, handles);


% --- Executes on button press in PushClosePlots.
function PushClosePlots_Callback(hObject, eventdata, handles)
% hObject    handle to PushClosePlots (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

set(handles.MainWindow,'HandleVisibility','off');                              %dont want to close the main program
close all                                                                   %close every other figure
set(handles.MainWindow,'HandleVisibility','on');

%% Pushbuttons - Outputs overview

% --- Executes on button press in PushShowProfiles.
function PushShowProfiles_Callback(hObject, eventdata, handles)
% hObject    handle to PushShowProfiles (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if isfield(handles.prgmcontrol,'showProf') == 0
    msgbox('You must choose the profiles to be shown','modal');
    uiwait(gcf);
else
    showProf = handles.prgmcontrol.showProf;
    colNames = cell(1,numel(handles.metricdata.OUT.Profiles{1}(1,:)));      %preallocate varieble for column names
    for i = 1:numel(colNames)/2
        colNames{2*i-1} = ['Cut ' mat2str(i) '|X'];
        colNames{2*i}   = ['Cut ' mat2str(i) '|Y'];
    end
    for i = 1:numel(showProf)
        hFig = figure;                                                      %open figure window
        set(hFig,'Units','Pixels','Position',[0 0 1000 750],...
            'Name',['Mean profiles' mat2str(showProf)]);
        uitable(hFig,'Data',handles.metricdata.OUT.Profiles{showProf(i)},...
            'ColumnName',colNames,...
            'ColumnWidth','auto', ...
            'Units','Normal', 'Position',[0 0 1 1]);
    end
end

% --- Executes on button press in PushShowOtherData.
function PushShowOtherData_Callback(hObject, eventdata, handles)
% hObject    handle to PushShowOtherData (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


%% Listboxes - Outputs overview

% --- Executes on selection change in ListProfiles.
function ListProfiles_Callback(hObject, eventdata, handles)
% hObject    handle to ListProfiles (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns ListProfiles contents as cell array
%        contents{get(hObject,'Value')} returns selected item from ListProfiles

handles.prgmcontrol.showProf = get(hObject,'Value');                        %save indexes of selected

% Update handles structure
guidata(handles.MainWindow, handles);



% --- Executes during object creation, after setting all properties.
function ListProfiles_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ListProfiles (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on selection change in ListOtherData.
function ListOtherData_Callback(hObject, eventdata, handles)
% hObject    handle to ListOtherData (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns ListOtherData contents as cell array
%        contents{get(hObject,'Value')} returns selected item from ListOtherData


% --- Executes during object creation, after setting all properties.
function ListOtherData_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ListOtherData (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%% Checkboxes - Outputs overview

% --- Executes on button press in CheckShowDataPlots.
function CheckShowDataPlots_Callback(hObject, eventdata, handles)
% hObject    handle to CheckShowDataPlots (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of CheckShowDataPlots


%% Auxiliary functions
function [metricdata prgmcontrol] = ...
    initializeGUI(hObject,eventdata,handles)
%
% function for gui inicialization, to be executed just before progGui is
% made visible

% set default values for Preprocessing
set(handles.EditStorDir,'String',['No outputs storage directory is'...      %field the edit boxes
    ' selected.']);
set(handles.EditBcgLoc,'String','No background is loaded.');
set(handles.EditIMLoc,'String','No images are loaded.');
maxVal = get(handles.CheckDNL,'Max');                                       %uncheck checkbox
set(handles.CheckDNL,'Value',maxVal);
handles.prgmcontrol.DNTLoadIM = maxVal;                                     %by default, i dont want to store all image data in handles

% set default values for fields in Image Processing
handles.prgmcontrol.autoEdges = 3;                                          %default - completely automatic program execution
minVal = get(handles.CheckCuvettes,'Min');                                  %default - no graphic output
set(handles.CheckCuvettes,'Value',minVal);
minVal = get(handles.CheckPlate,'Min'); 
set(handles.CheckPlate,'Value',minVal);
handles.metricdata.GREdges    = [0 0];                                      %default - dont want any graphics
% default values for image processing
handles.metricdata.IMProcPars = [];                                         %empty field -> use default built-in parameters

% set defaults values for fields in rivutel processing
% program controls
handles.prgmcontrol.GR.regr     = 0;                                        %no graphics at all
handles.prgmcontrol.GR.contour  = 0;
handles.prgmcontrol.GR.profcompl= 0;
handles.prgmcontrol.GR.profcut  = 0;
handles.prgmcontrol.GR.regime   = 1;
handles.prgmcontrol.GR.format   = 'png';                                    %default format for graphics saving
set(handles.PopupLiqType,'Value',1);                                        %select 1 choice
%
%
minVal = get(handles.CheckCuvRegrGR,'Min');                                 %uncheck checkboxes
set(handles.CheckCuvRegrGR,'Value',minVal);
minVal = get(handles.CheckRivTopGR,'Min');                                  %uncheck checkboxes
set(handles.CheckRivTopGR,'Value',minVal);
minVal = get(handles.CheckCompProfGR,'Min');                                %uncheck checkboxes
set(handles.CheckCompProfGR,'Value',minVal);
minVal = get(handles.CheckMeanCutsGR,'Min');                                %uncheck checkboxes
set(handles.CheckMeanCutsGR,'Value',minVal);
minVal = get(handles.RadioShowPlots,'Min');
set(handles.RadioShowPlots,'Value',minVal);
maxVal = get(handles.RadioSavePlots,'Max');
set(handles.RadioSavePlots,'Value',maxVal);
minVal = get(handles.RadioShowSavePlots,'Min');
set(handles.RadioShowSavePlots,'Value',minVal);
% metricdata
% set default values for mandaroty variables
handles.metricdata.Treshold     = 0.1;                                      %set value
set(handles.EditTreshold, 'String', handles.metricdata.Treshold);           %fill in the field
handles.metricdata.FSensitivity = 10;
set(handles.EditFSensitivity, 'String', handles.metricdata.FSensitivity);
% default values for rivulet processing optional parameters
handles.metricdata.RivProcPars = [];
% set data for the liquid
handles.metricdata.fluidData = fluidDataFcn('DC 5');                        %set vaules into handles
set(handles.PopupLiqType,'Value',2);                                        %select 2 choice

% Specify root folder for program execution (must contain all the used
% functions)
handles.metricdata.rootDir = pwd;

metricdata = handles.metricdata;
prgmcontrol= handles.prgmcontrol;
% Update handles structure
guidata(handles.MainWindow, handles);



%% Menus
% --------------------------------------------------------------------
function FileMenu_Callback(hObject, eventdata, handles)
% hObject    handle to FileMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% --------------------------------------------------------------------
function SaveBase_Callback(hObject, eventdata, handles)
% hObject    handle to SaveBase (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
save_to_base(1);                                                            %save all variables into base workspace
set(handles.statusbar,'Text','All variables were saved into base workspace');

% Update handles structure
guidata(handles.MainWindow, handles);


% --------------------------------------------------------------------
function SaveFile_Callback(hObject, eventdata, handles)
% hObject    handle to SaveFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

metricdata = handles.metricdata;
prgmcontrol= handles.prgmcontrol;

strCell = {'metricdata' 'prgmcontrol'};

uisave(strCell,'RivProc_UsrDefVar');

set(handles.statusbar,'Text',...
    'User defined variables were saved into file.');


% --------------------------------------------------------------------
function LoadFile_Callback(hObject, eventdata, handles)
% hObject    handle to LoadFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

uiopen('load');                                                             %open dialog for loading variable
if exist('metricdata','var') == 0 || exist('prgmcontrol','var') == 0
    msgbox(['You can use this option only to load variables saved by'...
        '"save variables into .mat file" option from program menu.'],...
        'modal');uiwait(gcf);
    handles.statusbar = statusbar(handles.MainWindow,...
        'Loading variables from file failed.');
else
    handles.metricdata = metricdata;
    handles.prgmcontrol= prgmcontrol;
    handles.statusbar = statusbar(handles.MainWindow,...
        'Loading variables from file failed.');
end

% Update handles structure
guidata(handles.MainWindow, handles);


% --------------------------------------------------------------------
function findEdgesMenu_Callback(hObject, eventdata, handles)
% hObject    handle to findEdgesMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function SaveEdgCoord_Callback(hObject, eventdata, handles)
% hObject    handle to SaveEdgCoord (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if isfield(handles.metricdata,'EdgCoord') == 1
    EdgCoord = handles.metricdata.EdgCoord;
    uisave('EdgCoord','EdgCoord')
else
    msgbox('You must specify EdgCoord at first','modal');uiwait(gcf);
end

set(handles.statusbar,'Text',...
    'Edges of plate and cuvettes were saved into .mat file');


% --------------------------------------------------------------------
function LoadEdgCoord_Callback(hObject, eventdata, handles)
% hObject    handle to LoadEdgCoord (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

uiopen('load');                                                             %open dialog for loading variable
if exist('EdgCoord','var') == 0
    msgbox(['You can use this option only to load EdgCoord saved by'...
        '"save EdgCoord into .mat file" option from program menu.'],...
        'modal');uiwait(gcf);
    set(handles.statusbar,'Text',...
        'Loading EdgCoord from file failed.');
else
    handles.metricdata.EdgCoord = EdgCoord;
    set(handles.statusbar,'Text',...
        ['User defined variables were loaded from file.'...
        ' EdgCoord is prepared for rivulet processing.']);
end

% Update handles structure
guidata(handles.MainWindow, handles);


% --------------------------------------------------------------------
function ModHough_Callback(hObject, eventdata, handles)
% hObject    handle to ModHough (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.metricdata.IMProcPars = changeIMPars;                               %call gui for changing parameters

% Update handles structure
guidata(handles.MainWindow, handles);


% --------------------------------------------------------------------
function BestMethod_Callback(hObject, eventdata, handles)
% hObject    handle to BestMethod (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% check if there all required data are present
if isfield(handles.metricdata,'imNames') == 0                               %are there loaded images?                                                               %if not, force user to load them
    msgbox('First, you must load images','modal');uiwait(gcf);
    return
end

handles.metricdata.IMProcPars = ...                                         %call method for finding best image processing method
    bestMethod(handles);

% Update handles structure
guidata(handles.MainWindow, handles);


% --------------------------------------------------------------------
function QuitPrgm_Callback(hObject, eventdata, handles)
% hObject    handle to QuitPrgm (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
close(handles.MainWindow);                                                  %call closing function


% --------------------------------------------------------------------
function rivProcMenu_Callback(hObject, eventdata, handles)
% hObject    handle to rivProcMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function ModExpPars_Callback(hObject, eventdata, handles)
% hObject    handle to ModExpPars (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.metricdata.RivProcPars = changeRPPars;                              %call gui for changing parameters

% Update handles structure
guidata(handles.MainWindow, handles);


% --------------------------------------------------------------------
function SaveIMPars_Callback(hObject, eventdata, handles)
% hObject    handle to SaveIMPars (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if isempty(handles.metricdata.IMProcPars) == 0
    IMProcPars = handles.metricdata.IMProcPars;
    uisave('IMProcPars','IMProcPars')
else
    msgbox('You must specify IMProcPars at first','modal');uiwait(gcf);
end

set(handles.statusbar,'Text',...
    'Image processing parameters were saved into .mat file');


% --------------------------------------------------------------------
function LoadIMPars_Callback(hObject, eventdata, handles)
% hObject    handle to LoadIMPars (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

uiopen('load');                                                             %open dialog for loading variable
if exist('IMProcPars','var') == 0
    msgbox(['You can use this option only to load IMProcPars saved by'...
        '"save IMProcPars into .mat file" option from program menu.'],...
        'modal');uiwait(gcf);
    set(handles.statusbar,'Text',...
        'Loading IMProcPars from file failed.');
else
    handles.metricdata.IMProcPars = IMProcPars;
    set(handles.statusbar,'Text',...
        ['User defined variables were loaded from file.'...
        ' IMProcPars is prepared for image processing.']);
end

% Update handles structure
guidata(handles.MainWindow, handles);


% --------------------------------------------------------------------
function SpecAppPlatePos_Callback(hObject, eventdata, handles)
% hObject    handle to SpecAppPlatePos (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% extracting needed values from handles
if isfield(handles.metricdata,'daten') == 1                                 %see if there are images saved into handles
    DNTLoadIM = 0;
else
    DNTLoadIM = 1;
    imNames   = handles.metricdata.imNames;                                 %if not, obtain info for loading
    subsImDir = handles.metricdata.subsImDir;
end

% setting up the statusbar
handles.statusbar = statusbar(handles.MainWindow,...
    'Waiting for user response');

% obtaining approximate coordinates of the plate
options.Interpreter = 'tex';
options.WindowStyle = 'modal';
msgbox({['Please specify approximate position of the'...
    ' plate on processed images']...
    ['Click little bit outside of {\bf upper left} '...
    'and {\bf lower right corner}']},options);uiwait(gcf);
se      = strel('disk',12);                                                 %morphological structuring element
if DNTLoadIM == 1                                                           %if the images are not loaded, i need to get the image from directory
    tmpIM = imread([subsImDir '/' imNames{1}]);                             %load image from directory with substracted images
else
    tmpIM = handles.metricdata.daten{1};                                    %else i can get it from handles
end
tmpIM   = imtophat(tmpIM,se);
tmpIM   = imadjust(tmpIM,stretchlim(tmpIM),[1e-2 0.99]);                    %enhance contrasts
tmpIM   = im2bw(tmpIM,0.16);                                                %conversion to black and white
figure;imshow(tmpIM);                                                       %show image to work with
cutMat  = round(ginput(2));close(gcf);                                      %let the user specify approximate position of the plate
cutLeft = cutMat(1,1);cutRight = cutMat(2,1);
cutTop  = cutMat(1,2);cutBottom= cutMat(2,2);                               %cut out \pm the plate (less sensitive than exact borders)

handles.metricdata.AppPlatePos = ...                                        %save approximate plate position into handles
    [cutLeft cutTop cutRight cutBottom];

set(handles.statusbar,'Text',['Approximate plate edges position was '...
    'saved into handles']);

% Update handles structure
guidata(handles.MainWindow, handles);


% --------------------------------------------------------------------
function PostProcMenu_Callback(hObject, eventdata, handles)
% hObject    handle to PostProcMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function ShowGenPlots_Callback(hObject, eventdata, handles)
% hObject    handle to ShowGenPlots (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

FilterSpec  = {'*.fig';'*.png;*.eps;*.tif'};
DlgTitle   = 'Select figures to load';
if isfield(handles.metricdata,'storDir')                                    %if storDir is selected and subdirectories created
    start_path = [handles.metricdata.storDir '/Plots'];
else
    start_path = pwd;
end
selectmode  = 'on';
% choose background image
[fileNames fileDir] = uigetfile(FilterSpec,DlgTitle,'Multiselect',...
    selectmode,start_path);
if isa(fileNames,'char') == 1
    fileNames = {fileNames};                                                %if only 1 is selected, convert to cell
end
for i = 1:numel(fileNames)                                                  %for all loaded images
    if strcmp(fileNames{1}(end-3:end),'.fig') == 1
        openfig([fileDir '/' fileNames{i}]);
    else
        figure;imshow([fileDir '/' fileNames{i}]);
    end
end
