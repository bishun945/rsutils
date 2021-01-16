#' @name points_over_rasters
#' @title points_over_rasters
#' @description points_over_rasters
#' @param im Raster object or file path could be read
#' @param pts data.frame of points with the colname \strong{name, lon, lat}
#' @param show.map Whether to plot the position and raster frame on \link{leaflet}.
#'   Default is \code{FALSE}.
#' @return Data frame extracted from the raster file
#' @note The crs of \code{pts} should be \code{+proj=longlat +datum=WGS84 +no_defs}.
#' @importFrom raster brick projectRaster extract crs nlayers
#' @importFrom sp SpatialPoints
#' @importFrom magrittr %>%
#' @importFrom htmltools htmlEscape
#' @importFrom leaflet leaflet addTiles addScaleBar addRectangles addCircleMarkers labelOptions
#' @export
#' @examples
#' library(raster)
#' library(rsutlis)
#' f <- system.file("external/test.grd", package="raster")
#' im <- raster(f)
#' im2 <- brick(im, im*2, im*3)
#' pts <- data.frame(name = paste0("ID", 1:5),
#'                   lon = c(5.73576, 5.73747, 5.74089, 20.00, 21.00),
#'                   lat = c(50.97330, 50.96790, 50.97942, 100.00, 101.00))
#' if(require(leaflet)){
#' result_im <- points_over_rasters(im, pts, show.map = TRUE)
#' result_im2 <- points_over_rasters(im2, pts, show.map = TRUE)
#' }else{
#' result_im <- points_over_rasters(im, pts, show.map = FALSE)
#' result_im2 <- points_over_rasters(im2, pts, show.map = FALSE)
#' }
#'

points_over_rasters <- function(im, pts, show.map=FALSE){

  if(!(class(im)[1] %in% c("RasterBrick", "RasterLayer"))){
    if(is.character(im)){
      im <- brick(im)
    }else{
      stop("im should be a raster file (brick) or file path could be read as it.")
    }
  }

  if(is.data.frame(pts)){
    if(ncol(pts) != 3){
      stop("The pts should have three columns: name, lon, and lat")
    }
    # if(!all(names(pts) == c("name", "lon", "lat"))){
    #   stop("colnames of pts should be name, lon, and lat")
    # }
    if(anyNA(pts)) {
      stop("Remove the NA values before using the funciton!")
    }
    if(!(is.numeric(pts[,2]) & is.numeric(pts[,3]))) {
      stop("The second and third column of `pts` should be numeric lonlat!")
    }
  }else{
    stop("The pts should be a data.frame")
  }

  if(crs(im) %>% as.character != "+proj=longlat +datum=WGS84 +no_defs"){
    im <- projectRaster(im, crs = "+proj=longlat +datum=WGS84 +no_defs", method="ngb")
  }

  im_ext <- im@extent

  w <- pts[, 2] >= im_ext@xmin & pts[, 2] <= im_ext@xmax &
          pts[, 3] >= im_ext@ymin & pts[, 3] <= im_ext@ymax

  if(length(which(!w)) != 0) {
    cat(sprintf("Point `%s` with lon `%s` and lat `%s` is out of the raster extent\n",
                pts[!w, 1], pts[!w, 2], pts[!w, 3]))
  }

  xy_extract <- extract(im, SpatialPoints(pts[w, c(2, 3)]))

  result <- matrix(NA, nrow = nrow(pts), ncol = raster::nlayers(im)) %>%
    as.data.frame() %>%
    setNames(., names(im))

  rownames(result) <- pts[,1]

  result[w,] <- xy_extract

  # result <- cbind(StaName = pts$name, xy_extract) %>% as.data.frame

  # show map
  if(show.map){
    p <- leaflet() %>%
      addTiles() %>%
      addScaleBar() %>%
      addCircleMarkers(pts[w,2], pts[w,3], label=htmlEscape(pts$name),
                       labelOptions = labelOptions(noHide=FALSE, textonly=TRUE, textsize="9px"),
                       radius=2, opacity=0, fillOpacity = 1, color="red") %>%
      addRectangles(
        lng1 = im_ext@xmin,
        lng2 = im_ext@xmax,
        lat1 = im_ext@ymin,
        lat2 = im_ext@ymax,
        fillColor = "transparent"
      )

    print(p)
  }

  return(result)

}




