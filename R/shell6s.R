#' @name rm_in_file
#' @rdname run_simulate_aod
#' @description This function shells 6s.exe in the current work path.
#' @param in_file in_file
#' @param exe_file 6s.exe file
#' @param out_file out.txt file generated from 6s.exe
#' @param rm_out_file Remove the out.txt after runing 6s. Default is \code{TRUE}.
#' @param rm_in_file Remove the in.txt after running 6s. Default is \code{TRUE}.
#' @return None
#'
run_6s <- function(in_file = "in.txt",
                   exe_file = "6s.exe",
                   out_file = "out.txt",
                   rm_out_file = TRUE,
                   rm_in_file = TRUE) {

  if(!file.exists(in_file)) {
    stop("No in.txt found!")
  }

  if(!file.exists(exe_file)) {
    stop("No 6s.exe found!")
  }

  shell(sprintf("%s<%s>%s", exe_file, in_file, out_file))

  if(!file.exists(out_file)) {
    stop("After running 6s, we cannot find out.txt!")
  }else {
    if(rm_out_file) {
      tmp = file.remove(out_file)
      rm(tmp)
    }
  }

  if(!file.exists("sixs.out")) {
    stop("After running 6s, we cannot find sixs.out!")
  }

  if(rm_in_file) {
    tmp = file.remove(in_file)
    rm(tmp)
  }

}

#' @name read_6s_ref
#' @title read_6s_ref
#' @description read the reflectance of sixs.out
#' @param sixs_out file of sixs.out
#' @note the return value is reflectance with unit 1
#' @importFrom stringr str_detect str_extract_all
#' @importFrom magrittr %>%
#' @return Vector of reflectance
#' @noRd
#'

read_6s_ref <- function(sixs_out = "sixs.out") {

  if(!file.exists(sixs_out)) {
    stop("No sixs.out found!")
  }

  lines <- readLines(sixs_out)

  w <- which(stringr::str_detect(lines, "reflectance        :"))
  if(length(w) == 0) {
    stop("Could not find reflectance in sixs.out!")
  }

  key_line <- lines[w]
  ref <- stringr::str_extract_all(key_line, "\\.[:digit:]+", simplify = TRUE) %>%
    as.numeric() %>%
    setNames(., c("rayleigh", "aerosols", "total"))

  return(ref)

}



#' @name run_simulate_aod
#' @title run_simulate_aod
#' @description Simulate the reflectance of aerosol varying on AOD550.
#' @param band_file band_file
#' @param in_ref in.txt reference
#' @param aod550_arr simulated aod550
#' @param verbose TRUE
#' @param sleep TRUE
#' @param ... parameters of the function \code{run_6s}
#' @return A list including the output reflectance.
#' @export
#' @importFrom readr write_lines
#' @importFrom stats setNames
#' @importFrom utils read.csv
#' @importFrom reshape2 melt dcast
#' @examples
#' \dontrun{
#' result <- run_simulate_aod(aod550_arr = seq(0.1, 0.5, 0.1))
#' ref_aerosols <- result$spec_aerosols
#' tmp <- reshape2::melt(ref_aerosols, id=c("aod550"))
#' if(require(ggplot2)) {
#' tmp$variable <- as.numeric(as.vector(tmp$variable))
#' ggplot(data = tmp) + geom_path(aes(x = variable, y = value / pi,
#' group = aod550, color = aod550), size=1) + scale_color_viridis_c()
#' }
#' }
#'

run_simulate_aod <- function(band_file = system.file("OLCI_BN15.csv", package = "rsutlis"),
                             in_ref = system.file("in_ref.txt", package = "rsutlis"),
                             aod550_arr = seq(0.1, 0.5, 0.1),
                             verbose = TRUE,
                             sleep = TRUE,
                             ...) {

  old_wd <- getwd()
  tmp_wd <- tempdir()
  setwd(tmp_wd)
  tmp =file.copy(system.file("6s.exe", package = "rsutlis"), tmp_wd)
  rm(tmp)

  bands <- read.csv(band_file)

  result <- matrix(NA,
                   nrow = nrow(bands) * length(aod550_arr),
                   ncol = 5) %>%
    as.data.frame() %>%
    setNames(., c("wv", "aod550", "rayleigh", "aerosols", "total"))

  j = 1

  for(i in 1:nrow(bands)) {

    for(aod550 in aod550_arr) {


      lines <- readLines(in_ref)
      lines[11] <- aod550
      lines[15] <- bands[i, 1]
      lines[16] <- bands[i, 2]

      readr::write_lines(lines, file = "in.txt")

      run_6s(...)

      ref <- read_6s_ref()
      wv_ref <- c(400, 413, 443, 490, 510, 560, 620, 665,
                  674, 681, 709, 754, 779, 865, 885)
      wv  <- wv_ref[i]

      tmp <- data.frame(wv = wv, aod550 = aod550, t(ref))
      result[j, ] = tmp
      j = j + 1

      if(verbose) {
        cat(paste(tmp, collapse = " ") %>% paste0(., "\n"))
      }

      if(sleep) {
        Sys.sleep(0.0001)
      }

    }

  }

  unlink(tmp_wd, recursive = TRUE)
  setwd(old_wd)

  # spec_rayleigh <- reshape2::dcast(result, aod550 ~ wv, value.var = "rayleigh")
  spec_aerosols <- reshape2::dcast(result, aod550 ~ wv, value.var = "aerosols")
  # spec_total <- reshape2::dcast(result, aod550 ~ wv, value.var = "total")

  return(list(
    result = result,
    # spec_rayleigh = spec_rayleigh,
    spec_aerosols = spec_aerosols
    # spec_total = spec_total
  ))

}
