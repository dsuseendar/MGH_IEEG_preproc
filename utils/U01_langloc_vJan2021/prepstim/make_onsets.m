
%This script creates the array of onset times for a given order of
%conditions, given as 'conditions' in an array
%fieldName is the field that the onsets should be placed in the struct of
%stimulus materials



function [onsets] = make_onsets(conditions)

onsets = []; %place to store the onset times
i = 1; %iterator for the onset times

onsets(i,1) = 0; %initialize the first onset time 
i = i + 1; %iterate onsets

num_conditions = size(conditions,1); %get the number of conditions given


for x = 1:(num_conditions)-1 %exclude last onset
    current_condition = conditions{x};
    %if the condition is fixation next onset time is in 5 s
    if (current_condition == 'F') 
        if (i == 2 || i == num_conditions)
            onsets(i,1) = onsets(i-1,1) + 5; %first and last fixation should be 5 s
        else
            onsets(i,1) = onsets(i-1,1) + 1; % all other fixations should be 1 s
        end    
        i = i + 1;
    end
    
    %if the condition is S or N, next onset time includes
    %words (8 words*450 ms), pre-probe interval (400 ms), probe (1500 ms)
    %and post-probe interval (500 ms)
    % this needs to happen 3 times because there are 3 trials per block
    if (current_condition == 'S' | current_condition == 'N')
        
            time_to_add = 0;
            time_to_add = time_to_add + 0.200; %fixation time
            time_to_add = time_to_add + 12.*0.400; %words presentation length
            time_to_add = time_to_add + 0.200; %pre-probe length
            time_to_add = time_to_add + 1.000; %probe length
            time_to_add = time_to_add + 0.600; %post probe length
            onsets(i,1) = onsets(i-1,1) + time_to_add;
            i = i + 1;
        
    end
    
end


%return onsets
return
        
