#' @name points_over_rasters
#' @title points_over_rasters
#' @description points_over_rasters
#' @param im Raster object or file path could be read
#' @param pts data.frame of points with name, lon, and lat
#' @param show.map Whether to plot the position and raster frame on \link{leaflet}.
#'   Default is \code{FALSE}.
#' @return Data frame extracted from the raster file
#' @note The crs of \code{pts} should be \code{+proj=longlat +datum=WGS84 +no_defs}.
#' @importFrom raster brick projectRaster extract
#' @importFrom sp SpatialPoints
#' @importFrom magrittr %>%
#' @importFrom htmltools htmlEscape
#' @importFrom leaflet addTiles addScaleBar addRectangles addCircleMarkers labelOptions
#' @export
#' @examples
#' library(raster)
#' library(rsutlis)
#' f <- system.file("external/test.grd", package="raster")
#' im <- raster(f)
#' pts <- data.frame(name = 1:3,
#'                   lon = c(5.73576, 5.73747, 5.74089),
#'                   lat = c(50.97330, 50.96790, 50.97942))
#' result <- points_over_rasters(im, pts)
#'

points_over_rasters <- function(im, pts, show.map=FALSE){

  if(class(im)[1] != "RasterLayer"){
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
    if(!all(names(pts) == c("name", "lon", "lat"))){
      stop("colnames of pts should be name, lon, and lat")
    }
  }else{
    stop("The pts should be a data.frame")
  }

  if(crs(im) %>% as.character != "+proj=longlat +datum=WGS84 +no_defs"){
    im <- projectRaster(im, crs = "+proj=longlat +datum=WGS84 +no_defs", method="ngb")
  }

  xy_extract <- extract(im, SpatialPoints(pts[,c("lon", "lat")]))

  result <- cbind(StaName = pts$name, xy_extract) %>% as.data.frame

  # show map
  if(show.map){
    im_ext <- im@extent
    p <- leaflet() %>%
      addTiles() %>%
      addScaleBar() %>%
      addCircleMarkers(pts$lon, pts$lat, label=htmlEscape(pts$name),
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

globalVariables("crs")



