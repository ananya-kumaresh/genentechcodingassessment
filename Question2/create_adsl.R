#=========================================================
# Program: create_adsl.R
# Purpose: Create ADSL dataset for Question 2
# Author : Ananya Kumaresh
# Date   : 04-13-26
#=========================================================

sink("create_adsl.txt", split = TRUE)

library(metacore)
library(metatools)
library(pharmaversesdtm)
library(admiral)
library(xportr)
library(dplyr)
library(tidyr)
library(lubridate)
library(stringr)

# Read in input SDTM data
dm <- pharmaversesdtm::dm
ds <- pharmaversesdtm::ds
ex <- pharmaversesdtm::ex
ae <- pharmaversesdtm::ae
vs <- pharmaversesdtm::vs
suppdm <- pharmaversesdtm::suppdm

# Convert blanks to NA
dm <- convert_blanks_to_na(dm)
ds <- convert_blanks_to_na(ds)
ex <- convert_blanks_to_na(ex)
ae <- convert_blanks_to_na(ae)
vs <- convert_blanks_to_na(vs)
suppdm <- convert_blanks_to_na(suppdm)


adsl <- dm %>%
  select(-DOMAIN)

#---------------------------------------------------------
# AGEGR9 / AGEGR9N
#---------------------------------------------------------
adsl <- adsl %>%
  mutate(
    AGEGR9 = case_when(
      AGE < 18 ~ "<18",
      AGE >= 18 & AGE <= 50 ~ "18 - 50",
      AGE > 50 ~ ">50",
      TRUE ~ NA_character_
    ),
    AGEGR9N = case_when(
      AGE < 18 ~ 1,
      AGE >= 18 & AGE <= 50 ~ 2,
      AGE > 50 ~ 3,
      TRUE ~ NA_real_
    )
  )

#---------------------------------------------------------
# ITTFL
#---------------------------------------------------------
adsl <- adsl %>%
  mutate(
    ITTFL = if_else(!is.na(ARM), "Y", "N")
  )

#---------------------------------------------------------
# Prepare EX
#---------------------------------------------------------
ex_ext <- ex %>%
  derive_vars_dtm(
    dtc = EXSTDTC,
    new_vars_prefix = "EXST"
  ) %>%
  derive_vars_dtm(
    dtc = EXENDTC,
    new_vars_prefix = "EXEN",
    time_imputation = "last"
  ) %>%
  mutate(
    VALIDDOSE = EXDOSE > 0 |
      (EXDOSE == 0 & str_detect(EXTRT, "PLACEBO"))
  )

#---------------------------------------------------------
# TRTSDTM / TRTSTMF
#---------------------------------------------------------
adsl <- adsl %>%
  derive_vars_merged(
    dataset_add = ex_ext,
    by_vars = exprs(STUDYID, USUBJID),
    filter_add = VALIDDOSE & !is.na(EXSTDTM),
    new_vars = exprs(
      TRTSDTM = EXSTDTM,
      TRTSTMF = EXSTTMF
    ),
    order = exprs(EXSTDTM, EXSEQ),
    mode = "first"
  )

#---------------------------------------------------------
# TRTEDTM for LSTAVLDT source
#---------------------------------------------------------
adsl <- adsl %>%
  derive_vars_merged(
    dataset_add = ex_ext,
    by_vars = exprs(STUDYID, USUBJID),
    filter_add = VALIDDOSE & !is.na(EXENDTM),
    new_vars = exprs(
      TRTEDTM = EXENDTM
    ),
    order = exprs(EXENDTM, EXSEQ),
    mode = "last"
  )

# Fallback to last EXSTDTM if EXENDTM missing
trt_fallback <- ex_ext %>%
  filter(VALIDDOSE & !is.na(EXSTDTM)) %>%
  arrange(STUDYID, USUBJID, EXSTDTM, EXSEQ) %>%
  group_by(STUDYID, USUBJID) %>%
  slice_tail(n = 1) %>%
  ungroup() %>%
  transmute(
    STUDYID,
    USUBJID,
    TRTEDTM_FALLBACK = EXSTDTM
  )

adsl <- adsl %>%
  left_join(trt_fallback, by = c("STUDYID", "USUBJID")) %>%
  mutate(
    TRTEDTM = coalesce(TRTEDTM, TRTEDTM_FALLBACK)
  ) %>%
  select(-TRTEDTM_FALLBACK)

#---------------------------------------------------------
# Prepare source dates for LSTAVLDT
#---------------------------------------------------------

# VS: last date with valid result
vs_ext <- vs %>%
  derive_vars_dt(
    dtc = VSDTC,
    new_vars_prefix = "VS"
  ) %>%
  filter(
    !is.na(VSDT),
    !(is.na(VSSTRESN) & is.na(VSSTRESC))
  ) %>%
  group_by(STUDYID, USUBJID) %>%
  summarise(
    LSTVSADT = max(VSDT),
    .groups = "drop"
  )

# AE: last AE onset date
ae_ext <- ae %>%
  derive_vars_dt(
    dtc = AESTDTC,
    new_vars_prefix = "AEST"
  ) %>%
  filter(!is.na(AESTDT)) %>%
  group_by(STUDYID, USUBJID) %>%
  summarise(
    LSTAEADT = max(AESTDT),
    .groups = "drop"
  )

# DS: last disposition date
ds_ext <- ds %>%
  derive_vars_dt(
    dtc = DSSTDTC,
    new_vars_prefix = "DSST"
  ) %>%
  filter(!is.na(DSSTDT)) %>%
  group_by(STUDYID, USUBJID) %>%
  summarise(
    LSTDSADT = max(DSSTDT),
    .groups = "drop"
  )

# Treatment: datepart of TRTEDTM
trt_ext <- adsl %>%
  transmute(
    STUDYID,
    USUBJID,
    LSTTRTDT = as.Date(TRTEDTM)
  )

#---------------------------------------------------------
# Merge LSTAVLDT components
#---------------------------------------------------------
adsl <- adsl %>%
  left_join(vs_ext, by = c("STUDYID", "USUBJID")) %>%
  left_join(ae_ext, by = c("STUDYID", "USUBJID")) %>%
  left_join(ds_ext, by = c("STUDYID", "USUBJID")) %>%
  left_join(trt_ext, by = c("STUDYID", "USUBJID")) %>%
  rowwise() %>%
  mutate(
    LSTAVLDT = {
      x <- c(LSTVSADT, LSTAEADT, LSTDSADT, LSTTRTDT)
      x <- x[!is.na(x)]
      if (length(x) == 0) as.Date(NA) else max(x)
    }
  ) %>%
  ungroup()

#---------------------------------------------------------
# Keep variables
#---------------------------------------------------------
adsl <- adsl %>%
  select(
    STUDYID,
    USUBJID,
    SUBJID,
    SITEID,
    AGE,
    AGEU,
    SEX,
    RACE,
    ETHNIC,
    ARMCD,
    ARM,
    ACTARMCD,
    ACTARM,
    AGEGR9,
    AGEGR9N,
    TRTSDTM,
    TRTSTMF,
    ITTFL,
    LSTAVLDT
  )

cat("ADSL created successfully\n")
print(dim(adsl))
print(head(adsl, 10))

write.csv(adsl, "adsl.csv", row.names = FALSE)

sink()