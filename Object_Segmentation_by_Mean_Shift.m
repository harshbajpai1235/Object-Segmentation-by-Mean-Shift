% Loading image as uint8 and converting to double
imgPath = '/Users/harshbajpai/Documents/MATLAB/Segmentation_Data/Baboon.bmp';
inputImg = double(imread(imgPath));
[imgRows, imgCols] = size(inputImg);
[xCoord, yCoord] = meshgrid(1:imgCols, 1:imgRows);

% Forming dataset with features [x, y, intensity]
pixelFeatures = [xCoord(:), yCoord(:), inputImg(:)];
numPixels = imgRows * imgCols;

% Mean shifting parameters
bandwidth = 8;              % h: bandwidth
convThreshold = 1;          % TH: convergence threshold
maxIterations = 100;

% Initializing output data
convergedPixels = zeros(size(pixelFeatures));

fprintf('Running mean shift on %d pixels...\n', numPixels);
for px = 1:numPixels
    currentPoint = pixelFeatures(px, :);
    iter = 0;
    hasConverged = false;

    while ~hasConverged && iter < maxIterations
        delta = pixelFeatures - currentPoint;
        distSquared = sum(delta.^2, 2);

        % Neighborhood mask
        neighborMask = (distSquared <= bandwidth^2);
        weightSum = sum(neighborMask);

        if weightSum == 0
            break;
        end

        % Weighted mean update
        updatedPoint = (neighborMask' * pixelFeatures) / weightSum;
        movement = updatedPoint - currentPoint;

        if (norm(movement)^2 / bandwidth^2) <= convThreshold^2
            hasConverged = true;
        end

        currentPoint = updatedPoint;
        iter = iter + 1;
    end

    convergedPixels(px, :) = currentPoint;

    % Showing progress every 5000 pixels
    if mod(px, 5000) == 0
        fprintf('Processed %d of %d pixels...\n', px, numPixels);
    end
end

% Reconstructing filtered image from converged intensities
filteredImg = reshape(convergedPixels(:, 3), [imgRows, imgCols]);

% Cluster points based on convergence positions ===
clusterCenters = convergedPixels;
pixelLabels = zeros(numPixels, 1);
clusterID = 1;

for i = 1:numPixels
    if pixelLabels(i) ~= 0
        continue;
    end

    diffVec = clusterCenters - clusterCenters(i, :);
    distVec = sqrt(sum(diffVec.^2, 2));
    closePoints = (distVec <= bandwidth);

    pixelLabels(closePoints) = clusterID;
    clusterID = clusterID + 1;
end

% Eliminate small regions
minClusterSize = 10;
allLabels = unique(pixelLabels);

for j = 1:length(allLabels)
    mask = (pixelLabels == allLabels(j));
    if sum(mask) < minClusterSize
        pixelLabels(mask) = 0;
    end
end

% Reshape segmented labels to image form
segmentedResult = reshape(pixelLabels, [imgRows, imgCols]);

% Display Results 
figure;
subplot(1, 3, 1); imshow(inputImg, []); title('Original Image');
subplot(1, 3, 2); imshow(filteredImg, []); title('Mean Shift Filtering');
subplot(1, 3, 3); imshow(segmentedResult, [0, 1]); title('Segmented Image');