# Question 3: TLG - Adverse Events Reporting

## Overview
This section generates regulatory-style outputs for adverse events (AEs) using the `pharmaverseadam` datasets and R packages such as `{dplyr}`, `{ggplot2}`, and `{gt}`.

The outputs include:
1. A summary table of treatment-emergent adverse events (TEAEs)
2. Two visualizations:
   - AE severity distribution by treatment
   - Top 10 most frequent adverse events with 95% confidence intervals

---

## Input Data
The following datasets from `pharmaverseadam` were used:
- `adsl` – Subject-level dataset
- `adae` – Adverse events dataset

Only the following treatment arms were included:
- Placebo  
- Xanomeline High Dose  
- Xanomeline Low Dose  

---

## Summary Table (TEAE Table)

### Script
- `create_ae_summary_table.R`

### Output Files
- `teae_summary_table.docx`
- `teae_summary_table.csv`
- `create_ae_summary_table.txt`

### Description
The TEAE summary table:
- Includes only records where `TRTEMFL == "Y"`
- Uses:
  - `AESOC` (System Organ Class)
  - `AETERM` (Preferred Term)
- Displays hierarchical structure:
  - SOC as main rows
  - Indented preferred terms underneath
- Reports values as:
  - **n (%)**, where:
    - n = number of subjects with the event
    - % = proportion of subjects within treatment arm
- Counts are **subject-level** (each subject counted once per SOC and per AETERM)
- SOCs are ordered in a predefined clinical order
- Preferred terms are sorted **alphabetically within each SOC**
- No total column is included

---

## Plot 1: AE Severity Distribution

### Output File
- `plot1_ae_severity_distribution.png`

### Description
- Stacked bar chart showing AE counts by:
  - Treatment arm (`ACTARM`)
  - Severity (`AESEV`: Mild, Moderate, Severe)
- Uses raw AE record counts
- X-axis: Treatment Arm  
- Y-axis: Count of AEs  
- Fill: Severity/Intensity  

---

## Plot 2: Top 10 Most Frequent AEs

### Output File
- `plot2_top10_ae_incidence.png`

### Description
- Displays the **Top 10 most frequent adverse events** based on `AETERM`
- Uses **subject-level incidence**:
  - Each subject counted once per event
- Includes **95% Clopper-Pearson confidence intervals**

### Details
- Denominator:
  - Total number of subjects in analysis population (**n = 254**)
- X-axis:
  - Percentage of patients
- Y-axis:
  - Adverse event terms
- Error bars:
  - Exact 95% confidence intervals using binomial distribution

---

## Log Files
- `create_ae_summary_table.txt`
- `create_ae_plots.txt`

These files confirm that:
- All scripts ran successfully
- No errors were encountered

---

## Reproducibility
All outputs can be reproduced by running:
- `create_teae_table.R`
- `create_ae_plots.R`

in a clean R session with required packages installed.

---
