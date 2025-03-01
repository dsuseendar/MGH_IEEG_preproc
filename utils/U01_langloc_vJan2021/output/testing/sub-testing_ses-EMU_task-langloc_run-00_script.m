% Created by: Hannah Small, for aphasia project in Ev Federenko's lab
% 08/26/2019 --- MODIFIED for ecog project 01/10/2020 by Hannah Small
% updated 12/23/2020 for U01 ecog experiments

% This is a language localizer experiment with two conditions: sentences,
% and nonword lists. Each trial contains a list of 12 words or nonwords and
% a memory probe. The memory probe is either a word from the
% the preceding list or a word that did not show in the list at all.
% The subject must indicate if the word was present by pressing '1' or that
% the word was not present by pressing '2'.
% The purpose of the memory probe is the keep the subject alert and reading
% each word of the list.

% Every 8 trials there is an optional break. Press space to continue the
% task

% The materials are prepared when prepstim() is run, including the
% 20 sentences and 20 nonword lists, the orders of the conditions and their
% onset times, the memory probes (correct and incorrect), and the order of
% the probe presentation.
% prepstim() should be run before this experiment is run if there is no
% materials.mat present.
%
% The order is pseudorandom, with no more than 3 of sentences or nonwords
% being showed consecutively.

%Each trial will be structured as follows (8s total):
%200ms fixation
%each word/nonword presented for 400ms for the total stim duration of 400x12=4.8s
%200ms fixation
%1000ms probe presentation (in a different color)
%600ms extra time to answer (they can answer as soon as the probe appears and until the end of the trial)
%6.8 seconds per trial

%total time without breaks is 6.8x40 = 272s -- 4 min 32 s.


%subjectID-subject ID (a string)
%list-subset of the materials to use (1-3)


function U01_langloc_vJan2021(cfg)

subjectID = cfg.SUBJECT;
list = cfg.RUN_ID;
send_triggers = cfg.SEND_TRIGGERS;
rootDir=cfg.PATH_LOG;
dataFile = cfg.EVENT_FILENAME;
dataFile_csv = [dataFile '.csv'];

%Trigger codes
ExpStart =      1;
ExpEnd =        2;
Cond =          3;
CodedWords =    4:8;
CodeMap={...
    '0ms: fixation 200ms 13 01101',...
    '200ms: word1 400ms 1	00001',...
    '600ms: word2 400ms 2	00010',...
    '1000ms: word3 400ms 3	00011',...
    '1400ms: word4 400ms 4	00100',...
    '1800ms: word5 400ms 5	00101',...
    '2200ms: word6 400ms 6	00110',...
    '2600ms: word7 400ms 7	00111',...
    '3000ms: word8 400ms 8	01000',...
    '3400ms: word9 400ms 9	01001',...
    '3800ms: word10 400ms 10	01010',...
    '4200ms: word11 400ms 11	01011',...
    '4600ms: word12 400ms 12	01100',...
    '5000ms: fixation 200ms 14	01110',...
    '5200ms: probe 1000ms 16	10000',...
    '6200ms: extra time to answer 600ms 15	01111'};
IDValues=[13 1:12 14 16 15]';
CodedValues={'01101',...
    '00001',...
    '00010',...
    '00011',...
    '00100',...
    '00101',...
    '00110',...
    '00111',...
    '01000',...
    '01001',...
    '01010',...
    '01011',...
    '01100',...
    '01110',...
    '10000',...
    '01111'};

% Create empty structure.
TrialStruct = struct();
if(send_triggers)
    TrialStruct = Setup_DAQ_Stim(TrialStruct);
end

save_path = [rootDir filesep 'output' filesep];
expt_name = 'U01_langloc_vJan2021';

%handle duplicate filename, and other checks
if ischar(subjectID) == 0
    error('subjectID must be a string')
end

%input checks
if list > 3 || list < 0
    error('USE: U01_langloc_vJan2021(subjectID, list) -- list must be between 1 and 3')
end

%get the latest attempt at this list -- will be *_resume(n).csv
d = dir([dataFile '*.csv']);
n_files = length(d);
if(n_files > 0)
    dataFile_csv = [d(n_files).folder filesep d(n_files).name];
    resume_number = 0;

    if contains(dataFile_csv,'resume') || contains(dataFile_csv,'restart')
        filename_len = length(dataFile_csv);
        resume_number = str2num(dataFile_csv(filename_len-4));
    end
end

if ~isempty(d)
    
    previous_run = readtable(dataFile_csv);
    
    %determine if this run was finished
    num_completed = sum(previous_run.trial_completed == 1);
    num_trials = length(previous_run.trial);
    
    if num_completed < num_trials
        choice = str2num(input(['\nThis subject has partially completed this list.\nPress 1 to resume. Press 2 to restart.\n'],'s'));
    else
        error(['This subject has completed this list. Please enter a different subject ID or list.']);
    end
    
    %compute the resume numbers (largest resume + 1)
    current_resume_number = resume_number + 1;
    
    if choice == 1 
        previous_run = readtable(dataFile_csv);
        NUM_STIMULI = height(previous_run);
        
        stimuli = previous_run;
        output = previous_run;
        
        %find resume spot
        completed = previous_run.trial_completed == 1;
        start = sum(completed) + 1; %start with next sentence
    
        %update the name of the output file with new resume number
        dataFile_csv = [dataFile '_resume' num2str(current_resume_number) '.csv'];

        fprintf('Resuming list %d at trial %d \n', list, start);
    elseif choice == 2 %RESTARTING
        
        %update the name of the output file with new resume number
        dataFile_csv = [dataFile '_restart' num2str(current_resume_number) '.csv'];
         % get materials for this set
        load('materials.mat')
        %run practice run
        if (list == 0)
            stimuli = materials.practice_run;
        else
            stimuli = materials.(['run' num2str(list)]);
        end
        NUM_STIMULI = height(stimuli);
        %set the start at the beginning, not resumed
        start = 1;
        stimuli.time_info = zeros(NUM_STIMULI,1);
        writetable(stimuli, dataFile_csv, 'WriteVariableNames', true);
        output = readtable(dataFile_csv); %save template to save output on
        fprintf('Restarting list %d \n', list);
    
    else %input was anything other than 1 or 2
        error('Unrecognized input. Press 1 to resume, press 2 to restart. Exiting.\n');
    end
    
else
    % no output file for this subject for this list yet
    % run the full list
    
    % get materials for this set
    load('materials.mat')
    
    %run practice run
    if (list == 0)
        stimuli = materials.practice_run;
    else
        stimuli = materials.(['run' num2str(list)]);
    end
    NUM_STIMULI = height(stimuli);
    %set the start at the beginning, not resumed
    start = 1;
    current_resume_number = 0;
    stimuli.time_info = zeros(NUM_STIMULI,1);
    writetable(stimuli, dataFile_csv, 'WriteVariableNames', true);
    output = readtable(dataFile_csv); %save template to save output on
   
end

%Psychtoolbox setup
PsychDefaultSetup(2);

KbName('UnifyKeyNames');
spaceBar = KbName('space');
% escapeKey = KbName('escape');

key_mapping = ["1", "2"];
trigger_response_keys = [KbName('1!'), KbName('2@')];
triggerKey = trigger_response_keys;
escapeKey = KbName('ESCAPE');

%% Initialize Window %%
oldLevel = Screen('Preference', 'Verbosity', 0);
java; %clear java cache
AssertOpenGL;
Screen('Preference', 'VisualDebugLevel',    0);
Screen('Preference', 'SuppressAllWarnings', 1);
Screen('Preference', 'TextRenderer',        0);
Screen('Preference', 'SkipSyncTests',       1);

%Screen('CloseAll')

screensAll = Screen('Screens'); %Get the screen numbers
screenNumber = max(screensAll); % Which screen you want to use. "1" is external monitor, "0" is this screen. use external if it is present

%define colors
white = WhiteIndex(screenNumber);
black = BlackIndex(screenNumber);
blue = [0 0 1];
GREY = 0.6;

% Open screen.
[window, windowRect] = PsychImaging('OpenWindow', screenNumber, GREY); %, [0 0 640 480]

priorityLevel = MaxPriority(window);
Priority(priorityLevel);

%HideCursor;

Screen('TextSize', window, 40);
Screen('TextFont', window, 'Arial');
Screen('TextStyle', window, 0);

% Wait for scanner
DrawFormattedText(window, 'You will read sentences one word at a time.\n\n After, you will see a word in blue. \n\n Press 1 if that word was in the sentence you just read \n\n and press 2 if not. \n\nPress SPACE to begin', 'center', 'center', black);
Screen('Flip', window);

%set text size larger for the stimuli
Screen('TextSize', window, 80);

% while 1
%     FlushEvents();
%     key = GetChar();
%     if key == escapeKey % escape
%         %PsychPortAudio('Close');
%         Screen('CloseAll');
%         ShowCursor;
%         error('Experiment quit using ESCAPE');
%     elseif key == ' ' % space
%         break
%     end
%     
%     WaitSecs(0.001)
% end

[~, keyCode] = KbWait([], 2);
if any(ismember(find(keyCode),escapeKey))
    Screen('CloseAll');
    ShowCursor;
    error('Experiment quit using ESCAPE');
end


word_time = 0.400; %seconds

word_onsets = [];
onset = 0;

for i=1:13 %12 words
    word_onsets(i) = onset;
    onset = onset + word_time;
end

on = GetSecs;

stim_onsets = stimuli.planned_onset;

if(isa(stim_onsets,'cell'))
    stim_onsets = cell2mat(stim_onsets);
end

start_onset = stim_onsets(start);
%reset the starting onset to be zero, all other before it will be negative
stim_onsets = stim_onsets - start_onset;
onsets = on + stim_onsets;

%output.planned_onset = stim_onsets;

%put NA as actual onset for any trials that were run previously
if start>1
    na_list = zeros(start,1);
    na_list(:) = NaN;
    output.actual_onset(1:start) = na_list;
end

firstT=0;
startTask = GetSecs;
ind =1;
%go through the experiment, evaluating if condition is fixation or a list
%of words followed by a memory probe


% TRIGGER start of experiment 
TriggerCode = zeros(1,8);
TriggerCode(ExpStart) = 1;
if(send_triggers)
    SendTrigger( TrialStruct, TriggerCode )
end

for i = start:NUM_STIMULI
    
    t = now; 
    date_time = datetime(t,'ConvertFrom','datenum');
    
    if(mod(ind-1, 8) == 0 && ind ~= start && ind ~= NUM_STIMULI) %give a rest every 8 trials, excluding first and last trial
        ind = 1;
        Screen('TextSize', window, 40);
        DrawFormattedText(window, 'Take a break \n\n Press the spacebar to continue', 'center', 'center', black);
        start_break = Screen('Flip', window);
        Screen('TextSize', window, 80);

        while 1
            [keyIsDown, seconds_time, keyCode] = KbCheck(-3);        % -3 = check input from ALL devices
            if keyCode(escapeKey)
                Screen('CloseAll');
                
                writetable(output, dataFile_csv, 'WriteVariableNames', true);

                WaitSecs(2);
                error('Experiment quit by pressing ESCAPE\n');
            elseif ismember(find(keyCode,1), spaceBar)
                %update onsets
                break_time = GetSecs() - start_break;
                onsets = onsets + break_time;
                stim_onsets = stim_onsets + break_time;
           
                break;
            end
            WaitSecs(0.001);
        end
        
    end
    
    pres = table2array(stimuli(i,5:16)); %words1-12 from stimuli
    
    if pres{1} == '+'       
        DrawFormattedText(window, '+', 'center', 'center', black);
        Screen('Flip', window,onsets(i));
        onset_time = GetSecs() - startTask;
        
        output.planned_onset(i) = stim_onsets(i);
        output.actual_onset(i) = onset_time;
        output.trial_completed(i) = 1;
        output.time_info(i) = seconds(timeofday(date_time));
        
        % 1 second fixation
    else
        
        condition = output.condition{i};
        if(condition == 'S')
            cond_trigger = 1;
        elseif(condition == 'N')
            cond_trigger = 0;
        end
                
        %pre-stimuli fixation 200 ms
        DrawFormattedText(window, '', 'center', 'center', white);
        Screen('Flip', window,onsets(i));
        onset_time = GetSecs() - startTask;

        %TRIGGER first fixation (last 5 bits are ID #13)
        TriggerCode = zeros(1,8);
        TriggerCode(ExpStart) = 1;
        Bitword=CodedValues{find(IDValues==13)};
        for SU=1:5; TriggerCode(CodedWords(SU)) = str2num(Bitword(SU)); end
        %%%%%%%%%%%%%%%%%%%%%%%%%%
        TriggerCode(Cond) = cond_trigger;
        %%%%%%%%%%%%%%%%%%%%%%%%%%
        if(send_triggers)
            SendTrigger( TrialStruct, TriggerCode )
        end
%         first_fix = Bitword
%         TriggerCode
        
        pre_fixation = WaitSecs(0.200);
        pre_fixation_time = pre_fixation - onset_time - startTask;
        
        %use while loop and onset times for each word for more precise
        %timing
        trigger_sent = 0;
        for word_num = 1:length(pres)
            next_word_onset = word_onsets(word_num+1);
            
            while GetSecs()-pre_fixation < next_word_onset
                
                %% SEND WORD TRIGGERS HERE %%
                % each word (word_num) corresponds to the ID #
                % ie word3 is ID# 3 for the last 5 bits
                
                %only sent trigger once, on the onset of the word
                if(~trigger_sent)
                    TriggerCode = zeros(1,8);
                    TriggerCode(ExpStart) = 1;

                    %%%%%%%%%%%%%%%%%%%%%%%%%%
                    Bitword=CodedValues{find(IDValues==word_num)};  % word_num indicates the ID of the word we are presenting at this time, adding one because of the pre-word fixation
                    for SU=1:5; TriggerCode(CodedWords(SU)) = str2num(Bitword(SU));end%What variable is needed to indicate this ID???
                    %%%%%%%%%%%%%%%%%%%%%%%%%%
                    %%%%%%%%%%%%%%%%%%%%%%%%%%
                    TriggerCode(Cond) = cond_trigger;
                    %%%%%%%%%%%%%%%%%%%%%%%%%%
                    if(send_triggers)
                        SendTrigger( TrialStruct, TriggerCode )
                    end
                    
                    trigger_sent = 1;
                end
                

                w = char(pres(word_num));
                DrawFormattedText(window, upper(w), 'center', 'center', black);
                Screen('Flip', window);

                [~, ~, keyCode] = KbCheck(-1);

                if keyCode(escapeKey)
                    %save all info first
                    writetable(output, dataFile_csv, 'WriteVariableNames', true);

                    Screen('CloseAll');
                    WaitSecs(2); %time to finish saving and closing screen
                    error('Experiment quit by pressing ESCAPE\n');
                end

                WaitSecs(0.000000000001);
            end
%             word_num
%             TriggerCode
            %reset trigger_sent
            trigger_sent = 0;
        
        end

        %memory probe
        %pre-probe interval (200 ms), probe (1000 ms)and post-probe interval (600 ms)

        DrawFormattedText(window, '', 'center', 'center', white);
        Screen('Flip', window);
        %TRIGGER second fixation (last 5 bits are ID #14)
        TriggerCode = zeros(1,8);
        TriggerCode(ExpStart) = 1;
        %%%%%%%%%%%%%%%%%%%%%%%%%%
        Bitword=CodedValues{find(IDValues==14)};
        for SU=1:5; TriggerCode(CodedWords(SU)) = str2num(Bitword(SU));end
        %%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%
        TriggerCode(Cond) = cond_trigger;
        %%%%%%%%%%%%%%%%%%%%%%%%%%
        if(send_triggers)
            SendTrigger( TrialStruct, TriggerCode )
        end
%         memory_preprobe = Bitword
%         TriggerCode


        WaitSecs(0.200); %pre-probe for 200 ms

        probe = cell2mat(table2array(stimuli(i, 'probe')));

        %set up the display of the probe
        DrawFormattedText(window, probe, 'center', 'center', blue);
        Screen('Flip', window);
        %TRIGGER probe (last 5 bits are ID #16)
        TriggerCode = zeros(1,8);
        TriggerCode(ExpStart) = 1;
        %%%%%%%%%%%%%%%%%%%%%%%%%%
        Bitword=CodedValues{find(IDValues==16)};
        for SU=1:5; TriggerCode(CodedWords(SU)) = str2num(Bitword(SU));end
        %%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%
        TriggerCode(Cond) = cond_trigger;
        %%%%%%%%%%%%%%%%%%%%%%%%%%
        if(send_triggers)
            SendTrigger( TrialStruct, TriggerCode )
        end
        
%         probe = Bitword
%         TriggerCode

        %pressed = 0;
        response = NaN;
        rt = NaN;
        response_period_start = GetSecs;

        tigger_sent = 0;
        while GetSecs < response_period_start + 1.6 %probe for 1.6 seconds (1s + post probe 0.6 s)
            [~, ~, keyCode] = KbCheck(-1);

            if ismember(find(keyCode,1), triggerKey)
                index = find(triggerKey == find(keyCode,1));
                response(1,1) = key_mapping(index); % output determined by key_mapping at top of script
                rt = GetSecs - response_period_start;

                output.response(i) = response;
                output.RT(i) = rt;
                %             end
            end

            if keyCode(escapeKey)
                %save all info first
                writetable(output, dataFile_csv, 'WriteVariableNames', true);

                Screen('CloseAll');
                WaitSecs(2)
                fprintf('Experiment quit by pressing ESCAPE\n');
                break;
            end

            if(GetSecs > response_period_start + 1) %don't show probe after 1 s but still allow a response
                
                %only send trigger once, when this period starts
                if(~trigger_sent)
                    %TRIGGER extra time to respond (last 5 bits are ID #15)
                    TriggerCode = zeros(1,8);
                    TriggerCode(ExpStart) = 1;
                    %%%%%%%%%%%%%%%%%%%%%%%%%%
                    Bitword=CodedValues{find(IDValues==15)};
                    for SU=1:5; TriggerCode(CodedWords(SU)) = str2num(Bitword(SU));end
                    %%%%%%%%%%%%%%%%%%%%%%%%%%
                    %%%%%%%%%%%%%%%%%%%%%%%%%%
                    TriggerCode(Cond) = cond_trigger;
                    %%%%%%%%%%%%%%%%%%%%%%%%%%
                    if(send_triggers)
                        SendTrigger( TrialStruct, TriggerCode )
                    end
%                     extra_time = Bitword
%                     TriggerCode
%                     
                    trigger_sent = 1;
                end

                
                DrawFormattedText(window, '' , 'center', 'center', white);
                Screen('Flip', window);
            end

        end
        
        ind = ind +1; %increment ind (for breaks every 8 trials)
        
        output.planned_onset(i) = stim_onsets(i);
        output.actual_onset(i) = onset_time;
        output.trial_completed(i) = 1;
        output.time_info(i) = seconds(timeofday(date_time));
 
        %save on each completed non-fixation trial in case something goes wrong
        writetable(output, dataFile_csv, 'WriteVariableNames', true);
    end
end

[keyIsDown, seconds_time, keyCode] = KbCheck(-3);        % -3 = check input from ALL devices
if keyCode(escapeKey)
    %save all info first
    writetable(output, dataFile_csv, 'WriteVariableNames', true);
    
    Screen('CloseAll');
    WaitSecs(2);
    error('Experiment quit by pressing ESCAPE\n');
end
% TRIGGER end of experiment
 TriggerCode = zeros(1,8);
 TriggerCode(ExpStart) = 0;
 TriggerCode(ExpEnd) = 1;
 if(send_triggers)
    SendTrigger( TrialStruct, TriggerCode )
 end


EntireTime = GetSecs - startTask
sca;

writetable(output, dataFile_csv, 'WriteVariableNames', true);

%clear the keyboard
KbQueueRelease();
KbReleaseWait();

end %- for the function









