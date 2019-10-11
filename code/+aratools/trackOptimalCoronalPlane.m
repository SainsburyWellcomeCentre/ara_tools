function varargout = trackOptimalCoronalPlane(imStack,trackCoords,varargin)
% Return an image of the optimal coronal plane of an elextrode track
%
% function varargout = trackOptimalCoronalPlane(imStack,trackCoords,varargin)
%
% 
% Purpose
% Most electrode tracks don't traverse too many coronal planes so it is informative
% to plot an "optimal" plane for a track. The optimal plane is tilted rostro-caudally
% so that the track is visible throughout. This function determines the tilt angle
% based upon electrode track coordinates. It then performs an affine transform on 
% the image stack and returns the optimal coronal plane. The plane is plotted to 
% screen if no outputs are requested.
%
%
% Inputs (required)
% imStack - A 3D image stack of a brain containing electrode tracks
% trackCoords - A matrix of electrode track coordinates or the path to a CSV file
%               containing these data. Each row is one point along the track and
%               the columns are z slice, x coordinate in coronal plane, y coordinate
%               in coronal plane. The pixel size must match that of the image stack. 
% 
% Inputs (optional)
% These are supplied as parameter value pairs
% 'planesToAverage - 1 by default. If >1 the function averages this many planes
%                    either side when producing the average image.
%
%
% Outputs
% coronalPlane - Image of the coronal plane. If this is returned, nothing is 
%                plotted to screen. 
%
% 
% 



% Parse input arguments

if nargin<2
    %Display help text and quit if user provided fewer than two input arguments
    help(mfilename)
    return
end

if ~isnumeric(imStack) || ~ismatrix(imStack) || numel(size(imStack)) ~= 3
    %Do not proceed if imStack is not a numeric 3D matrix
    fprintf('Input argument "imStack" should be a 3D matrix\n')
    return
end

% Determine if trackCoords is a file name or a matrix corresponding to electrode coordinates
if isstr(trackCoords)
    if ~exist(trackCoords,'file')
        fprintf('Unable to find file %s\n', trackCoords)
        return
    end
    % Read file
    trackCoords = csvread(trackCoords); 
end


% If the electrode coordinates contains points that are outside of imStack, display a 
% warning message and quit
if(  not( max(trackCoords) > size(imStack) | min(trackCoords) < 0)  )
    % NB: "An expression is true when its result is nonempty and contains
    % only nonzero elements (logical or real numeric). 
    % Otherwise, the expression is false"
    % Therefore have taken the INVERSE, and will quite the function if ELSE
else
    %Do not proceed if imStack is not a numeric 3D matrix
    fprintf('Input argument "trackCoords" is out of the range of the image\n')
    return
end



% Parse optional arguments
params = inputparser;
params.CaseSensitive = false;
params.addParameter('planesToAverage', 1, @(x) isnumeric(x) && isscalar(x))

params.parse(varargin{:});

planesToAverage = params.Results.planesToAverage;





% TODO
% Fit a line (REGRESS) to the electrode track along the sagittal plane. 
% From this obtain the slope of the track along this axis

tiltAngleInDegrees=0; % TODO: place-holder


%Report to screen the electrode tilt in degrees
fprintf('Electrode tilt rostro-caudally by %0.2f degrees\n', tiltAngleInDegrees)


% Crop the stack so it includes only the range of z-planes encompassed by the 
% track plus a small buffer.
firstPlane = min(trackCoords(:,1))-planesToAverage;
lastPlane  = max(trackCoords(:,1))+planesToAverage;
if firstPlane<1
    firstPlane=1; 
end
if lastPlane>size(imStack,3)
    lastPlane=size(imStack,3);
end
imStack = imStack(:,:,firstPlane:lastPlane);




%TODO 
%Rotate the cropped stack along the rostro-caudal axis using a 3D affine transform
%See: AFFINE3D, IMWARP, 
% rot argument in: https://github.com/SainsburyWellcomeCentre/BakingTray/blob/master/code/BTresources/affineMatGen.m
% The form of the matrix for rotating in 3D is defined on the last page of this PDF:
% https://people.cs.clemson.edu/~dhouse/courses/401/notes/affines-matrices.pdf

transformedStack=imStack; %TODO: place-holder

% The middle plane should be the optimal plane:
ind = round(size(transformedStack,3));  % Qs; odd vs even number of planes? Does it matter?
optimalPlane = transformedStack(:,:,ind);


% Plot image only if the user requested no output arguments
if nargout>0
    varargout{1}=optimalPlane;
    return
end


% Plot
clf
imagesc(optimalPlane)
axes equal 
colormap gray


hold on
% TODO: over-lay datapoints corresponding to the track
hold off
