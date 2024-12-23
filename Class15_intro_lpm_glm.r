#Class  15 Econometrics 1 (Economics - University of Beira Interior) 
#Introduction to limited dependent variable models
#This file may contain errors, if you have any questions please contact tiago.afonso@ubi.pt via Teams

#cleaning the environment
rm(list=ls())

ch <- function () {
  write("", file=".blank")
  loadhistory(".blank")
  unlink(".blank")
}
ch()

#load all packags, if not installed use install.packages("package_name")
library(readxl) #read external files
library(stargazer) #manipulatns data frame
library(tidyverse) #estimating models
library(systemfit) #testing models
library(caret) #classification 
library(magrittr) #to calculate statistics
library(mfx) #tocalculate derivations 
library(performance) #evaluating binary outcome models
library(lmtest) #lm test
library(moments) #statistical tests
library(AER) #sample database
library(MASS) #transformations
library(scales) #rescale
library(sandwich) #empirical estimation function
library(nlme) #non linear
library(skedastic) #heteroskedasticity
library(tseries) # time series

#get working directory
getwd()
#Make sure you have the .xlsx file in your working directory
#Wooldridge package - data from "loanapp"
loanapp <- read_xlsx("loanapp.xlsx")

#get an overview from the data
head(loanapp)

#the goal is to estimate the probability of a loan being accepted

#variables definition

#approve: =1 if approved

#some factor that could affect the probability
#loanamt: loan amt in thousands
#married: =1 if applicant married
#dep: number of dependents
#emp: years employed in line of work
#price: purchase price

##
## LMP - Linear probability model (mlp) - Livro wooldridge - computer example##
##

# Linear Probability Model (LPM) estimation
lpm <- lm(approve~loanamt+married+dep+emp+price,loanapp)
summary(lpm)
summary(fitted(lpm))

# Plot the fitted values and the actual values of approve
library(ggplot2)

# Create a data frame with actual and fitted values
plot_data <- loanapp %>%
    mutate(actual = approve,
                 fitted_lpm = fitted(lpm))

# Plot fitted (red), actual (blue) alongside with "loan amount"
# this plot is not mandatory
ggplot(plot_data, aes(x = loanamt)) +
    geom_point(aes(y = actual), color = "darkblue", alpha = 0.5) +
    geom_point(aes(y = fitted_lpm), color = "darkred", alpha = 0.5) +
    labs(title = "Actual vs Fitted Values",
             x = "Loan Amount",
             y = "Values",
             color = "Legend") +
    scale_color_manual(values = c("Actual" = "darkblue", "Fitted" = "darkred"))+
    theme_bw()
# it is possible to see adjusted values greater than 100%.


# lm - assumptions
# linearity
# homoskedasticity
# independence
# normnormality

#GLM
# it doesn't have those assumptions

# GLM - family (binomial(link="probit"))
# GLM - family (binomial(link="logit"))

#estimate logit model
logit_model <- glm(approve~loanamt+married+dep+emp+price,
          family = binomial(link="logit"),
          data=loanapp)

#estimate probit model
probit_model <- glm(approve~loanamt+married+dep+emp+price,
          family = binomial(link="probit"),
          data=loanapp)


# Add fitted values from LPM, Logit, and Probit models to the loanapp data frame
loanapp <- loanapp %>% mutate(
    fit_lpm = fitted(lpm),
    fit_logit = fitted(logit_model),
    fit_probit = fitted(probit_model)
)

# Summarize the fitted values from the LPM, Logit, and Probit models
# the goal is to see if there are probabilities less than 0 or greater than 1. If so, the model is not appropriate
#see min and max
summary(loanapp$fit_lpm)
summary(loanapp$fit_logit)
summary(loanapp$fit_probit)

#or to see all fitted values
loanapp %>% dplyr::select(fit_lpm, fit_logit, fit_probit) %>%
  summary()

#evaluate the sign and statistical significance of each estimated model
#verify if there are any changes between models
summary(lpm)
summary(logit_model)
summary(probit_model)

#see all models at once
stargazer(lpm, logit_model, probit_model, type="text")

# Calculate marginal effects at the mean for the logit model
me_logit <- logitmfx(approve~loanamt+married+dep+emp+price, loanapp, atmean = TRUE)

# Calculate average marginal effects for the logit model
ame_logit <- logitmfx(approve~loanamt+married+dep+emp+price, loanapp, atmean = FALSE)

# Calculate marginal effects at the mean for the probit model
me_probit <- probitmfx(approve~loanamt+married+dep+emp+price, loanapp, atmean = TRUE)

# Calculate average marginal effects for the probit model
ame_probit <- probitmfx(approve~loanamt+married+dep+emp+price, loanapp, atmean = FALSE)

#to see each marginal effect
me_logit
ame_logit
me_probit
ame_probit

# Evaluate probit and logit models
# pseudo R2
# percentage correctly predicted
# likelihood ratio test

#1 pseudo r2 for logit model - pseudo R2 = 1-(LLur/LLr)
#Calculate pseudo R2 step by step

#restricted model - rm - only with constant
#unrestricted model - urm
urm_logit <- logit_model
rm_logit <- glm(approve~1,
          family = binomial(link="logit"),
          data=loanapp)

(LLr_logit <- logLik(rm_logit))
(LLur_logit <- logLik(urm_logit))
(pseudo_r_logit <- (1-(LLur_logit/LLr_logit)))

#or
# Calculate pseudo R2 for logit model
pseudo_r2_logit_v2 <- 1 - (logLik(logit_model) / logLik(glm(approve ~ 1, family = binomial(link = "logit"), data = loanapp)))
pseudo_r2_logit_v2

pseudo_r2_logit_v3 <- 1-(logit_model$deviance/logit_model$null.deviance)
pseudo_r2_logit_v3
#1 pseudo r2 probit model - pseudo R2 = 1-(LLur/LLr)
#Calculate pseudo R2 step by step
urm_probit<-probit_model
rm_probit <- glm(approve~1,
          family = binomial(link="probit"),
          data=loanapp)
(LLr_probit <- logLik(rm_probit))
(LLur_probit <- logLik(urm_probit))
(pseudo_r_probit <- (1-(LLur_probit/LLr_probit)))

#or
# Calculate pseudo R2 for probit model
pseudo_r2_probit_v2 <- 1 - (logLik(probit_model) / logLik(glm(approve ~ 1, family = binomial(link = "probit"), data = loanapp)))
pseudo_r2_probit_v2

pseudo_r2_probit_v3 <- 1-(probit_model$deviance/probit_model$null.deviance)
pseudo_r2_probit_v3

#2 Percentage correctly predicted method: "Herron" or "Gelman-Hilll"
performance_pcp(logit_model,ci=0.95, method = "Gelman-Hill")

performance_pcp(probit_model,ci=0.95, method = "Gelman-Hill")
#3 information criteria
performance_aic(logit_model)
performance_aic(probit_model)

#4 likehood ratio

# Perform likelihood ratio test for the logit model
lrtest_logit <- lrtest(logit_model, rm_logit)
lrtest_logit

# Perform likelihood ratio test for the probit model
lrtest_probit <- lrtest(probit_model, rm_probit)
lrtest_probit

#not tested yet
#5 Confusion matrix

# Predict the probabilities
probit_predictions <- predict(probit_model, type = "response")

# Convert probabilities to binary outcomes
probit_pred_class <- ifelse(probit_predictions > 0.5, 1, 0)

# Define actual outcomes
actual_outcomes <- loanapp$approve

# Create confusion matrix
confusion_matrix <- confusionMatrix(as.factor(probit_pred_class), as.factor(actual_outcomes))
print(confusion_matrix)

#ROC curve and AUC
# plot the ROC curve and calculate the AUC (Area Under the Curve) to evaluate the model's performance


# Predict the probabilities
probit_predictions <- predict(probit_model, type = "response")

# Plot ROC curve
roc_curve <- roc(actual_outcomes, probit_predictions)
plot(roc_curve)

# Calculate AUC
auc_value <- auc(roc_curve)
print(auc_value)
