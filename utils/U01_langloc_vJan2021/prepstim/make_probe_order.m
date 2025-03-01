
function [materials] = make_probe_order(materials,num_sets,num_trials_per_set,num_conds)
%constraints
% in each condition need half to be correct and half to be incorrect
%create vectors to sample from for each condition
% go through the order of conditions from the materials, selecting from the
% sample space
%constraint - need at least one correct and one incorrect in each trial
%(of three lists of words)

%space for the different orders
materials.probe_orders = struct;

num_correct = num_trials_per_set/num_conds/2;

for x = 1:num_sets
%create the vectors to sample from for each condition
% half should be 1 (incorrect) and half
%should be 2 (correct) - 12 of each trial so 6 correct and 6 incorrect

sample_sent = Shuffle([ones(1,num_correct) 2*ones(1,num_correct)]);
sample_nonword = Shuffle([ones(1,num_correct) 2*ones(1,num_correct)]);


order = strcat('ord', num2str(x));

conditions = materials.(order).conds;
length_cond = length(conditions);

probe_order = zeros(length_cond,1);
probe_index = 1;

s = 1; %counter for sample_sent
n = 1; %counter for sample_nonword

for j = 1:length_cond
    
    current_cond = conditions{j,1};
    
    %        if(current_cond == 'F')
    %            continue; %skip the fixation condition
    %       end
    
    which_probe_condition = 0;
    
    if(current_cond == 'S')
        which_probe_condition = sample_sent(1, s);
        s = s + 1;
    elseif(current_cond == 'N')
        which_probe_condition = sample_nonword(1, n);
        n = n + 1;
    end
    
    probe_order(probe_index, 1) = which_probe_condition;
    probe_index = probe_index + 1;
    
end

materials.probe_orders.(order) = probe_order;

end


save('materials_temp.mat', 'materials');
%return materials
return
