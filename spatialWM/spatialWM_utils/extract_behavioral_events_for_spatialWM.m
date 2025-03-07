function events_table = extract_behavioral_events_for_spatialWM(varargin)
%EXTRACT_BEHAVIORAL_EVENTS_FOR_SPATIALWM Summary of this function goes here
%   Detailed explanation goes here
    p = inputParser;
    addParameter(p, 'behavior_files', []);
    addParameter(p, 'sampling', []);
    addParameter(p, 'filteredEventTimes', []);

    parse(p, varargin{:});
    
    d_events = p.Results.behavior_files;
    filteredEventTimes = p.Results.filteredEventTimes;
    fs = p.Results.sampling;

    trialId = 2;
    choiceId = 3;
    responseId = 4;

    HeadersOrder = {'session','run','trial','condition','ImageStimulus',...
    'ChoiceLeft','ChoiceRight','stimulusPos','response','trial_onset',...
    'choice_onset','response_onset','RT','accuracy'};
    events_table = struct();
    for iField = 1:length(HeadersOrder)
        events_table.(HeadersOrder{iField})=[];
    end
    trialOnsets = filteredEventTimes{trialId};
    choiceOnsets = filteredEventTimes{choiceId};
    responseOnsets = filteredEventTimes{responseId};
    
    trialId = 1;
    for bid = 1:length(d_events)
        trigId = 1;
        expt_str = readtable(fullfile(d_events(bid).folder, d_events(bid).name));
        ImageOn = expt_str.ActualTrialOnset;
        ImageOff = expt_str.ChoiceOnset;
        numStim = length(ImageOn);
    
        StimID = zeros(length(ImageOn),1);
        
        for tid=1:numStim
            
            if(strcmp(expt_str.Condition(tid),'fix'))
                continue;
            end
            tid
            events_table(trialId).session = 1;
            events_table(trialId).run = bid;
            events_table(trialId).trial = expt_str.TrialNum(tid);
            events_table(trialId).condition = expt_str.Condition(tid);
            correct_ans = expt_str.CorrectAnswer(tid);
            switch correct_ans
                case 3
                    events_table(trialId).ImageStimulus = [str2num(expt_str.LeftGrid{tid})];
                    events_table(trialId).stimulusPos = 'L';
                case 4
                    events_table(trialId).ImageStimulus = [str2num(expt_str.RightGrid{tid})];
                    events_table(trialId).stimulusPos = 'R';
            end
            events_table(trialId).ChoiceLeft = [str2num(expt_str.LeftGrid{tid})];
            events_table(trialId).ChoiceRight = [str2num(expt_str.RightGrid{tid})];
            response = expt_str.Response(tid);
            switch response
                case 3
                    events_table(trialId).response = 'L';
                case 4
                    events_table(trialId).response = 'R';
            end
            events_table(trialId).trial_onset = (trialOnsets(trialId))/fs;
            events_table(trialId).choice_onset = (choiceOnsets(trialId))/fs;
            events_table(trialId).beh_onset = ImageOn(tid);
            
            events_table(trialId).accuracy = expt_str.Accuracy(tid);
            
                timediff =  (responseOnsets-choiceOnsets(trialId))./fs;
                respId = find(timediff>0&timediff<6);
                if(~isempty(respId))
                    respId = respId(1);
                    events_table(trialId).response_onset = (responseOnsets(respId))/fs;
                else
                    events_table(trialId).response_onset = nan;
    
                end
            
            events_table(trialId).RT = expt_str.RT(tid);
            trialId = trialId + 1;
            trigId = trigId + 1;
        end
    
        
    end

    % Change RT to NaN for incorrect trials
    
end

