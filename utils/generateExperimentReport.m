function generateExperimentReport(obj, reportName)
     % Create the crunched folder if it doesn't exist
    crunchedFolder = fullfile(obj.crunched_file_path);
    if ~exist(crunchedFolder, 'dir')
        mkdir(crunchedFolder);
    end

    % Create a new PDF file in the crunched folder
    pdfFileName = fullfile(crunchedFolder, [reportName '.pdf']);
    if exist(pdfFileName, 'file')
        delete(pdfFileName);
    end

    % Start the PDF document with proper title page
    import mlreportgen.report.*
    import mlreportgen.dom.*

    tempFolder = tempdir;
    
    % Create report object with title page
    rpt = Report(pdfFileName, 'pdf');
    
    % Add title page
    tp = TitlePage();
    tp.Title = 'Experiment Results Report';
    tp.Subtitle = 'Neural Data Analysis';
    tp.Author = input('Enter author name: ', 's');

    tp.PubDate = datestr(now, 'dd-mmm-yyyy');
    add(rpt, tp);

    % General Experiment Information
    add(rpt, Heading1('General Experiment Information'));
    
    

    if(sum(contains(obj.elec_ch_type, 'seeg')))
        if(isfield(obj.stats.time_series,'pSigChan_bip'))
                infoTable = {
                'Subject Name', obj.subject;
                'Experiment Name', obj.experiment;
                'Total Trials Completed', num2str(size(obj.events_table,1));
                'Total Electrodes Implanted', num2str(length(obj.elec_ch_label));
                'Total SEEG Electrodes', num2str(sum(contains(obj.elec_ch_type, 'seeg')));
                'Total ECoG Grid Electrodes', num2str(sum(contains(obj.elec_ch_type, 'ecog_grd')));
                 'Total ECoG Strip Electrodes', num2str(sum(contains(obj.elec_ch_type, 'ecog_strip')));
                'Unipolar Contacts', num2str(length(obj.elec_ch_valid));
                'Bipolar Contacts', num2str(length(obj.bip_ch_label));
                 'Significant Unipolar Electrodes (High Gamma)', num2str(sum(cellfun(@(x) any(x.h_sig_05), obj.stats.time_series.pSigChan)));
                 'Significant Bipolar Electrodes (High Gamma)', num2str(sum(cellfun(@(x) any(x.h_sig_05), obj.stats.time_series.pSigChan_bip)));
            };

        else

            infoTable = {
                'Subject Name', obj.subject;
                'Experiment Name', obj.experiment;
                'Total Trials Completed', num2str(size(obj.events_table,1));
                'Total Electrodes Implanted', num2str(length(obj.elec_ch_label));
                'Total SEEG Electrodes', num2str(sum(contains(obj.elec_ch_type, 'seeg')));
                'Total ECoG Grid Electrodes', num2str(sum(contains(obj.elec_ch_type, 'ecog_grd')));
                 'Total ECoG Strip Electrodes', num2str(sum(contains(obj.elec_ch_type, 'ecog_strip')));
                'Unipolar Contacts', num2str(length(obj.elec_ch_valid));
                'Bipolar Contacts', num2str(length(obj.bip_ch_label));
                 'Significant Unipolar Electrodes (High Gamma)', num2str(sum(cellfun(@(x) any(x.h_sig_05), obj.stats.time_series.pSigChan)));                
            };

        end
    else
    infoTable = {
        'Subject Name', obj.subject;
        'Experiment Name', obj.experiment;
        'Total Trials Completed', num2str(size(obj.events_table,1));
        'Total Electrodes Implanted', num2str(length(obj.elec_ch_label));
        'Total SEEG Electrodes', num2str(sum(contains(obj.elec_ch_type, 'seeg')));
        'Total ECoG Grid Electrodes', num2str(sum(contains(obj.elec_ch_type, 'ecog_grd')));
         'Total ECoG Strip Electrodes', num2str(sum(contains(obj.elec_ch_type, 'ecog_strip')));
        'Unipolar Contacts', num2str(length(obj.elec_ch_valid));
        'Bipolar Contacts', num2str(length(obj.bip_ch_label));
         'Significant Unipolar Electrodes (High Gamma)', num2str(sum(cellfun(@(x) any(x.h_sig_05), obj.stats.time_series.pSigChan)));
           
    };
    
    end
    
    tbl = Table(infoTable);
    tbl.Style = {Border('solid'), ColSep('solid'), RowSep('solid')};
    tbl.TableEntriesStyle = {HAlign('left')};
    add(rpt, tbl);

   % Data Extraction
    acc = [obj.events_table.accuracy];
    rt = [obj.events_table.RT];
    cond = [obj.condition];

    % Performance Metrics
    add(rpt, Heading2('Performance Metrics'));

    % Overall Accuracy
    accuracy_percentage = mean(acc)*100;
    add(rpt, Paragraph(['Overall accuracy: ' num2str(accuracy_percentage, '%.1f') '%']));

    % Reaction Time Analysis
    rt_correct = rt(acc == 1);
    cond_correct = cond(acc == 1);

    switch obj.experiment

        case {'MITSentences'}
           
            mean_rt_all = mean(rt_correct, 'omitnan');
            mean_rt_low_surprisal = mean(rt_correct(strcmp(cond_correct, 'L')), 'omitnan');
            mean_rt_high_surprisal = mean(rt_correct(strcmp(cond_correct, 'H')), 'omitnan');
        
           %  % Results Table
           %  tableContent = {
           %      'Condition', 'Mean RT (ms)';
           %      'Overall', sprintf('%6.1f ± %.1f', mean_rt_all*1000, std(rt_correct)*1000);
           %      'Low Surprisal Trials (E)', sprintf('%6.1f ± %.1f', mean_rt_easy*1000, std(rt_correct(strcmp(cond_correct, 'sentence')))*1000);
           %      'Hard Trials (H)', sprintf('%6.1f ± %.1f', mean_rt_hard*1000, std(rt_correct(strcmp(cond_correct, 'nonword')))*1000)
           %  };
           %  tbl = Table(tableContent);
           %  tbl.Style = {Border('solid'), ColSep('solid'), RowSep('solid')};
           %  tbl.TableEntriesStyle = {HAlign('center')};
           %  add(rpt, tbl);
           % 
           %  % Reaction Time Distribution Plot
           %  add(rpt, Heading2('Reaction Time Distributions'));
           %  debugMode = false; % Set to true for debugging
           %  if debugMode
           %      f = figure('Visible', 'on', 'Position', [100 100 800 600]);
           %  else
           %      f = figure('Visible', 'off', 'Position', [100 100 800 600]);
           %  end
           %  subplot(1,2,1)
           %  histogram(rt_correct(strcmp(cond_correct, 'E'))*1000, 'BinWidth', 50)
           %  title('Easy Trials Condition RT Distribution')
           %  xlabel('Reaction Time (ms)')
           %  ylabel('Frequency')
           % 
           %  subplot(1,2,2)
           %  histogram(rt_correct(strcmp(cond_correct, 'H'))*1000, 'BinWidth', 50)
           %  title('Hard Trials Condition RT Distribution')
           %  xlabel('Reaction Time (ms)')
           %  ylabel('Frequency')
           % 
           % % Add the figure to the PDF
           %  imgObj = addImageToReport( tempFolder, f);
           % 
           %   % Add the image to the report
           %  add(rpt, imgObj);
           % 
           %  % Add a page break after the image
            % add(rpt, PageBreak());

            % High Gamma Plot Generation (All trials)
            add(rpt, Heading2('High Gamma Plots '));
            conditionImages = high_gamma_plot(obj);

            for i = 1:size(conditionImages, 1)
                 settingName = conditionImages{i, 1};
                 add(rpt, Chapter(settingName));

                 imageFiles = conditionImages{i,3};

                 for imgPathId = 1:length(imageFiles)
                    imgPath = imageFiles{imgPathId};
                    imgObj = Image(imgPath);
                    imgObj.Width = "6in";
                    imgObj.Height = "7in";
                    
                    add(rpt, imgObj);
                    add(rpt, PageBreak());
                end
                 
            end

        case {'SpatialWM'}
           
            mean_rt_all = mean(rt_correct, 'omitnan');
            mean_rt_easy = mean(rt_correct(strcmp(cond_correct, 'E')), 'omitnan');
            mean_rt_hard = mean(rt_correct(strcmp(cond_correct, 'H')), 'omitnan');
        
            % Results Table
            tableContent = {
                'Condition', 'Mean RT (ms)';
                'Overall', sprintf('%6.1f ± %.1f', mean_rt_all*1000, std(rt_correct)*1000);
                'Easy Trials (E)', sprintf('%6.1f ± %.1f', mean_rt_easy*1000, std(rt_correct(strcmp(cond_correct, 'sentence')))*1000);
                'Hard Trials (H)', sprintf('%6.1f ± %.1f', mean_rt_hard*1000, std(rt_correct(strcmp(cond_correct, 'nonword')))*1000)
            };
            tbl = Table(tableContent);
            tbl.Style = {Border('solid'), ColSep('solid'), RowSep('solid')};
            tbl.TableEntriesStyle = {HAlign('center')};
            add(rpt, tbl);
        
            % Reaction Time Distribution Plot
            add(rpt, Heading2('Reaction Time Distributions'));
            debugMode = false; % Set to true for debugging
            if debugMode
                f = figure('Visible', 'on', 'Position', [100 100 800 600]);
            else
                f = figure('Visible', 'off', 'Position', [100 100 800 600]);
            end
            subplot(1,2,1)
            histogram(rt_correct(strcmp(cond_correct, 'E'))*1000, 'BinWidth', 50)
            title('Easy Trials Condition RT Distribution')
            xlabel('Reaction Time (ms)')
            ylabel('Frequency')
        
            subplot(1,2,2)
            histogram(rt_correct(strcmp(cond_correct, 'H'))*1000, 'BinWidth', 50)
            title('Hard Trials Condition RT Distribution')
            xlabel('Reaction Time (ms)')
            ylabel('Frequency')
        
           % Add the figure to the PDF
            imgObj = addImageToReport( tempFolder, f);

             % Add the image to the report
            add(rpt, imgObj);
            
            % Add a page break after the image
            add(rpt, PageBreak());

            % High Gamma Plot Generation (All trials)
            add(rpt, Heading2('High Gamma Plots '));
            conditionImages = high_gamma_plot(obj);

            for i = 1:size(conditionImages, 1)
                 settingName = conditionImages{i, 1};
                 add(rpt, Chapter(settingName));

                 imageFiles = conditionImages{i,3};

                 for imgPathId = 1:length(imageFiles)
                    imgPath = imageFiles{imgPathId};
                    imgObj = Image(imgPath);
                    imgObj.Width = "6in";
                    imgObj.Height = "7in";
                    
                    add(rpt, imgObj);
                    add(rpt, PageBreak());
                end
                 
            end

        case {'LangLocVisual','LangLoc','MITLangloc'}
           
            mean_rt_all = mean(rt_correct, 'omitnan');
            mean_rt_sentence = mean(rt_correct(strcmp(cond_correct, 'sentence')), 'omitnan');
            mean_rt_nonword = mean(rt_correct(strcmp(cond_correct, 'nonword')), 'omitnan');
        
            % Results Table
            tableContent = {
                'Condition', 'Mean RT (ms)';
                'Overall', sprintf('%6.1f ± %.1f', mean_rt_all*1000, std(rt_correct)*1000);
                'Sentence (S)', sprintf('%6.1f ± %.1f', mean_rt_sentence*1000, std(rt_correct(strcmp(cond_correct, 'sentence')))*1000);
                'Nonword (N)', sprintf('%6.1f ± %.1f', mean_rt_nonword*1000, std(rt_correct(strcmp(cond_correct, 'nonword')))*1000)
            };
            tbl = Table(tableContent);
            tbl.Style = {Border('solid'), ColSep('solid'), RowSep('solid')};
            tbl.TableEntriesStyle = {HAlign('center')};
            add(rpt, tbl);
        
            % Reaction Time Distribution Plot
            add(rpt, Heading2('Reaction Time Distributions'));
            debugMode = false; % Set to true for debugging
            if debugMode
                f = figure('Visible', 'on', 'Position', [100 100 800 600]);
            else
                f = figure('Visible', 'off', 'Position', [100 100 800 600]);
            end
            subplot(1,2,1)
            histogram(rt_correct(strcmp(cond_correct, 'sentence'))*1000, 'BinWidth', 50)
            title('Sentence Condition RT Distribution')
            xlabel('Reaction Time (ms)')
            ylabel('Frequency')
        
            subplot(1,2,2)
            histogram(rt_correct(strcmp(cond_correct, 'nonword'))*1000, 'BinWidth', 50)
            title('Nonword Condition RT Distribution')
            xlabel('Reaction Time (ms)')
            ylabel('Frequency')
        
            % Add the figure to the PDF
            imgObj = addImageToReport( tempFolder, f);

             % Add the image to the report
            add(rpt, imgObj);
            
            % Add a page break after the image
            add(rpt, PageBreak());

            % High Gamma Plot Generation (All trials)
            add(rpt, Heading2('High Gamma Plots '));
            conditionImages = high_gamma_plot(obj);

            for i = 1:size(conditionImages, 1)
                 settingName = conditionImages{i, 1};
                 add(rpt, Chapter(settingName));

                 imageFiles = conditionImages{i,3};

                 for imgPathId = 1:length(imageFiles)
                    imgPath = imageFiles{imgPathId};
                    imgObj = Image(imgPath);
                    imgObj.Width = "6in";
                    imgObj.Height = "7in";
                    
                    add(rpt, imgObj);
                    add(rpt, PageBreak());
                end
                 
            end

            

            
        case {'LangLocAudio','LangLocAudio-2'}

            mean_rt_all = mean(rt_correct, 'omitnan');
            mean_rt_sentence = mean(rt_correct(strcmp(cond_correct, 'sentence')), 'omitnan');
            mean_rt_nonword = mean(rt_correct(strcmp(cond_correct, 'nonword')), 'omitnan');
        
            % Results Table
            tableContent = {
                'Condition', 'Mean RT (ms)';
                'Overall', sprintf('%6.1f ± %.1f', mean_rt_all*1000, std(rt_correct)*1000);
                'Sentence (S)', sprintf('%6.1f ± %.1f', mean_rt_sentence*1000, std(rt_correct(strcmp(cond_correct, 'sentence')))*1000);
                'Nonword (N)', sprintf('%6.1f ± %.1f', mean_rt_nonword*1000, std(rt_correct(strcmp(cond_correct, 'nonword')))*1000)
            };
            tbl = Table(tableContent);
            tbl.Style = {Border('solid'), ColSep('solid'), RowSep('solid')};
            tbl.TableEntriesStyle = {HAlign('center')};
            add(rpt, tbl);
        
            % Reaction Time Distribution Plot
            add(rpt, Heading2('Reaction Time Distributions'));
            debugMode = false; % Set to true for debugging
            if debugMode
                f = figure('Visible', 'on', 'Position', [100 100 800 600]);
            else
                f = figure('Visible', 'off', 'Position', [100 100 800 600]);
            end
            subplot(1,2,1)
            histogram(rt_correct(strcmp(cond_correct, 'sentence'))*1000, 'BinWidth', 50)
            title('Sentence Condition RT Distribution')
            xlabel('Reaction Time (ms)')
            ylabel('Frequency')
        
            subplot(1,2,2)
            histogram(rt_correct(strcmp(cond_correct, 'nonword'))*1000, 'BinWidth', 50)
            title('Nonword Condition RT Distribution')
            xlabel('Reaction Time (ms)')
            ylabel('Frequency')
        
            % Add the figure to the PDF
            imgObj = addImageToReport( tempFolder, f);

             % Add the image to the report
            add(rpt, imgObj);
            
            % Add a page break after the image
            add(rpt, PageBreak());
        
            % Audio Duration Histogram
            add(rpt, Heading2('Audio Duration Distribution'));
            f = figure('Visible', 'off', 'Position', [100 100 800 600]);
            audioDur=obj.events_table.audio_ended_natus-obj.events_table.audio_onset_natus;
            sentence_durations = audioDur(strcmp(obj.condition, 'sentence'));
            nonword_durations = audioDur(strcmp(obj.condition, 'nonword'));
            size(sentence_durations)
            subplot(1,2,1)
            histogram(sentence_durations, 'BinWidth', 0.1)
            title('Sentence Audio Duration Distribution')
            xlabel('Duration (s)')
            ylabel('Frequency')
            
        
            subplot(1,2,2)
            histogram(nonword_durations, 'BinWidth', 0.1)
            title('Nonword Audio Duration Distribution')
            xlabel('Duration (s)')
            ylabel('Frequency')
            
        
            % Add the figure to the PDF
            imgObj = addImageToReport( tempFolder, f);

             % Add the image to the report
            add(rpt, imgObj);
            
            % Add a page break after the image
            add(rpt, PageBreak());
        
            % High Gamma Plot Generation (All trials)
            % conds.A = find(strcmp(obj.condition, 'sentence'));
            % conds.B = find(strcmp(obj.condition, 'nonword'));
           add(rpt, Heading2('High Gamma Plots '));
            conditionImages = high_gamma_plot_word_boundaries(obj);

            for i = 1:size(conditionImages, 1)
                 settingName = conditionImages{i, 1};
                 add(rpt, Chapter(settingName));

                 imageFiles = conditionImages{i,3};

                 for imgPathId = 1:length(imageFiles)
                    imgPath = imageFiles{imgPathId};
                    imgObj = Image(imgPath);
                    imgObj.Width = "6in";
                    imgObj.Height = "7in";
                    
                    add(rpt, imgObj);
                    add(rpt, PageBreak());
                end
                 
            end
        
        case {'MITConstituentBounds'}
            mean_rt_all = mean(rt_correct, 'omitnan');
            mean_rt_1end = mean(rt_correct(strcmp(cond_correct, 'onebound_end')), 'omitnan');
            mean_rt_29end = mean(rt_correct(strcmp(cond_correct, 'twobound_9end')), 'omitnan');
            mean_rt_347end = mean(rt_correct(strcmp(cond_correct, 'threebound_47end')), 'omitnan');
            mean_rt_358end = mean(rt_correct(strcmp(cond_correct, 'threebound_58end')), 'omitnan');
            % Results Table
            tableContent = {
                'Condition', 'Mean RT (ms)';
                'Overall', sprintf('%6.1f ± %.1f', mean_rt_all*1000, std(rt_correct)*1000);
                'One Bound End', sprintf('%6.1f ± %.1f', mean_rt_1end*1000, std(rt_correct(strcmp(cond_correct, 'onebound_end')))*1000);
                'Two Bound 9 End', sprintf('%6.1f ± %.1f', mean_rt_29end*1000, std(rt_correct(strcmp(cond_correct, 'twobound_9end')))*1000);
                'Three Bound 47 End', sprintf('%6.1f ± %.1f', mean_rt_347end*1000, std(rt_correct(strcmp(cond_correct, 'threebound_47end')))*1000);
                'Three Bound 58 End', sprintf('%6.1f ± %.1f', mean_rt_358end*1000, std(rt_correct(strcmp(cond_correct, 'threebound_58end')))*1000);
            };
            tbl = Table(tableContent);
            tbl.Style = {Border('solid'), ColSep('solid'), RowSep('solid')};
            tbl.TableEntriesStyle = {HAlign('center')};
            add(rpt, tbl);
        
            % Reaction Time Distribution Plot
            add(rpt, Heading2('Reaction Time Distributions'));
            debugMode = false; % Set to true for debugging
            if debugMode
                f = figure('Visible', 'on', 'Position', [100 100 800 600]);
            else
                f = figure('Visible', 'off', 'Position', [100 100 800 600]);
            end
            subplot(2,2,1)
            histogram(rt_correct(strcmp(cond_correct, 'onebound_end'))*1000, 'BinWidth', 50)
            title('One Bound End Condition RT Distribution')
            xlabel('Reaction Time (ms)')
            ylabel('Frequency')
        
            subplot(2,2,2)
            histogram(rt_correct(strcmp(cond_correct, 'twobound_9end'))*1000, 'BinWidth', 50)
            title('Two Bound 9 End Condition RT Distribution')
            xlabel('Reaction Time (ms)')
            ylabel('Frequency')

            subplot(2,2,3)
            histogram(rt_correct(strcmp(cond_correct, 'threebound_47end'))*1000, 'BinWidth', 50)
            title('Three Bound 47 End Condition RT Distribution')
            xlabel('Reaction Time (ms)')
            ylabel('Frequency')


            subplot(2,2,4)
            histogram(rt_correct(strcmp(cond_correct, 'threebound_58end'))*1000, 'BinWidth', 50)
            title('Three Bound 58 End Condition RT Distribution')
            xlabel('Reaction Time (ms)')
            ylabel('Frequency')
        
            % Add the figure to the PDF
            imgObj = addImageToReport( tempFolder, f);

             % Add the image to the report
            add(rpt, imgObj);
            
            % Add a page break after the image
            add(rpt, PageBreak());

            % High Gamma Plot Generation (All trials)
            % conds.A = find(strcmp(obj.condition, 'H'));
            % conds.B = find(strcmp(obj.condition, 'E'));
            add(rpt, Heading2('High Gamma Plots '));
            conditionImages = high_gamma_plot(obj);

            for i = 1:size(conditionImages, 1)
                 settingName = conditionImages{i, 1};
                 add(rpt, Chapter(settingName));

                 imageFiles = conditionImages{i,3};

                 for imgPathId = 1:length(imageFiles)
                     imgPath = imageFiles{imgPathId};
                     imgObj = Image(imgPath);
                     imgObj.Width = "6in";
                     imgObj.Height = "7in";
                     
                     add(rpt, imgObj);
                     add(rpt, PageBreak());
                 end

            end

            % Inside the switch statement
            case 'MITNLengthSentences'
                % Extract unique conditions
                condLabels = unique(obj.condition);
                
                % Initialize table for results
                tableContent = {};
                
                % Perform contrast analysis for each condition
                for iCond = 1:length(condLabels)
                    condName = condLabels{iCond};
                    
                    % Find trials for intact and scrambled versions
                    intactTrials = find(contains(obj.condition,  '_intact'));
                    scrambledTrials = find(contains(obj.condition,  '_scrambled'));
                    
                    if ~isempty(intactTrials) && ~isempty(scrambledTrials)
                        % Calculate mean RT for intact and scrambled conditions
                        rt_intact = mean(rt(intactTrials));
                        rt_scrambled = mean(rt(scrambledTrials));
                        
                        % Add to results table
                        tableContent{end+1,1} = condName;
                        tableContent{end,2} = sprintf('%6.1f ± %.1f', rt_intact*1000, std(rt(intactTrials))*1000);
                        tableContent{end,3} = sprintf('%6.1f ± %.1f', rt_scrambled*1000, std(rt(scrambledTrials))*1000);
                    end
                end
                
                % Create table for results
                if ~isempty(tableContent)
                    tbl = Table(tableContent);
                    tbl.Style = {Border('solid'), ColSep('solid'), RowSep('solid')};
                    tbl.TableEntriesStyle = {HAlign('center')};
                    add(rpt, tbl);
                else
                    add(rpt, Paragraph('No valid conditions found for contrast analysis.'));
                end
                
                % High Gamma Plot Generation
                add(rpt, Heading2('High Gamma Plots '));
                conditionImages = high_gamma_plot(obj);
                
                for i = 1:size(conditionImages, 1)
                    settingName = conditionImages{i, 1};
                    add(rpt, Chapter(settingName));
                    
                    imageFiles = conditionImages{i,3};
                    
                    for imgPathId = 1:length(imageFiles)
                        imgPath = imageFiles{imgPathId};
                        imgObj = Image(imgPath);
                        imgObj.Width = "6in";
                        imgObj.Height = "7in";
                        
                        add(rpt, imgObj);
                        add(rpt, PageBreak());
                    end
                    deleteTemporaryFiles(imageFiles);
                end

           
    end

           

     % Add summary report of significant channels
    add(rpt, Chapter('Summary of Significant Channels'));
    
    % Unipolar channels
    add(rpt, Heading2('Unipolar Channels with Significant Time Clusters'));
    sigUnipolarChannels = find(cellfun(@(x) any(x.h_sig_05), obj.stats.time_series.pSigChan));
    if ~isempty(sigUnipolarChannels)
        unipolarList = cell(length(sigUnipolarChannels), 1);
        for i = 1:length(sigUnipolarChannels)
            unipolarList{i} = obj.elec_ch_label{sigUnipolarChannels(i)};
        end
        add(rpt, UnorderedList(unipolarList));
    else
        add(rpt, Paragraph('No significant unipolar channels found.'));
    end
    
    % Bipolar channels
    if(isfield(obj.stats.time_series,'pSigChan_bip'))
        add(rpt, Heading2('Bipolar Channels with Significant Time Clusters'));
        sigBipolarChannels = find(cellfun(@(x) any(x.h_sig_05), obj.stats.time_series.pSigChan_bip));
        if ~isempty(sigBipolarChannels)
            bipolarList = cell(length(sigBipolarChannels), 1);
            for i = 1:length(sigBipolarChannels)
                bipolarList{i} = obj.bip_ch_label{sigBipolarChannels(i)};
            end
            add(rpt, UnorderedList(bipolarList));
        else
            add(rpt, Paragraph('No significant bipolar channels found.'));
        end
    end

    % Close the PDF document   
    
    try
        close(rpt);
    catch ME
        % Handle the error gracefully
        fprintf('Error closing the report: %s\n', ME.message);
        % Attempt to close the report again
        try
            close(rpt);
        catch ME2
            fprintf('Failed to close the report again: %s\n', ME2.message);
        end
    end


    % Save the updated object in the crunched folder
    saveUpdatedObject(obj);

    
   
end

function conditionImages = high_gamma_plot(obj)
    import mlreportgen.report.*
    import mlreportgen.dom.*

    % Temporary folder for saving images
    tempFolder = tempdir; % Get system temporary folder path

    acc = [obj.events_table.accuracy];
    numTrials = length(obj.condition);
    conditionIds = obj.condition;
    condLabels = unique(obj.condition); % Extract unique condition labels

    % Define settings for each experiment
    conditionImages = {
        'All Trials', 1:numTrials;
    };
    
    accurateTrials = find(acc == 1);
    if ~isempty(accurateTrials)
        conditionImages(end+1, :) = {'Accurate Trials', accurateTrials};
    end


    % Data epoching
    epochTimeRange = [-0.5 2.5];
    [epochData, epochData_bip] = obj.extract_trial_epochs('epoch_tw', epochTimeRange, 'selectChannels', obj.elec_ch_clean);

   
    for i = 1:size(conditionImages, 1)
        settingName = conditionImages{i, 1};
        trials2include = conditionImages{i, 2};

        

         % Process each setting
          imageFiles = {}; % Store image file paths for cleanup later

        %add(rpt, Chapter(['High Gamma Plots: ' settingName]));

        % Determine experiment type and handle conditions dynamically
        if contains(obj.experiment, {'LangLoc', 'LangLocVisual', 'LangLocAudio'})
            % For LangLoc experiments: Use Sentence ('S') and Nonword ('N') conditions
            specifiedConditions = {'sentence', 'nonword'};
        elseif contains(obj.experiment, 'MITLangloc')
            % For SpatialWM experiments: Use Hard Trials ('H') and Easy Trials ('E') conditions
            specifiedConditions = {'Sentences', 'Jabberwocky'};
        elseif contains(obj.experiment, 'SpatialWM')
            % For SpatialWM experiments: Use Hard Trials ('H') and Easy Trials ('E') conditions
            specifiedConditions = {'H', 'E'};
        elseif contains(obj.experiment, 'MITSentences')
            % For MITSentences experiments: Use High Surprisal ('H') and Low Surprisal ('L') conditions
            specifiedConditions = {'H', 'L'};
        elseif contains(obj.experiment, 'MITNLengthSentences')
        % For MITNLengthSentences: Use unique conditions with intact/scrambled contrast
            
            specifiedConditions = {'1sent_24words','3sents_8words','6sents_4words'};
        else
            % For multi-condition experiments like MITConstituentBounds, use all conditions
            specifiedConditions = condLabels;
        end

       
        unipolarImages = process_and_save_images(obj, epochData,conditionIds, trials2include, 'unipolar', obj.elec_ch_label(obj.elec_ch_valid), epochTimeRange, specifiedConditions, tempFolder, settingName);
        imageFiles = [imageFiles unipolarImages]; % Append image file paths
        

        % Process bipolar data
        if ~isempty(epochData_bip)
            %add(rpt, Chapter('Bipolar Data'));
            bipolarImages = process_and_save_images(obj, epochData_bip,conditionIds, trials2include, 'bipolar', obj.bip_ch_label, epochTimeRange, specifiedConditions, tempFolder, settingName);
            imageFiles = [imageFiles bipolarImages]; % Append image file paths         
        end

        conditionImages{i,3} = imageFiles;

    end

    % % Delete all temporary image files after the report is saved
    % deleteTemporaryFiles(imageFiles);
end

function imageFiles = process_and_save_images(obj, data, conds, trials2include, data_type, chanLab, epochTimeRange, conditions, tempFolder, settingName)
    duration = size(data, 3);
    x = linspace(epochTimeRange(1), epochTimeRange(2), duration);

    data2process = data(:,trials2include,:);
    conds2process = conds(trials2include);
    
    numChan = 10; % Number of channels to plot per figure
    totChanBlock = ceil(size(data2process, 1) / numChan);

    colors = lines(numel(conditions)); % Generate distinct colors for each condition

    imageFiles = {}; % Initialize list of saved images

    assert(size(data2process,2)==length(conds2process),'Uneven trial length');
    
    % Initialize pSig cell array
    pSig = cell(1, size(data2process, 1));
    
    % Determine experiment type and handle conditions dynamically
    if contains(obj.experiment, 'MITNLengthSentences')
        % Special handling for MITNLengthSentences
        % Group trials by base condition (without _intact/_scrambled)
        base_conditions = unique(regexprep(conds2process, '_intact|_scrambled', '', 'ignorecase'));
        
        % For each channel, perform timePermCluster for each base condition
        % pSig will be a struct: pSig{iChan}(base_condition) = result
        pSig = {};
        
        parfor iChan = 1:size(data2process, 1)
           
            for iCondIdx = 1:length(base_conditions)
                base_cond = base_conditions{iCondIdx};
                intactTrials = find(strcmp(conds2process, [base_cond '_intact']));
                scrambledTrials = find(strcmp(conds2process, [base_cond '_scrambled']));
                
                if ~isempty(intactTrials) && ~isempty(scrambledTrials)
                    intactData = squeeze(data2process(iChan, intactTrials, :));
                    scrambledData = squeeze(data2process(iChan, scrambledTrials, :));
                    
                    % Perform timePermCluster test
                    pSig{iChan}{iCondIdx} = timePermCluster(intactData, scrambledData, 'numTail', 1);
                end
            end
        end
        
        % Plotting for MITNLengthSentences
        for iF = 0:totChanBlock-1
            
            
            for iChan = 1:min(numChan, size(data2process, 1) - iF*numChan)
                iChan2 = iF*numChan + iChan;

                if strcmp(data_type, 'unipolar')
                    sigTime = x(obj.stats.time_series.pSigChan{iChan2}.h_sig_05 == 1);
                else
                    sigTime = x(obj.stats.time_series.pSigChan_bip{iChan2}.h_sig_05 == 1);
                end

                f = figure('Visible', 'off', 'Position', [100 100 1000 1200], 'Renderer', 'painters');

                
                for iCondIdx = 1:length(base_conditions)
                    base_cond = base_conditions{iCondIdx};
                    intactTrials = find(strcmp(conds2process, [base_cond '_intact']));
                    scrambledTrials = find(strcmp(conds2process, [base_cond '_scrambled']));
                    
                    if ~isempty(intactTrials) && ~isempty(scrambledTrials)
                        intactData = squeeze(data2process(iChan2, intactTrials, :));
                        scrambledData = squeeze(data2process(iChan2, scrambledTrials, :));
                        
                        % Plot mean and SEM
                        intactMean = nanmean(intactData, 1);
                        scrambledMean = nanmean(scrambledData, 1);
                        intactSEM = nanstd(intactData, 0, 1) / sqrt(size(intactData, 1));
                        scrambledSEM = nanstd(scrambledData, 0, 1) / sqrt(size(scrambledData, 1));
                        
                        subplot(length(base_conditions), 1, iCondIdx);
                        hold on;
                        patch([x fliplr(x)], [intactMean+intactSEM fliplr(intactMean-intactSEM)], ...
                              'b', 'FaceAlpha', 0.3, 'EdgeColor', 'none');
                        plot(x, intactMean, 'Color', 'b', 'LineWidth', 1);
                        patch([x fliplr(x)], [scrambledMean+scrambledSEM fliplr(scrambledMean-scrambledSEM)], ...
                              'r', 'FaceAlpha', 0.3, 'EdgeColor', 'none');
                        plot(x, scrambledMean, 'Color', 'r', 'LineWidth', 1);
                        title(base_cond, 'Interpreter', 'none');
                        title([chanLab{iChan2} '-' base_cond], 'Interpreter', 'none');
                        max_val_intact = max(intactMean+intactSEM);
                        max_val_scrambled = max(scrambledMean+scrambledSEM);
                    
                        % Determine overall max_val
                        max_val = max(max_val_intact, max_val_scrambled);
                    
                        % Set ylim
                        ylim([-1 max_val + 0.5]);
                    
                        % Set font size for axes
                        set(gca, 'FontSize', 10);

                        scatter(sigTime, -0.5 * ones(size(sigTime)), 10, 'k', 'filled'); % significant HG activations

                        % Plot significance markers
                        sigTimeCond = x(pSig{iChan}{iCondIdx}.h_sig_05 == 1);
        
                        scatter(sigTimeCond, -0.75 * ones(size(sigTimeCond)), 10, 'r', 'filled');
        
                        plot([epochTimeRange(1) epochTimeRange(2)], [0 0], 'k', 'LineWidth', 0.25);
                        hold off;

                         % After plotting all subplots for the figure 'f', create a separate axes for the legend
                    legendAxes = axes('Position', [0.1, 0.02, 0.8, 0.05], 'Visible', 'off');
                    
                    hold(legendAxes, 'on');
                    
                    % Dummy plots for legend entries
                    scatter(legendAxes, NaN, NaN, 30, 'k', 'filled'); % Black dots
                    scatter(legendAxes, NaN, NaN, 30, 'r', 'filled'); % Red dots
                    
                    % Use the same colors as your conditions for lines
                    numConditions = numel(conditions);
                    for iCondIdx = 1:2
                        plot(legendAxes, NaN, NaN, 'Color', colors(iCondIdx,:), 'LineWidth', 2);
                    end
                    
                    
        
                % Define legend labels based on experiment type
                legendLabels = cell(1, numConditions + 2); % +2 for HG activations and Contrast activations
                legendLabels{1} = 'Significant HG activations';
                legendLabels{2} = 'Significant Contrast activations';

                legendLabels{3} = 'Intact';
                legendLabels{4} = 'Scrambled';
                
                
                legend(legendAxes, legendLabels, ...
                       'Orientation', 'horizontal', 'Location', 'southoutside');
                
                hold(legendAxes, 'off');
                            end
                        end
                    end
                    
                    % Save figure
                    imageFileName = fullfile(tempFolder, sprintf('%s_%s_Block%d.png', data_type, obj.experiment, iF));
                    exportgraphics(f, imageFileName, 'Resolution',300); % Save figure as PNG file
                    imageFiles{end+1} = imageFileName; % Append to list of saved images
                    
                    close(f); % Close the figure to free memory
                end
        
        % Save pSig results
        if strcmp(data_type, 'unipolar')
            obj.stats.time_series.(['pSigChan_MITNLengthSentences_' strrep(settingName, ' ', '_')]) = pSig;
        else
            obj.stats.time_series.(['pSigChan_bip_MITNLengthSentences_' strrep(settingName, ' ', '_')]) = pSig;
        end
        
    else
        % Perform statistical analysis based on the number of conditions
        numConditions = numel(conditions);
        
        if numConditions == 2
            % Assign conditions based on user-specified order
            aCondition = conditions{1};
            bCondition = conditions{2};

            if (~ismember(aCondition, conds2process)) || (~ismember(bCondition, conds2process))
                error('Specified conditions "%s" and "%s" do not match available conditions.', aCondition, bCondition);
            end

            aTrialData = squeeze(data2process(:, ismember(conds2process, aCondition), :)); % Data for aCondition
            bTrialData = squeeze(data2process(:, ismember(conds2process, bCondition), :)); % Data for bCondition

            % Use timePermCluster for two conditions
            parfor iChan = 1:size(data2process, 1)
                aTrial = squeeze(aTrialData(iChan, :, :));
                bTrial = squeeze(bTrialData(iChan, :, :));
                pSig{iChan} = timePermCluster(squeeze(aTrialData(iChan, :, :)), squeeze(bTrialData(iChan, :, :)), 'numTail', 1);
            end
        else
            % Use timePermClusterMulti for more than two conditions
           parfor iChan = 1:size(data2process, 1)
               signalCell = [];
               for iCond = 1:length(conditions)
                   condtrials2include = ismember(conds2process,conditions{iCond});
                   signalCell{iCond} = squeeze(data2process(iChan, condtrials2include, :));
               end
                pSig{iChan} = timePermClusterMulti(signalCell); % Perform cluster statistics across conditions
           end
        end
        
        % Save pSig results
        if strcmp(data_type, 'unipolar')
            obj.stats.time_series.(['pSigChan_' strrep(settingName, ' ', '_')]) = pSig;
        else
            obj.stats.time_series.(['pSigChan_bip_' strrep(settingName, ' ', '_')]) = pSig;
        end
        
        % Plotting for other experiments
        for iF = 0:totChanBlock-1
            f = figure('Visible', 'off', 'Position', [100 100 1000 1200], 'Renderer', 'painters');
            
            numRows = 5; % Rows per figure
            numCols = 2; % Columns per figure

            for iChan = 1:min(numChan, size(data2process, 1) - iF*numChan)
                iChan2 = iF*numChan + iChan;

                subplot(numRows, numCols, iChan);
                hold on;

                row = floor((iChan - 1) / numCols) + 1;
                col = mod(iChan - 1, numCols) + 1;

                % Plot data for each condition
                for iCondIdx = 1:numel(conditions)
                    trialIndices = ismember(conds2process,conditions{iCondIdx});%conds.(conditions{iCondIdx});
                    trialData = squeeze(data2process(iChan2, trialIndices, :));
                    trialMean = nanmean(trialData, 1);
                    trialSEM = nanstd(trialData, 0, 1) / sqrt(size(trialData, 1));

                    patch([x fliplr(x)], [trialMean+trialSEM fliplr(trialMean-trialSEM)], ...
                          colors(iCondIdx,:), 'FaceAlpha', 0.3, 'EdgeColor', 'none');
                    plot(x, trialMean, 'Color', colors(iCondIdx,:), 'LineWidth', 1);
                    max_val_cond(iCondIdx) = max(trialMean + trialSEM);
                end

                 % Plot significance markers and horizontal line
                if strcmp(data_type, 'unipolar')
                    sigTime = x(obj.stats.time_series.pSigChan{iChan2}.h_sig_05 == 1);
                else
                    sigTime = x(obj.stats.time_series.pSigChan_bip{iChan2}.h_sig_05 == 1);
                end

                scatter(sigTime, -0.5 * ones(size(sigTime)), 10, 'k', 'filled'); % significant HG activations

                % Plot significance markers
                sigTimeCond = x(pSig{iChan2}.h_sig_05 == 1);

                scatter(sigTimeCond, -0.75 * ones(size(sigTimeCond)), 10, 'r', 'filled');

                plot([epochTimeRange(1) epochTimeRange(2)], [0 0], 'k', 'LineWidth', 0.25);

                % Add X-label only for the last row
                if row == numRows
                    xlabel('Time (s)');
                else
                    xlabel('');
                end

                % Add Y-label only for the first column
                if col == 1
                    ylabel('Z-score');
                else
                    ylabel('');
                end
                title(chanLab{iChan2},'Interpreter','none');
                max_val = max(max_val_cond);
        
                % Set ylim
                ylim([-1 max_val + 0.25]);
                yline(0, 'k-.')
                xlim(epochTimeRange);

                

                hold off;
            end

            % After plotting all subplots for the figure 'f', create a separate axes for the legend
            legendAxes = axes('Position', [0.1, 0.02, 0.8, 0.05], 'Visible', 'off');
            
            hold(legendAxes, 'on');
            
            % Dummy plots for legend entries
            scatter(legendAxes, NaN, NaN, 30, 'k', 'filled'); % Black dots
            scatter(legendAxes, NaN, NaN, 30, 'r', 'filled'); % Red dots
            
            % Use the same colors as your conditions for lines
            numConditions = numel(conditions);
            for iCondIdx = 1:numConditions
                plot(legendAxes, NaN, NaN, 'Color', colors(iCondIdx,:), 'LineWidth', 2);
            end
            
            

        % Define legend labels based on experiment type
        legendLabels = cell(1, numConditions + 2); % +2 for HG activations and Contrast activations
        legendLabels{1} = 'Significant HG activations';
        legendLabels{2} = 'Significant Contrast activations';
        
        for iCondIdx = 1:numConditions
            legendLabels{iCondIdx + 2} = conditions{iCondIdx};
        end
        
        legend(legendAxes, legendLabels, ...
               'Orientation', 'horizontal', 'Location', 'southoutside');
        
        hold(legendAxes, 'off');


        % Save the figure as an image file in the temporary folder
        imageFileName = fullfile(tempFolder, sprintf('%s_%s_Block%d.png', data_type, obj.experiment, iF));
        exportgraphics(f, imageFileName, 'Resolution',330); % Save figure as PNG file
        imageFiles{end+1} = imageFileName; % Append to list of saved images
        
        close(f); % Close the figure to free memory
    end
    end
end

function deleteTemporaryFiles(imageFiles)
    for iFile = 1:numel(imageFiles)
        delete(imageFiles{iFile}); % Delete each temporary file
    end
end


function saveUpdatedObject(obj)
    % Create the crunched folder if it doesn't exist
    crunchedFolder = fullfile(obj.crunched_file_path);
    if ~exist(crunchedFolder, 'dir')
        mkdir(crunchedFolder);
    end

    % Generate the filename
    filename = fullfile(crunchedFolder, [obj.subject '_' obj.experiment '_crunched_HG_ZScore.mat']);

    % Save the object
    save(filename, 'obj', '-v7.3');
    
    fprintf('Updated object saved as: %s\n', filename);
end

function imgObj = addImageToReport(tempFolder, f)
    import mlreportgen.report.*
    import mlreportgen.dom.*

    % Generate the image file name
    imageFileName = fullfile(tempFolder, 'imageAdd.png');
    
    % Save the figure as a PNG file
    exportgraphics(f, imageFileName,'Resolution',300);
    
    % Create an Image object from the saved file
    imgObj = Image(imageFileName);
    imgObj.Width = "6in";
    imgObj.Height = "7in";
    
   
    
    % Close the figure to free up memory
    close(f);
end

function conditionImages = high_gamma_plot_word_boundaries(obj)
    import mlreportgen.report.*;
    import mlreportgen.dom.*;

    % Temporary folder for saving images
    tempFolder = tempdir; % Get system temporary folder path

    % Define settings for each experiment
    conditionImages = {
        'All Trials', 1:size(obj.trial_timing, 1);
    };

    % Data epoching
    epochTimeRange = [-0.5 0.5];
    numWords = 12;
    % Loop through each word position

    concatenatedEpochsSentence = [];
    concatenatedEpochsNonword = [];
    for wordPos = 1:numWords
        [epochData, epochData_bip] = obj.extract_trial_epochs('epoch_tw', epochTimeRange, 'probe_key', wordPos+1);

        % Extract sentence and nonword trials
        sentenceTrials = epochData(:, ismember(obj.condition, 'sentence'), :);
        nonwordTrials = epochData(:, ismember(obj.condition, 'nonword'), :);

        % Concatenate along time axis
        if isempty(concatenatedEpochsSentence)
            concatenatedEpochsSentence = sentenceTrials;
            concatenatedEpochsNonword = nonwordTrials;
        else
            concatenatedEpochsSentence = cat(3, concatenatedEpochsSentence, sentenceTrials);
            concatenatedEpochsNonword = cat(3, concatenatedEpochsNonword, nonwordTrials);
        end

        % Perform timePermCluster test for significance
        parfor iChan = 1:size(epochData,1)
            aTrialData = squeeze(epochData(iChan, ismember(obj.condition, 'sentence'), :));
            bTrialData = squeeze(epochData(iChan, ismember(obj.condition, 'nonword'), :));
            pSig{iChan, wordPos} = timePermCluster(aTrialData, bTrialData, 'numTail', 1);
        end

        % Perform timePermCluster test for bipolar data
        if ~isempty(epochData_bip)
            parfor iChan = 1:size(epochData_bip, 1)
                aTrialData = squeeze(epochData_bip(iChan, ismember(obj.condition, 'sentence'), :));
                bTrialData = squeeze(epochData_bip(iChan, ismember(obj.condition, 'nonword'), :));
                pSig_bip{iChan, wordPos} = timePermCluster(aTrialData, bTrialData, 'numTail', 1);
            end
        end
    end

    % Plot concatenated epochs
    timePointsPerWord = size(concatenatedEpochsSentence, 3) / numWords;
    totalTimePoints = timePointsPerWord * numWords;
    wordBoundaries = 0:timePointsPerWord:totalTimePoints;

    % Determine experiment type and handle conditions dynamically
    
        specifiedConditions = {'sentence', 'nonword'};
    

    % Initialize variables to store image files and conditions
    imageFiles = {};
    

    % Process and plot data for each condition
    for i = 1:size(conditionImages, 1)
        settingName = conditionImages{i, 1};
        trials2include = conditionImages{i, 2};

        % Process each setting
        imageFiles = {}; % Store image file paths for cleanup later

        % Unipolar data
        imageFiles_unipolar = process_and_save_images_word_boundaries(obj, concatenatedEpochsSentence, concatenatedEpochsNonword, ...
            pSig, wordBoundaries, timePointsPerWord, totalTimePoints, tempFolder, settingName, 'unipolar',obj.elec_ch_label);
        imageFiles = [imageFiles imageFiles_unipolar];

        % Bipolar data if available
        if ~isempty(epochData_bip)
            concatenatedEpochsSentence_bip = [];
            concatenatedEpochsNonword_bip = [];
            for wordPos = 1:numWords
                [~, epochData_bip] = obj.extract_trial_epochs('epoch_tw', epochTimeRange, 'probe_key', wordPos+1);
                sentenceTrials_bip = epochData_bip(:, ismember(obj.condition, 'sentence'), :);
                nonwordTrials_bip = epochData_bip(:, ismember(obj.condition, 'nonword'), :);

                if isempty(concatenatedEpochsSentence_bip)
                    concatenatedEpochsSentence_bip = sentenceTrials_bip;
                    concatenatedEpochsNonword_bip = nonwordTrials_bip;
                else
                    concatenatedEpochsSentence_bip = cat(3, concatenatedEpochsSentence_bip, sentenceTrials_bip);
                    concatenatedEpochsNonword_bip = cat(3, concatenatedEpochsNonword_bip, nonwordTrials_bip);
                end
            end

            imageFiles_bipolar = process_and_save_images_word_boundaries(obj, concatenatedEpochsSentence_bip, concatenatedEpochsNonword_bip, ...
                pSig_bip, wordBoundaries, timePointsPerWord, totalTimePoints, tempFolder, settingName, 'bipolar', obj.bip_ch_label);
            imageFiles = [imageFiles imageFiles_bipolar];
        end

        % Store image files for this setting
        conditionImages{end+1,1} = settingName;
        conditionImages{end,2} = trials2include;
        conditionImages{end,3} = imageFiles;
    end
end

function imageFiles = process_and_save_images_word_boundaries(obj,...
    dataSentence, dataNonword, pSig, wordBoundaries, timePointsPerWord,...
    totalTimePoints, tempFolder, settingName, dataType,chanLab)
    numChanBlock = 10; % Number of channels per figure
    totChanBlock = ceil(size(dataSentence, 1) / numChanBlock);

    imageFiles = {};
    colors = lines(2);
    for iChanBlock = 0:totChanBlock-1
        f = figure('Visible', 'off', 'Position', [100 100 1000 1200], 'Renderer', 'painters');

        for iChan = 1:min(numChanBlock, size(dataSentence, 1) - iChanBlock*numChanBlock)
            iChan2 = iChanBlock*numChanBlock + iChan;

            subplot(numChanBlock, 1, iChan);
            hold on;
            title( chanLab{iChan2}, 'Interpreter', 'none');

    % Calculate mean and SEM for each condition
    
            trialData = squeeze(dataSentence(iChan2, :, :));
            trialMean = nanmean(trialData, 1);
            trialSEM = nanstd(trialData, 0, 1) / sqrt(size(trialData, 1));
            max_val_sentence = max(trialMean + trialSEM);

            x = 1:totalTimePoints; % Time points for plotting

            % Patch for SEM
            patch([x fliplr(x)], [trialMean+trialSEM fliplr(trialMean-trialSEM)], ...
                  colors(1,:), 'FaceAlpha', 0.3, 'EdgeColor', 'none');

            % Plot mean
            plot(x, trialMean, 'Color', colors(1,:), 'LineWidth',1);

             trialData = squeeze(dataNonword(iChan2, :, :));
            trialMean = nanmean(trialData, 1);
            trialSEM = nanstd(trialData, 0, 1) / sqrt(size(trialData, 1));

            max_val_nonword = max(trialMean + trialSEM); 
            x = 1:totalTimePoints; % Time points for plotting

            % Patch for SEM
            patch([x fliplr(x)], [trialMean+trialSEM fliplr(trialMean-trialSEM)], ...
                  colors(2,:), 'FaceAlpha', 0.3, 'EdgeColor', 'none');


            % Plot mean
            plot(x, trialMean, 'Color', colors(2,:), 'LineWidth',1);

        

        % Add vertical dotted lines at word boundaries
        for boundary = wordBoundaries
            xline(boundary, 'k--');
        end

        % Set x-axis labels as word1, word2, ... between boundaries
        midPoints = (wordBoundaries(1:end-1) + wordBoundaries(2:end)) / 2;
        set(gca, 'XTick', midPoints, 'XTickLabel', arrayfun(@(x) sprintf('word%d', x), 1:size(dataSentence, 3)/timePointsPerWord, 'UniformOutput', false));

        % Plot significance markers
        sigTimePoints = [];
        for wordPos = 1:size(dataSentence, 3)/timePointsPerWord
            sigTimePoints = [sigTimePoints, find(pSig{iChan2, wordPos}.h_sig_05) + (wordPos-1)*timePointsPerWord];
        end
        scatter(sigTimePoints, -0.5*ones(size(sigTimePoints)), 10, 'r', 'filled');
        % Determine overall max_val
        max_val = max(max_val_sentence, max_val_nonword);
        
        % Set ylim
        ylim([-1 max_val + 0.5]);
        yline(0, 'k-.')

        
        hold off;
    end

        
    % After plotting all subplots for the figure 'f', create a separate axes for the legend
    legendAxes = axes('Position', [0.1, 0.02, 0.8, 0.05], 'Visible', 'off');
    
    hold(legendAxes, 'on');
    
    % Dummy plots for legend entries
   
    scatter(legendAxes, NaN, NaN, 30, 'r', 'filled'); % Red dots
    plot(legendAxes, NaN, NaN, 'Color', colors(1,:), 'LineWidth', 2);
    plot(legendAxes, NaN, NaN, 'Color', colors(2,:), 'LineWidth', 2);
    legendLabels{1} = 'Significant Contrast activations';
    legendLabels{2} = 'Sentences';
    legendLabels{3} = 'NonWords';


    legend(legendAxes, legendLabels, ...
           'Orientation', 'horizontal', 'Location', 'southoutside');

    hold(legendAxes, 'off');

    % Save the figure
    imageFileName = fullfile(tempFolder, sprintf('%s_%s_Block%d.png', dataType, obj.experiment, iChanBlock));
    exportgraphics(f, imageFileName, 'Resolution',300); % Save figure as PNG file
    imageFiles{end+1} = imageFileName; % Append to list of saved images

    % Close the figure to free memory
    close(f);
end
end
