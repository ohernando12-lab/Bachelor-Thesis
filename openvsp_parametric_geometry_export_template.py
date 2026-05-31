"""
OpenVSP Parametric Geometry & P3D Generator
Author: Omar Hernando de la Torre
Description: Automates the generation of .vsp3 and .p3d (Plot3D) mesh files
for a canard configuration. Organizes outputs into respective subdirectories.
"""

from __future__ import print_function
import openvsp as vsp
import numpy as np
import os
import sys
import time

# --- Configuration and Design Space ---
xw_range = np.array([], dtype=float)     # Wing longitudinal positions (X)
xc_range = np.array([], dtype=float)     # Canard longitudinal positions (X)
rot_range = np.array([], dtype=float)    # Canard incidence angles (Y-Rotation)

INPUT_FILE = r""

# --- Output Folder Structure ---
BASE_DIR = r""
PATH_VSP3 = os.path.join(BASE_DIR, "VSP3")
PATH_P3D = os.path.join(BASE_DIR, "P3D")

# Create directories if they do not exist
for folder in [PATH_VSP3, PATH_P3D]:
    if not os.path.exists(folder):
        os.makedirs(folder)

# --- Initialization ---
vsp.VSPCheckSetup()
vsp.ReadVSPFile(INPUT_FILE)

wing_id = vsp.FindGeom("Wing", 0)
canard_id = vsp.FindGeom("Canard", 0)

if not wing_id or not canard_id:
    print("Error: required OpenVSP geometry not found. Check 'Wing' and 'Canard' names.")
    sys.exit(1)

# Locate OpenVSP transformation parameters used as design variables
xw_parm = vsp.FindParm(wing_id, "X_Rel_Location", "XForm")
xc_parm = vsp.FindParm(canard_id, "X_Rel_Location", "XForm")
rot_parm = vsp.FindParm(canard_id, "Y_Rel_Rotation", "XForm")

missing_parameters = []
if not xw_parm:
    missing_parameters.append("Wing X_Rel_Location")
if not xc_parm:
    missing_parameters.append("Canard X_Rel_Location")
if not rot_parm:
    missing_parameters.append("Canard Y_Rel_Rotation")

if missing_parameters:
    print("Error: OpenVSP parameter(s) not found: {}".format(", ".join(missing_parameters)))
    sys.exit(1)

# Total number of cases is defined by the selected discretization levels
total_cases = len(xw_range) * len(xc_range) * len(rot_range)
print("\nStarting generation of {} geometries...".format(total_cases))
start_time = time.time()
case_count = 0

# --- Parametric Sweep ---
for xw in xw_range:
    for xc in xc_range:
        for r_val in rot_range:
            case_count += 1
            case_name = "Test_Xw{:.1f}_Xc{:.1f}_Rot{:.1f}".format(xw, xc, r_val)
            print("[{}/{}] Generating {}... ".format(case_count, total_cases, case_name))

            # 1. Apply the selected geometry state before exporting the case
            vsp.SetParmVal(xw_parm, xw)
            vsp.SetParmVal(xc_parm, xc)
            vsp.SetParmVal(rot_parm, r_val)
            vsp.Update()

            # 2. Export the native OpenVSP file to preserve geometry traceability
            vsp3_filepath = os.path.join(PATH_VSP3, case_name + ".vsp3")
            vsp.WriteVSPFile(vsp3_filepath)

            # 3. Export the Plot3D surface mesh used as the transfer file for FlightStream
            p3d_filepath = os.path.join(PATH_P3D, case_name + ".p3d")
            vsp.ExportFile(p3d_filepath, vsp.SET_ALL, vsp.EXPORT_PLOT3D)

print("\nGeneration completed in {:.2f} seconds.".format(time.time() - start_time))
