# syn_methods.R

# Required Libraries
library(glmnet)
library(MASS)

# LASSO for continuous outcomes (Gaussian)
syn.lasso.norm <- function(y, x, xp, proper = FALSE, nfolds = 10, ...) {
  x  <- as.matrix(x)
  xp <- as.matrix(xp)
  
  if (proper) {
    s  <- sample(length(y), replace = TRUE)
    x  <- x[s, , drop = FALSE]
    y  <- y[s]
  }
  
  x_glmnet  <- cbind(1, x)
  xp_glmnet <- cbind(1, xp)
  
  cv_lasso <- glmnet::cv.glmnet(
    x = x_glmnet, y = y,
    family = "gaussian",
    nfolds = nfolds,
    alpha = 1, ...
  )
  
  preds <- predict(cv_lasso, newx = x_glmnet, s = "lambda.min")
  s2hat <- mean((preds - y)^2)
  
  yhat <- as.vector(predict(cv_lasso, newx = xp_glmnet, s = "lambda.min"))
  res  <- yhat + rnorm(nrow(xp), mean = 0, sd = sqrt(s2hat))
  
  return(list(res = res, fit = summary(cv_lasso)))
}

# LASSO for binary outcomes (logistic regression)
syn.lasso.logreg <- function(y, x, xp, proper = FALSE, nfolds = 10, ...) {
  x  <- as.matrix(x)
  xp <- as.matrix(xp)
  
  if (proper) {
    s <- sample(length(y), replace = TRUE)
    x <- x[s, , drop = FALSE]
    y <- y[s]
  }
  
  x_glmnet  <- cbind(1, x)
  xp_glmnet <- cbind(1, xp)
  
  cv_lasso <- glmnet::cv.glmnet(
    x = x_glmnet, y = y,
    family = "binomial",
    nfolds = nfolds,
    alpha = 1, ...
  )
  
  p <- predict(cv_lasso, newx = xp_glmnet, s = "lambda.min", type = "response")
  
  vec <- (runif(nrow(p)) <= p)
  vec[vec] <- 1
  vec[!vec] <- 0
  
  if (is.factor(y)) {
    vec <- factor(vec, levels = c(0, 1), labels = levels(y))
  }
  
  return(list(res = vec, fit = summary(cv_lasso)))
}

# Linear Discriminant Analysis (LDA) for categorical outcomes
syn.lda <- function(y, x, xp, proper = FALSE, ...) {
  x  <- as.matrix(x)
  xp <- as.matrix(xp)
  
  y <- as.factor(y)
  nc <- length(levels(y))
  
  if (proper) {
    s <- sample(length(y), replace = TRUE)
    x <- x[s, , drop = FALSE]
    y <- y[s]
  }
  
  fit <- MASS::lda(x, grouping = y)
  post <- predict(fit, xp)$posterior
  
  un <- rep(runif(nrow(xp)), each = nc)
  idx <- 1 + apply(un > apply(post, 1, cumsum), 2, sum)
  
  res <- levels(y)[idx]
  fitted <- summary(fit)
  
  return(list(res = res, fit = fitted))
}
