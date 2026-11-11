% Read CSV file with x and y data for multiple cells
filename = '10.csv';  % Specify your CSV file
data = readtable(filename, 'VariableNamingRule', 'preserve');

% Extract unique cell IDs (TID) and time frames (PID)
cell_ids = unique(data.TID);  % Unique cell identifiers
num_cells = numel(cell_ids);  % Number of cells
time_frames = unique(data.PID);  % Unique time frames
time_interval = 4;  % Time interval between frames in minutes

% Initialize data arrays for velocity, travel distance, MSD, and mean velocity calculation
velocity = cell(num_cells, 1);  % Cell array to store velocity vectors for each cell
travel_distance = zeros(num_cells, 1);  % Array to store total travel distance for each cell
mean_velocity = zeros(num_cells, 1);  % Array to store mean velocity for each cell
msd = cell(num_cells, 1);  % Cell array to store MSD for each cell
all_velocity_magnitudes = [];  % To store all velocity magnitudes for colormap scaling

% Extract x and y coordinates for each cell
x_data = NaN(numel(time_frames), num_cells);
y_data = NaN(numel(time_frames), num_cells);
for i = 1:num_cells
    % Extract data for the current cell
    cell_data = data(data.TID == cell_ids(i), :);
    [~, loc] = ismember(cell_data.PID, time_frames);  % Map time frames to rows
    x_data(loc, i) = cell_data.("x");
    y_data(loc, i) = cell_data.("y");
end

% The rest of your original analysis code follows here, unchanged
% (Make sure to use `x_data` and `y_data` as initialized above)

% Note: Replace the old `xlsread` block with this updated CSV-reading section.


% Initialize variables for velocity, travel distance, MSD, and mean velocity calculation
num_cells = size(x_data, 2);  % Number of cells based on number of x columns
max_frames = size(x_data, 1);  % Number of frames (rows in the data)
velocity = cell(num_cells, 1);  % Cell array to store velocity vectors for each cell
travel_distance = zeros(num_cells, 1);  % Array to store total travel distance for each cell
mean_velocity = zeros(num_cells, 1);  % Array to store mean velocity for each cell
msd = cell(num_cells, 1);  % Cell array to store MSD for each cell

% To store the maximum velocity magnitude across all cells
all_velocity_magnitudes = [];

%% Plot the cell trajectories
figure;
hold on;
for i = 1:num_cells
    % Remove NaN values for the current cell
    x_displacement = x_data(:, i);
    y_displacement = y_data(:, i);
    valid_idx = ~isnan(x_displacement) & ~isnan(y_displacement);  % Only valid data points
    x_displacement = x_displacement(valid_idx) - x_displacement(find(valid_idx, 1));
    y_displacement = y_displacement(valid_idx) - y_displacement(find(valid_idx, 1));
    
    % Plot the trajectory
    plot(x_displacement, -y_displacement, 'LineWidth', 1.5);
    
    % Calculate velocity vectors for each frame
    num_frames = length(x_displacement);
    velocity{i} = zeros(num_frames-1, 2);  % Initialize velocity vectors (x and y components)
    velocity_magnitude = zeros(num_frames-1, 1);  % To store the magnitude of velocity
    
    for t = 1:(num_frames - 1)
        % Velocity vector components (change in x and y) in micrometers per minute
        vx = (x_displacement(t+1) - x_displacement(t)) / time_interval;
        vy = (y_displacement(t+1) - y_displacement(t)) / time_interval;
        velocity{i}(t, :) = [vx, vy];
        
        % Calculate the velocity magnitude
        velocity_magnitude(t) = sqrt(vx^2 + vy^2);
        
        % Add to the travel distance (in micrometers)
        travel_distance(i) = travel_distance(i) + velocity_magnitude(t) * time_interval;
    end
    
    % Collect all velocity magnitudes
    all_velocity_magnitudes = [all_velocity_magnitudes; velocity_magnitude];
    
    % Calculate the mean velocity for the cell (in micrometers per minute)
    mean_velocity(i) = mean(velocity_magnitude);
    
    % Calculate MSD for each valid frame
    msd{i} = (x_displacement.^2 + y_displacement.^2);
end

xlabel('X Displacement (μm)');
ylabel('Y Displacement (μm)');
title('Cell Trajectories');
axis equal;
hold off;
%xlim([-10, 10]);  % Set the x-axis range as needed
%ylim([-5, 30]);  % Set the y-axis range as needed

%% Plot velocity vectors (vector field) with color-coded magnitude (true positions)
figure;
hold on;

% Colormap for velocity magnitude
cmap = jet(256);  % Jet colormap
min_velocity = min(all_velocity_magnitudes);  % Minimum velocity magnitude across all cells
max_velocity = max(all_velocity_magnitudes);  % Maximum velocity magnitude across all cells

for i = 1:num_cells
    % Remove NaN values for the current cell
    x_displacement = x_data(:, i);  % Use original data, no normalization
    y_displacement = y_data(:, i);  % Use original data, no normalization
    valid_idx = ~isnan(x_displacement) & ~isnan(y_displacement);  % Only valid data points
    x_displacement = x_displacement(valid_idx);  % Keep valid data points
    y_displacement = y_displacement(valid_idx);  % Keep valid data points
    
    % Calculate velocity vectors for each frame
    num_frames = length(x_displacement);
    velocity_magnitude = zeros(num_frames-1, 1);  % To store the magnitude of velocity
    
    for t = 1:(num_frames - 1)
        % Velocity vector components (change in x and y) in micrometers per minute
        vx = (x_displacement(t+1) - x_displacement(t)) / time_interval;
        vy = (y_displacement(t+1) - y_displacement(t)) / time_interval;
        
        % Calculate the velocity magnitude
        velocity_magnitude(t) = sqrt(vx^2 + vy^2);
        
        % Normalize velocity magnitude to a color index based on min and max
        color_idx = min(256, max(1, round(255 * (velocity_magnitude(t) - min_velocity) / (max_velocity - min_velocity))));
        
        % Plot the velocity vector with color coding
        quiver(x_displacement(t), -y_displacement(t), vx, -vy, ...
            'Color', cmap(color_idx, :), 'AutoScaleFactor', 80, 'MaxHeadSize', 80);
    end
end

% Add a color bar for reference
colormap(cmap);
c = colorbar;
c.Label.String = 'Velocity Magnitude (μm/min)';
caxis([min_velocity, max_velocity]);  % Adjust color bar to match velocity range

xlabel('X Position (μm)');
ylabel('Y Position (μm)');
title('Velocity Vector Field (Color-Coded by Magnitude)');
axis equal;
hold off;

%% PIV-like Velocity Plot (using grid-based averaging)

% Parameters for gridding (adjust based on your data range)
grid_size = 13;  % Size of each grid cell in micrometers
x_min = min(min(x_data));  % Minimum x value across all cells
x_max = max(max(x_data));  % Maximum x value across all cells
y_min = min(min(y_data));  % Minimum y value across all cells
y_max = max(max(y_data));  % Maximum y value across all cells

% Define grid edges
x_edges = x_min:grid_size:x_max;
y_edges = y_min:grid_size:y_max;

% Initialize arrays for grid-averaged velocities
x_grid_centers = (x_edges(1:end-1) + x_edges(2:end)) / 2;
y_grid_centers = (y_edges(1:end-1) + y_edges(2:end)) / 2;
u_avg = zeros(length(y_grid_centers), length(x_grid_centers));  % Average velocity in x direction
v_avg = zeros(length(y_grid_centers), length(x_grid_centers));  % Average velocity in y direction
count_grid = zeros(length(y_grid_centers), length(x_grid_centers));  % Count of vectors in each grid cell

% Loop through each cell's trajectory
for i = 1:num_cells
    % Remove NaN values for the current cell
    x_displacement = x_data(:, i);
    y_displacement = y_data(:, i);
    valid_idx = ~isnan(x_displacement) & ~isnan(y_displacement);  % Only valid data points
    x_displacement = x_displacement(valid_idx);  % Keep valid data points
    y_displacement = y_displacement(valid_idx);  % Keep valid data points

    % Calculate velocity vectors for each frame
    num_frames = length(x_displacement);
    
    for t = 1:(num_frames - 1)
        % Velocity vector components (change in x and y) in micrometers per minute
        vx = (x_displacement(t+1) - x_displacement(t)) / time_interval;
        vy = (y_displacement(t+1) - y_displacement(t)) / time_interval;
        
        % Find which grid cell the current vector belongs to
        x_idx = find(x_displacement(t) >= x_edges(1:end-1) & x_displacement(t) < x_edges(2:end), 1);
        y_idx = find(y_displacement(t) >= y_edges(1:end-1) & y_displacement(t) < y_edges(2:end), 1);
        
        if ~isempty(x_idx) && ~isempty(y_idx)
            % Accumulate velocity in the corresponding grid cell
            u_avg(y_idx, x_idx) = u_avg(y_idx, x_idx) + vx;
            v_avg(y_idx, x_idx) = v_avg(y_idx, x_idx) + vy;
            count_grid(y_idx, x_idx) = count_grid(y_idx, x_idx) + 1;
        end
    end
end

% Compute the average velocities in each grid cell
u_avg = u_avg ./ max(count_grid, 1);  % Avoid division by zero
v_avg = -v_avg ./ max(count_grid, 1);

% Plot PIV averaged velocity field
figure;
quiver(x_grid_centers, -y_grid_centers, u_avg, v_avg, 'k', 'AutoScaleFactor', 4, 'LineWidth', 1.5, 'MaxHeadSize', 10);
xlabel('X Position (μm)');
ylabel('Y Position (μm)');
title('PIV Averaged Velocity Field');
axis equal;

%% Plot Mean Velocity for Each Cell
figure;
bar(mean_velocity);  % Plot mean velocity as a bar chart
xlabel('Cell Number');
ylabel('Mean Velocity (μm/min)');
title('Mean Velocity for Each Cell');
grid on;

%% Plot Total Travel Distance for Each Cell
figure;
bar(travel_distance);  % Plot total travel distance as a bar chart
xlabel('Cell Number');
ylabel('Total Travel Distance (μm)');
title('Total Travel Distance for Each Cell');
grid on;

%% Plot MSD for Each Cell
figure;
hold on;
for i = 1:num_cells
    plot(1:length(msd{i}), msd{i}, '-o', 'LineWidth', 1.5);  % Plot MSD for each cell
end
xlabel('Time Frame');
ylabel('Mean Square Displacement (μm²)');
title('Mean Square Displacement (MSD) for Each Cell');
grid on;
hold off;

%% Display Mean Velocity and Total Travel Distance for Each Cell
fprintf('--- Summary of Cell Dynamics ---\n');
for i = 1:num_cells
    fprintf('Cell %d:\n', i);
    fprintf('  - Mean velocity: %.2f μm/min\n', mean_velocity(i));
    fprintf('  - Total travel distance: %.2f μm\n', travel_distance(i));
    fprintf('\n');
end
