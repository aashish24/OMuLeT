function xml2mat(filename)
%READKML Summary of this function goes here
%   Detailed explanation goes here
    if nargin<1
        fprintf('Not enough input arguments!\n');
        return;
    end
    [filepath,name,ext] = fileparts(filename);
    xml = xml2struct(filename);
    save(sprintf('%s/%s.mat',filepath,name),'xml');
end

