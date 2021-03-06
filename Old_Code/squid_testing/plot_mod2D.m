function [up_data, down_data] = plot_mod2D(varargin) % pass (axis handle, output, data) or (csvfilestring)
%plot_squidIV Summary of this function goes here
%   Detailed explanation goes here
% 1 argument: csvfile
% 2 arguments: csvfile, Imod single value
% 4 arguments: axes, output, data, Imod array

%% Add paths
% on Squidward
 addpath('C:\Users\root\Documents\GitHub\Nowack_Lab\Equipment_Drivers');
 addpath('C:\Users\root\Documents\GitHub\Nowack_Lab\Utilities');

% on Mac, testing
% addpath('/Users/brian/Documents/Nowack_Lab/Equipment_Drivers');
% addpath('/Users/brian/Documents/Nowack_Lab/Utilities');

%% Read from CSV
if (nargin == 1 || nargin == 2)
    % On Squidward
    dropbox = 'C:\Users\root\Dropbox\TeamData\';
    path = strcat(dropbox, 'Montana\squid_testing\', varargin{1});

    % For testing on Mac
%     dropbox = '~/Dropbox (Nowack lab)/TeamData/';
%     path = strcat(dropbox, 'Montana/squid_testing/', varargin{1});

    parampath = strrep(path, 'data', 'params'); %same path name, but with "params" instead of "data"
    [p, ~] = param_parse(parampath); 
    
    % arg 2: output
    IsquidR = IVramp(p.squid);
    output = IsquidR/p.squid.Rbias;
    
    % arg 3: data
    data = csvread(path,5,0); % 5,0 gets rid of title rows and IsquidR and Imod rows
    % this matrix will be the 2D values of Vsquid, with rows for each Imod,
    % columns for each IsquidR

    % arg 4: Imod
    Vmod = IVramp(p.mod, false); % false: do not ramp down
    Imod = Vmod/p.mod.Rbias;
    
    %arg 1: axes
    fig = figure;
    axes = gca;
    colormap(coolwarm)
end

if nargin == 2
    Imod_slice = varargin{2};
    diffs = abs(Imod-Imod_slice); % trying to find closest Imod
    [~,min_index] = min(diffs); % smallest difference between passed Imod and the array of Imods
    Imod = Imod(min_index); % pick out Imod for this particular slice
    Vsquid_slice = data(min_index, :); % picks out slice of Vsquid
    plot_squidIV(axes, IsquidR, Vsquid_slice, p);

    % Put Imod somewhere (this is how we decided to do it, too lazy for text boxes :P)
    hold(axes, 'on');
    plot(IsquidR(1),Vsquid_slice(1),'w.','MarkerSize',1); % plotting blank data point because want third legend entry
    leg = legend(axes,'increasing', 'decreasing', strcat('Imod = ',num2str(Imod*1e6), 'uA'), 'Location', 'best');
    
    return
%% Pass data
elseif nargin==4
    axes = varargin{1};
    output = varargin{2};
    data = varargin{3};
    Imod = varargin{4};
else
    error('check arguments');
end

%% Do the plots
split_index = int64(size(data,2)/2); % finds split point between up and down ramps. up and down ramps are equal in size so this should always be an integer

up_out = output(1:split_index); % splits up and down ramps
down_out = output(split_index+1:end);

up_data = data(:,1:split_index); % splits up and down ramps
down_data = data(:,split_index+1:end);

imagesc(1e6*up_out,1e6*Imod,up_data,'Parent',axes); % plots I_squid (uA) on x-axis, I_mod (uA) on y-axis, and V_squid as color
%imagesc(1e6*down_out,1e6*Imod,down_data,'Parent',axes); % plots I_squid (uA) on x-axis, I_mod (uA) on y-axis, and V_squid as color

xlabel(axes,'I_{squid} = V_{squid}/R_{bias} (\mu A)','fontsize',20);
ylabel(axes,'I_{mod} = V_{mod}/R_{bias} (\mu A)','fontsize',20);
c = colorbar(axes);
colormap(coolwarm)
ylabel(c,'V_{squid} (V)','fontsize',20);
end

