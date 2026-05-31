# MATLAB Templates

This folder contains the MATLAB templates used to document the numerical workflow of the thesis.

## Files

| File | Description |
| --- | --- |
| [canard_geometry_trim_iteration_template.m](canard_geometry_trim_iteration_template.m) | Local sensitivity-based geometry correction using finite-difference derivatives and constrained least squares. |
| [flightstream_data_refinement_matlab_template.m](flightstream_data_refinement_matlab_template.m) | FlightStream data cleaning, derived coefficient calculation and polar export. |
| [mesh_convergence_plot_generator_template.m](mesh_convergence_plot_generator_template.m) | Mesh-convergence plotting and formatted table generation. |

## Main Inputs

Depending on the script, the user must provide:

- Aerodynamic target values.
- Aircraft reference quantities.
- Exposed canard geometry.
- Baseline and perturbed FlightStream coefficients.
- Raw FlightStream sweep matrices.
- Mesh convergence tables.
- Output folders.

## Main Outputs

The templates produce:

- Recommended geometry corrections.
- Diagnostic canard volume coefficients.
- Static margin and neutral point estimates.
- Clean aerodynamic tables.
- Aerodynamic polar figures.
- Mesh-convergence plots and tables.
