%% ============================================================
%  Motion coherence and strain rate from manually tracked cells
%
%  Required CSV columns:
%       TID = track/cell ID
%       PID = frame number/order
%       x   = x position (micron)
%       y   = y position (micron)
%
%  Written for your MTrackJ-style CSV
%% ============================================================

clear;
clc;
close all;

%% ================= USER SETTINGS =============================

filename = '02.csv';

% Time interval between consecutive frames
frameInterval = 27.91;     % seconds, CHANGE THIS

% Physical width of this spatial bin
binWidth = 30;           % micron, CHANGE THIS

% Direction from villus tip toward villus base.
% For your current dataset, cells move mainly toward negative y.
%
% [0 -1] means negative-y is defined as positive axial direction.
axisVector = [0 -1];

%% =============================================================

axisVector = axisVector / norm(axisVector);

%% Read file
data = readtable(filename, 'VariableNamingRule', 'preserve');

trackID = data.('TID');
frameID = data.('PID');
x = data.('x');
y = data.('y');

tracks = unique(trackID);

nTracks = length(tracks);

%% Find number of frames
frames = unique(frameID);
frames = sort(frames);

nFrames = length(frames);

fprintf('Number of cells: %d\n', nTracks);
fprintf('Number of frames: %d\n', nFrames);
fprintf('Frame interval: %.2f sec\n', frameInterval);
fprintf('Bin width: %.2f micron\n\n', binWidth);

%% ============================================================
%  CALCULATE VELOCITIES
%% ============================================================

% Each row:
% cell ID, interval, x position, y position, vx, vy,
% axial position, axial velocity, speed

velocityData = [];

for i = 1:nTracks

    id = tracks(i);

    idx = find(trackID == id);

    % Sort each trajectory by frame
    [~, order] = sort(frameID(idx));
    idx = idx(order);

    xi = x(idx);
    yi = y(idx);
    fi = frameID(idx);

    for j = 1:(length(idx)-1)

        dx = xi(j+1) - xi(j);
        dy = yi(j+1) - yi(j);

        vx = dx / frameInterval;
        vy = dy / frameInterval;

        % midpoint position during interval
        xmid = (xi(j+1) + xi(j))/2;
        ymid = (yi(j+1) + yi(j))/2;

        % position projected onto villus axis
        s = xmid*axisVector(1) + ...
            ymid*axisVector(2);

        % velocity projected onto villus axis
        vAxial = vx*axisVector(1) + ...
                 vy*axisVector(2);

        speed = sqrt(vx^2 + vy^2);

        velocityData = [velocityData;
            id, fi(j), xmid, ymid, vx, vy, ...
            s, vAxial, speed];

    end
end

%% ============================================================
%  MOTION COHERENCE
%
%  C = |sum(unit velocity vectors)| / N
%
%  C = 1 --> all cells move in exactly same direction
%  C = 0 --> random/opposing directions
%% ============================================================

nIntervals = nFrames - 1;

coherence = nan(nIntervals,1);

for k = 1:nIntervals

    currentFrame = frames(k);

    idx = velocityData(:,2) == currentFrame;

    vx = velocityData(idx,5);
    vy = velocityData(idx,6);

    speed = sqrt(vx.^2 + vy.^2);

    % Remove zero-motion cells
    valid = speed > 0;

    vx = vx(valid);
    vy = vy(valid);
    speed = speed(valid);

    % Unit vectors
    ux = vx ./ speed;
    uy = vy ./ speed;

    % Mean direction vector
    meanUx = mean(ux);
    meanUy = mean(uy);

    % Coherence
    coherence(k) = sqrt(meanUx^2 + meanUy^2);

end

meanCoherence = mean(coherence, 'omitnan');

fprintf('============================================\n');
fprintf('MOTION COHERENCE\n');
fprintf('============================================\n');
fprintf('Mean coherence = %.4f\n\n', meanCoherence);

%% ============================================================
%  AXIAL STRAIN RATE
%
%       strain rate = dv_axial / ds
%
%  For each time interval, regress axial velocity against
%  axial position.
%
%       v(s) = strainRate*s + intercept
%
%  slope has units:
%
%       (micron/sec) / micron = 1/sec
%% ============================================================

strainRate = nan(nIntervals,1);
R2 = nan(nIntervals,1);

for k = 1:nIntervals

    currentFrame = frames(k);

    idx = velocityData(:,2) == currentFrame;

    s = velocityData(idx,7);
    vAxial = velocityData(idx,8);

    valid = ~isnan(s) & ~isnan(vAxial);

    s = s(valid);
    vAxial = vAxial(valid);

    if length(s) >= 3

        % Linear fit:
        % velocity = slope*position + intercept
        p = polyfit(s, vAxial, 1);

        strainRate(k) = p(1);

        % R squared
        predicted = polyval(p, s);

        SSres = sum((vAxial - predicted).^2);
        SStot = sum((vAxial - mean(vAxial)).^2);

        R2(k) = 1 - SSres/SStot;

    end

end

meanStrainRate = mean(strainRate, 'omitnan');

fprintf('============================================\n');
fprintf('STRAIN RATE\n');
fprintf('============================================\n');

fprintf('Mean strain rate = %.6f 1/sec\n', ...
    meanStrainRate);

fprintf('Mean strain rate = %.4f %%/sec\n', ...
    meanStrainRate*100);

fprintf('Mean strain rate = %.2f %%/hour\n\n', ...
    meanStrainRate*3600*100);

%% ============================================================
%  OPTIONAL: BIN-AVERAGED STRAIN RATE
%
%  This estimates the characteristic deformation rate from the
%  velocity difference across the physical width of this bin.
%
%       strain rate ~ Delta-v / Delta-x
%% ============================================================

meanAxialVelocity = nan(nIntervals,1);

for k = 1:nIntervals

    idx = velocityData(:,2) == frames(k);

    meanAxialVelocity(k) = ...
        mean(velocityData(idx,8),'omitnan');

end

fprintf('Mean axial velocity = %.5f micron/sec\n', ...
    mean(meanAxialVelocity,'omitnan'));

%% ============================================================
%  PLOTS
%% ============================================================

time = (0:nIntervals-1)' * frameInterval;

%% Motion coherence
figure;

plot(time/60, coherence, 'o-', 'LineWidth',1.5);

xlabel('Time (min)');
ylabel('Motion coherence');
ylim([0 1.05]);

title(sprintf('Motion coherence, mean = %.3f', ...
    meanCoherence));

box off;


%% Strain rate
figure;

plot(time/60, strainRate*100, 'o-', ...
    'LineWidth',1.5);

yline(0,'--');

xlabel('Time (min)');
ylabel('Axial strain rate (% s^{-1})');

title(sprintf('Mean strain rate = %.4f %% s^{-1}', ...
    meanStrainRate*100));

box off;


%% Strain rate converted to % / hour
figure;

plot(time/60, strainRate*3600*100, ...
    'o-', 'LineWidth',1.5);

yline(0,'--');

xlabel('Time (min)');
ylabel('Axial strain rate (% h^{-1})');

title(sprintf('Mean = %.2f %% h^{-1}', ...
    meanStrainRate*3600*100));

box off;


%% ============================================================
%  SAVE RESULTS
%% ============================================================

results = table( ...
    time, ...
    coherence, ...
    strainRate, ...
    strainRate*100, ...
    strainRate*3600*100, ...
    R2, ...
    'VariableNames', ...
    {'Time_sec', ...
     'MotionCoherence', ...
     'StrainRate_per_sec', ...
     'StrainRate_percent_per_sec', ...
     'StrainRate_percent_per_hour', ...
     'StrainRate_R2'});

writetable(results, 'motion_coherence_strain_rate_results.csv');

fprintf('\nResults saved as:\n');
fprintf('motion_coherence_strain_rate_results.csv\n');