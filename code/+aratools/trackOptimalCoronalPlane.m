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
% screen if no outputs are requested.  This plane is a sum of a number of
% slices acround the optimal slice.
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

if ~isnumeric(imStack) || numel(size(imStack)) ~= 3
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
if any(fliplr(max(trackCoords)) > size(imStack)) || any(min(trackCoords) < 0)
    % NB: "An expression is true when its result is nonempty and contains
    % only nonzero elements (logical or real numeric). 
    fprintf('Input argument "trackCoords" is out of the range of the image\n')
    return
end



% Parse optional arguments
params = inputParser;
params.CaseSensitive = false;
params.addParameter('planesToAverage', 1, @(x) isnumeric(x) && isscalar(x))

params.parse(varargin{:});
planesToAverage = params.Results.planesToAverage;



% Fit the electrode track along the sagittal plane, which means collapsing along dimension 2
trackFit = polyfit(trackCoords(:,1), trackCoords(:,3), 1);

% The tilt angle of the electrode can be computed with tan(a) = opp/base
% BUT the gradient currently expresses (base/opp), so take inverse:
tiltAngleInRads = atan( (1/trackFit(1)) );
tiltAngleInDegrees = rad2deg(tiltAngleInRads);

%Report to screen the electrode tilt in degrees
fprintf('Electrode tilt rostro-caudally by %0.2f degrees\n', tiltAngleInDegrees)


% We are going to crop the stack before rotating it and want to ensure that all
% planes which contain the electrode track will still look like full sections 
% after the rotation. Use the tilt angle to pad the stack appropriately.
padSlices = round(abs(tan(tiltAngleInRads)*max(trackCoords(:,3))));
% Crop the stack so it includes only the range of z-planes encompassed by the 
% track plus a small buffer.

firstPlane = min(round(trackCoords(:,1)))-(planesToAverage+padSlices);
lastPlane  = max(round(trackCoords(:,1)))+(planesToAverage+padSlices);
if firstPlane<1
    firstPlane=1; 
end
if lastPlane>size(imStack,3)
    lastPlane=size(imStack,3);
end
imStack = imStack(:,:,firstPlane:lastPlane);


%Rotate the cropped stack along the rostro-caudal axis using a 3D affine transform
% The form of the matrix for rotating in 3D is defined on the last page of this PDF:
% https://people.cs.clemson.edu/~dhouse/courses/401/notes/affines-matrices.pdf

rotMat = eye(4);
if tiltAngleInRads~=0
    rAngC = cos(tiltAngleInRads * -1); % invert sign for correct transform!
    rAngS = sin(tiltAngleInRads * -1);

    rotMat(2,2) = rAngC;
    rotMat(3,3) = rAngC;
    rotMat(2,3) = rAngS;
    rotMat(3,2) = rAngS * -1;
end

% will use the imwarp() function to conduct the transformation
% therefore, need the transformation matrix as an affine3d object:
rotMat = affine3d(rotMat);

% perform the matrix multiplication - here using imwarp(), which converts the
% image to Homogenous Coordinates, applies the transform matrix, and
% converts back to the 3d image:
transformedStack = imwarp(imStack, rotMat);



% The middle plane should be the optimal plane:
% -1 as the optimal plane tends to move forward, as the electrode only goes into first 2/3s of image depth.
ind = round(size(transformedStack,3)/2)-1;
if planesToAverage>1
    optimalPlane = transformedStack(:,:,ind-planesToAverge:ind+planesToAverage);
    optimalPlane = max(optimalPlane,[],3); %TODO: is max the best idea?
else
    optimalPlane = transformedStack(:,:,ind);
end


% Plot image only if the user requested no output arguments
if nargout>0
    varargout{1}=optimalPlane;
    return
end


% Plot
clf
imagesc(optimalPlane)
axis equal tight
colormap gray


hold on
plot(trackCoords(:,2),trackCoords(:,3),'-r')
% TODO: overlay datapoints corresponding to the track
hold off
