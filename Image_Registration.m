% File path of your TIFF image stack
tiffFilePath = 'Showcase.tif'; % Update this to your correct file path

% Get image information
info = imfinfo(tiffFilePath);
numFrames = numel(info);  % Total number of frames in the TIFF file

% Preallocate cell array to store the image frames
imgStack = cell(numFrames, 1);

% Read all frames from the TIFF file
for k = 1:numFrames
    imgStack{k} = im2double(imread(tiffFilePath, k)); % Read as double for better precision
end

% Preallocate cell array to store corrected frames
correctedStack = cell(numFrames, 1);
correctedStack{1} = imgStack{1}; % The first frame doesn't need correction

% Initialize optical flow object for later refinement
opticFlow = opticalFlowLK('NoiseThreshold', 0.005); % Adjust NoiseThreshold to improve accuracy

% Loop through each frame to perform drift correction
for k = 2:numFrames
    % The current frame to be aligned
    movingFrame = imgStack{k};

    % Step 1: Create an average reference frame from the previous three corrected frames
    if k > 3
        avgReferenceFrame = (correctedStack{k-1} + correctedStack{k-2} + correctedStack{k-3}) / 3;
    else
        avgReferenceFrame = correctedStack{k-1}; % Use the previous frame if fewer than 3
    end

    % Step 2: Perform cross-correlation to estimate the initial offset
    c = normxcorr2(avgReferenceFrame, movingFrame);
    [~, maxIdx] = max(abs(c(:)));
    [peakY, peakX] = ind2sub(size(c), maxIdx);

    % Calculate the offset
    offsetX = peakX - size(avgReferenceFrame, 2);
    offsetY = peakY - size(avgReferenceFrame, 1);

    % Step 3: Apply the offset using 'imwarp' for translation
    tform = affine2d([1 0 0; 0 1 0; -offsetX, -offsetY, 1]); % Create an affine transformation
    translatedFrame = imwarp(movingFrame, tform, 'OutputView', imref2d(size(movingFrame)), 'Interp', 'cubic');

    % Step 4: Refine the correction using optical flow
    flow = estimateFlow(opticFlow, translatedFrame);
    refinedOffsetX = round(mean(flow.Vx(:)));  % Average x-offset
    refinedOffsetY = round(mean(flow.Vy(:)));  % Average y-offset

    % Limit the correction to small values to avoid over-correction
    refinedOffsetX = min(max(refinedOffsetX, -2), 2);
    refinedOffsetY = min(max(refinedOffsetY, -2), 2);

    % Final correction using translation (for the rigid part)
    tformRefined = affine2d([1 0 0; 0 1 0; -refinedOffsetX, -refinedOffsetY, 1]);
    correctedFrame = imwarp(translatedFrame, tformRefined, 'OutputView', imref2d(size(translatedFrame)), 'Interp', 'cubic');

    % Store the corrected frame
    correctedStack{k} = correctedFrame;
end

% Save the corrected frames as a new TIFF file
outputFilePath = 'final_corrected_image_cleaned.tif'; % Update this path if needed
for k = 1:numFrames
    % Convert to uint16 before saving
    correctedFrame = correctedStack{k};
    correctedFrame = mat2gray(correctedFrame); % Normalizes to [0, 1]
    correctedFrame = im2uint16(correctedFrame); % Converts to uint16

    % Save each frame
    if k == 1
        imwrite(correctedFrame, outputFilePath, 'WriteMode', 'overwrite', 'Compression', 'none');
    else
        imwrite(correctedFrame, outputFilePath, 'WriteMode', 'append', 'Compression', 'none');
    end
end

disp('Drift correction with noise reduction completed and saved to final_corrected_image_cleaned.tif');
