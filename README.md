# imperial-covid19-model
Code repository for COVID-19 models proposed by the [Imperial College COVID-19 Response Team](https://mrc-ide.github.io/covid19estimates/#/), and discussed in ["Effects of non-pharmaceutical interventions on COVID-19: A Tale of Three Models"](https://www.medrxiv.org/content/10.1101/2020.07.22.20160341v2.full.pdf).

## Installation

1) Install R.

    For Windows:<br/>
    Download the binary setup file for R [here](https://cran.r-project.org/bin/windows/base/) and open the downloaded .exe file.
    
    For MacOS:<br/>
    Download the appropriate version of .pkg file [here](https://cran.r-project.org/bin/macosx/) and open the downloaded .pkg file.
    
2) Install RStudio.
    Choose the appropriate installer file for your operating system [here](https://rstudio.com/products/rstudio/), download it and then run it to install RStudio.
    
3) Download all files in the repository to your working directory. 

## Script description
``model1.R`` contains code running the model in [Flaxman, S. *et al.* Estimating the effects of non-pharmaceutical interventions on COVID-19 in Europe. *Nature* (2020)](https://www.nature.com/articles/s41586-020-2405-7) up to May 5th.

``model1_lift.R`` contains code running the model in [Flaxman, S. *et al.* Estimating the effects of non-pharmaceutical interventions on COVID-19 in Europe. *Nature* (2020)](https://www.nature.com/articles/s41586-020-2405-7) up to July 12th, and allowing for asymmetric effects in NPIs imposition and lifting.

``model2.R`` contains code running the model in [Unwin, H. J. T. *et al.* State-level tracking of COVID-19 in the United States. *medRxiv* (2020)](https://www.medrxiv.org/content/10.1101/2020.07.13.20152355v2) up to May 5th or July 12th, but applied to European countries.

``model3.R`` contains code running model 3 up to May 5th.

## Acknowledgement
We thank the Imperial College COVID-19 Response Team for sharing openly the code for models 1 and 2 that has allowed the analysis for model 3.
