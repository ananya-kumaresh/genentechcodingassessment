#=========================================================
# Program: create_ae_plots.R
# Purpose: AE visualizations for Question 3
# Author : Ananya Kumaresh
# Date   : 04-13-26
#=========================================================

sink("create_ae_plots.txt", split = TRUE)

library(dplyr)
library(ggplot2)
library(pharmaverseadam)
library(scales)
library(binom)

# Read in data
adsl <- pharmaverseadam::adsl %>%
  filter(ACTARM %in% c("Placebo", "Xanomeline High Dose", "Xanomeline Low Dose"))

adae <- pharmaverseadam::adae %>%
  filter(ACTARM %in% c("Placebo", "Xanomeline High Dose", "Xanomeline Low Dose"))

arm_levels <- c("Placebo", "Xanomeline High Dose", "Xanomeline Low Dose")

#---------------------------------------------------------
# Plot 1: AE severity distribution by treatment
#---------------------------------------------------------
plot1_dat <- adae %>%
  filter(!is.na(ACTARM), !is.na(AESEV)) %>%
  mutate(
    ACTARM = factor(ACTARM, levels = arm_levels),
    AESEV = factor(AESEV, levels = c("SEVERE", "MODERATE", "MILD"))
  ) %>%
  count(ACTARM, AESEV, name = "n")

p1 <- ggplot(plot1_dat, aes(x = ACTARM, y = n, fill = AESEV)) +
  geom_col() +
  labs(
    title = "AE severity distribution by treatment",
    x = "Treatment Arm",
    y = "Count of AEs",
    fill = "Severity/Intensity"
  ) +
  theme_minimal(base_size = 13)

ggsave(
  filename = "plot1_ae_severity_distribution.png",
  plot = p1,
  width = 8,
  height = 6,
  dpi = 300
)

#---------------------------------------------------------
# Plot 2: Top 10 most frequent AEs with 95% CI for incidence
# Subject-level incidence across all included subjects
#---------------------------------------------------------
denom_n <- adsl %>%
  distinct(USUBJID) %>%
  nrow()

plot2_dat <- adae %>%
  filter(!is.na(AETERM)) %>%
  distinct(USUBJID, AETERM) %>%
  count(AETERM, name = "n") %>%
  arrange(desc(n), AETERM) %>%
  slice_head(n = 10) %>%
  mutate(
    prop = n / denom_n
  )

ci <- binom.confint(plot2_dat$n, denom_n, methods = "exact")

plot2_dat <- plot2_dat %>%
  mutate(
    lower = ci$lower,
    upper = ci$upper,
    AETERM = factor(AETERM, levels = rev(AETERM))
  )

p2 <- ggplot(plot2_dat, aes(x = prop, y = AETERM)) +
  geom_errorbarh(aes(xmin = lower, xmax = upper), height = 0.2) +
  geom_point(size = 3) +
  scale_x_continuous(labels = percent_format(accuracy = 1)) +
  labs(
    title = "Top 10 Most Frequent Adverse Events",
    subtitle = paste0("n = ", denom_n, " subjects; 95% Clopper-Pearson CIs"),
    x = "Percentage of Patients (%)",
    y = NULL
  ) +
  theme_minimal(base_size = 13)

ggsave(
  filename = "plot2_top10_ae_incidence.png",
  plot = p2,
  width = 8,
  height = 6,
  dpi = 300
)

cat("AE plots created successfully\n")
print(head(plot1_dat, 10))
print(plot2_dat)

sink()