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
countries <- readRDS('data/country-Jul-12.rds')
# Read deaths data for regions
d <- readRDS('data/COVID-19-Jul-12.rds')
# Read IFR and pop by country
ifr.by.country <- readRDS('data/popt-ifr-Jul-12.rds')

# Read interventions
interventions <- readRDS('data/interventions-Jul-12.rds')

forecast <- 0 # increase to get correct number of days to simulate

# Maximum number of days to simulate
N2 <- (max(d$DateRep) - min(d$DateRep) + 1 + forecast)[[1]]

processed_data <- process_covariates(countries = countries, interventions = interventions, 
                                     d = d , ifr.by.country = ifr.by.country, N2 = N2)

dates = processed_data$dates
deaths_by_country = processed_data$deaths_by_country
reported_cases = processed_data$reported_cases
stan_data = processed_data$stan_data

# Design matrix for lifting of some NPIs (lockdown and event ban)
interventions_lift <- readRDS('data/interventions-lifted-Jul-12.rds')

X_lift = array(NA, dim=c(dim(stan_data$X)[1:2], 3))
for(i in 1:dim(X_lift)[1]){
  for(j in 1:3){
    if(interventions_lift[i,j+1]>as.Date("2020-12-31")){
      X_lift[i,,j] = 0
    }else{
      index = which(dates[[i]]==interventions_lift[i,j+1])
      X_lift[i,1:(index-1),j] = 0
      X_lift[i,index:dim(X_lift)[2],j] = 1
    }
  }
}

X = abind(stan_data$X, X_lift, along=3)
P = dim(X)[3]

stan_data$X = X
stan_data$P = P

# Running model 1
options(mc.cores = parallel::detectCores())
rstan_options(auto_write = TRUE)
m = stan_model('model1_lift.stan')
fit = sampling(m, data=stan_data, iter=2000, warmup=1000, chains=10, control=list(adapt_delta=0.95))
