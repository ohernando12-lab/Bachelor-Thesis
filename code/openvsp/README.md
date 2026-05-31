# OpenVSP Automation Template

## File

[openvsp_parametric_geometry_export_template.py](openvsp_parametric_geometry_export_template.py)

## Purpose

This Python template automates OpenVSP geometry updates and exports each selected design case as:

- A native `.vsp3` file for geometry traceability.
- A Plot3D `.p3d` file for later FlightStream mesh conversion.

## User Inputs

The user must define:

- Main wing longitudinal positions.
- Canard longitudinal positions.
- Canard incidence angles.
- Baseline `.vsp3` input file.
- Output directory.
- OpenVSP component and parameter names if they differ from the template.

## Output

The script creates two output folders:

- `VSP3`
- `P3D`

Each generated case is named from its design-variable values.
