#install.packages("pak")

#pak::pak_install

install.packages(c(
'archive',
'languageserver',
'httpgd',
'quarto',
'dplyr',
'purrr',
'httr2',
'tidyr',
'forcats',
'devtools',
'reticulate',
'shiny',
'duckdbfs',
'sf',
'terra',
'gdalcubes',
'arrow',
'V8'))

install.packages("pak")
pak::pkg_install("ggplot2") # r-cran-s7 dependency is messed up?
pak::pkg_install("tidyverse")
