function filteredEventTimes = processAndPlotTriggerEventsLangLocVisual(TrigMat1)
    % Convert trigger matrix to binary and process
    trigMat2process = dec2bin(TrigMat1, 16);
    trigMat2process = double(trigMat2process) - 48;
    trigMat2process = fliplr(trigMat2process);

    % Define bit patterns for each event type
    bit1 = trigMat2process(:,8);
    bit2 = trigMat2process(:,7);
    bit3 = trigMat2process(:,6);
    bit4 = trigMat2process(:,5);
    bit5 = trigMat2process(:,4);
    bit6=trigMat2process(:,3);
    bit7=trigMat2process(:,2);
    bit8=trigMat2process(:,1);

    % Define event types for words 1 to 12
    eventTypes = {
        'fix', bit1 & ~bit2 & bit3 & bit4 & ~bit5;
        'word1', bit1 & ~bit2 & ~bit3 & ~bit4 & ~bit5;
        'word2', ~bit1 & bit2 & ~bit3 & ~bit4 & ~bit5;
        'word3', bit1 & bit2 & ~bit3 & ~bit4 & ~bit5;
        'word4', ~bit1 & ~bit2 & bit3 & ~bit4 & ~bit5;
        'word5', bit1 & ~bit2 & bit3 & ~bit4 & ~bit5;
        'word6', ~bit1 & bit2 & bit3 & ~bit4 & ~bit5;
        'word7', bit1 & bit2 & bit3 & ~bit4 & ~bit5;
        'word8', ~bit1 & ~bit2 & ~bit3 & bit4 & ~bit5;
        'word9', bit1 & ~bit2 & ~bit3 & bit4 & ~bit5;
        'word10', ~bit1 & bit2 & ~bit3 & bit4 & ~bit5;
        'word11', bit1 & bit2 & ~bit3 & bit4 & ~bit5;
        'word12', ~bit1 & ~bit2 & bit3 & bit4 & ~bit5;
        'preprobe', ~bit1 & bit2 & bit3 & bit4 & ~bit5;
        'probe', ~bit1 & ~bit2 & ~bit3 & ~bit4 & bit5;
        'extra_probe', bit1 & bit2 & bit3 & bit4 & ~bit5;
    };

    % Find event times for each event type
    eventTimes = cell(1, length(eventTypes));
    for i = 1:length(eventTypes)
        eventTimes{i} = find(diff([0; eventTypes{i, 2}]) == 1);
    end
    eventIds = [];
    for iEvent = 1:length(eventTimes)
        eventIds = [eventIds repmat(iEvent,1,length(eventTimes{iEvent}))];
    end

    

    % Remove non-consecutive word events (only for words 1-12)
    allEvents = cell2mat(eventTimes(1:16)');
    [sortedEvents, sortIndex] = sort(allEvents);
    
    % Sort the event IDs using the same sorting index
    sortedEventIds = [eventIds(sortIndex) ];

       % Calculate the difference between consecutive sorted event IDs
    diffSortIds = [diff(sortedEventIds) 0];  % Add a 0 at the end to maintain length
    diffSortIdsFlip = [0 fliplr([diff(fliplr(sortedEventIds))])];  % Add a 0 at the beginning to maintain length
    
    % Find indices where diffSortIds is either 1 or -13, or diffSortIdsFlip is -1 or 13
    validIndices = find((diffSortIds == 1 | diffSortIds == -15) | ...
                        (diffSortIdsFlip == -1 | diffSortIdsFlip == 15));
    
    % Filter the events and event IDs
    filteredEvents = sortedEvents(validIndices);
    filteredEventIds = sortedEventIds(validIndices);

   


    % Reorganize filtered events into a cell array
    numEventTypes = length(eventTypes);
    filteredEventTimes = cell(1, numEventTypes);

    % Add filtered word events (1-12)
    for i = 1:16
        filteredEventTimes{i} = filteredEvents(filteredEventIds == i);
    end

    % Check if lengths of filteredEventTimes are multiples of 40
    lengths = cellfun(@length, filteredEventTimes);
    if any(mod(lengths, 40) ~= 0)
        % Plot extracted events
        allExtractedEvents = sort(cell2mat(filteredEventTimes'));
        figure;
        hold on;
        colors = lines(length(filteredEventTimes));
        for i = 1:length(filteredEventTimes)
            stem(filteredEventTimes{i}, i * ones(length(filteredEventTimes{i}), 1), 'Color', colors(i, :), 'DisplayName', eventTypes{i, 1});
        end
        xlabel('Sample Index');
        ylabel('Event Occurrence');
        title('Stem Plot of Extracted Events');
        grid on;

        % Ask user for exclusion periods
        disp('The lengths of filteredEventTimes are not multiples of 40.');
        disp('Please provide exclusion periods as a matrix [start1 end1; start2 end2; ...]:');
        exclusionPeriods = input('Exclusion periods: ');

        % Apply exclusions
        for i = 1:size(exclusionPeriods, 1)
            startIdx = exclusionPeriods(i, 1);
            endIdx = exclusionPeriods(i, 2);
            for j = 1:length(filteredEventTimes)
                filteredEventTimes{j} = filteredEventTimes{j}(~(filteredEventTimes{j} >= startIdx & filteredEventTimes{j} <= endIdx));
            end
        end

        % Rerun analysis after exclusions
        lengths = cellfun(@length, filteredEventTimes);
    end

    % Ensure all lengths are now multiples of 40
    if any(mod(lengths, 40) ~= 0)
        error('Filtered event times still do not satisfy the multiple-of-40 condition after exclusions.');
    end
    
    
    % Plot events
    figure;
    hold on;
    colors = lines(numEventTypes);
    for i = 1:numEventTypes
        stem(eventTimes{i}, i * ones(length(eventTimes{i}), 1), 'Color', colors(i, :), 'DisplayName', eventTypes{i, 1});
    end
    xlabel('Sample Index');
    ylabel('Event Type');
    title('Extracted Trigger Events');
    legend('show', 'Location', 'eastoutside');
    ylim([0, numEventTypes + 1]);
    hold off;
    

    % Plot events
    figure;
    hold on;
    colors = lines(numEventTypes);
    for i = 1:numEventTypes
        stem(filteredEventTimes{i}, i * ones(length(filteredEventTimes{i}), 1), 'Color', colors(i, :), 'DisplayName', eventTypes{i, 1});
    end
    xlabel('Sample Index');
    ylabel('Event Type');
    title('Filtered Trigger Events');
    legend('show', 'Location', 'eastoutside');
    ylim([0, numEventTypes + 1]);
    hold off;
end
