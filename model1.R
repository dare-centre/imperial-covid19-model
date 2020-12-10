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

# Choose number of countries (11 or 14)
n.countries = 11

if(n.countries==11){
  # Read which countries to use
  countries <- readRDS('data/country-May-5.rds')
  # Read deaths data for regions
  d <- readRDS('data/COVID-19-May-5.rds')
  # Read IFR and pop by country
  ifr.by.country <- readRDS('data/popt-ifr-May-5.rds')
  # Read interventions
  interventions <- readRDS('data/interventions-May-5.rds')
}else if(n.countries==14){
  countries <- readRDS('data/country-Jul-12.rds')
  d <- readRDS('data/COVID-19-Jul-12.rds')
  d <- d %>% filter(DateRep <= as.Date("2020-05-05"))
  ifr.by.country <- readRDS('data/popt-ifr-Jul-12.rds')
  interventions <- readRDS('data/interventions-Jul-12.rds')
}

forecast <- 0 # increase to get correct number of days to simulate

# Maximum number of days to simulate
N2 <- (max(d$DateRep) - min(d$DateRep) + 1 + forecast)[[1]]

processed_data <- process_covariates(countries = countries, interventions = interventions, 
                                     d = d , ifr.by.country = ifr.by.country, N2 = N2)

dates = processed_data$dates
deaths_by_country = processed_data$deaths_by_country
reported_cases = processed_data$reported_cases
stan_data = processed_data$stan_data

# Running model 1
options(mc.cores = parallel::detectCores())
rstan_options(auto_write = TRUE)
m = stan_model('model1.stan')
fit = sampling(m, data=stan_data, iter=2000, warmup=1000, chains=10, control=list(adapt_delta=0.95))
