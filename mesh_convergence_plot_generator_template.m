% =========================================================================
% SCRIPT:       MESH_CONVERGENCE_PLOTS_TEMPLATE
% AUTHOR:       Omar Hernando de la Torre
% DATE:         April 2026
%
% DESCRIPTION:  This script stores the mesh convergence data obtained from
%               FlightStream for the wing, canard and horizontal tail. It
%               generates coefficient plots for the fixed-U and fixed-V
%               refinement sweeps and exports a graphical summary table.
%
% INPUT:        Manually entered convergence tables containing U, V, Cz, Cx
%               and Cmy values for each lifting component.
%
% OUTPUT:       PNG figures with bounded Y-axis limits and formatted tables
%               suitable for direct inclusion in the thesis.
% =========================================================================

clear; clc; close all;
format long g;

%% =========================
%  OUTPUT SETTINGS
%  =========================

% Save generated figures in the same folder as this MATLAB script.
outputFolder = fileparts(mfilename('fullpath'));

Y_LIMIT_MODE = "componentCoefficient"; 
% "componentCoefficient" -> same Y limits for Fixed U and Fixed V of each component/coefficient
% "coefficientGlobal"    -> same Y limits for all components of each coefficient

validModes = ["componentCoefficient", "coefficientGlobal"];
if ~ismember(Y_LIMIT_MODE, validModes)
    error('Invalid Y_LIMIT_MODE. Use "componentCoefficient" or "coefficientGlobal".');
end

%% =========================
%  DATA TABLES
%  =========================
%  Each table corresponds to one isolated component convergence sweep.
%  FixedU varies the V direction and FixedV varies the U direction.

data.Wing.FixedU = makeTable([], [], [], [], []);

data.Wing.FixedV = makeTable([], [], [], [], []);

data.Canard.FixedU = makeTable([], [], [], [], []);

data.Canard.FixedV = makeTable([], [], [], [], []);

data.HTP.FixedU = makeTable([], [], [], [], []);

data.HTP.FixedV = makeTable([], [], [], [], []);

%% =========================
%  Y-AXIS LIMITS
%  =========================
%  Component limits avoid visually exaggerating sub-percent variations.

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
%  GENERATE PLOTS AND TABLES
%  =========================

components = {
    'Wing',   'Wing';
    'Canard', 'Canard';
    'HTP',    'Horizontal Tail'
};

coeffs = {'Cz', 'Cx', 'Cmy'};

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
    % Convert numerical vectors into a labelled convergence table.
    vectorLengths = [numel(U), numel(V), numel(Cz), numel(Cx), numel(Cmy)];
    if any(vectorLengths ~= vectorLengths(1))
        error('Mesh convergence vectors must have the same length.');
    end

    T = table(U(:), V(:), Cz(:), Cx(:), Cmy(:), ...
        'VariableNames', {'U','V','Cz','Cx','Cmy'});
end

function plotMeshFigure(data, components, coeffs, sweepField, sweepTitle, xVar, xLabel, ...
    yMode, YComp, YGlobal, outputFolder)
    % Generate the 3-by-3 convergence plot matrix for one sweep direction.

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
    % Generate one formatted image containing all convergence data tables.

    fig = figure('Name','Mesh Convergence Tables', ...
        'Color','w', ...
        'Position',[50 50 1500 850]);

    mainLayout = tiledlayout(1,3, ...
        'TileSpacing','compact', ...
        'Padding','compact');

    for j = 1:size(components,1)
        fieldName = components{j,1};
        displayName = components{j,2};

        ax = nexttile;
        axis(ax, 'off');

        pos = ax.Position;

        % Component title band
        annotation(fig, 'textbox', ...
            [pos(1), pos(2)+pos(4)-0.035, pos(3), 0.035], ...
            'String', displayName, ...
            'EdgeColor', 'none', ...
            'BackgroundColor', [0 0 0.35], ...
            'Color', 'w', ...
            'FontWeight', 'bold', ...
            'FontSize', 14, ...
            'HorizontalAlignment', 'center', ...
            'VerticalAlignment', 'middle');

        % Fixed U subtitle
        annotation(fig, 'textbox', ...
            [pos(1), pos(2)+pos(4)-0.080, pos(3), 0.030], ...
            'String', 'Fixed U', ...
            'EdgeColor', 'none', ...
            'FontSize', 13, ...
            'HorizontalAlignment', 'center', ...
            'VerticalAlignment', 'middle');

        % Fixed U table
        addTable(fig, data.(fieldName).FixedU, ...
            [pos(1)+0.01, pos(2)+pos(4)-0.350, pos(3)-0.02, 0.245]);

        % Fixed V subtitle
        annotation(fig, 'textbox', ...
            [pos(1), pos(2)+pos(4)-0.420, pos(3), 0.030], ...
            'String', 'Fixed V', ...
            'EdgeColor', 'none', ...
            'FontSize', 13, ...
            'HorizontalAlignment', 'center', ...
            'VerticalAlignment', 'middle');

        % Fixed V table
        addTable(fig, data.(fieldName).FixedV, ...
            [pos(1)+0.01, pos(2)+0.04, pos(3)-0.02, pos(4)-0.500]);
    end

    exportgraphics(fig, fullfile(outputFolder, "Mesh_Convergence_Tables.png"), ...
        'Resolution', 300);
end

function addTable(fig, T, position)
    % Insert a formatted uitable at a normalized position inside the figure.

    formatted = cell(height(T), width(T));

    for i = 1:height(T)
        formatted{i,1} = sprintf('%.0f', T.U(i));
        formatted{i,2} = sprintf('%.0f', T.V(i));
        formatted{i,3} = sprintf('%.5f', T.Cz(i));
        formatted{i,4} = sprintf('%.5f', T.Cx(i));
        formatted{i,5} = sprintf('%.5f', T.Cmy(i));
    end

    uit = uitable(fig, ...
        'Data', formatted, ...
        'ColumnName', {'U','V','Cz','Cx','Cmy'}, ...
        'RowName', [], ...
        'Units', 'normalized', ...
        'Position', position, ...
        'FontSize', 11);

    uit.ColumnWidth = {45,45,85,85,85};
end

