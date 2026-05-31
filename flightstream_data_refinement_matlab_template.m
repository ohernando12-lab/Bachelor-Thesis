% =========================================================================
% SCRIPT:       DATA_REFINEMENT_MATLAB
% AUTHOR:       Omar Hernando de la Torre
% DATE:         April 2026
%
% DESCRIPTION:  MATLAB alternative to the Excel/VBA data refinement routine.
%               The script extracts the relevant FlightStream coefficient
%               columns, computes total drag and aerodynamic efficiency,
%               identifies the maximum L/D and closest trim point and exports
%               clean tables and plots.
%
% INPUT:        Raw FlightStream sweep matrix pasted into rawData.
%
% OUTPUT:       Clean MATLAB table, Excel file, text file, PNG polar figure
%               and a pop-up table for visual inspection.
% =========================================================================

clear; clc; close all;
format long g;

% =====================================================
% FLIGHTSTREAM COLUMN MAP
% =====================================================
COL_AOA = 1;
COL_CL  = 7;
COL_CDI = 8;
COL_CD0 = 9;
COL_CMY = 11;

% =====================================================
% PASTE RAW FLIGHTSTREAM DATA HERE
% =====================================================
rawData = [];
caseName = "";

if isempty(rawData)
    error('rawData is empty. Paste FlightStream data before running the script.');
end

if size(rawData, 2) < COL_CMY
    error('rawData must contain at least %d columns from the FlightStream export.', COL_CMY);
end

% =====================================================
% ORIGINAL FLIGHTSTREAM COLUMNS
% =====================================================
% Column COL_AOA = AOA
% Column COL_CL  = Cl
% Column COL_CDI = Cdi
% Column COL_CD0 = Cd0
% Column COL_CMY = Cmy

AOA = rawData(:,COL_AOA);
Cl  = rawData(:,COL_CL);
Cdi = rawData(:,COL_CDI);
Cd0 = rawData(:,COL_CD0);
Cmy = rawData(:,COL_CMY);

% =====================================================
% DERIVED AERODYNAMIC QUANTITIES
% =====================================================
Cd = Cdi + Cd0;

if any(Cd <= 0)
    error('Invalid drag coefficient: Cd must be positive to compute L/D.');
end

LD = Cl ./ Cd;

% =====================================================
% CLEAN OUTPUT TABLE
% =====================================================
results = table(AOA, Cl, Cdi, Cd0, Cmy, Cd, LD, ...
    'VariableNames', {'AOA','Cl','Cdi','Cd0','Cmy','Cd','L_D'});

disp(results);

% =====================================================
% KEY PERFORMANCE INDICATORS
% =====================================================
[maxLD, idxMaxLD] = max(LD);
[~, idxBestTrim] = min(abs(Cmy));

fprintf('\n===== SUMMARY: %s =====\n', caseName);
fprintf('Max L/D: %.4f at AOA = %.2f deg\n', maxLD, AOA(idxMaxLD));
fprintf('Best trim: Cmy = %.4f at AOA = %.2f deg\n', Cmy(idxBestTrim), AOA(idxBestTrim));

% =====================================================
% AERODYNAMIC POLAR PLOTS
% =====================================================
fig = figure('Name', caseName, 'Color', 'w');

subplot(2,2,1)
plot(AOA, Cd, 'LineWidth', 1.5,'Color',"k",'Marker','diamond',"MarkerEdgeColor","r","MarkerSize",4,"MarkerFaceColor","w")
grid on
xlabel('\alpha [deg]')
ylabel('Cd')
title('Drag: Cd')

subplot(2,2,2)
plot(AOA, Cmy,'LineWidth', 1.5,'Color',"k",'Marker','diamond',"MarkerEdgeColor","r","MarkerSize",4,"MarkerFaceColor","w")
yline(0, '--')
grid on
xlabel('\alpha [deg]')
ylabel('Cmy')
title('Moment: Cmy')

subplot(2,2,3)
plot(AOA, Cl, 'LineWidth', 1.5,'Color',"k",'Marker','diamond',"MarkerEdgeColor","r","MarkerSize",4,"MarkerFaceColor","w")
grid on
xlabel('\alpha [deg]')
ylabel('Cl')
title('Lift: Cl')

subplot(2,2,4)
plot(AOA, LD, 'LineWidth', 1.5,'Color',"k",'Marker','diamond',"MarkerEdgeColor","r","MarkerSize",4,"MarkerFaceColor","w")
grid on
xlabel('\alpha [deg]')
ylabel('L/D')
title('Efficiency: L/D')

sgtitle(caseName)

% =====================================================
% OUTPUT FOLDER
% =====================================================
outputFolder = "";

if ~exist(outputFolder, "dir")
    mkdir(outputFolder);
end

outputExcel = fullfile(outputFolder, "FlightStream_refined_results.xlsx");
outputPlots = fullfile(outputFolder, "FlightStream_plots.png");
outputTXT   = fullfile(outputFolder, "FlightStream_refined_results.txt");

% =====================================================
% EXPORT CLEAN TABLE AND FIGURES
% =====================================================
writetable(results, outputExcel, 'Sheet', caseName);

writetable(results, outputTXT, ...
    'Delimiter', '\t', ...
    'FileType', 'text');

saveas(fig, outputPlots);

% =====================================================
% POP-UP TABLE FOR QUICK VISUAL INSPECTION
% =====================================================
tableFig = figure('Name', 'Clean FlightStream Table', ...
    'Color', 'w', ...
    'Position', [100 100 950 360]);

uitable(tableFig, ...
    'Data', table2cell(results), ...
    'ColumnName', {'AOA','Cl','Cdi','Cd0','Cmy','Cd','L/D'}, ...
    'RowName', [], ...
    'Units', 'normalized', ...
    'Position', [0.02 0.02 0.96 0.88]);

annotation(tableFig, 'textbox', [0.02 0.91 0.96 0.07], ...
    'String', caseName + " - Clean FlightStream Table", ...
    'EdgeColor', 'none', ...
    'HorizontalAlignment', 'center', ...
    'FontWeight', 'bold', ...
    'FontSize', 12);

fprintf('\nFiles saved in:\n%s\n', outputFolder);
fprintf('Excel file:     %s\n', outputExcel);
fprintf('Plots PNG file: %s\n', outputPlots);
fprintf('TXT file:       %s\n', outputTXT);

