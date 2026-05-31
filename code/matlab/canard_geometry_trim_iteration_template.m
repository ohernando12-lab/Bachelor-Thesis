% =========================================================================
% SCRIPT:       CANARD_GEOMETRY_ITERATION_TEMPLATE
% AUTHOR:       Omar Hernando de la Torre
% DATE:         April 2026
%
% DESCRIPTION:  Sanitized template for a local sensitivity-based canard
%               geometry correction. Fill all user inputs before execution.
% =========================================================================

clear; clc;
format long g;

%% =======================
%  1. TARGET VALUES
%  =======================

CL_target  = [];
Cm_target  = [];
Cma_target = [];

%% =======================
%  2. AIRCRAFT REFERENCE DATA
%  =======================

Sw   = [];   % FlightStream exposed/projected reference area [m^2]
MAC  = [];   % Wing mean aerodynamic chord [m]
Lref = [];   % FlightStream pitching moment reference length [m]

%% =======================
%  3. CANARD EXPOSED GEOMETRY
%  =======================

k_canard_reference = [];
Xc = [];

S_canard_exposed_ref = [];
b_canard_semi_ref = [];
cr_canard_ref = [];
ct_canard_ref = [];
sweep_c4_deg = [];

%% =======================
%  4. BASELINE GEOMETRY
%  =======================

Xw0 = [];
xCG0 = [];
iw1_0 = [];
iw2_0 = [];
ic0 = [];
k0 = [];

%% =======================
%  5. BASELINE AERODYNAMIC RESULTS
%  =======================

CL_m2_0 = [];
CL0 = [];
CL_p2_0 = [];

Cm_m2_0 = [];
Cm0 = [];
Cm_p2_0 = [];

%% =======================
%  6. FINITE-DIFFERENCE PERTURBATIONS
%  =======================

dXw = [];
dxCG = [];
diw = [];
dic = [];
dk = [];

%% ============================================================
%  7. PERTURBED CASE RESULTS
%  ============================================================
%  Rows must follow this order: Xw, xCG, iw, ic, k.

CL_m2_cases = [];
CL_0_cases  = [];
CL_p2_cases = [];

Cm_m2_cases = [];
Cm_0_cases  = [];
Cm_p2_cases = [];

%% ============================================================
%  8. INPUT DATA CHECKS
%  ============================================================

requiredScalarInputs = {CL_target, Cm_target, Cma_target, Sw, MAC, Lref, ...
    k_canard_reference, Xc, S_canard_exposed_ref, b_canard_semi_ref, ...
    cr_canard_ref, ct_canard_ref, sweep_c4_deg, Xw0, xCG0, iw1_0, ...
    iw2_0, ic0, k0, CL_m2_0, CL0, CL_p2_0, Cm_m2_0, Cm0, Cm_p2_0, ...
    dXw, dxCG, diw, dic, dk};

if any(cellfun(@isempty, requiredScalarInputs)) || ...
   any(isnan(cell2mat(requiredScalarInputs)))
    error('One or more scalar inputs are empty. Fill the template before running it.');
end

if numel(CL_m2_cases) ~= 5 || numel(CL_0_cases) ~= 5 || numel(CL_p2_cases) ~= 5 || ...
   numel(Cm_m2_cases) ~= 5 || numel(Cm_0_cases) ~= 5 || numel(Cm_p2_cases) ~= 5
    error('Perturbed aerodynamic vectors must contain five values: Xw, xCG, iw, ic and k.');
end

if any(isnan([CL_m2_cases(:); CL_0_cases(:); CL_p2_cases(:); ...
              Cm_m2_cases(:); Cm_0_cases(:); Cm_p2_cases(:)]))
    error('One or more perturbed aerodynamic values are NaN.');
end

%% ============================================================
%  9. CANARD GEOMETRY MODEL
%  ============================================================

b_canard_semi = b_canard_semi_ref / k_canard_reference;
cr_canard = cr_canard_ref / k_canard_reference;
ct_canard = ct_canard_ref / k_canard_reference;

lambda_c = ct_canard / cr_canard;

S_canard_base = S_canard_exposed_ref / k_canard_reference^2;
MAC_canard_base = (2/3) * cr_canard * ...
    (1 + lambda_c + lambda_c^2) / (1 + lambda_c);
y_MAC_canard_base = (b_canard_semi/3) * ...
    (1 + 2*lambda_c) / (1 + lambda_c);
xac_offset_base = 0.25*cr_canard + y_MAC_canard_base * tand(sweep_c4_deg);

MAC_canard0 = MAC_canard_base * k0;
xac_canard0 = Xc + k0 * xac_offset_base;
S_canard_exposed0 = S_canard_base * k0^2;
lc0 = abs(xCG0 - xac_canard0);
Vc0 = (S_canard_exposed0 * lc0) / (Sw * MAC);

%% ============================================================
%  10. BASELINE STABILITY
%  ============================================================

CLa0 = (CL_p2_0 - CL_m2_0) / 4.0;
Cma0 = (Cm_p2_0 - Cm_m2_0) / 4.0;

if CLa0 <= 0
    error('Invalid baseline lift-curve slope: CLa0 must be positive.');
end

SM_Lref0 = -Cma0 / CLa0;
SM0 = SM_Lref0 * Lref / MAC;
xNP0 = xCG0 + SM_Lref0 * Lref;

%% ============================================================
%  11. SENSITIVITY MATRIX
%  ============================================================

CLa_cases = (CL_p2_cases(:) - CL_m2_cases(:)) / 4.0;
Cma_cases = (Cm_p2_cases(:) - Cm_m2_cases(:)) / 4.0;

dy = [CL_target - CL0;
      Cm_target - Cm0;
      Cma_target - Cma0];

dSteps = [dXw; dxCG; diw; dic; dk];
A = zeros(3,5);

for i = 1:5
    A(:,i) = [(CL_0_cases(i) - CL0) / dSteps(i);
              (Cm_0_cases(i) - Cm0) / dSteps(i);
              (Cma_cases(i) - Cma0) / dSteps(i)];
end

if any(vecnorm(A) < 1e-6)
    warning('At least one sensitivity column is almost zero. Check the corresponding perturbation case.');
end

%% ============================================================
%  12. CONSTRAINED WEIGHTED LEAST-SQUARES SOLUTION
%  ============================================================

CL_tolerance = [];
Cm_tolerance = [];
Cma_tolerance = [];

if any(cellfun(@isempty, {CL_tolerance, Cm_tolerance, Cma_tolerance}))
    error('Fill CL_tolerance, Cm_tolerance and Cma_tolerance before running the script.');
end

w_CL = 1/CL_tolerance;
w_Cm = 1/Cm_tolerance;
w_Cma = 1/Cma_tolerance;

W = diag([w_CL, w_Cm, w_Cma]);
A_w = W * A;
dy_w = W * dy;

lb_step = [];
ub_step = [];

if numel(lb_step) ~= 5 || numel(ub_step) ~= 5
    error('lb_step and ub_step must contain five values.');
end

lb_step = lb_step(:);
ub_step = ub_step(:);

Xw_min = [];
Xw_max = [];
xCG_min = [];
xCG_max = [];
iw_min = [];
iw_max = [];
ic_min = [];
ic_max = [];
k_min = [];
k_max = [];

if any(cellfun(@isempty, {Xw_min, Xw_max, xCG_min, xCG_max, iw_min, iw_max, ic_min, ic_max, k_min, k_max}))
    error('Fill all absolute optimization limits before running the script.');
end

lb_abs = [Xw_min - Xw0;
          xCG_min - xCG0;
          iw_min - iw1_0;
          ic_min - ic0;
          k_min - k0];

ub_abs = [Xw_max - Xw0;
          xCG_max - xCG0;
          iw_max - iw2_0;
          ic_max - ic0;
          k_max - k0];

lb = max(lb_step, lb_abs);
ub = min(ub_step, ub_abs);

if any(lb > ub)
    disp(table(lb, ub, 'VariableNames', {'LowerBound','UpperBound'}))
    error('Incompatible optimisation limits.');
end

if exist('lsqlin','file') == 2
    options = optimoptions('lsqlin','Display','off');
    dx_lsq = lsqlin(A_w, dy_w, [], [], [], [], lb, ub, [], options);
else
    warning('lsqlin not available. Pseudoinverse solution will be clipped to bounds.');
    dx_lsq = pinv(A_w) * dy_w;
    dx_lsq = max(lb, min(ub, dx_lsq));
end

%% ============================================================
%  13. RELAXATION AND NEW GEOMETRY
%  ============================================================

relaxation = [];

if isempty(relaxation)
    error('Fill the relaxation factor before running the script.');
end

dx_used = relaxation * dx_lsq;

Xw_new = Xw0 + dx_used(1);
xCG_new = xCG0 + dx_used(2);
iw1_new = iw1_0 + dx_used(3);
iw2_new = iw2_0 + dx_used(3);
ic_new = ic0 + dx_used(4);
k_new = k0 + dx_used(5);
Sc_new = k_new^2;

MAC_canard_new = MAC_canard_base * k_new;
xac_canard_new = Xc + k_new * xac_offset_base;
S_canard_exposed_new = S_canard_base * k_new^2;
lc_new = abs(xCG_new - xac_canard_new);
Vc_new = (S_canard_exposed_new * lc_new) / (Sw * MAC);

%% ============================================================
%  14. LINEAR PREDICTION
%  ============================================================

y0 = [CL0; Cm0; Cma0];
y_pred = y0 + A * dx_used;

CL_pred = y_pred(1);
Cm_pred = y_pred(2);
Cma_pred = y_pred(3);

B_CLa = (CLa_cases(:)' - CLa0) ./ dSteps(:)';
CLa_pred = CLa0 + B_CLa * dx_used;

SM_Lref_pred = -Cma_pred / CLa_pred;
SM_pred = SM_Lref_pred * Lref / MAC;
xNP_pred = xCG_new + SM_Lref_pred * Lref;

%% ============================================================
%  15. OUTPUT
%  ============================================================

newGeometry = table( ...
    ["Xw"; "xCG"; "iw1"; "iw2"; "ic"; "k"; "Sc"], ...
    [Xw_new; xCG_new; iw1_new; iw2_new; ic_new; k_new; Sc_new], ...
    ["m"; "m"; "deg"; "deg"; "deg"; "-"; "-"], ...
    'VariableNames', {'Variable','Value','Unit'});

canardDiagnostics = table( ...
    ["S_canard_exposed"; "MAC_canard"; "xac_canard"; "lc"; "Vc"], ...
    [S_canard_exposed_new; MAC_canard_new; xac_canard_new; lc_new; Vc_new], ...
    ["m^2"; "m"; "m"; "m"; "-"], ...
    'VariableNames', {'Variable','Value','Unit'});

predictionSummary = table( ...
    ["CL_pred"; "Cm_pred"; "Cma_pred"; "SM_MAC_pred"; "xNP_pred"], ...
    [CL_pred; Cm_pred; Cma_pred; SM_pred; xNP_pred], ...
    ["-"; "-"; "1/deg"; "MAC"; "m"], ...
    'VariableNames', {'Variable','Value','Unit'});

fprintf('\n================ GEOMETRY TO APPLY NOW ================\n')
disp(newGeometry)

fprintf('\n================ CANARD GEOMETRY DIAGNOSTICS ================\n')
disp(canardDiagnostics)

fprintf('\n================ LINEAR PREDICTION SUMMARY ================\n')
disp(predictionSummary)
