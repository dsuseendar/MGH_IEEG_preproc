function updated_electrode_names = format_electrode_names(electrode_names)
    % Initialize cell array for updated electrode names
    updated_electrode_names = cell(size(electrode_names));

    for i = 1:length(electrode_names)
        % Extract the electrode name
        name = electrode_names{i};

        % Use regular expression to identify single-digit numbers at the end
        updated_name = regexprep(name, '(?<=[A-Za-z])(\d)(?!\d)', '0$1');

        % Store the updated name
        updated_electrode_names{i} = updated_name;
    end
end