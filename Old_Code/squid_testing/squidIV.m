function [ptable, Vsquid] = squidIV()

clear all % MATLAB is complaining but this function will only be run like a script
close all
%% Add paths 
addpath('C:\Users\Hemlock\Documents\GitHub\Nowack_Lab\Equipment_Drivers');
addpath('C:\Users\Hemlock\Documents\GitHub\Nowack_Lab\Utilities');

%% Edit before running

% If testing without a squid, for wiring, etc
no_squid = true;

% Choose parameter file
paramfile = 'janky_resistance.csv';
% paramfile = 'StarCryo_IV.csv';

parampath = strcat('C:\Users\Hemlock\Documents\GitHub\Nowack_Lab\SQUID_Testing\Parameters\',paramfile);
[p, ptable] = param_parse(parampath); % use ptable to see parameters in table form


% Git dump? Uncomment if you want a cluttered git.
% git_dump();

%% Define file locations
dropbox = 'C:\Users\Hemlock\Dropbox (Nowack Lab)\TeamData\';
time = char(datetime('now','TimeZone','local','Format', 'yyyyMMdd_HHmmss'));

paramsavepath = strcat(dropbox, 'Montana\squid_testing\'); % Where the parameters will be saved
paramsavefile = strcat('squidIV_params_', time, '.csv'); % What the parameters will be called

datapath = strcat(dropbox, 'Montana\squid_testing\'); % Where the data will be saved
datafile = strcat('squidIV_data_', time, '.csv'); % What the data will be called

plotpath = strcat(dropbox, 'Montana\squid_testing\');
plotfile = strcat('squidIV_plot_IV_', time, '.pdf');
plotfile2 = strcat('squidIV_plot_IV_', time, '.png');

%% Ask the user for information
% Check parameters
param_prompt(paramfile);

% Double check no squid
squid_prompt(no_squid);

% Ask for notes
notes = input('Notes about this run: ','s');
fid = fopen('tempnotes.csv', 'w');
fprintf(fid, '%s', notes);
fclose(fid);

%% Some initial checks

% Check for potential SQUIDicide
if ~no_squid
    check_currents(max(abs(p.squid.Irampmax), abs(p.squid.Irampmin)), abs(p.mod.I));
end

% Check to make sure preamp doesn't filter out your signal
if p.preamp.rolloff_high < p.daq.rate
    error('You''re filtering out your signal -____-');
end


%% Send and collect data
nidaq = NI_DAQ(p.daq); % Initializes DAQ parameters
nidaq.set_io('squid'); % For setting input/output channels for measurements done on a SQUID

% Set output data
IsquidR = IVramp(p.squid);
Vmod = p.mod.I * p.mod.Rbias * ones(1,length(IsquidR)); % constant mod current

% prep and send output to the daq
output = [IsquidR; Vmod]; % puts Vsquid into first row and Vmod into second row
[Vsquid, ~] = nidaq.run(output); % Sends a signal to the daq and gets data back
Vsquid = Vsquid/p.preamp.gain; % corrects for gain of preamp

%% Save data, parameters, and notes
%Data file dump
data_dump(datafile, datapath,[IsquidR' Vsquid'],{'IsquidR (V)', 'Vsquid (V)'}); % pass cell array to prevent concatentation

% Get temperature data
temps = get_temps;
temptypes = fieldnames(temps);
fid = fopen('temperatures.csv', 'w');
for i=1:size(temps,1)+1
    fprintf(fid, '%s\n', strcat(char(temptypes(i)),',',char(temps.(char(temptypes(i)))),',K,montana'));
end
fclose(fid);

% Dress up parameters file
copyfile('tempnotes.csv', strcat(paramsavepath,paramsavefile)); %copies parameter file to permanent location % changed to following line
copyfile('temperatures.csv', strcat(paramsavepath,paramsavefile)); %copies temperatures file to permanent location % changed to following line
disp(['copy tempnotes.csv + ', ...
        parampath, ' + temperatures.csv ', ...
        '"', strcat(paramsavepath,paramsavefile), '"', ' /b']);
disp('asjkof');
system(['copy tempnotes.csv + ', ...
        parampath, ' + temperatures.csv ', ...
        '"', strcat(paramsavepath,paramsavefile), '"', ' /b']); 
    % fid = fopen(strcat(paramsavepath,paramsavefile), 'a+'); %moved up above
% fprintf(fid, '%s', strcat('notes',notes,'none','notes'));
% fclose(fid);
%delete('tempnotes.csv');
%delete('temperatures.csv');


%% Plot
figure;
plot_squidIV(gca, IsquidR, Vsquid, p); 
title({['Parameter file: ' paramsavefile];['Data file: ' datafile];['Rate: ' num2str(p.daq.rate) ' Hz']; ['Imod: ' num2str(p.mod.I) ' A']},'Interpreter','none');

print('-dpdf', strcat(plotpath, plotfile));
print('-dpng', strcat(plotpath, plotfile2));

end
