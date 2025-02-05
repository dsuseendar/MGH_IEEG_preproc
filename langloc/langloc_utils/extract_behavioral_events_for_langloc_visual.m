function events_table = extract_behavioral_events_for_langloc_visual(varargin)
    % Parse input arguments
    p = inputParser;
    addParameter(p, 'behavior_files', []);
    addParameter(p, 'sampling', []);
    parse(p, varargin{:});
    
    d_events = p.Results.behavior_files;
    sampling_freq = p.Results.sampling;

    % Process behavioral events
    all_events_Table = {};
    for nn = 1:numel(d_events)
        filename = fullfile(d_events(nn).folder, d_events(nn).name);
        opts = detectImportOptions(filename);
        opts = setvartype(opts, 'char');
        event_table = readtable(filename, opts);
        condition = event_table.condition;
        non_fixation = ~strcmp(condition, 'F');
        event_table = event_table(non_fixation, :);
        all_events_Table{nn, 1} = event_table;
    end

    events_table = all_events_Table{1};
    for tt = 2:size(all_events_Table, 1)
        events_table = [events_table; all_events_Table{tt}];
    end

    % Convert relevant columns to numeric
    numeric_cols = {'list', 'planned_onset', 'actual_onset', 'probe_answer', 'response', 'RT', 'trial', 'trial_completed'};
    for col = numeric_cols
        events_table.(col{1}) = cellfun(@str2double, events_table.(col{1}));
    end
    events_table.final_list = events_table.list;

    % Load materials based on the number of d_events
    load('materials.mat');
    num_runs = numel(d_events);
    
    switch num_runs
        case 1
            mat_r1r2r3 = materials.run1;
        case 2
            mat_r1r2r3 = [materials.run1; materials.run2];
        case 3
            mat_r1r2r3 = [materials.run1; materials.run2; materials.run3];
        otherwise
            mat_r1r2r3 = [];
            for i = 1:num_runs
                run_name = sprintf('run%d', i);
                if isfield(materials, run_name)
                    mat_r1r2r3 = [mat_r1r2r3; materials.(run_name)];
                else
                    warning('Run %d not found in materials. Skipping.', i);
                end
            end
    end
    
    mat_r1r2r3 = mat_r1r2r3(~ismember(mat_r1r2r3.condition, 'F'), :);
    
    assert(all(ismember(events_table.word1, mat_r1r2r3.word1)));
    assert(all(events_table.list == cell2mat(mat_r1r2r3.list)));
    assert(all(events_table.trial == cell2mat(mat_r1r2r3.trial)));
    
    words = [arrayfun(@(x) ['word', num2str(x)], 1:12, 'UniformOutput', false), 'probe'];
    
    for word = words
        events_table.(word{1}) = mat_r1r2r3.(word{1});
    end
end
