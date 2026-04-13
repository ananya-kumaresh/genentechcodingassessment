# Question 1: SDTM DS Domain Creation

## Files Included
- **01_create_ds_domain.R**: R script to create the DS domain using sdtm.oak
- **ds.csv**: Final SDTM DS dataset
- **question1_log.txt**: Log file showing the script ran without errors

## Description
This script maps raw disposition data from `pharmaverseraw::ds_raw` to the SDTM DS domain.

The following variables were created:
- STUDYID, DOMAIN, USUBJID
- DSSEQ, DSTERM, DSDECOD
- DSCAT, VISITNUM, VISIT
- DSDTC, DSSTDTC, DSSTDY

The topic variable (DSTERM) was mapped first, followed by qualifier, identifier, and timing variables.

## Notes
- "Other, specify" values were handled using the OTHERSP variable.
- Study day (DSSTDY) was derived using RFSTDTC from the DM domain.
