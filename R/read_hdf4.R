library(gdalUtils)
library(stringr)
library(magrittr)
library(rgdal)

# parameter settings
fn = "H:\\ImageData\\MODIS_taihu\\MOD00.P2016204.0450_1_hdf4.L2_LAC"
verbose = TRUE


read_sds_names <- function(fn){
  info = gdalUtils::gdalinfo(fn)
  sds <- get_subdatasets(fn)
  sds_ind <- str_split(sds, "\\\\|:", simplify = TRUE) %>%
    .[, ncol(.)] %>% str_c(":", .)
  sds_name_ind <- NULL
  for(i in 1:length(sds_ind)){
    sds_name_ind[i] <- str_match(info, sds_ind[i]) %>% is.na %>% {which(!.) + 1}
  }
  if(is.null(sds_name_ind)){
    stop("Can not match sds_names!")
  }
  sds_name <- str_split(info[sds_name_ind], "[:blank:]", simplify = TRUE) %>% .[,4]
  return(
    data.frame(sds, sds_name, stringsAsFactors = FALSE)
  )
}

#' @name get_sds_info
#' @export
get_sds_info <- function(fn){
  sds_info <- read_sds_names(fn)
  return(sds_info$sds_name)
}


#' @name read_hdf4
#' @export
read_hdf4 <- function(fn, which_sds = "all"){

  sds_info <- read_sds_names(fn)

  df_hdf <- data.frame()


  if(which_sds = "all"){
    sds_select <- sds_info$sds_name
  }else{
    if(all(which_sds %in% sds_info$sds_name)){
      sds_select <- which_sds
    }else{
      which(which_sds %in% sds_info$sds_name == FALSE) %>% which_sds[.] %>%
        cat("which_sds has [", ., "] not included in the HDF4.\n")
    }
  }

  for(i in 1:length(sds_select)){

    if(verbose) cat("Reading ", sds_select[i], "\n")

    sds_value <- readGDAL(sds_info$sds[i], silent=TRUE) %>% as.data.frame

    if(i == 1){
      df_hdf <- data.frame(stringsAsFactors = FALSE,
                           x = sds_value$x,
                           y = sds_value$y)
    }
    df_hdf <- cbind(df_hdf, sds_value[, 1])
    names(df_hdf)[ncol(df_hdf)] <- sds_select[i]

  }

  return(df_hdf)

}

