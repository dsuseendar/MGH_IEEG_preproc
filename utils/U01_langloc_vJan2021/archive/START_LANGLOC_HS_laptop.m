% Launcher script for MIT's Language Localizer task - EMU version

%% Setting paths and configuration structure

% Creating configuration structure
% subject and session
cfg.SESSION_LABEL = 'EMU'; % session type
if ~isfield(cfg,'SUBJECT')
  cfg.SUBJECT = ''; %subject identifier
end

% Paths and PTB configuration on task computer
[~, userdir] = system('echo %USERPROFILE%');
userdir = strtrim(userdir);
cfg.PATH_TASK = [userdir 'U01_langloc_vJan2021'];
cfg.PATH_SOURCEDATA = ['output']; %rawdata root folder
cfg.SEND_TRIGGERS = 0;

% % Paths and PTB configuration on test computer
% cfg.PATH_TASK = '~/git/Task_MIT_Fedorenko/U01_langloc_vJan2021';
% cfg.PATH_SOURCEDATA = '~/Sandbox'; %rawdata root folder
% cfg.SEND_TRIGGERS = 0;

%% Task parameters 
cfg.TASK = 'langloc'; % name of current task
cfg.TASK_FUNCTION = 'U01_langloc_vJan2021.m';

%% Warngins
warning('on','all'); %enabling warnings
beep off

%% Confirmation prompt
prompt = {'Subject','Session','Run (1-3, 0 practice)'};
dlgtitle = sprintf('%s Task',cfg.TASK);
dims = [1 35];
definput = {cfg.SUBJECT,cfg.SESSION_LABEL,''};
answer = inputdlg(prompt,dlgtitle,dims,definput);

if isempty(answer)
  error('Task canceled by user')
else
  cfg.SUBJECT = answer{1,1};
  cfg.SESSION_LABEL = answer{2,1};
	runId = str2double(answer{3,1});
end

%% Constructing and checking paths 
pathSub = [cfg.PATH_SOURCEDATA filesep cfg.SUBJECT];
if ~isfolder(cfg.PATH_SOURCEDATA)
    error('sourcedata folder %s does not exist',cfg.PATH_SOURCEDATA)
end
if ~isfolder(pathSub)
    fprintf('Creating subject folder %s \n',pathSub)
    mkdir(pathSub)
end

%% creating files basename 
fileBaseName = ['sub-' cfg.SUBJECT '_ses-' cfg.SESSION_LABEL '_task-' cfg.TASK '_run-'];
cfg.RUN_ID = runId;
cfg.PATH_LOG = pathSub;
cfg.BASE_NAME = [fileBaseName num2str(cfg.RUN_ID,'%02.f') '_'];
cfg.LOG_FILENAME = [cfg.PATH_LOG filesep cfg.BASE_NAME 'log.txt'];
cfg.EVENT_FILENAME = [cfg.PATH_LOG filesep cfg.BASE_NAME 'events'];

%% Starting diary
%open diary for this run (saves PTB initialization output)
diary(cfg.LOG_FILENAME);
onCleanupTasks = cell(10,1); 
onCleanupTasks{10} = onCleanup(@() diary('off'));
fprintf('\nStarting run at %s \n',datestr(now,'HH:MM:SS am'));
fprintf('\nConfiuration struture:\n');
disp(cfg)

%% Saving task function in log folder for documentation
task_function = [pwd filesep cfg.TASK_FUNCTION];
if ~isfile(task_function)
    error('%s.m should be in current working directory',cfg.TASK_FUNCTION);
end
copyfile(task_function,[cfg.PATH_LOG filesep cfg.BASE_NAME 'script.m']);

%% Launching the task
commandwindow
try
  U01_langloc_vJan2021(cfg);
catch e
	fprintf('The identifier was:\n%s',e.identifier);
	fprintf('There was an error! The message was:\n%s',e.message);
end
%% Cleaning up
clear onCleanupTasks

