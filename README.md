# Bachelor Thesis Supplementary Appendix

This repository contains supplementary appendix material for the Bachelor Thesis:

**Aerodynamic and Stability Analysis of Canard Configurations for Commercial Aircraft**

Author: Omar Hernando de la Torre

The thesis document remains self-contained. This repository is intended to provide a clean and organized supplementary appendix with sanitized code templates and supporting material for reproducibility and traceability.

## Repository Scope

The material included here is not the full working directory of the thesis. It is a curated appendix repository containing:

- Sanitized OpenVSP automation template.
- Sanitized FlightStream preprocessing and solver script templates.
- Sanitized MATLAB analysis and post-processing templates.
- Sanitized Excel VBA data-refinement template.
- Placeholder folders for selected figures, complete tables and workflow notes.

Personal paths, local machine references and simulation-specific raw values have been removed from the code templates. Values that must be supplied by the user are left as empty inputs or placeholders.

## Folder Structure

```text
code/
  openvsp/
  flightstream/
  matlab/
  vba/
figures/
tables/
docs/
```

Direct indexes are available for the main supplementary folders:

- [Code templates](code/README.md)
- [Appendix figure gallery](figures/README.md)
- [Supplementary material index](docs/appendix_material_index.md)

## Code Templates

The `code` folder contains templates derived from the computational workflow used in the thesis:

- `code/openvsp/openvsp_parametric_geometry_export_template.py`
- `code/flightstream/flightstream_scripts_template.txt`
- `code/matlab/canard_geometry_trim_iteration_template.m`
- `code/matlab/flightstream_data_refinement_matlab_template.m`
- `code/matlab/mesh_convergence_plot_generator_template.m`
- `code/vba/excel_data_refinement_vba_template.txt`

These templates document the workflow structure without exposing local paths or project-specific raw values.

## Software Context

The workflow documented by the thesis uses:

- OpenVSP for parametric aircraft geometry generation.
- FlightStream for surface-vorticity aerodynamic simulations.
- MATLAB for sensitivity analysis, mesh-convergence plotting and data refinement.
- Microsoft Excel and VBA for spreadsheet-based data refinement and visualization.

## Notes

This repository is prepared as supplementary academic material. It should be read together with the final thesis document, where the methodology, assumptions, results and discussion are fully described.
