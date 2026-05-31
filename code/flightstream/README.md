# FlightStream Script Templates

## File

[flightstream_scripts_template.txt](flightstream_scripts_template.txt)

## Purpose

This text file contains four sanitized FlightStream script templates:

1. Canard configuration mesh preprocessing.
2. Canard configuration solver setup and sweep.
3. Conventional tail configuration mesh preprocessing.
4. Conventional tail configuration solver setup and sweep.

## User Inputs

The user must replace all placeholders written between `<...>`, including:

- CCS component file paths.
- Fluid properties.
- Centre of gravity coordinates.
- Reference area and reference length.
- Boundary IDs.
- Angle-of-attack sweep range.
- Freestream velocity.
- Output CSV path.

## Notes

The preprocessing and solver stages are kept separate because the workflow includes manual inspection of the symmetry cut and selected boundary-condition definitions before running the solver stage.
