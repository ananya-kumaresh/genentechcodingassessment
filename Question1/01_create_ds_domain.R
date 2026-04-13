#=========================================================
# Program: 01_create_ds_domain
# Purpose: DS SDTM Domain
# Author : Ananya Kumaresh
# Date   : 04-10-26
#=========================================================

# Load Libraries
library(sdtm.oak)
library(pharmaverseraw)
library(pharmaversesdtm)
library(dplyr)

# Read in raw DS and DM
ds_raw <- pharmaverseraw::ds_raw
dm <- pharmaversesdtm::dm

# Create oak ID vars
ds_raw <- ds_raw %>%
  generate_oak_id_vars(
    pat_var = "PATNUM",
    raw_src = "ds_raw"
  )

# Read in study CT
study_ct <- read.csv("C:/Users/anany/OneDrive/Documents/Genentech/sdtm_ct.csv")

#---------------------------------------------------------
# Map Topic Variable
#---------------------------------------------------------
ds <-
  assign_no_ct(
    raw_dat = ds_raw,
    raw_var = "IT.DSTERM",
    tgt_var = "DSTERM",
    id_vars = oak_id_vars()
  )

#---------------------------------------------------------
# Map Rest of Variables
#---------------------------------------------------------
ds <- ds %>%
  # Map DSDECOD
  assign_no_ct(
    raw_dat = ds_raw,
    raw_var = "IT.DSDECOD",
    tgt_var = "DSDECOD",
    id_vars = oak_id_vars()
  ) %>%
  # Map OTHERSP so missing DSTERM/DSDECOD can be filled
  assign_no_ct(
    raw_dat = ds_raw,
    raw_var = "OTHERSP",
    tgt_var = "OTHERSP",
    id_vars = oak_id_vars()
  ) %>%
  # Map VISIT from INSTANCE
  assign_no_ct(
    raw_dat = ds_raw,
    raw_var = "INSTANCE",
    tgt_var = "VISIT",
    id_vars = oak_id_vars()
  ) %>%
  # Map DSDTC from collected date + time
  assign_datetime(
    raw_dat = ds_raw,
    raw_var = c("DSDTCOL", "DSTMCOL"),
    tgt_var = "DSDTC",
    raw_fmt = c("m-d-y", "H:M"),
    id_vars = oak_id_vars()
  ) %>%
  # Map DSSTDTC from disposition start date
  assign_datetime(
    raw_dat = ds_raw,
    raw_var = "IT.DSSTDAT",
    tgt_var = "DSSTDTC",
    raw_fmt = "m-d-y",
    id_vars = oak_id_vars()
  ) %>%
  # Fill missing topic/decoded terms from OTHERSP
  mutate(
    DSTERM = ifelse(is.na(DSTERM) & !is.na(OTHERSP), OTHERSP, DSTERM),
    DSDECOD = ifelse(is.na(DSDECOD) & !is.na(OTHERSP), OTHERSP, DSDECOD)
  )

#---------------------------------------------------------
# Create SDTM identifiers and derived variables
#---------------------------------------------------------
ds <- ds %>%
  mutate(
    STUDYID = "CDISCPILOT01",
    DOMAIN = "DS",
    USUBJID = paste0("01-", patient_number),
    DSCAT = "DISPOSITION EVENT",
    VISITNUM = case_when(
      VISIT == "Baseline" ~ 0,
      grepl("^Week ", VISIT) ~ as.numeric(gsub("^Week ", "", VISIT)),
      TRUE ~ NA_real_
    )
  ) %>%
  derive_seq(
    tgt_var = "DSSEQ",
    rec_vars = c("USUBJID")
  )

# Derive DSSTDY
ds <- derive_study_day(
  sdtm_in = ds,
  dm_domain = dm,
  tgdt = "DSSTDTC",
  refdt = "RFSTDTC",
  study_day_var = "DSSTDY"
)

# Final variable order
ds <- ds %>%
  select(
    STUDYID,
    DOMAIN,
    USUBJID,
    DSSEQ,
    DSTERM,
    DSDECOD,
    DSCAT,
    VISITNUM,
    VISIT,
    DSDTC,
    DSSTDTC,
    DSSTDY
  )


ds %>% count(USUBJID, DSSEQ) %>% filter(n > 1)

# Print final dataset
ds

# Save final dataset
write.csv(ds, "ds.csv", row.names = FALSE)