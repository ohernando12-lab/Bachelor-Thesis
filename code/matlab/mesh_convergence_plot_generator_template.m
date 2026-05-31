    % =========================================================================
% SCRIPT:       MESH_CONVERGENCE_PLOTS_TEMPLATE
% AUTHOR:       Omar Hernando de la Torre
% DATE:         April 2026
%
% DESCRIPTION:  Sanitized MATLAB template for plotting mesh convergence
%               results. Fill the convergence tables and Y-axis limits before
%               running the script.
% =========================================================================

clear; clc; close all;
format long g;

%% =========================
%  USER INPUTS
%  =========================

outputFolder = "";
Y_LIMIT_MODE = "componentCoefficient";

if strlength(outputFolder) == 0
    error('outputFolder is empty. Provide an output directory.');
end

validModes = ["componentCoefficient", "coefficientGlobal"];
if ~ismember(Y_LIMIT_MODE, validModes)
    error('Invalid Y_LIMIT_MODE. Use "componentCoefficient" or "coefficientGlobal".');
end

%% =========================
%  DATA TABLES
%  =========================
%  Fill each makeTable call with U, V, Cz, Cx and Cmy vectors.

data.Wing.FixedU = makeTable([], [], [], [], []);
data.Wing.FixedV = makeTable([], [], [], [], []);

data.Canard.FixedU = makeTable([], [], [], [], []);
data.Canard.FixedV = makeTable([], [], [], [], []);

data.HTP.FixedU = makeTable([], [], [], [], []);
data.HTP.FixedV = makeTable([], [], [], [], []);

%% =========================
%  Y-AXIS LIMITS
%  =========================

YComp.Wing.Cz = [];
YComp.Wing.Cx = [];
YComp.Wing.Cmy = [];

YComp.Canard.Cz = [];
YComp.Canard.Cx = [];
YComp.Canard.Cmy = [];

YComp.HTP.Cz = [];
YComp.HTP.Cx = [];
YComp.HTP.Cmy = [];

YGlobal.Cz = [];
YGlobal.Cx = [];
YGlobal.Cmy = [];

%% =========================
%  INPUT CHECKS
%  =========================

components = {
    'Wing',   'Wing';
    'Canard', 'Canard';
    'HTP',    'Horizontal Tail'
};

coeffs = {'Cz', 'Cx', 'Cmy'};
sweeps = {'FixedU', 'FixedV'};

for i = 1:size(components,1)
    fieldName = components{i,1};
    for j = 1:numel(sweeps)
        if isempty(data.(fieldName).(sweeps{j}))
            error('Fill data.%s.%s before running the script.', fieldName, sweeps{j});
        end
    end
end

%% =========================
%  GENERATE PLOTS AND TABLES
%  =========================

if ~exist(outputFolder, "dir")
    mkdir(outputFolder);
end

plotMeshFigure(data, components, coeffs, "FixedU", "Fixed U", "V", "V span", ...
    Y_LIMIT_MODE, YComp, YGlobal, outputFolder);

plotMeshFigure(data, components, coeffs, "FixedV", "Fixed V", "U", "U chord", ...
    Y_LIMIT_MODE, YComp, YGlobal, outputFolder);

plotMeshTables(data, components, outputFolder);

fprintf('\nFiles saved in:\n%s\n', outputFolder);

%% =========================
%  LOCAL FUNCTIONS
%  =========================

function T = makeTable(U, V, Cz, Cx, Cmy)
    vectorLengths = [numel(U), numel(V), numel(Cz), numel(Cx), numel(Cmy)];
    if any(vectorLengths ~= vectorLengths(1))
        error('Mesh convergence vectors must have the same length.');
    end

    if isempty(U)
        T = table();
        return
    end

    T = table(U(:), V(:), Cz(:), Cx(:), Cmy(:), ...
        'VariableNames', {'U','V','Cz','Cx','Cmy'});
end

function plotMeshFigure(data, components, coeffs, sweepField, sweepTitle, xVar, xLabel, ...
    yMode, YComp, YGlobal, outputFolder)

    fig = figure('Color','w', ...
        'Name', "Mesh Convergence - " + sweepTitle, ...
        'Position', [50 50 1700 850]);

    tiledlayout(3,3, 'TileSpacing','compact', 'Padding','compact');

    for i = 1:numel(coeffs)
        coef = coeffs{i};

        for j = 1:size(components,1)
            fieldName = components{j,1};
            displayName = components{j,2};
            T = data.(fieldName).(sweepField);

            nexttile;

            plot(T.(xVar), T.(coef), ...
                'LineWidth', 1.5, ...
                'Color', "g", ...
                'Marker', 'diamond', ...
                'MarkerEdgeColor', "r", ...
                'MarkerSize', 4, ...
                'MarkerFaceColor', "w");

            grid on;
            xlabel(xLabel);
            ylabel(coef);
            title(sprintf('%s Mesh Convergence - %s (%s)', coef, displayName, sweepTitle));

            if yMode == "coefficientGlobal"
                ylim(YGlobal.(coef));
            else
                ylim(YComp.(fieldName).(coef));
            end

            xlim([min(T.(xVar)) max(T.(xVar))]);
            xticks(T.(xVar));
            ytickformat('%.4f');
        end
    end

    fileName = "Mesh_Convergence_" + erase(sweepTitle, " ") + ".png";
    exportgraphics(fig, fullfile(outputFolder, fileName), 'Resolution', 300);
end

function plotMeshTables(data, components, outputFolder)
    fig = figure('Name','Mesh Convergence Tables', ...
        'Color','w', ...
        'Position',[50 50 1500 850]);

    tiledlayout(1,3, 'TileSpacing','compact', 'Padding','compact');

    for j = 1:size(components,1)
        fieldName = components{j,1};
        displayName = components{j,2};

        ax = nexttile;
        axis(ax, 'off');

        title(ax, displayName, 'FontWeight', 'bold');
        text(ax, 0.05, 0.85, "Fixed U", 'FontWeight', 'bold');
        text(ax, 0.05, 0.78, evalc('disp(data.(fieldName).FixedU)'), ...
            'FontName', 'Consolas', 'FontSize', 8);
        text(ax, 0.05, 0.42, "Fixed V", 'FontWeight', 'bold');
        text(ax, 0.05, 0.35, evalc('disp(data.(fieldName).FixedV)'), ...
            'FontName', 'Consolas', 'FontSize', 8);
    end

    exportgraphics(fig, fullfile(outputFolder, "Mesh_Convergence_Tables.png"), ...
        'Resolution', 300);
end
