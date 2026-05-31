# Code Templates

This folder contains sanitized code templates derived from the computational workflow used in the thesis. The templates preserve the structure and methodology of the original scripts while removing personal paths and simulation-specific raw values.

## OpenVSP

| File | Purpose |
| --- | --- |
| [openvsp_parametric_geometry_export_template.py](openvsp/openvsp_parametric_geometry_export_template.py) | Generates parametric OpenVSP geometry cases and exports native `.vsp3` and Plot3D `.p3d` files. |

## FlightStream

| File | Purpose |
| --- | --- |
| [flightstream_scripts_template.txt](flightstream/flightstream_scripts_template.txt) | Contains the four FlightStream script templates used for canard preprocessing, canard solver setup, conventional tail preprocessing and conventional tail solver setup. |

## MATLAB

| File | Purpose |
| --- | --- |
| [canard_geometry_trim_iteration_template.m](matlab/canard_geometry_trim_iteration_template.m) | Performs local sensitivity-based canard geometry correction using finite differences and constrained least squares. |
| [flightstream_data_refinement_matlab_template.m](matlab/flightstream_data_refinement_matlab_template.m) | Cleans FlightStream sweep data, calculates derived coefficients and exports report-ready plots and tables. |
| [mesh_convergence_plot_generator_template.m](matlab/mesh_convergence_plot_generator_template.m) | Generates mesh-convergence plots and tables for fixed-U and fixed-V refinement studies. |

## Excel VBA

| File | Purpose |
| --- | --- |
| [excel_data_refinement_vba_template.txt](vba/excel_data_refinement_vba_template.txt) | Cleans FlightStream output inside Excel, computes derived coefficients and generates spreadsheet plots. |

## Notes on Sanitization

The templates intentionally use empty inputs or placeholders instead of local project values. This keeps the repository suitable for public supplementary material while preserving the computational workflow described in the thesis.

Examples of sanitized fields include:

- Local import and export paths.
- FlightStream CCS file locations.
- Raw aerodynamic sweep matrices.
- Geometry-specific numerical values.
- Solver case output filenames.

The full methodology and interpretation of the results are provided in the thesis document.
