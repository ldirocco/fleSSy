# flessy.R

# Required Libraries
library(dplyr)
library(flexsurv)
library(synthpop)
library(mice)
library(rlang)

flessy <- function(data,
                   n,                  # Number of synthetic units to generate
                   pred,               # Predictors for survival model
                   seq,                # Visit sequence for synthpop
                   methods = "parametric",
                   dropout = NULL,
                   entry_date = NULL,
                   start = NULL, 
                   knots = NULL,
                   seed = 134,
                   exclude_pred = FALSE,
                   r = TRUE) {
  
  # Add dropout column if missing
  if (is.null(dropout)) {
    data$dropout <- 0
  }
  
  # Add entry_date column if missing
  if (is.null(entry_date)) {
    data$entry_date <- 0
  }
  
  # Remove rows with missing time or status
  data <- data %>%
    filter(!is.na(!!sym("time")) & !is.na(!!sym("status")))
  
  # Prepare formula for survival model
  if (is.numeric(pred)) {
    pred <- names(data)[pred]
  }
  
  surv_part <- "Surv(time, status)"
  cov_part  <- paste(pred, collapse = " + ")
  full_formula <- as.formula(paste(surv_part, "~", cov_part))
  
  # Fit flexible survival model
  surv_model <- flexsurvspline(
    formula = full_formula, 
    data = data, 
    scale = "hazard",
    knots = knots,
    k = 3
  )
  
  # Use synthpop to generate synthetic predictors
  if (is.numeric(seq)) {
    seq <- names(data)[seq]
  }
  
  seq <- c("dropout", seq)
  
  synth.obj <- syn(
    data = data, 
    visit.sequence = seq,
    k = n,  
    seed = seed, 
    method = methods
  )
  
  db_syn <- synth.obj$syn[, seq, drop = FALSE]
  
  # Exclude predictors if requested
  if (exclude_pred) {
    db_syn <- db_syn[, !(names(db_syn) %in% pred), drop = FALSE]
  }
  
  # Impute missing values if any
  if (anyNA(db_syn)) {
    db_syn <- complete(mice(db_syn))
  }
  
  # Simulate survival times
  synthetic_surv <- simulate(
    surv_model, 
    newdata = db_syn, 
    nsim = 1,
    tidy = TRUE, 
    seed = seed, 
    censtime = max(data$time)
  )
  
  if (r) {
    synthetic_surv$time <- round(synthetic_surv$time, 0)
  }
  
  return(synthetic_surv)
}
