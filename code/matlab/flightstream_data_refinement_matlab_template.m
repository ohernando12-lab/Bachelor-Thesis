% =========================================================================
% SCRIPT:       DATA_REFINEMENT_MATLAB_TEMPLATE
% AUTHOR:       Omar Hernando de la Torre
% DATE:         April 2026
%
% DESCRIPTION:  Sanitized MATLAB template for processing FlightStream sweep
%               data. Paste a raw FlightStream matrix and define a case name
%               and output folder before running the script.
% =========================================================================

clear; clc; close all;
format long g;

%% =========================
%  USER INPUTS
%  =========================

rawData = [];
caseName = "";
outputFolder = "";

%% =========================
%  FLIGHTSTREAM COLUMN MAP
%  =========================

COL_AOA = 1;
COL_CL  = 7;
COL_CDI = 8;
COL_CD0 = 9;
COL_CMY = 11;

if isempty(rawData)
    error('rawData is empty. Paste FlightStream data before running the script.');
end

if strlength(caseName) == 0
    error('caseName is empty. Provide a descriptive case name.');
end

if strlength(outputFolder) == 0
    error('outputFolder is empty. Provide an output directory.');
end

if size(rawData, 2) < COL_CMY
    error('rawData must contain at least %d columns from the FlightStream export.', COL_CMY);
end

AOA = rawData(:,COL_AOA);
Cl  = rawData(:,COL_CL);
Cdi = rawData(:,COL_CDI);
Cd0 = rawData(:,COL_CD0);
Cmy = rawData(:,COL_CMY);

Cd = Cdi + Cd0;

if any(Cd <= 0)
    error('Invalid drag coefficient: Cd must be positive to compute L/D.');
end

LD = Cl ./ Cd;

results = table(AOA, Cl, Cdi, Cd0, Cmy, Cd, LD, ...
    'VariableNames', {'AOA','Cl','Cdi','Cd0','Cmy','Cd','L_D'});

disp(results);

[maxLD, idxMaxLD] = max(LD);
[~, idxBestTrim] = min(abs(Cmy));

fprintf('\n===== SUMMARY: %s =====\n', caseName);
fprintf('Max L/D: %.4f at AOA = %.2f deg\n', maxLD, AOA(idxMaxLD));
fprintf('Best trim: Cmy = %.4f at AOA = %.2f deg\n', Cmy(idxBestTrim), AOA(idxBestTrim));

fig = figure('Name', caseName, 'Color', 'w');

subplot(2,2,1)
plot(AOA, Cd, 'LineWidth', 1.5, 'Color', "k", ...
    'Marker', 'diamond', 'MarkerEdgeColor', "r", ...
    'MarkerSize', 4, 'MarkerFaceColor', "w")
grid on
xlabel('\alpha [deg]')
ylabel('Cd')
title('Drag: Cd')

subplot(2,2,2)
plot(AOA, Cmy, 'LineWidth', 1.5, 'Color', "k", ...
    'Marker', 'diamond', 'MarkerEdgeColor', "r", ...
    'MarkerSize', 4, 'MarkerFaceColor', "w")
yline(0, '--')
grid on
xlabel('\alpha [deg]')
ylabel('Cmy')
title('Moment: Cmy')

subplot(2,2,3)
plot(AOA, Cl, 'LineWidth', 1.5, 'Color', "k", ...
    'Marker', 'diamond', 'MarkerEdgeColor', "r", ...
    'MarkerSize', 4, 'MarkerFaceColor', "w")
grid on
xlabel('\alpha [deg]')
ylabel('Cl')
title('Lift: Cl')

subplot(2,2,4)
plot(AOA, LD, 'LineWidth', 1.5, 'Color', "k", ...
    'Marker', 'diamond', 'MarkerEdgeColor', "r", ...
    'MarkerSize', 4, 'MarkerFaceColor', "w")
grid on
xlabel('\alpha [deg]')
ylabel('L/D')
title('Efficiency: L/D')

sgtitle(caseName)

if ~exist(outputFolder, "dir")
    mkdir(outputFolder);
end

outputExcel = fullfile(outputFolder, caseName + "_refined_results.xlsx");
outputPlots = fullfile(outputFolder, caseName + "_plots.png");
outputTXT   = fullfile(outputFolder, caseName + "_refined_results.txt");

writetable(results, outputExcel, 'Sheet', caseName);
writetable(results, outputTXT, 'Delimiter', '\t', 'FileType', 'text');
saveas(fig, outputPlots);

fprintf('\nFiles saved in:\n%s\n', outputFolder);
