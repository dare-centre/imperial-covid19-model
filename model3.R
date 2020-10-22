library(rstan)
library(data.table)
library(lubridate)
library(gdata)
library(dplyr)
library(tidyr)
library(EnvStats)
library(optparse)
library(stringr)
library(bayesplot)
library(matrixStats)
library(scales)
library(gridExtra)
library(ggpubr)
library(cowplot)
library(ggplot2)
library(abind)

source('process-covariates.r')

# Read which countries to use
countries <- readRDS('data/country-May-5.rds')
# Read deaths data for regions
d <- readRDS('data/COVID-19-May-5.rds')
# Read IFR and pop by country
ifr.by.country <- readRDS('data/popt-ifr-May-5.rds')

# Read interventions
interventions <- readRDS('data/interventions-May-5.rds')

forecast <- 0 # increase to get correct number of days to simulate

# Maximum number of days to simulate
N2 <- (max(d$DateRep) - min(d$DateRep) + 1 + forecast)[[1]]

processed_data <- process_covariates(countries = countries, interventions = interventions, 
                                     d = d , ifr.by.country = ifr.by.country, N2 = N2)

dates = processed_data$dates
deaths_by_country = processed_data$deaths_by_country
reported_cases = processed_data$reported_cases
stan_data = processed_data$stan_data

# Combining the design matrices of NPI interventions and average Google mobility
X_npi = stan_data$X
X_mobility = readRDS("data/average-google-mobility-X-May-5.rds")
X_partial_state = readRDS("data/average-google-mobility-partial-X-May-5.rds")
X = abind(X_mobility, X_npi[,,c(1:3,5,6)], along=3)

P = dim(X)[3]
P_partial_state = dim(X_partial_state)[3]

# AR(2) weekly auto-regressive process
W = readRDS("data/W-May-5.rds")
week_index = readRDS("data/week_index-May-5.rds")

stan_data$P = P
stan_data$P_partial_state = P_partial_state
stan_data$X = X
stan_data$X_partial_state = X_partial_state
stan_data$W = W
stan_data$week_index = week_index

# Running model 3 (adjust the maximum tree depth to reduce computational time)
options(mc.cores = parallel::detectCores())
rstan_options(auto_write = TRUE)
m = stan_model('model3.stan')
fit = sampling(m, data=stan_data, iter=10000, warmup=5000, chains=4, control=list(max_treedepth=15, metric="dense_e", adapt_delta=0.9))

# Plotting posterior distributions of coefficients
out = rstan::extract(fit)
covariates = c("Average mobility", "School closure", "Self isolation", "Event ban", "Lockdown", "School closure")
par(mfrow=c(2,3))
for(i in 1:6){
  plot(density(out$alpha[,i]), main=covariates[i])
}
