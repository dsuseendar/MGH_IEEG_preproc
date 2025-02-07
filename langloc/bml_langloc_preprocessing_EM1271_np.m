clear all
% close all
%% BML LangLoc Pre-processing
%  Ashley Walton Spring 2024
% This script is designed for quick pre-processing of language localizer
% data, which will usually be performed locally because connection to the
% server over VPN is too slow. Then it will be copied onto Nexus4

%% NOTES ON PROCESSING THIS PATIENT
% You had issues with the triggers because the bits were switched where
% bit3 is end_exp and bit2 is start_audio (in prevoius task data this was
% switched). You created a new version of the
% extract_timing_for_langloc_audio.m for this purpose
% It is not necessarily true that this will be true moving forward, Alan
% said there are possibly different versions of this task on different
% rigs.
%% DEFINE VARIABLES
DATAPATH = '/Users/dsuseendar/nese/LangLoc/data';
SUBJECT='sub-EM1271';
SESSION = 'LangLocVisual';
MODALITY='visual';

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
PATH_EVENTS = [PATH_SESSION filesep 'task' ];
PATH_DER = [DATAPATH filesep 'derivatives'];
PATH_ANNOT = [PATH_DER SUBJECT '/annot/'];
PATH_SAVE = [PATH_DER SUBJECT '/preproc/'];

if ~exist(PATH_ANNOT,'dir'), mkdir(PATH_ANNOT); end
if ~exist(PATH_SAVE,'dir'), mkdir(PATH_SAVE); end

%% LOAD NEURAL DATA
% addpath('/Users/ashleywalton/Dropbox/1_BraindModulationLab/0_MIT/EMU_Preprocessing/EMU_LangLoc_Preprocessing_aw/langloc_utils/edfread.m');
% edf_file=[SUBJECT,'_LangLocAudio_d02.EDF'];
edflist = dir([PATH_EDF filesep '*.EDF']);
edfname = edflist.name;

[hdr,record]=edfread([PATH_EDF filesep edfname]);
info = edfinfo([PATH_EDF filesep edfname]);
sampling_frequency = hdr.frequency;
%% READ IN OR CREATE CHANNELS FILE
%channels_path = '/Users/ashleywalton/Dropbox/1_BrainModulationLab/0_MIT/EMU_Preprocessing/LangLoc_preprocessing_2024/EM1233/derivatives/annot/sub-EM1233_ses-LangLocAudio_channels.tsv';
%channels = readtable(channels_path, 'FileType', 'text', 'Delimiter', '\t');
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
filteredEventTimes = processAndPlotTriggerEventsLangLocVisual(TrigMat1);
% The processAndPlotTriggerEvents function processes TrigMat1 to represent each element's binary state
% across 16 channels, visualizes each channel in separate colors. It
% identifies all the trials between start and end runs, and has modules to
% discard noisy trials that occur at same time. 
% and ultimately affects TrigMat1 by transforming its data from numerical
% trigger states into a binary format with adjusted bit order. The code is
% automated, it doesnt' require any prefix or exclusion period

trialTimingOnset = filteredEventTimes{1};
% The filteredEventTimes is of the same order as TrigMat. All we need is
% filteredEventTimes{2}

assert(length(trialTimingOnset)==120,'Failed trigger condition; Try the less automated approach');




%% HERE YOU MIGHT USE bml_sync_match_events.m?
% bml_defaults()

%% GET BEHAVIORAL DATA
d_events=dir(strcat(PATH_EVENTS,'/*.csv'));
%This was manually excluding events files for runs that were not completed
%task_files_to_pick=[2:4];
%d_events=d_events(task_files_to_pick);


[events_table] = extract_behavioral_events_for_langloc_visual('behavior_files',d_events,'sampling',unique(sampling_frequency));
% check if there are the correct number of trials (120)
assert(size(events_table,1)==120);


%% Checking Behavior recordings with Natus recordings
time2save = trialTimingOnset(1)-30*sampling_frequency:trialTimingOnset(end)+30*sampling_frequency;
timeStart = time2save(1);
natusTrialStart = (trialTimingOnset-timeStart)./sampling_frequency(1);
natusAudioEnd = (filteredEventTimes{10}-timeStart)./sampling_frequency(1);
% natusTimingProbe = (filteredEventTimes{6}-timeStart)./sampling_frequency(1);
% natusEndProbe = (filteredEventTimes{14}-timeStart)./sampling_frequency(1);
behTimingOnset = events_table.actual_onset;

% audioDurNatus = natusAudioEnd-natusTrialStart;
% audioDurBeh = behTimingOffset-behTimingOnset;

isiNatus = [diff(natusTrialStart(1:40)); diff(natusTrialStart(41:80))];
isiBeh = [diff(behTimingOnset(1:40)); diff(behTimingOnset(41:80))];

%figure; scatter(isiNatus,isiBeh,20,'black','filled'); % Should look correlated
figure; histogram(isiNatus-isiBeh,50); %The distribution must be close to 0
xlabel('Discrepancy in time (s)')
ylabel('Trials');

% events_table.trial_onset_natus = natusTrialStart - 0.2;
% events_table.audio_onset_natus = natusTrialStart;
% events_table.audio_ended_natus = natusAudioEnd;
% events_table.probe_onset_natus = natusTimingProbe;
% events_table.trial_ended_natus = natusEndProbe+0.2;

%time2save = trialTimingOnset(1)-15*sampling_frequency:trialTimingOnset(end)+15*sampling_frequency;

%% FOR VISUAL LANGLOC
[trial_timing] = get_timing_for_LangLocVideo(filteredEventTimes,events_table,timeStart);


%% WRITING ECOG DATA STRUCTURE
subject = SUBJECT;
experiment = SESSION;
order = 'defaultSEEGorBOTHBroadBand';
save_filename = [ subject '_' experiment '_crunched_' order '.mat'];
save_path = [PATH_SAVE filesep 'crunched' filesep];
currentDateTime = datetime('now');
formattedDateTime = datestr(currentDateTime, 'yyyymmdd_HHMM');
log_filename = [PATH_SAVE filesep 'logs' filesep subject '_' experiment '_' order '_' formattedDateTime '.txt'];
d_files = [PATH_EDF filesep edfname];
ch_labels = channels_table.name;
ch_nums = 1:length(ch_labels);
ch_type = string(channels_table.type);
ch_deselect = find(~contains(ch_type,'seeg'));
ch_select = find(contains(ch_type,'seeg'));


for_preproc = struct;
for_preproc.elec_data_raw = single(record(ch_select,time2save));
for_preproc.event_table = events_table;
for_preproc.stitch_index_raw = 1;
for_preproc.sample_freq_raw = sampling_frequency(1);
for_preproc.log_file_name = log_filename;
for_preproc.decimation_freq = sampling_frequency(1)/4;

obj = ecog_data(for_preproc,subject,experiment,save_filename,save_path,d_files,...
    PATH_EDF,ch_labels(ch_select),1:length(ch_select),[],ch_type(ch_select));
obj.preprocess_signal('order',order,'isPlotVisible',true,'doneVisualInspection',false);
obj.events_table = obj.for_preproc.event_table;
obj.condition = cellfun(@(x) replace(x, {'S', 'N'}, {'sentence', 'nonword'}), obj.for_preproc.event_table.condition, 'UniformOutput', false);

obj.session = (obj.for_preproc.event_table.list);

obj.trial_timing = trial_timing(:,1);


if(~isfolder(save_path))
    mkdir(save_path)
end

save([save_path filesep save_filename],'obj','-v7.3');

%% Extract HG data


% Extract high gamma components using NapLab filter extraction
obj.extract_high_gamma('doNapLabFilterExtraction', true);

% Downsample the signal to 200 Hz
obj.downsample_signal('decimationFreq', 200);

% Extract significant channels from the signal
obj.extract_significant_channel();

% Determine time-based significance of the signal
obj.extract_time_significance();

% Calculate metrics for signal normalization
obj.extract_normalization_metrics();

% Normalize the signal using z-score method
obj.normalize_signal("normtype", 'z-score');

%% Generate the report

generateExperimentReport(obj, 'EM1271-langloc')