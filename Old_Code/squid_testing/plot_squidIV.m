function [up_data, down_data] = plot_squidIV(varargin) % pass (axis handle, output, data) or (csvfilestring)
%plot_squidIV Summary of this function goes here
%   Detailed explanation goes here

if nargin == 1
    % On Squidward
    dropbox = 'C:\Users\root\Dropbox\TeamData\';
    path = strcat(dropbox, 'Montana\squid_testing\', varargin{1});

    
    % For testing on Mac
%     dropbox = '~/Dropbox (Nowack lab)/TeamData/';
%     path = strcat(dropbox, 'Montana/squid_testing/', varargin{1});

    parampath = strrep(path, 'data', 'params'); %same path name, but with "params" instead of "data"
    [p, ~] = param_parse(parampath);

    matrix = csvread(path,1,0); % 1,0 gets rid of title row
    output = matrix(:,1);
    data = matrix(:,2);
    figure;
    axes = gca;
elseif nargin==4
    axes = varargin{1};
    output = varargin{2};
    data = varargin{3};
    p = varargin{4};
else
    error('check arguments');
end

split_index = int64(length(data)/2); % finds split point between up and down ramps. up and down ramps are equal in size so this should always be an integer

up_out = output(1:split_index); % splits up and down ramps
down_out = output(split_index+1:end);

up_data = data(1:split_index); % splits up and down ramps
down_data = data(split_index+1:end);

plot(axes, 1e6*up_out/p.squid.Rbias, up_data, '-r'); % 1e6 converts from A to uA
hold(axes,'on')
plot(axes, 1e6*down_out/p.squid.Rbias, down_data, '-b');
legend(axes,'increasing', 'decreasing', 'Location', 'best');

xlabel(axes,'I_{bias} = V_{bias}/R_{bias} (\mu A)','fontsize',20);
ylabel(axes,'V_{squid} (V)','fontsize',20);

end

