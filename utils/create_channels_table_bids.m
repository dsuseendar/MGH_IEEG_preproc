function channels_table = create_channels_table_bids(edfinfo, PATH_ANNOT, SUBJECT, SESSION)
    % Create BIDS format channels table from EDF header information
    
    % Extract relevant information from info struct
    chan_labels = edfinfo.SignalLabels;
    chan_labels = format_electrode_names(chan_labels)
    units = edfinfo.PhysicalDimensions;
    sampling_frequency = edfinfo.NumSamples / seconds(edfinfo.DataRecordDuration);
    
    % Create table
    channels_table = table('Size', [length(chan_labels), 6], ...
                           'VariableTypes', ["string", "string", "string", "double", "string", "string"], ...
                           'VariableNames', ["name", "type", "units", "sampling_frequency", "group", "reference_bipolar"]);
    
    % Assign values to columns
    channels_table.name = chan_labels;
    channels_table.units = units;
    channels_table.sampling_frequency = sampling_frequency;
    channels_table.group = regexprep(channels_table.name, '\d', '');
    
    % Define channel type patterns
    type_patterns = struct('seeg', ["L", "R"], ...
                           'eeg', ["FP", "F7", "F3", "F4", "F8", "FZ", "T1", "T2", "T3", "T4", "T5", "T6", "O1", "O2", "PZ", "P3", "P4", "CZ", "C3", "C4"], ...
                           'eog', ["LOC", "ROC"], ...
                           'ecg', ["EKG"], ...
                           'emg', ["EMG"], ...
                           'TRIG', ["TRIG"], ...
                           'MISC', ["DC", "OS", "PR", "Ple","RESP"], ...
                           'OTHER', ["CII"]);
    
    % Assign channel types
    channels_table.type = categorical(repmat({'not labeled'}, height(channels_table), 1));
    for type = fieldnames(type_patterns)'
        type = type{1};
        channels_table.type(contains(channels_table.name, type_patterns.(type))) = type;
    end
    channels_table.type(channels_table.name == "CII" | channels_table.group == "C") = "OTHER";
    
    % Define bipolar reference channels
    channels_table.reference_bipolar = [channels_table.name(2:end); "n/a"];
    channels_table.reference_bipolar(channels_table.type ~= "SEEG" | ...
                                     channels_table.group ~= [channels_table.group(2:end); "n/a"]) = "n/a";
    
    % Write channels table to annot folder
    writetable(channels_table, fullfile(PATH_ANNOT, [SUBJECT '_ses-' SESSION '_channels.tsv']), ...
               'Delimiter', '\t', 'FileType', 'text');
end
