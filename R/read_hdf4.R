#' @name read_sds_names
#' @title read_sds_names
#' @param fn fn
#' @importFrom stringr str_match str_c str_split
#' @importFrom gdalUtils gdalinfo get_subdatasets
#' @noRd
read_sds_names <- function(fn){
  info = gdalUtils::gdalinfo(fn)
  sds <- gdalUtils::get_subdatasets(fn)
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
#' @title get_sds_info
#' @param fn fn
#' @noRd
#'
get_sds_info <- function(fn){
  sds_info <- read_sds_names(fn)
  return(sds_info$sds_name)
}


#' @name read_hdf4
#' @title read_hdf4
#' @param fn fn
#' @param which_sds which_sds
#' @param verbose verbose
#' @importFrom rgdal readGDAL
#' @noRd
read_hdf4 <- function(fn, which_sds = "all", verbose = TRUE){

  sds_info <- read_sds_names(fn)

  df_hdf <- data.frame()


  if(which_sds == "all"){
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

