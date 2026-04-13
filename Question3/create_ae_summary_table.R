#=========================================================
# Program: create_ae_summary_table.R
# Purpose: FDA-style TEAE summary table
# Author : Ananya Kumaresh
# Date   : 04-13-26
#=========================================================

sink("create_ae_summary_table.txt", split = TRUE)

# Load Libraries
library(dplyr)
library(tidyr)
library(stringr)
library(gt)
library(gtsummary)
library(cards)
library(pharmaverseadam)

theme_gtsummary_compact()

# Read in input datasets
adsl <- pharmaverseadam::adsl %>%
  filter(ACTARM %in% c("Placebo", "Xanomeline High Dose", "Xanomeline Low Dose"))

adae <- pharmaverseadam::adae %>%
  filter(ACTARM %in% c("Placebo", "Xanomeline High Dose", "Xanomeline Low Dose"))

# Fixed treatment arm order
arm_levels <- c("Placebo", "Xanomeline High Dose", "Xanomeline Low Dose")

#---------------------------------------------------------
# Denominators from ADSL
#---------------------------------------------------------
adsl_denoms <- adsl %>%
  distinct(USUBJID, ACTARM)

arm_denoms <- adsl_denoms %>%
  count(ACTARM, name = "N") %>%
  mutate(ACTARM = factor(ACTARM, levels = arm_levels)) %>%
  arrange(ACTARM) %>%
  mutate(ACTARM = as.character(ACTARM))

#---------------------------------------------------------
# Keep treatment-emergent AEs only
#---------------------------------------------------------
teae <- adae %>%
  filter(TRTEMFL == "Y")

#---------------------------------------------------------
# n (%)
#---------------------------------------------------------
fmt_npct <- function(n, denom) {
  pct <- 100 * n / denom
  ifelse(
    pct >= 10,
    sprintf("%d (%.0f%%)", n, pct),
    sprintf("%d (%.1f%%)", n, pct)
  )
}

#---------------------------------------------------------
# Treatment Emergent AEs
#---------------------------------------------------------
overall_arm <- teae %>%
  distinct(USUBJID, ACTARM) %>%
  count(ACTARM, name = "n") %>%
  left_join(arm_denoms, by = "ACTARM") %>%
  mutate(
    value = fmt_npct(n, N),
    row_label = "Treatment Emergent AEs",
    row_type = 0,
    AESOC = NA_character_,
    AETERM = NA_character_
  ) %>%
  select(row_label, row_type, AESOC, AETERM, ACTARM, value)

#---------------------------------------------------------
# AESOC rows
#---------------------------------------------------------
soc_arm <- teae %>%
  distinct(USUBJID, ACTARM, AESOC) %>%
  count(AESOC, ACTARM, name = "n") %>%
  left_join(arm_denoms, by = "ACTARM") %>%
  mutate(
    value = fmt_npct(n, N),
    row_label = AESOC,
    row_type = 1,
    AETERM = NA_character_
  ) %>%
  select(row_label, row_type, AESOC, AETERM, ACTARM, value)

#---------------------------------------------------------
# AETERM rows
#---------------------------------------------------------
term_arm <- teae %>%
  distinct(USUBJID, ACTARM, AESOC, AETERM) %>%
  count(AESOC, AETERM, ACTARM, name = "n") %>%
  left_join(arm_denoms, by = "ACTARM") %>%
  mutate(
    value = fmt_npct(n, N),
    row_label = paste0("   ", AETERM),
    row_type = 2
  ) %>%
  select(row_label, row_type, AESOC, AETERM, ACTARM, value)

#---------------------------------------------------------
# Sort SOCs and PTs by descending frequency
#---------------------------------------------------------
soc_order <- teae %>%
  distinct(USUBJID, AESOC) %>%
  count(AESOC, name = "soc_n") %>%
  arrange(desc(soc_n), AESOC)

term_order <- teae %>%
  distinct(USUBJID, AESOC, AETERM) %>%
  count(AESOC, AETERM, name = "term_n") %>%
  arrange(AESOC, desc(term_n), AETERM)

soc_arm <- soc_arm %>% left_join(soc_order, by = "AESOC")

term_arm <- term_arm %>%
  left_join(term_order, by = c("AESOC", "AETERM")) %>%
  left_join(soc_order, by = "AESOC")

#---------------------------------------------------------
# Combine rows
#---------------------------------------------------------
all_rows <- bind_rows(
  overall_arm %>%
    mutate(soc_n = Inf, term_n = Inf),
  soc_arm %>%
    mutate(term_n = Inf),
  term_arm
)

table_wide <- all_rows %>%
  select(row_label, row_type, ACTARM, value, soc_n, term_n, AESOC, AETERM) %>%
  pivot_wider(
    names_from = ACTARM,
    values_from = value
  ) %>%
  arrange(row_type, desc(soc_n), desc(term_n), AESOC, AETERM, row_label) %>%
  select(-soc_n, -term_n, -AESOC, -AETERM)

table_wide <- table_wide %>%
  mutate(across(-c(row_label, row_type), ~replace_na(.x, "0 (0.0%)")))

#---------------------------------------------------------
# Final column order
#---------------------------------------------------------
final_cols <- c("row_label", "row_type", arm_levels)
final_cols <- final_cols[final_cols %in% names(table_wide)]

table_wide <- table_wide %>%
  select(all_of(final_cols))

#---------------------------------------------------------
# Build simple gt table
#---------------------------------------------------------
arm_headers <- arm_denoms %>%
  filter(ACTARM %in% arm_levels) %>%
  mutate(header = paste0(ACTARM, "<br>N = ", N))

gt_tbl <- table_wide %>%
  select(-row_type) %>%
  gt() %>%
  cols_label(
    row_label = md("Primary System Organ Class<br>Reported Term for the Adverse Event")
  )

for (arm in arm_levels) {
  if (arm %in% names(table_wide)) {
    hdr <- arm_headers %>%
      filter(ACTARM == arm) %>%
      pull(header)
    
    gt_tbl <- gt_tbl %>%
      cols_label(!!arm := md(hdr))
  }
}

gt_tbl <- gt_tbl %>%
  tab_options(
    table.font.size = px(13),
    data_row.padding = px(6)
  )

#---------------------------------------------------------
# Print and save
#---------------------------------------------------------
gt_tbl

gtsave(gt_tbl, "teae_summary_table.html")
write.csv(table_wide %>% select(-row_type), "teae_summary_table.csv", row.names = FALSE)

cat("TEAE table created successfully\n")
print(dim(table_wide))
print(head(table_wide, 15))

sink()
