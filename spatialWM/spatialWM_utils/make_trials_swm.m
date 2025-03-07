function trial_timing = make_trials_swm(event_table,fs,timeStart) 
%MAKE_TRIALS_SWM Summary of this function goes here
%   Detailed explanation goes here
if(istable(event_table))
    event_table = table2struct(event_table);
end
trial_period = 1.5*fs;
baseString = 'box';
trial_timing_keys = {'key',...
                                'string',...
                                'start',...
                                'end'...
            };


trial_timing = cell(size(event_table,2),1);
numInstances = [];
condTemp = event_table(1).condition{1};
stimTemp = [event_table(1).ImageStimulus];

switch condTemp
    case 'E'
        numInstances = length(stimTemp);
    case 'H'
        numInstances = length(stimTemp)/2;
end
indexedStings = arrayfun(@(x) sprintf('%s_%d', baseString, x), 1:numInstances, 'UniformOutput', false); 
keys = [indexedStings {'choice'} {'response'} ]';
for iTrial = 1:length(event_table)
    %trial_timing_table = cell2table(cell(length(keys),4), 'VariableNames', trial_timing_keys);
    trial_timing_struct = struct();
    for i = 1:length(trial_timing_keys)
        trial_timing_struct.(trial_timing_keys{i}) = []; % Initialize each field to empty
    end
    for iKey = 1:length(keys)
        trial_timing_struct(iKey).key = keys{iKey};
    end
    condTemp = event_table(iTrial).condition{1};
    trialOnset = int64(event_table(iTrial).trial_onset*fs-timeStart);
    switch condTemp
        case 'E'
            for iKey = 1:numInstances
                trial_timing_struct(iKey).string = event_table(iTrial).ImageStimulus(iKey);
                trial_timing_struct(iKey).start = (iKey-1)*trial_period+trialOnset+1;
                trial_timing_struct(iKey).end = (iKey)*trial_period+trialOnset;
            end
        case 'H'

            for iKey = 1:numInstances
                
                trial_timing_struct(iKey).string = [event_table(iTrial).ImageStimulus(2*iKey-1) event_table(iTrial).ImageStimulus(2*iKey)];
                trial_timing_struct(iKey).start = (iKey-1)*trial_period+trialOnset+1;
                trial_timing_struct(iKey).end = (iKey)*trial_period+trialOnset;
            end
    end
    trial_timing_struct(numInstances+1).string = [event_table(iTrial).ChoiceLeft; event_table(iTrial).ChoiceRight];
    trial_timing_struct(numInstances+1).start = int64(event_table(iTrial).choice_onset*fs+1-timeStart);
    trial_timing_struct(numInstances+1).end = int64(event_table(iTrial).response_onset*fs-timeStart);

    trial_timing_struct(numInstances+2).string = event_table(iTrial).response;
    trial_timing_struct(numInstances+2).start = int64(event_table(iTrial).response_onset*fs+1-timeStart);
    trial_timing_struct(numInstances+2).end = int64(event_table(iTrial).response_onset*fs+1.5*fs-timeStart);

    

    trial_timing{iTrial} = struct2table(trial_timing_struct);



end

trial_timing = trial_timing';
    
   
    
end


