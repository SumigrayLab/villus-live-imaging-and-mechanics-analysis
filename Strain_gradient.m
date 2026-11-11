% Load data
data = readtable('Mh9-cKO-CTRL-Villus1.xlsx');

% Assume columns are named 'Curvature_length' and 'Nuclear_strain'
x = data.Curvature_length;
y = data.Nuclear_strain;

% Sort by curvature length
[x, sortIdx] = sort(x);
y = y(sortIdx);

% Define bin edges every 30 microns
binSize = 10;
edges = 0:binSize:max(x);

% Compute mean strain in each bin
binCenters = edges(1:end-1) + binSize/2;
binMeans = zeros(length(edges)-1,1);
for i = 1:length(edges)-1
    inBin = (x >= edges(i)) & (x < edges(i+1));
    binMeans(i) = mean(y(inBin),'omitnan');
end

% Smooth the mean strain profile
smoothedMeans = smooth(binCenters, binMeans, 0.2, 'lowess');

% Compute gradient from smoothed strain (Δstrain / Δx)
gradients = -diff(smoothedMeans) / binSize;
gradCenters = binCenters(1:end-1) + binSize/2;

% Smooth the gradient as well
smoothedGradients = smooth(gradCenters, gradients, 0.2, 'lowess');

%% --- Plot raw vs smoothed mean strain ---
figure;
plot(binCenters, binMeans,'-o','Color',[0.7 0.7 0.7]); hold on;
plot(binCenters, smoothedMeans,'-r','LineWidth',2);
xlabel('Curvature length (µm)');
ylabel('Mean nuclear strain');
title('Smoothed Mean Strain vs Curvature Length');
legend('Raw binned','Smoothed','Location','best');

% Axis limits (set [] to auto)
xLimits = [0 300];   % adjust as needed, or [] for auto
yLimits = [0 2];     % adjust as needed, or [] for auto
if ~isempty(xLimits), xlim(xLimits); end
if ~isempty(yLimits), ylim(yLimits); end

%% --- Plot strain gradient ---
figure;
plot(gradCenters, gradients,'-s','Color',[0.6 0.6 1]); hold on;
plot(gradCenters, smoothedGradients,'-b','LineWidth',2);
xlabel('Curvature length (µm)');
ylabel(sprintf('Strain gradient (Δstrain / %d µm)', binSize));
title('Smoothed Strain Gradient along Villus Axis');
legend('Raw gradient','Smoothed gradient','Location','best');

% Axis limits (set [] to auto)
xLimits = [0 300];   % adjust as needed, or [] for auto
yLimits = [-0.03 0.05]; % adjust as needed, or [] for auto
if ~isempty(xLimits), xlim(xLimits); end
if ~isempty(yLimits), ylim(yLimits); end

% Normalized gradient
%% --- Normalize curvature length to villus axis (0 = bottom, 1 = tip) ---
villusLength = max(x);
normBinCenters = 1-binCenters / villusLength;
normGradCenters = 1-gradCenters / villusLength;

%% --- Define normalized bins (5 parts along villus) ---
normEdges = 0:0.2:1;  % [0, 0.2, 0.4, 0.6, 0.8, 1.0]
normCenters = normEdges(1:end-1) + 0.1;

% Initialize arrays
binnedStrain = zeros(1, length(normCenters));
binnedGradient = zeros(1, length(normCenters));

%% --- Bin the smoothed mean strain ---
for i = 1:length(normCenters)
    inBin = (normBinCenters >= normEdges(i)) & (normBinCenters < normEdges(i+1));
    binnedStrain(i) = mean(smoothedMeans(inBin), 'omitnan');
end

%% --- Bin the smoothed strain gradient ---
for i = 1:length(normCenters)
    inBin = (normGradCenters >= normEdges(i)) & (normGradCenters < normEdges(i+1));
    binnedGradient(i) = mean(smoothedGradients(inBin), 'omitnan');
end

%% --- Display results with bin edges instead of centers ---
disp('Binned values along villus (0=bottom, 1=tip):');
binLabels = strcat(string(normEdges(1:end-1)), '-', string(normEdges(2:end)));
T = table(binLabels', binnedStrain', binnedGradient', ...
    'VariableNames', {'Bin','Mean_Strain','Mean_Gradient'});
disp(T);

first100mask = gradCenters <= 100;  % include bins from 0–100 µm
meanGradFirst100 = mean(smoothedGradients(first100mask), 'omitnan');

%% --- Mean strain gradient and total strain change over defined regions ---
regions = [50, 100, 150, 200];  % µm ranges
fprintf('\n=== Mean Strain Gradient Summary ===\n');

for r = regions
    mask_raw = gradCenters <= r;
    mask_smooth = gradCenters <= r;

    % ---- RAW ----
    meanGrad_raw = mean(gradients(mask_raw), 'omitnan');
    netStrainChange_raw = meanGrad_raw * r;

    % ---- SMOOTHED ----
    meanGrad_smooth = mean(smoothedGradients(mask_smooth), 'omitnan');
    netStrainChange_smooth = meanGrad_smooth * r;

    % ---- Print results ----
    fprintf('\nRegion: 0–%d µm\n', r);
    fprintf('  Mean RAW strain gradient: %.4f per µm\n', meanGrad_raw);
    fprintf('  Total RAW strain change:  %.4f\n', netStrainChange_raw);
    fprintf('  Mean SMOOTHED strain gradient: %.4f per µm\n', meanGrad_smooth);
    fprintf('  Total SMOOTHED strain change:  %.4f\n', netStrainChange_smooth);
end


