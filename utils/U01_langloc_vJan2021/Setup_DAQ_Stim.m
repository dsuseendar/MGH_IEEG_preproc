function TrialStruct = Setup_DAQ_Stim( TrialStruct )
% Utility function to setup communication between the Cash Lab rig's
% parallel port and PsychToolbox.
% Depends on the "io64" MEX library.
% Also depends on you knowing where the parallel ports are in your machine.

if strcmp(getenv('COMPUTERNAME'),'PRESENTATION1')
    portAddress = hex2dec('2000'); % cashlap presentation laptop
    disp('I think Im doing triggers on the laptop');
elseif strcmp(getenv('COMPUTERNAME'),'SPIKEWAVE4')
    portAddress = hex2dec('C010'); % White rig
    disp('I think Im doing triggers on the white rig');
elseif strcmp(getenv('COMPUTERNAME'),'STORMTROOPER-PC') %stormtrooper
    portAddress = hex2dec('EFF8'); % stormtrooper
    disp('I think Im doing triggers on the Stormtrooper');  
elseif strcmp(getenv('COMPUTERNAME'),'ENTERPRISE-PC') %Enterprise
    portAddress = hex2dec('B010'); % Enterprise
    disp('I think Im doing triggers on the Enterprise');   
elseif strcmp(getenv('COMPUTERNAME'),'DESKTOP-VASDQ79') %Enterprise
    portAddress = hex2dec('D010'); % Enterprise
    disp('I think Im doing triggers on Streaky');    
elseif strcmp(getenv('COMPUTERNAME'),'PRESENTATION-4')
    portAddress = hex2dec('DFF8'); % Presentation 4 computer
    disp('I think Im doing triggers on the Presentation 4 computer');         
elseif exist(fullfile(getenv('USERPROFILE'), 'Documents', 'MATLAB', 'port.txt'), 'file') == 2  % get the port from a specified text file
    portFile = fullfile(getenv('USERPROFILE'), 'Documents', 'MATLAB', 'port.txt');
    portAddress = hex2dec(fileread(portFile));
    disp('Im gonna use the port specified in ~/Documents/port.text');
else
    portAddress = hex2dec('DCF8');   % Cashlab presentation LPT3;
    disp('I think Im doing triggers on the main rig');
end

% Initialize the io64 library.
portObj = io64;
portStatus = io64(portObj);

if portStatus > 0
    error(['Parallel port driver init failed with error ' num2str(portStatus)]);
end

% Zero the lines.
io64(portObj,portAddress,0);

% Save these in the trial struct.
TrialStruct.portObj = portObj;
TrialStruct.portAddress = portAddress;

