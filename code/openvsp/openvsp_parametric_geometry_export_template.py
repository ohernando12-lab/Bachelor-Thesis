"""
OpenVSP Parametric Geometry and P3D Export Template
Author: Omar Hernando de la Torre
Description: Template version of the OpenVSP automation script. It generates
.vsp3 and .p3d files from a user-defined parametric design space while avoiding
personal paths and fixed project-specific simulation values.
"""

from __future__ import print_function
import openvsp as vsp
import numpy as np
import os
import sys
import time

# --- User Inputs ---
# Fill these arrays with the design points to be exported.
xw_range = np.array([], dtype=float)      # Main wing X positions [m]
xc_range = np.array([], dtype=float)      # Canard X positions [m]
rot_range = np.array([], dtype=float)     # Canard pitch/incidence angles [deg]

INPUT_FILE = r""                          # Path to the baseline .vsp3 file
BASE_DIR = r""                            # Output directory for generated cases

WING_NAME = "Wing"
CANARD_NAME = "Canard"

WING_X_PARAM = "X_Rel_Location"
CANARD_X_PARAM = "X_Rel_Location"
CANARD_ROT_PARAM = "Y_Rel_Rotation"
PARAM_GROUP = "XForm"


def validate_inputs():
    """Stop early if the template has not been filled."""
    if not INPUT_FILE:
        raise ValueError("INPUT_FILE is empty. Provide the baseline .vsp3 path.")
    if not BASE_DIR:
        raise ValueError("BASE_DIR is empty. Provide an output folder.")
    if len(xw_range) == 0 or len(xc_range) == 0 or len(rot_range) == 0:
        raise ValueError("At least one value is required in xw_range, xc_range and rot_range.")


validate_inputs()

# --- Output Folder Structure ---
PATH_VSP3 = os.path.join(BASE_DIR, "VSP3")
PATH_P3D = os.path.join(BASE_DIR, "P3D")

for folder in [PATH_VSP3, PATH_P3D]:
    if not os.path.exists(folder):
        os.makedirs(folder)

# --- Initialization ---
vsp.VSPCheckSetup()
vsp.ReadVSPFile(INPUT_FILE)

wing_id = vsp.FindGeom(WING_NAME, 0)
canard_id = vsp.FindGeom(CANARD_NAME, 0)

if not wing_id or not canard_id:
    print("Error: required OpenVSP geometry not found. Check component names.")
    sys.exit(1)

xw_parm = vsp.FindParm(wing_id, WING_X_PARAM, PARAM_GROUP)
xc_parm = vsp.FindParm(canard_id, CANARD_X_PARAM, PARAM_GROUP)
rot_parm = vsp.FindParm(canard_id, CANARD_ROT_PARAM, PARAM_GROUP)

missing_parameters = []
if not xw_parm:
    missing_parameters.append(WING_X_PARAM)
if not xc_parm:
    missing_parameters.append(CANARD_X_PARAM)
if not rot_parm:
    missing_parameters.append(CANARD_ROT_PARAM)

if missing_parameters:
    print("Error: OpenVSP parameter(s) not found: {}".format(", ".join(missing_parameters)))
    sys.exit(1)

total_cases = len(xw_range) * len(xc_range) * len(rot_range)
print("\nStarting generation of {} geometries...".format(total_cases))
start_time = time.time()
case_count = 0

# --- Parametric Sweep ---
for xw in xw_range:
    for xc in xc_range:
        for r_val in rot_range:
            case_count += 1
            case_name = "Case_Xw{:.3f}_Xc{:.3f}_Rot{:.3f}".format(xw, xc, r_val)
            print("[{}/{}] Generating {}... ".format(case_count, total_cases, case_name))

            vsp.SetParmVal(xw_parm, xw)
            vsp.SetParmVal(xc_parm, xc)
            vsp.SetParmVal(rot_parm, r_val)
            vsp.Update()

            vsp3_filepath = os.path.join(PATH_VSP3, case_name + ".vsp3")
            p3d_filepath = os.path.join(PATH_P3D, case_name + ".p3d")

            vsp.WriteVSPFile(vsp3_filepath)
            vsp.ExportFile(p3d_filepath, vsp.SET_ALL, vsp.EXPORT_PLOT3D)

print("\nGeneration completed in {:.2f} seconds.".format(time.time() - start_time))
