function varargout=brainAreaBarChart(data)
% Bar chart of number of hits or points by area in the Allen Reference Atlas (ARA)
% 
% function out=brainAreaBarChart(data)
%
% Purpose
% Makes a bar chart of the number of hits by brain area
% also returns the data used for the plots. Useful for stats. 
%
%
% Inputs
% data - output of from getLeavesInARA or pointsInARA
%        if data is an array then we make one plot instance
%        the x axes are the same across plots
%
%
% Outputs
% out - optionally returns the y values used to make the plots 
%       and the area index values.
%       
% 
% Rob Campbell - Basel 2015
%
%
% See also: pointsInARA, pointsByAreaPlot


%unique brain areas across array
uInd = [];
for ii=1:length(data)
    uInd = [uInd; data(ii).ind];
end

uInd = unique(uInd);


ns=numSubplots(length(data));

if nargin>0
    out.y=cell(length(data),1);
end

for ii=1:length(data)
    subplot(ns(1),ns(2),ii)

    hits=zeros(size(uInd));

    for kk=1:length(hits)
        hits(kk) = length(find(data(ii).ind==uInd(kk)));
    end

    bar(1:length(hits),hits)
    drawnow

    if nargin>0
        out.y{ii}=hits;
    end

end

if nargin>0
    out.areaInd=uInd;
    varargout{1}=out;
end
