
%This function makes a cell array containing word lists.
%Each word is in its own cell and each word list is its own row

%The function will gather the lists of a specified condition
%(specific_cond, S or N) given the list of stimuli and their
%corresponding conditions
function [materials] = make_stimuli(materials, stimuli, cond, probes_correct, probes_incorrect,num_trials_per_set,num_conds,num_sets)

num_stimuli_per_set = num_trials_per_set/num_conds;

%create the structs to store 3 subsets in, each <____CHECKKKK
materials.sent = struct;
materials.nonword = struct;

num_stimuli = size(stimuli,1);
s = 0; %counter for the sentences list
n = 0; %counter for the nonword list

for i = 1:num_stimuli 
    
    temp_words = split(stimuli(i,1)); %break string from stimuli into separate words
    probe_correct = probes_correct(i,1);
    probe_incorrect = probes_incorrect(i,1);
    
        if(cond{i,1} == 'S')
            s = s + 1; %update position in sentence array
            index = s;
            condition = 'sent';
            
            %subset 1
            if(index <= num_stimuli_per_set)
                materials.(condition).s1(index,:) = temp_words(:,1); %add each word to this row in cell array
                materials.(condition).probes_correct.s1(index,:) = probe_correct;
                materials.(condition).probes_incorrect.s1(index,:) = probe_incorrect;
            end

            %subset 2
            if(index > num_stimuli_per_set && index <= num_stimuli_per_set*2)
                index = index - num_stimuli_per_set;
                materials.(condition).s2(index,:) = temp_words(:,1); %add each word to this row in cell array
                materials.(condition).probes_correct.s2(index,:) = probe_correct;
                materials.(condition).probes_incorrect.s2(index,:) = probe_incorrect;
            end

            %subset 3
            if(index > num_stimuli_per_set*2 && index <= num_stimuli_per_set*3)
                index = index - num_stimuli_per_set*2;
                materials.(condition).s3(index,:) = temp_words(:,1); %add each word to this row in cell array
                materials.(condition).probes_correct.s3(index,:) = probe_correct;
                materials.(condition).probes_incorrect.s3(index,:) = probe_incorrect;
            end
            
             %save the practice materials
            if(index > num_stimuli_per_set*3 && index <=num_stimuli_per_set*4)
                index = index - num_stimuli_per_set*3;
                materials.practice.(condition).stim(index,:) = temp_words(:,1);
                materials.practice.(condition).probes_correct(index,:) = probe_correct;
                materials.practice.(condition).probes_incorrect(index,:) = probe_incorrect;
            end
            
        elseif(cond{i,1} == 'N')
            n = n + 1; %update position in nonword array
            index = n;
            condition = 'nonword';
            
            %subset 1
            if(index <= num_stimuli_per_set)
                materials.(condition).s1(index,:) = temp_words(:,1); %add each word to this row in cell array
                materials.(condition).probes_correct.s1(index,:) = probe_correct;
                materials.(condition).probes_incorrect.s1(index,:) = probe_incorrect;
            end

            %subset 2
            if(index > num_stimuli_per_set && index <= num_stimuli_per_set*2)
                index = index - num_stimuli_per_set;
                materials.(condition).s2(index,:) = temp_words(:,1); %add each word to this row in cell array
                materials.(condition).probes_correct.s2(index,:) = probe_correct;
                materials.(condition).probes_incorrect.s2(index,:) = probe_incorrect;
            end

            %subset 3
            if(index > num_stimuli_per_set*2 && index <= num_stimuli_per_set*3)
                index = index - num_stimuli_per_set*2;
                materials.(condition).s3(index,:) = temp_words(:,1); %add each word to this row in cell array
                materials.(condition).probes_correct.s3(index,:) = probe_correct;
                materials.(condition).probes_incorrect.s3(index,:) = probe_incorrect;
            end
            
             %save the practice materials
            if(index > num_stimuli_per_set*3 && index <=num_stimuli_per_set*4)
                index = index - num_stimuli_per_set*3;
                materials.practice.(condition).stim(index,:) = temp_words(:,1);
                materials.practice.(condition).probes_correct(index,:) = probe_correct;
                materials.practice.(condition).probes_incorrect(index,:) = probe_incorrect;
            end
        
        end

       
        
end

materials = make_probe_order(materials,num_sets,num_trials_per_set, num_conds);



%return materials
return


