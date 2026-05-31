# Excel VBA Data Refinement Template

## File

[excel_data_refinement_vba_template.txt](excel_data_refinement_vba_template.txt)

## Purpose

This VBA template cleans raw FlightStream sweep data directly inside Excel. It reconstructs a compact aerodynamic table, calculates derived coefficients and generates report-ready plots.

## User Inputs

The user must define:

- Start angle of attack.
- End angle of attack.
- Angle-of-attack step.
- Target lift coefficient.

## Output

The macro creates:

- Clean columns for angle of attack, lift, induced drag, parasitic drag and pitching moment.
- Derived total drag and lift-to-drag ratio columns.
- Conditional formatting for lift target, trim and efficiency.
- A synchronized set of aerodynamic plots.
