function filteredEventTimes = processAndPlotTriggerEventsSpatialWM(TrigMat1)
   % Convert trigger matrix to binary and process
    trigMat2process = dec2bin(TrigMat1, 16);
    trigMat2process = double(trigMat2process) - 48;
    trigMat2process = fliplr(trigMat2process);

    % Define channel indices for all 16 channels
    channels = 1:16;

    % Find event start times for all 16 channels
    eventTimes = cell(1, 16);
    for ch = 1:8
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

    % Remove overlapping events across first 8 channels, preserve events for next 16 channels
    % overlap_threshold = 10; % Define overlap threshold (e.g., 10 samples)
    % cleanedEvents = [];
    % prevTime = -inf; % Initialize with a very small value
    % for i = 1:size(allEvents, 1)
    %     currentTime = allEvents(i, 1);
    %     currentChannel = allEvents(i, 2);
    % 
    %     if currentChannel <= 6
    %         % For first 8 channels, remove overlapping events
    %         if (currentTime - prevTime) >= overlap_threshold
    %             cleanedEvents = [cleanedEvents; allEvents(i, :)];
    %             prevTime = currentTime;
    %         end
    %     else
    %         % For channels 9-24, preserve all events
    %         cleanedEvents = [cleanedEvents; allEvents(i, :)];
    %     end
    % end

cleanedEvents = allEvents;
   % Separate filtered events back into channels
    cleanedEventTimes = cell(1, 16);
    for ch = 1:16
        cleanedEventTimes{ch} = cleanedEvents(cleanedEvents(:, 2) == ch, 1);
    end

    % Plot events for channels 1-8
    figure;
    hold on;
    colors = lines(16);
    for i = 1:8
        stem(cleanedEventTimes{i}, i * ones(length(cleanedEventTimes{i}), 1), 'Color', colors(i, :));
    end
    xlabel('Sample Index');
    ylabel('Event Type');
    title('Events for Channels 1-8');
    hold off;

    % Plot events for channels 9-16
    figure;
    hold on;
    for i = 9:16
        stem(cleanedEventTimes{i}, (i-8) * ones(length(cleanedEventTimes{i}), 1), 'Color', colors(i, :));
    end
    xlabel('Sample Index');
    ylabel('Event Type');
    title('Events for Channels 9-16');
    hold off;

    % Prompt user for exclusion periods
    exclusionPeriods = [];
    while true
        startExclusion = input('Enter start time for exclusion period (in samples), or press Enter to finish: ');
        if isempty(startExclusion)
            break;
        end
        endExclusion = input('Enter end time for exclusion period (in samples): ');
        exclusionPeriods = [exclusionPeriods; startExclusion endExclusion];
    end

    % Apply exclusions to allEvents
    for i = 1:size(exclusionPeriods, 1)
        cleanedEvents = cleanedEvents(cleanedEvents(:,1) < exclusionPeriods(i,1) | cleanedEvents(:,1) > exclusionPeriods(i,2), :);
    end


    % Sort all events by timestamp
    cleanedEvents = sortrows(cleanedEvents, 1);

   % % Remove overlapping events across first 8 channels, preserve events for next 16 channels
   %  overlap_threshold = 10; % Define overlap threshold (e.g., 10 samples)
   %  cleanedEvents = [];
   %  prevTime = -inf; % Initialize with a very small value
   %  for i = 1:size(allEvents, 1)
   %      currentTime = allEvents(i, 1);
   %      currentChannel = allEvents(i, 2);
   % 
   %      if currentChannel <= 6
   %          % For first 8 channels, remove overlapping events
   %          if (currentTime - prevTime) >= overlap_threshold
   %              cleanedEvents = [cleanedEvents; allEvents(i, :)];
   %              prevTime = currentTime;
   %          end
   %      else
   %          % For channels 9-24, preserve all events
   %          cleanedEvents = [cleanedEvents; allEvents(i, :)];
   %      end
   %  end



 %  cleanedEvents = allEvents;

     % Prompt user for start and end run IDs
    startRunId = input('Enter the start run ID: ');
    endRunId = input('Enter the end run ID: ');



    % Extract Start Run and End Run events from cleaned events
    startRunEvents = cleanedEvents(cleanedEvents(:, 2) == startRunId, 1); % Channel 1: Start Run
    endRunEvents = cleanedEvents(cleanedEvents(:, 2) == endRunId, 1);   % Channel 3: End Run

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

    
  

   

    % Filter events to keep only those between selected Start Run and End Run, excluding specified periods
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

   
    % Plot only the selected cleaned events
    figure;
    hold on;
    colors = lines(16); % Use different colors for each selected channel
    for i = 1:16
        ch = i;
        stem(filteredEventTimes{ch}, i * ones(length(filteredEventTimes{ch}), 1), 'Color', colors(i, :));
    end
    xlabel('Sample Index');
    ylabel('Event Type');
    title('Cleaned Trigger Events (Between Paired Start Run and End Run)');
    legend show;
    ylim([0, 17]); % Adjust y-axis limits for better visualization
    hold off;
end
