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

# Running model 1 (adjust the maximum tree depth to reduce computational time)
options(mc.cores = parallel::detectCores())
rstan_options(auto_write = TRUE)
m = stan_model('base-nature.stan')
fit = sampling(m, data=stan_data, iter=10000, warmup=5000, chains=4, control=list(max_treedepth=15, metric="dense_e", adapt_delta=0.9))
