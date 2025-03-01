% This script preps the stimuli from the materials in an excel file
% 3 sets of 40 trials each (20 S, 20 N)
% 
% This should not be run again - HS 12/23/2020
function [materials] = prepstim()
%create the data structure to hold the stimuli and conditions
materials = struct;

num_sets = 3;
num_trials_per_set = 40;
num_conds = 2;

%store all data from excel file in stimuli
data = readtable('full_langloc_stim_expandedOct2018_forMarkRJan2020_updDec23.xlsx');

%get the type of stimuli (stimuli condition)
cond = data{:,'cond'};

%get the stimuli, lists of 12 words separated by spaces, including 
%sentences, and nonword lists
stimuli = data{:,'trial_str'};
probes_correct = data{:, 'probe_match'};
probes_incorrect = data{:, 'probe_mismatch'};

%create and populate the conditions for each possible order 
% key:
% F - fixation
% S - sentence
% N - nonword list

%% generate orders

% this assumes 40 total trials (20 of S, 20 of N)
%subsets necessary because we dont want more than 3 of the same stimuli in a row
for x = 1:num_sets
subset_1 = ['S' 'S' 'N'];
subset_2 = ['S' 'N' 'N'];

%intersperse shuffled subsets for a pseudorandom order
condition_order = [];
%fill in 36/40 conditions
for i = 1:6
    temp = [subset_1(randperm(length(subset_1))) subset_2(randperm(length(subset_2)))];
    condition_order = [condition_order temp];
end

%add the four remaining conditions (random sampling of set 1 plus an N
condition_order= [condition_order subset_1(randperm(length(subset_1))) 'N']

to_add = [];
for j = 1:length(condition_order)
    to_add = [to_add condition_order(j)];
    to_add = [to_add 'F']; %add F in every other
end

condition_order = to_add;

condition_order = [ 'F' condition_order ]'; %fixations on beginning of the stimuli

order = ['ord' num2str(x)];

materials.(order).conds = cellstr(condition_order);
% create and assign the onset times for each of the possible orders
% see make_onsets.m for the specifics on the timing
materials.(order).onsets = make_onsets(materials.(order).conds);
end


%load all stimuli
materials = make_stimuli(materials, stimuli, cond, probes_correct, probes_incorrect,num_trials_per_set,num_conds,num_sets); %^needs to be run after the orders have been read in


%split into the 3 runs (tables)

for i = 1:3
    conds = materials.(['ord' num2str(i)]).conds;
    onsets = num2cell(materials.(['ord' num2str(i)]).onsets);
    num_stim = length(conds);
    zero_array = num2cell(zeros(num_stim,1));
    list = num2cell(ones(num_stim,1)*i);
    trial = num2cell(1:num_stim)';
    temp_array = [list conds onsets zero_array zero_array zero_array zero_array zero_array zero_array zero_array ...
        zero_array zero_array zero_array zero_array zero_array zero_array zero_array zero_array zero_array zero_array trial zero_array];
    
    run_table = array2table(temp_array);
    run_table.Properties.VariableNames = {'list' 'condition' 'planned_onset' 'actual_onset' 'word1' 'word2' 'word3' 'word4'...
        'word5' 'word6' 'word7' 'word8' 'word9' 'word10' 'word11' 'word12' 'probe' 'probe_answer' 'response' 'RT' 'trial' 'trial_completed'};


    current_set = ['s' num2str(i)];
    
   
   
    sentence = materials.sent.(current_set);
    nonword = materials.nonword.(current_set);

    %grab the correct probes from the materials
    sentence_probes_correct = materials.sent.probes_correct.(current_set);
    nonword_probes_correct = materials.nonword.probes_correct.(current_set);

    %grab the incorrect probes from the materials
    sentence_probes_incorrect = materials.sent.probes_incorrect.(current_set);
    nonword_probes_incorrect = materials.nonword.probes_incorrect.(current_set);
    
    %shuffle the sentences and nonwords and their probes
    n_sentence = length(sentence);
    n_nonword = length(nonword);
    
    sent_indx_shuffled = randperm(n_sentence);
    nonword_indx_shuffled = randperm(n_nonword);
    
    sentence = sentence(sent_indx_shuffled,:);
    sentence_probes_correct = sentence_probes_correct(sent_indx_shuffled);
    sentence_probes_incorrect = sentence_probes_incorrect(sent_indx_shuffled);
    
    nonword = nonword(nonword_indx_shuffled,:);
    nonword_probes_correct = nonword_probes_correct(nonword_indx_shuffled);
    nonword_probes_incorrect = nonword_probes_incorrect(nonword_indx_shuffled);
    
    
    %get the probe type order from the materials
    probe_order = materials.probe_orders.(['ord' num2str(i)]);
    
    Si = 0;
    Ni = 0;
    
    probe_index = 0;
    
    for j=1:length(conds)
        condition = conds{j,1};
        
        if(condition == 'F')
            run_table(j,'word1') = {'+'};
            probe_index = probe_index+1;
            
        elseif (condition == 'S' || condition == 'N')
                probe_index = probe_index + 1;
                probe_type = probe_order(probe_index,1);
                
                run_table{j,'probe_answer'} = {probe_type};
                if(condition=='S')
                    Si = Si + 1;
                    run_table(j,5:16)=upper(sentence(Si,:));
                    if(probe_type == 1) %1 is correct, 2 is incorrect
                        run_table{j,'probe'} = sentence_probes_correct(Si,1);
                    elseif(probe_type == 2)
                        run_table{j,'probe'} = sentence_probes_incorrect(Si,1);
                    end
                elseif (condition == 'N')
                        Ni = Ni + 1;
                        run_table(j,5:16)=upper(nonword(Ni,:));
                        if(probe_type == 1) %1 is correct, 2 is incorrect
                            run_table{j,'probe'} = nonword_probes_correct(Ni,1);
                        elseif(probe_type == 2)
                            run_table{j,'probe'} = nonword_probes_incorrect(Ni,1);
                        end
                end
        end
    end
    
    materials.(['run' num2str(i)]) = run_table;
end

%add the practice ones



%grab the stimuli from the specified set of materials
sentence = materials.practice.sent.stim;
nonword = materials.practice.nonword.stim;

%grab the correct probes from the materials
sentence_probes_correct = materials.practice.sent.probes_correct;
nonword_probes_correct = materials.practice.nonword.probes_correct;

%grab the incorrect probes from the materials
sentence_probes_incorrect = materials.practice.sent.probes_incorrect;
nonword_probes_incorrect = materials.practice.nonword.probes_incorrect;

%shuffle the sentences and nonwords and their probes
n_sentence = length(sentence);
n_nonword = length(nonword);

sent_indx_shuffled = randperm(n_sentence);
nonword_indx_shuffled = randperm(n_nonword);

sentence = sentence(sent_indx_shuffled,:);
sentence_probes_correct = sentence_probes_correct(sent_indx_shuffled);
sentence_probes_incorrect = sentence_probes_incorrect(sent_indx_shuffled);

nonword = nonword(nonword_indx_shuffled,:);
nonword_probes_correct = nonword_probes_correct(nonword_indx_shuffled);
nonword_probes_incorrect = nonword_probes_incorrect(nonword_indx_shuffled);


%pseudorandom order with fixations between
order = [ 'F' 'S' 'F' 'N' 'F' 'S' 'F' 'S' 'F' 'N' 'F' 'N' 'F' 'S' 'F' 'N' 'F' 'S' 'F' 'N' 'F' 'N' 'F' 'S' 'F']';

ord = materials.ord1;
conds = ord.conds(1:25);
stim_onsets = num2cell(ord.onsets(1:25));
ord = cellstr(order);

probe_order = [ 0 1 0 1 0 2 0 1 0 1 0 2 0 2 0 2 0 1 0 2 0 2 0 2 0 1 0]';

    num_stim = length(order);
    zero_array = num2cell(zeros(num_stim,1));
    list = cell(num_stim,1);
    list(:) = {'practice'};
    trial = num2cell(1:num_stim)';
    temp_array = [list ord stim_onsets zero_array zero_array zero_array zero_array zero_array zero_array zero_array ...
        zero_array zero_array zero_array zero_array zero_array zero_array zero_array zero_array zero_array zero_array trial zero_array];
    
    run_table = array2table(temp_array);
    run_table.Properties.VariableNames = {'list' 'condition' 'planned_onset' 'actual_onset' 'word1' 'word2' 'word3' 'word4'...
        'word5' 'word6' 'word7' 'word8' 'word9' 'word10' 'word11' 'word12' 'probe' 'probe_answer' 'response' 'RT' 'trial' 'trial_completed'};

    Si = 0;
    Ni = 0;
    
    probe_index = 0;
    

for j=1:length(conds)
        condition = conds{j,1};
        
        if(condition == 'F')
            run_table(j,'word1') = {'+'};
            probe_index = probe_index+1;
            
        elseif (condition == 'S' || condition == 'N')
                probe_index = probe_index + 1;
                probe_type = probe_order(probe_index,1);
                
                run_table{j,'probe_answer'} = {probe_type};
                if(condition=='S')
                    Si = Si + 1;
                    run_table(j,5:16)=upper(sentence(Si,:));
                    if(probe_type == 1) %1 is correct, 2 is incorrect
                        run_table{j,'probe'} = sentence_probes_correct(Si,1);
                    elseif(probe_type == 2)
                        run_table{j,'probe'} = sentence_probes_incorrect(Si,1);
                    end
                elseif (condition == 'N')
                        Ni = Ni + 1;
                        run_table(j,5:16)=upper(nonword(Ni,:));
                        if(probe_type == 1) %1 is correct, 2 is incorrect
                            run_table{j,'probe'} = nonword_probes_correct(Ni,1);
                        elseif(probe_type == 2)
                            run_table{j,'probe'} = nonword_probes_incorrect(Ni,1);
                        end
                end
        end
        materials.('practice_run') = run_table;
end
    


save('materials.mat', 'materials');

return





