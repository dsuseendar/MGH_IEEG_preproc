%% BML LangLoc Pre-processing
%  Kumar Duraivel Spring 2024

%% NOTES ON PROCESSING THIS PATIENT
clear all
close all

%% DEFINE VARIABLES
DATAPATH = '/Volumes/disk/nese/LangLoc/data';
SUBJECT='sub-EM1126';
SESSION = 'LangLocAudio';
MODALITY='audio';

%% LOAD NEW UTILITIES FOLDER
% Specify the folder containing Utilities
langloc_utils_folder = fullfile(pwd, 'langloc_utils');
utils_folder = fullfile("../utils");
% Add the folder and all subfolders to the MATLAB path
addpath(genpath(langloc_utils_folder));
addpath(genpath(utils_folder));

%% DEFINE DATA PATHS
PATH_DATA = [DATAPATH filesep 'raw_data' filesep SUBJECT filesep];
PATH_SESSION = [PATH_DATA filesep 'ses-' SESSION];
PATH_EDF = [PATH_SESSION filesep 'natus' ];
PATH_EVENTS = [PATH_SESSION filesep 'tasks' ];
PATH_DER = [DATAPATH filesep 'derivatives'];
PATH_ANNOT = [PATH_DER filesep SUBJECT '/annot/'];
PATH_SAVE = [PATH_DER filesep SUBJECT '/preproc/'];

if ~exist(PATH_ANNOT,'dir'), mkdir(PATH_ANNOT); end
if ~exist(PATH_SAVE,'dir'), mkdir(PATH_SAVE); end

%% LOAD NEURAL DATA
% addpath('/Users/ashleywalton/Dropbox/1_BraindModulationLab/0_MIT/EMU_Preprocessing/EMU_LangLoc_Preprocessing_aw/langloc_utils/edfread.m');
% edf_file=[SUBJECT,'_LangLocAudio_d02.EDF'];
edflist = dir([PATH_EDF filesep '*.EDF']);
edfname = edflist(2).name;

[hdr,record]=edfread([PATH_EDF filesep edfname]);
info = edfinfo([PATH_EDF filesep edfname]);
sampling_frequency = hdr.frequency;
%% READ IN OR CREATE CHANNELS FILE

channels_table = create_channels_table_bids(info, PATH_ANNOT, SUBJECT, SESSION);

%% LOAD AND PLOT TRIGGERS
% Get triggers from edf file
chan_insp={'TRIG'};
DC_files=cell2mat(cellfun(@(x) find(strcmp(hdr.label,x)), chan_insp,'uni',false));
TrigMat1=record(DC_files,:)';%record is the edf file contents
% Here TrigMat1 is single column, transformation from binary state
% into a 16-column data structure is performed as part of the plot_trigger
% function

% Plot triggers
% TrigMat has 16 columns, only using the first 7
% Row 1 and 3 of graph indicate beginning of blocks where start_expt_bit=bit1;end_expt_bit=bit2;
% Row 2 is start of audio where start_aud_bit=bit3;
% Row 4 indiciates condition, not sure which is 0 or 1; cond_bit=bit4;
% Row 5 is end of audio where end_aud_bit=bit5;
% Row 6 is the probe, which happens after every 12 words where probe_bit=bit6;
% Row 7 is fixation - don't know what this means? fixation_bit=bit7;
%TrigMatplot=plot_trigger(TrigMat1);
% The plot_trigger function modifies TrigMat1 to represent each element's binary state
% across 16 channels, visualizes each channel in separate subplots,
% and ultimately affects TrigMat1 by transforming its data from numerical
% trigger states into a binary format with adjusted bit order
filteredEventTimes = processAndPlotTriggerEventsLangLocAudio(TrigMat1);
% The processAndPlotTriggerEvents function processes TrigMat1 to represent each element's binary state
% across 16 channels, visualizes each channel in separate colors. It
% identifies all the trials between start and end runs, and has modules to
% discard noisy trials that occur at same time. 
% and ultimately affects TrigMat1 by transforming its data from numerical
% trigger states into a binary format with adjusted bit order. The code is
% automated, it doesnt' require any prefix or exclusion period
% Open filteredEventTimes; It should contain multiples of 40
% trialTimingOnset = filteredEventTimes{1};
% % The filteredEventTimes is of the same order as TrigMat. All we need is
% % filteredEventTimes{2}
% 
% assert(length(trialTimingOnset)==120,'Failed trigger condition; Try the less automated approach');






%% GET BEHAVIORAL DATA
d_events=dir(strcat(PATH_EVENTS,'/*.csv'));
if(isempty(d_events))
    PATH_EVENTS = [PATH_SESSION filesep 'task' ];
    d_events=dir(strcat(PATH_EVENTS,'/*.csv'));
end
%This was manually excluding events files for runs that were not completed
task_files_to_pick=[2:4];
d_events=d_events(task_files_to_pick);


[events_table] = extract_behavioral_events_for_langloc_audio('behavior_files',d_events,'sampling',unique(sampling_frequency));
% check if there are the correct number of trials (120)
assert(size(events_table,1)==120);



%% Checking Behavior recordings with Natus recordings
% Define the time window to save, including a 30-second buffer before and after the events
time2save = filteredEventTimes{3}(1)-15*sampling_frequency:filteredEventTimes{3}(end)+15*sampling_frequency;

% Set the start time for normalization
timeStart = time2save(1);

% Calculate the audio start times from the Natus system, normalized to timeStart
natusAudioStart = (filteredEventTimes{3}-timeStart)./sampling_frequency(1);

% Calculate the audio end times from the Natus system, normalized to timeStart
natusAudioEnd = (filteredEventTimes{5}-timeStart)./sampling_frequency(1);

% Calculate the probe onset times from the Natus system, normalized to timeStart
natusTimingProbe = (filteredEventTimes{6}-timeStart)./sampling_frequency(1);

% Calculate the probe end times from the Natus system, normalized to timeStart
natusEndProbe = (filteredEventTimes{14}-timeStart)./sampling_frequency(1);

% Extract the trial onset times from the behavioral data
behTimingOnset = events_table.trial_onset;

% Extract the audio end times from the behavioral data
behTimingOffset = events_table.audio_ended;

% Calculate the audio duration based on Natus timing
audioDurNatus = natusAudioEnd-natusAudioStart;

% Calculate the audio duration based on behavioral timing
audioDurBeh = behTimingOffset-behTimingOnset;

% Create a scatter plot to compare Natus and behavioral audio durations
figure; scatter(audioDurNatus,audioDurBeh,20,'black','filled');

% Create a histogram of the differences between Natus and behavioral audio durations
figure; histogram(audioDurNatus-audioDurBeh,50);
xlabel('Discrepancy in time (s)')
ylabel('Trials');

% Add Natus-based timing information to the events table, adjusting for
% known fixation
events_table.trial_onset_natus = natusAudioStart - 0.2;  % Subtract 200ms to code for fixation
events_table.audio_onset_natus = natusAudioStart;
events_table.audio_ended_natus = natusAudioEnd;
events_table.probe_onset_natus = natusTimingProbe;
events_table.trial_ended_natus = natusEndProbe+0.2;  % Add 200ms to code for fixation


%time2save = trialTimingOnset(1)-15*sampling_frequency:trialTimingOnset(end)+15*sampling_frequency;

%% FOR AUDIO LANGLOC, ALIGN AUDIO WITH WAVELET
with_wavelet=false;
% save data as an object for ease of further processing

audio_align_path='./audio_alignment/stimuli_alignment_handfix';
% This needs to be properly defined from within the
% trial_timing_from_json_files... function (how to make this globally
% available?
audio_path='./audio_alignment/stimuli';
trial_timing=get_timing_from_json_files_LangLocAudio_Optim(events_table,audio_align_path,with_wavelet,sampling_frequency(1));




%% WRITING ECOG DATA STRUCTURE
% Assign the subject identifier
subject = SUBJECT;
% Assign the experiment name
experiment = SESSION;
% Set the processing order
order = 'defaultSEEGorBOTHBroadBand';
% Create the filename for saving the processed data
save_filename = [ subject '_' experiment '_crunched_' order '.mat'];
% Set the path for saving the processed data
save_path = [PATH_SAVE filesep 'crunched' filesep];
% Get the current date and time
currentDateTime = datetime('now');
% Format the date and time for the log filename
formattedDateTime = datestr(currentDateTime, 'yyyymmdd_HHMM');
% Create the full log filename
log_filename = [PATH_SAVE filesep 'logs' filesep subject '_' experiment '_' order '_' formattedDateTime '.txt'];
% Set the path to the EDF file
d_files = [PATH_EDF filesep edfname];
% Get the channel labels from the channels table
ch_labels = channels_table.name;
% Create a vector of channel numbers
ch_nums = 1:length(ch_labels);
% Convert channel types to strings
ch_type = string(channels_table.type);
% Find indices of non-SEEG channels
ch_deselect = find(~contains(ch_type,'seeg'));
% Find indices of SEEG channels
ch_select = find(contains(ch_type,'seeg'));

% Create a structure to hold preprocessing data
for_preproc = struct;
% Store the raw electrode data for selected channels
for_preproc.elec_data_raw = single(record(ch_select,time2save));
% Store the events table
for_preproc.event_table = events_table;
% Set the stitch index (used for combining multiple files)
for_preproc.stitch_index_raw = 1;
% Store the original sampling frequency
for_preproc.sample_freq_raw = sampling_frequency(1);
% Store the log filename
for_preproc.log_file_name = log_filename;
% Set the decimation frequency (for downsampling)
for_preproc.decimation_freq = sampling_frequency(1)/4;

% Create an ecog_data object with the preprocessing data and metadata
obj = ecog_data(for_preproc,subject,experiment,save_filename,save_path,d_files,...
    PATH_EDF,ch_labels(ch_select),1:length(ch_select),[],ch_type(ch_select));
% Preprocess the signal
obj.preprocess_signal('order',order,'isPlotVisible',false,'doneVisualInspection',false);
% Store the events table in the object
obj.events_table = obj.for_preproc.event_table;
% Convert condition labels from 'S' and 'N' to 'sentence' and 'nonword'
obj.condition = cellfun(@(x) replace(x, {'S', 'N'}, {'sentence', 'nonword'}), obj.for_preproc.event_table.condition, 'UniformOutput', false);

% Store the session information
obj.session = (obj.for_preproc.event_table.list);

% Store the trial timing information
obj.trial_timing = trial_timing(:,1);

% Create the save directory if it doesn't exist
if(~isfolder(save_path))
    mkdir(save_path)
end

% Save the ecog_data object
save([save_path filesep save_filename],'obj','-v7.3');

% % Extract high gamma components using NapLab filter extraction
% obj.extract_high_gamma('doNapLabFilterExtraction', true);
% 
% % Downsample the signal to 100 Hz
% obj.downsample_signal('decimationFreq', 100);
% 
% % Extract significant channels from the signal
% obj.extract_significant_channel();
% 
% % Determine time-based significance of the signal
% obj.extract_time_significance();
% 
% % Calculate metrics for signal normalization
% obj.extract_normalization_metrics();
% 
% % Normalize the signal using z-score method
% obj.normalize_signal("normtype", 'z-score');
% 
% % Generate the experiment report
% generateExperimentReport(obj, [subject '_' experiment]);
