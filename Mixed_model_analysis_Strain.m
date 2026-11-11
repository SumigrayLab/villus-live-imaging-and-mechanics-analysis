%% Hierarchical mixed-effects analysis of strain gradient
% Expected Excel columns:
% Mouse
% Villus
% Treatment
% Curvature_length
% Strain_gradient

clear; clc;

%% Load data
T = readtable('Mixed_model_Bleb_Strain.xlsx');

%% Optional: restrict to near-tip region
% Use < 150 if your bin centers are 5,15,...,145 µm
T = T(T.Curvature_length < 150, :);

%% Convert grouping variables to categorical
T.Mouse = categorical(T.Mouse);
T.Villus = categorical(T.Villus);
T.Treatment = categorical(T.Treatment);

%% Create unique IDs
% Important because "Mouse 1" in CTRL and "Mouse 1" in CK666
% should not accidentally be treated as the same animal.

T.MouseID = categorical( ...
    strcat(string(T.Treatment), "_", string(T.Mouse)) );

T.VillusID = categorical( ...
    strcat(string(T.Treatment), "_", string(T.Mouse), "_", string(T.Villus)) );

%% Treat curvature positions as categorical bins
% This is closest to your Prism analysis and does not assume
% that the spatial profile is linear.
T.CurvatureBin = categorical(T.Curvature_length);

%% Fit hierarchical linear mixed-effects model
%
% Fixed effects:
%   Treatment
%   CurvatureBin
%   Treatment × CurvatureBin
%
% Random effects:
%   Mouse
%   Villus nested within mouse

lme = fitlme(T, ...
    ['Strain ~ Treatment*CurvatureBin ' ...
     '+ (1|MouseID) + (1|VillusID)'], ...
    'FitMethod','REML');

%% Display model
disp(lme);

%% ANOVA for fixed effects
anovaTable = anova(lme, 'DFMethod', 'Satterthwaite');

disp(' ');
disp('===== FIXED-EFFECT ANOVA =====');
disp(anovaTable);

%% Display random effects / variance components
disp(' ');
disp('===== RANDOM EFFECTS =====');
disp(covarianceParameters(lme));

%% Optional: continuous-curvature model
% This tests whether the slope of strain gradient vs curvature length
% differs among treatments.

lme_continuous = fitlme(T, ...
    ['Strain ~ Treatment*Curvature_length ' ...
     '+ (1|MouseID) + (1|VillusID)'], ...
    'FitMethod','REML');

disp(' ');
disp('===== CONTINUOUS CURVATURE MODEL =====');
disp(anova(lme_continuous, 'DFMethod', 'Satterthwaite'));