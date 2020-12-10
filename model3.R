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

# Choose time period (May or July)
time = "May"

if(time=="May"){
  # Read which countries to use
  countries <- readRDS('data/country-May-5.rds')
  # Read deaths data for regions
  d <- readRDS('data/COVID-19-May-5.rds')
  # Read IFR and pop by country
  ifr.by.country <- readRDS('data/popt-ifr-May-5.rds')
  # Read interventions
  interventions <- readRDS('data/interventions-May-5.rds')
}else if(time=="July"){
  countries <- readRDS('data/country-Jul-12.rds')
  d <- readRDS('data/COVID-19-Jul-12.rds')
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

if(time=="May"){
  # Combining the design matrices of NPI interventions and average Google mobility
  X_npi = stan_data$X
  X_mobility = readRDS("data/average-google-mobility-X-May-5.rds")
  X_partial_state = readRDS("data/average-google-mobility-partial-X-May-5.rds")
  X = abind(X_mobility, X_npi[,,c(1:3,5,6)], along=3)
  
  # AR(2) weekly auto-regressive process
  W = readRDS("data/W-May-5.rds")
  week_index = readRDS("data/week_index-May-5.rds")
}else if(time=="July"){
  X_npi = stan_data$X
  X_mobility = readRDS("data/average-google-mobility-X-Jul-12.rds")
  X_partial_state = readRDS("data/average-google-mobility-partial-X-Jul-12.rds")
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
  X = abind(X_mobility, X_npi[,,c(1:3,5,6)], X_lift, along=3)
  
  W <- ceiling(N2/7)
  
  week_index <- matrix(1,length(countries$Regions),N2)
  for(state.i in 1:nrow(week_index)) {
    week_index[state.i,] <- rep(2:(W+1),each=7)[1:N2]
    last_ar_week = which(dates[[state.i]]==max(d$DateRep) -28)
    week_index[state.i,last_ar_week:ncol(week_index)] <-  week_index[state.i,last_ar_week]
  }
}

P = dim(X)[3]
P_partial_state = dim(X_partial_state)[3]

stan_data$P = P
stan_data$P_partial_state = P_partial_state
stan_data$X = X
stan_data$X_partial_state = X_partial_state
stan_data$W = W
stan_data$week_index = week_index

# Running model 3
options(mc.cores = parallel::detectCores())
rstan_options(auto_write = TRUE)
m = stan_model('model3.stan')
fit = sampling(m, data=stan_data, iter=2000, warmup=1000, chains=10, control=list(adapt_delta=0.95))
