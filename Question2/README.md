# Question 2: ADaM ADSL Dataset Creation

## Files Included
- **create_adsl.R**: R script to create the ADSL dataset using {admiral} and SDTM inputs
- **adsl.csv**: Final ADSL dataset
- **create_adsl.txt**: Log file showing the script ran without errors

## Description
This script creates a subject-level ADSL dataset starting from the DM domain and using SDTM datasets (DM, EX, AE, VS, DS).

The following variables were derived:
- **AGEGR9 / AGEGR9N**: Age group categories ("<18", "18 - 50", ">50")
- **TRTSDTM / TRTSTMF**: First treatment start datetime and imputation flag from EX
- **ITTFL**: Flag indicating randomized subjects (ARM not missing)
- **LSTAVLDT**: Last known alive date derived from VS, AE, DS, and treatment data

{admiral} functions were used for date and datetime derivations where applicable, including:
- `derive_vars_dtm()`
- `derive_vars_merged()`
- `derive_vars_dt()`

## Notes
- Valid dose was defined as EXDOSE > 0 or EXDOSE = 0 with treatment containing "PLACEBO"
- Missing time components in EXSTDTC were imputed according to the specification
- LSTAVLDT was derived as the maximum date across all relevant clinical sources
