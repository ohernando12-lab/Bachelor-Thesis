clear; clc;
format long g;

%% ========================================================================
%
%  Script: CANARD_GEOMETRY_ITERATION_TEMPLATE
%
%  Author: Omar Hernando de la Torre
%
%  Date: April 2026
%
%  Degree: BSc in Aerospace Engineering
%
%  Thesis: Aerodynamic and Stability Analysis of Canard Configurations for
%          Commercial Aircraft
%
%  Description:This script performs a local linear sensitivity-based correction of
%              the longitudinal aircraft geometry. The objective is to estimate a
%              new configuration that improves the trim and static stability
%              condition of the aircraft at a prescribed flight condition.
%
%              The aerodynamic response is obtained from FlightStream simulations.
%              A baseline configuration and five perturbed configurations are used
%              to build a finite-difference sensitivity matrix. The matrix relates
%              small changes in the selected design variables to changes in the
%              longitudinal aerodynamic coefficients.
%
%  Main aerodynamic targets:
%       CL(0 deg)  -> Target lift coefficient at zero angle of attack
%       Cm(0 deg)  -> Target pitching moment coefficient at zero angle of attack
%       Cma        -> Target pitching moment slope with angle of attack
%
%  Design variables:
%       Xw   : Longitudinal position of the main wing [m]
%       xCG  : Longitudinal position of the centre of gravity [m]
%       iw   : Common variation of the wing incidence/twist [deg]
%              iw1_new = iw1_base + diw
%              iw2_new = iw2_base + diw
%       ic   : Canard incidence angle [deg]
%       k    : Canard linear scale factor used in OpenVSP [-]
%
%  Diagnostic parameters:
%       CLa  : Lift curve slope [1/deg]
%       Cma  : Pitching moment slope [1/deg]
%       SM   : Static margin as a fraction of the wing MAC [-]
%       xNP  : Estimated neutral point position [m]
%       Vc   : Canard volume coefficient [-]
%
%  Methodology:
%       The correction is based on the linear relation:
%
%           dy = A * dx
%
%       where:
%
%           dy = [dCL; dCm; dCma]
%
%       and:
%
%           dx = [dXw; dxCG; diw; dic; dk]
%
%       The matrix A is obtained through finite differences from the
%       perturbed FlightStream cases. A constrained weighted least-squares
%       problem is then solved to estimate the geometry correction.
%
%  Notes:
%       - Vc is calculated only as a diagnostic parameter. It is not used as
%         an optimisation target in this version of the script.
%       - The correction is local and linear. Therefore, the proposed
%         geometry must be re-simulated in FlightStream.
%       - If the predicted and simulated results differ significantly, the
%         new simulated configuration should be used as the next baseline
%         and the process should be repeated.
%
%  Canard scale convention:
%       The canard scale factor k is treated as a linear scale factor and
%       the diagnostic volume coefficient uses FlightStream exposed area.
%       Therefore:
%
%           S_canard_exposed   = S_canard_base * k^2
%           MAC_canard_exposed = MAC_canard_base * k
%           xac_canard         = Xc + k * xac_offset_base
%
%  Stability relations:
%       The aerodynamic slopes are estimated from the polar values at
%       alpha = -2 deg and alpha = +2 deg:
%
%           CLa = (CL(+2) - CL(-2)) / 4
%           Cma = (Cm(+2) - Cm(-2)) / 4
%
%       FlightStream normalises the pitching moment coefficient with Lref.
%       Therefore, -Cma/CLa first gives a distance normalised by Lref. It
%       is converted to a wing-MAC static margin before reporting:
%
%           SM_Lref = -Cma / CLa
%           SM_MAC  = SM_Lref * Lref / MAC
%           xNP     = xCG + SM_Lref * Lref


%% =======================
%  1. TARGET VALUES
%  =======================

CL_target  = [];      % Target lift coefficient at alpha = 0 deg
Cm_target  = [];      % Target pitching moment coefficient at alpha = 0 deg
Cma_target = [];     % Target pitching moment slope [1/deg]


%% =======================
%  2. AIRCRAFT REFERENCE DATA
%  =======================

Sw  = [];           % Wing reference area [m^2]
MAC = [];             % Wing mean aerodynamic chord [m]
Lref = [];           % FlightStream moment reference length [m]


%% =======================
%  3. CANARD EXPOSED GEOMETRY FROM FLIGHTSTREAM
%  =======================

k_canard_reference = []; % Reference OpenVSP canard scale factor [-]

Xc = [];                  % Exposed canard root leading-edge X position in FlightStream [m]

% Exposed canard dimensions measured in FlightStream at k = 1.06.
S_canard_exposed_ref = []; % FlightStream exposed canard area [m^2]
b_canard_semi_ref = []; % Exposed canard semispan [m]
cr_canard_ref     = [];  % Exposed canard root chord [m]
ct_canard_ref     = [];  % Exposed canard tip chord [m]

% Convert exposed reference dimensions to an equivalent k = 1 baseline.
b_canard_semi = b_canard_semi_ref / k_canard_reference;
cr_canard     = cr_canard_ref     / k_canard_reference;
ct_canard     = ct_canard_ref     / k_canard_reference;

lambda_c = ct_canard / cr_canard;

% Exposed canard area for k = 1
S_canard_base = S_canard_exposed_ref / k_canard_reference^2;

% Exposed canard MAC for k = 1
MAC_canard_base = (2/3) * cr_canard * ...
    (1 + lambda_c + lambda_c^2) / (1 + lambda_c);

% Spanwise position of the exposed canard MAC for k = 1
y_MAC_canard_base = (b_canard_semi/3) * ...
    (1 + 2*lambda_c) / (1 + lambda_c);

sweep_c4_deg = [];      % Quarter-chord sweep angle [deg]

% Longitudinal offset from Xc to the exposed canard aerodynamic centre for k = 1
xac_offset_base = 0.25*cr_canard + ...
    y_MAC_canard_base * tand(sweep_c4_deg);


%% =======================
%  4. BASELINE GEOMETRY
%  =======================

Xw0  = [];            % Baseline wing X position [m]
xCG0 = [];             % Baseline CG X position [m]

iw1_0 = [];           % Baseline wing twist section 1 [deg]
iw2_0 = [];           % Baseline wing twist section 2 [deg]

ic0 = [];                % Baseline canard incidence [deg]
k0  = k_canard_reference; % Baseline canard linear scale factor [-]

% Canard geometry at baseline scale
Sc0 = k0^2;

MAC_canard0     = MAC_canard_base * k0;
xac_canard0     = Xc + k0 * xac_offset_base;
S_canard_exposed0  = S_canard_base * k0^2;
lc0             = abs(xCG0 - xac_canard0);
Vc0             = (S_canard_exposed0 * lc0) / (Sw * MAC);


%% =======================
%  5. BASELINE AERODYNAMIC RESULTS
%  =======================
%  Values extracted from the FlightStream polar at alpha = -2, 0 and +2 deg.

CL_m2_0 = [];
CL0     = [];
CL_p2_0 = [];

Cm_m2_0 = [];
Cm0     = [];
Cm_p2_0 = [];

CLa0 = (CL_p2_0 - CL_m2_0) / 4.0;
Cma0 = (Cm_p2_0 - Cm_m2_0) / 4.0;

if CLa0 <= 0
    error('Invalid baseline lift-curve slope: CLa0 must be positive.');
end

SM_Lref0 = -Cma0 / CLa0;
SM0      = SM_Lref0 * Lref / MAC;
xNP0     = xCG0 + SM_Lref0 * Lref;


%% =======================
%  6. FINITE-DIFFERENCE PERTURBATIONS
%  =======================
%  Each perturbation case must modify only one design variable.

dXw  = [];             % Wing X perturbation [m]
dxCG =  [];             % CG X perturbation [m]
diw  = [];             % Common wing twist perturbation [deg]
dic  =  [];             % Canard incidence perturbation [deg]
dk   = [];             % Canard linear scale perturbation [-]


%% ============================================================
%  7. PERTURBED CASE RESULTS
%  ============================================================

%% Case 1: wing X perturbation

CL_m2_Xw = [];
CL_Xw    = [];
CL_p2_Xw = [];

Cm_m2_Xw = [];
Cm_Xw    = [];
Cm_p2_Xw = [];

CLa_Xw = (CL_p2_Xw - CL_m2_Xw) / 4.0;
Cma_Xw = (Cm_p2_Xw - Cm_m2_Xw) / 4.0;

xCG_Xw = xCG0;
k_Xw = k0;
xac_canard_Xw = Xc + k_Xw * xac_offset_base;
S_canard_exposed_Xw = S_canard_base * k_Xw^2;
lc_Xw = abs(xCG_Xw - xac_canard_Xw);
Vc_Xw = (S_canard_exposed_Xw * lc_Xw) / (Sw * MAC);


%% Case 2: centre of gravity perturbation

CL_m2_CG = [];
CL_CG    = [];
CL_p2_CG = [];

Cm_m2_CG = [];
Cm_CG    = [];
Cm_p2_CG = [];

CLa_CG = (CL_p2_CG - CL_m2_CG) / 4.0;
Cma_CG = (Cm_p2_CG - Cm_m2_CG) / 4.0;

xCG_CG = xCG0 + dxCG;
k_CG = k0;
xac_canard_CG = Xc + k_CG * xac_offset_base;
S_canard_exposed_CG = S_canard_base * k_CG^2;
lc_CG = abs(xCG_CG - xac_canard_CG);
Vc_CG = (S_canard_exposed_CG * lc_CG) / (Sw * MAC);


%% Case 3: wing twist perturbation

CL_m2_iw = [];
CL_iw    = [];
CL_p2_iw = [];

Cm_m2_iw = [];
Cm_iw    = [];
Cm_p2_iw = [];

CLa_iw = (CL_p2_iw - CL_m2_iw) / 4.0;
Cma_iw = (Cm_p2_iw - Cm_m2_iw) / 4.0;

xCG_iw = xCG0;
k_iw = k0;
xac_canard_iw = Xc + k_iw * xac_offset_base;
S_canard_exposed_iw = S_canard_base * k_iw^2;
lc_iw = abs(xCG_iw - xac_canard_iw);
Vc_iw = (S_canard_exposed_iw * lc_iw) / (Sw * MAC);


%% Case 4: canard incidence perturbation

CL_m2_ic = [];
CL_ic    = [];
CL_p2_ic = [];

Cm_m2_ic = [];
Cm_ic    = [];
Cm_p2_ic = [];

CLa_ic = (CL_p2_ic - CL_m2_ic) / 4.0;
Cma_ic = (Cm_p2_ic - Cm_m2_ic) / 4.0;

xCG_ic = xCG0;
k_ic = k0;
xac_canard_ic = Xc + k_ic * xac_offset_base;
S_canard_exposed_ic = S_canard_base * k_ic^2;
lc_ic = abs(xCG_ic - xac_canard_ic);
Vc_ic = (S_canard_exposed_ic * lc_ic) / (Sw * MAC);


%% Case 5: canard scale perturbation

CL_m2_k = [];
CL_k    = [];
CL_p2_k = [];

Cm_m2_k = [];
Cm_k    = [];
Cm_p2_k = [];

CLa_k = (CL_p2_k - CL_m2_k) / 4.0;
Cma_k = (Cm_p2_k - Cm_m2_k) / 4.0;

xCG_k = xCG0;
k_k = k0 + dk;
xac_canard_k = Xc + k_k * xac_offset_base;
S_canard_exposed_k = S_canard_base * k_k^2;
lc_k = abs(xCG_k - xac_canard_k);
Vc_k = (S_canard_exposed_k * lc_k) / (Sw * MAC);


%% ============================================================
%  8. INPUT DATA CHECKS
%  ============================================================

data_vector = [CL_m2_Xw; CL_Xw; CL_p2_Xw; Cm_m2_Xw; Cm_Xw; Cm_p2_Xw; ...
               CL_m2_CG; CL_CG; CL_p2_CG; Cm_m2_CG; Cm_CG; Cm_p2_CG; ...
               CL_m2_iw; CL_iw; CL_p2_iw; Cm_m2_iw; Cm_iw; Cm_p2_iw; ...
               CL_m2_ic; CL_ic; CL_p2_ic; Cm_m2_ic; Cm_ic; Cm_p2_ic; ...
               CL_m2_k;  CL_k;  CL_p2_k;  Cm_m2_k;  Cm_k;  Cm_p2_k];

if any(isnan(data_vector))
    error('Some perturbed aerodynamic values are missing.');
end


%% ============================================================
%  9. ERROR VECTOR
%  ============================================================

dy = [CL_target  - CL0;
      Cm_target  - Cm0;
      Cma_target - Cma0];


%% ============================================================
%  10. SENSITIVITY MATRIX
%  ============================================================
%  Each column contains the finite-difference sensitivities of
%  [CL, Cm, Cma] with respect to one design variable.

A = zeros(3,5);

A(:,1) = [(CL_Xw  - CL0)  / dXw;
          (Cm_Xw  - Cm0)  / dXw;
          (Cma_Xw - Cma0) / dXw];

A(:,2) = [(CL_CG  - CL0)  / dxCG;
          (Cm_CG  - Cm0)  / dxCG;
          (Cma_CG - Cma0) / dxCG];

A(:,3) = [(CL_iw  - CL0)  / diw;
          (Cm_iw  - Cm0)  / diw;
          (Cma_iw - Cma0) / diw];

A(:,4) = [(CL_ic  - CL0)  / dic;
          (Cm_ic  - Cm0)  / dic;
          (Cma_ic - Cma0) / dic];

A(:,5) = [(CL_k  - CL0)  / dk;
          (Cm_k  - Cm0)  / dk;
          (Cma_k - Cma0) / dk];

% Warning if one design variable appears to have no local influence.
col_norms = vecnorm(A);

if any(col_norms < 1e-6)
    warning('At least one sensitivity column is almost zero. Check the corresponding perturbation case.');
end


%% ============================================================
%  11. CONSTRAINED WEIGHTED LEAST-SQUARES SOLUTION
%  ============================================================

% Objective weights based on acceptable tolerances.
CL_tolerance = [];
Cm_tolerance = [];
Cma_tolerance = [];

w_CL  = 1/CL_tolerance;
w_Cm  = 1/Cm_tolerance;
w_Cma = 1/Cma_tolerance;

W = diag([w_CL, w_Cm, w_Cma]);

A_w  = W * A;
dy_w = W * dy;

dx_pinv = pinv(A_w) * dy_w;

% Maximum allowed correction in a single iteration.
lb_step = [];
ub_step = [];

% Absolute physical limits.
Xw_min  = [];
Xw_max  = [];

xCG_min = [];
xCG_max = [];

iw_min  = [];
iw_max  = [];

ic_min  = [];
ic_max  = [];

k_min   = [];
k_max   = [];

lb_abs = [Xw_min  - Xw0;
          xCG_min - xCG0;
          iw_min  - iw1_0;
          ic_min  - ic0;
          k_min   - k0];

ub_abs = [Xw_max  - Xw0;
          xCG_max - xCG0;
          iw_max  - iw2_0;
          ic_max  - ic0;
          k_max   - k0];

lb = max(lb_step, lb_abs);
ub = min(ub_step, ub_abs);

if any(lb > ub)
    disp(table(lb, ub, 'VariableNames', {'LowerBound','UpperBound'}))
    error('Incompatible optimisation limits: at least one lower bound is greater than its upper bound.');
end

if exist('lsqlin','file') == 2
    options = optimoptions('lsqlin','Display','off');
    dx_lsq = lsqlin(A_w, dy_w, [], [], [], [], lb, ub, [], options);
else
    warning('lsqlin not available. Pseudoinverse solution will be used without constraints.');
    dx_lsq = dx_pinv;
end

%% ============================================================
%  12. RELAXATION FACTOR
%  ============================================================
%  The linear solution is relaxed to reduce overshooting in the
%  non-linear aerodynamic model.

relaxation = [];

dx_used = relaxation * dx_lsq;


%% ============================================================
%  13. NEW GEOMETRY
%  ============================================================

Xw_new  = Xw0  + dx_used(1);
xCG_new = xCG0 + dx_used(2);

iw1_new = iw1_0 + dx_used(3);
iw2_new = iw2_0 + dx_used(3);

ic_new = ic0 + dx_used(4);

k_new  = k0 + dx_used(5);
Sc_new = k_new^2;

MAC_canard_new    = MAC_canard_base * k_new;
xac_canard_new    = Xc + k_new * xac_offset_base;
S_canard_exposed_new = S_canard_base * k_new^2;

lc_new = abs(xCG_new - xac_canard_new);

Vc_new = (S_canard_exposed_new * lc_new) / (Sw * MAC);


%% ============================================================
%  14. LINEAR PREDICTION
%  ============================================================

y0 = [CL0; Cm0; Cma0];
y_pred = y0 + A * dx_used;

CL_pred  = y_pred(1);
Cm_pred  = y_pred(2);
Cma_pred = y_pred(3);

% Estimate the new lift curve slope for neutral point calculation.
B_CLa = zeros(1,5);

B_CLa(1) = (CLa_Xw - CLa0) / dXw;
B_CLa(2) = (CLa_CG - CLa0) / dxCG;
B_CLa(3) = (CLa_iw - CLa0) / diw;
B_CLa(4) = (CLa_ic - CLa0) / dic;
B_CLa(5) = (CLa_k  - CLa0) / dk;

CLa_pred = CLa0 + B_CLa * dx_used;

if CLa_pred <= 0
    warning('Predicted lift-curve slope is not positive. Static-margin estimate may not be physically meaningful.');
end

SM_Lref_pred = -Cma_pred / CLa_pred;
SM_pred      = SM_Lref_pred * Lref / MAC;
xNP_pred     = xCG_new + SM_Lref_pred * Lref;


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
    ["dXw_used"; "dxCG_used"; "diw_used"; "dic_used"; "dk_used"; ...
     "CL_pred"; "Cm_pred"; "Cma_pred"; "SM_MAC_pred"; "xNP_pred"], ...
    [dx_used(1); dx_used(2); dx_used(3); dx_used(4); dx_used(5); ...
     CL_pred; Cm_pred; Cma_pred; SM_pred; xNP_pred], ...
    ["m"; "m"; "deg"; "deg"; "-"; "-"; "-"; "1/deg"; "MAC"; "m"], ...
    'VariableNames', {'Variable','Value','Unit'});

fprintf('\n================ GEOMETRY TO APPLY NOW ================\n')
disp(newGeometry)

fprintf('\n================ CANARD GEOMETRY DIAGNOSTICS ================\n')
disp(canardDiagnostics)

fprintf('\n================ LINEAR PREDICTION SUMMARY ================\n')
disp(predictionSummary)


