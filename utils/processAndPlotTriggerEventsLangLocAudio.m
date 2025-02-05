function filteredEventTimes = processAndPlotTriggerEventsLangLocAudio(TrigMat1)
    % Convert trigger matrix to binary and process
    trigMat2process = dec2bin(TrigMat1, 16); % there are 16 digital channels
    trigMat2process = double(trigMat2process); % convert characters to numbers
    trigMat2process = trigMat2process - 48; % 48 -> '0' and 49 -> '1'
    trigMat2process = fliplr(trigMat2process); % bit-16 is the first channel

    % Define channel indices for all 8 channels
    channels = 1:8;

    % Find event start times for all 8 channels
    eventTimes = cell(1, 8);
    for ch = channels
        eventTimes{ch} = find(diff(trigMat2process(:, ch)) == 1) + 1;
    end

    for ch = 9:16
        eventTimes{ch} = find(diff(trigMat2process(:, ch-8)) == -1) + 1;
    end

    % Combine all events into a single list with channel identifiers
    allEvents = [];
    for ch = 1:16
        allEvents = [allEvents; eventTimes{ch}, repmat(ch, length(eventTimes{ch}), 1)];
    end

    % Sort all events by timestamp
    allEvents = sortrows(allEvents, 1);

   % Remove overlapping events across first 8 channels, preserve events for next 16 channels
    overlap_threshold = 10; % Define overlap threshold (e.g., 10 samples)
    cleanedEvents = [];
    prevTime = -inf; % Initialize with a very small value
    for i = 1:size(allEvents, 1)
        currentTime = allEvents(i, 1);
        currentChannel = allEvents(i, 2);
        
        if currentChannel <= 8
            % For first 8 channels, remove overlapping events
            if (currentTime - prevTime) >= overlap_threshold
                cleanedEvents = [cleanedEvents; allEvents(i, :)];
                prevTime = currentTime;
            end
        else
            % For channels 9-24, preserve all events
            cleanedEvents = [cleanedEvents; allEvents(i, :)];
        end
    end


    % Extract Start Run and End Run events from cleaned events
    startRunEvents = cleanedEvents(cleanedEvents(:, 2) == 1, 1); % Channel 1: Start Run
    endRunEvents = cleanedEvents(cleanedEvents(:, 2) == 2, 1);   % Channel 3: End Run

    % Discard consecutive Start Runs without an End Run in between
    validStartRunEvents = [];
    i = 1;
    while i <= length(startRunEvents)
        % Check if the next Start Run occurs before the next End Run
        if i < length(startRunEvents) & (isempty(endRunEvents) | startRunEvents(i+1) < min(endRunEvents(endRunEvents > startRunEvents(i))))
            % Discard consecutive Start Runs
            i = i + 1;
        else
            % Keep valid Start Run
            validStartRunEvents = [validStartRunEvents; startRunEvents(i)];
            i = i + 1;
        end
    end

    % Discard consecutive End Runs without a Start Run in between
    validEndRunEvents = [];
    i = 1;
    while i <= length(endRunEvents)
        % Check if the next End Run occurs before the next Start Run
        if i < length(endRunEvents) & (isempty(startRunEvents) | endRunEvents(i+1) < min(startRunEvents(startRunEvents > endRunEvents(i))))
            % Discard consecutive End Runs
            i = i + 1;
        else
            % Keep valid End Run
            validEndRunEvents = [validEndRunEvents; endRunEvents(i)];
            i = i + 1;
        end
    end

    % Pair each valid Start Run with the next valid End Run
    pairedRuns = [];
    startIdx = 1;
    endIdx = 1;
    while startIdx <= length(validStartRunEvents) && endIdx <= length(validEndRunEvents)
        % Find the next End Run that occurs after the current Start Run
        while endIdx <= length(validEndRunEvents) && validEndRunEvents(endIdx) <= validStartRunEvents(startIdx)
            endIdx = endIdx + 1;
        end
        if endIdx <= length(validEndRunEvents)
            % Pair the Start Run with the next End Run
            pairedRuns = [pairedRuns; validStartRunEvents(startIdx), validEndRunEvents(endIdx)];
            startIdx = startIdx + 1;
            endIdx = endIdx + 1;
        else
            break; % No more End Runs to pair
        end
    end

    % Filter events to keep only those between paired Start Run and End Run
    filteredEvents = [];
    for i = 1:size(pairedRuns, 1)
        startTime = pairedRuns(i, 1);
        endTime = pairedRuns(i, 2);
        % Find events within the current Start Run and End Run range
        eventsInRange = cleanedEvents(cleanedEvents(:, 1) >= startTime & cleanedEvents(:, 1) <= endTime, :);
        filteredEvents = [filteredEvents; eventsInRange];
    end

    % Separate filtered events back into channels
    filteredEventTimes = cell(1, 16);
    for ch = 1:16
        filteredEventTimes{ch} = filteredEvents(filteredEvents(:, 2) == ch, 1);
    end

    % Define selected channels and their labels
    selectedChannels = [1, 3, 2, 10, 5, 6, 7]; % Channels for Start Run, End Run, Start Trial, Start Choice, Start Response, Start Block
    channelLabels = {'Start Run', 'End Run', 'Start Audio', 'End Audio', 'Pre-probe', 'Start Probe', 'Fixation'};

    % Plot only the selected cleaned events
    figure;
    hold on;
    colors = lines(length(selectedChannels)); % Use different colors for each selected channel
    for i = 1:length(selectedChannels)
        ch = selectedChannels(i);
        stem(filteredEventTimes{ch}, i * ones(length(filteredEventTimes{ch}), 1), 'Color', colors(i, :), 'DisplayName', channelLabels{i});
    end
    xlabel('Sample Index');
    ylabel('Event Type');
    title('Cleaned Trigger Events (Between Paired Start Run and End Run)');
    legend show;
    ylim([0, length(selectedChannels) + 1]); % Adjust y-axis limits for better visualization
    hold off;
end
