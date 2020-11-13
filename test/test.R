library(magrittr)

fn_xlsx <-  "E:\\野外实验\\太湖 202008\\202008太湖实验数据质量汇总V1.3-20201108.xlsx"
tmp <- openxlsx::read.xlsx(fn_xlsx, "基本参数 ")
names(tmp)

w = which(tmp$`采水深度.[m]` == 0)

dt_pt <- tmp[w, c("通用编号", "测量时间.[年月日]", "测量时间.[时分]", "经度.[°]", "纬度.[°]")] %>%
  setNames(., c("StaName", "Date","Time","LON","LAT"))

dt_pt$Date <- readxl::read_excel(fn_xlsx, "基本参数 ", range = "C1:C191") %>% as.data.frame %>% .[w, ]
dt_pt$Time <- readxl::read_excel(fn_xlsx, "基本参数 ", range = "D1:D191") %>% as.data.frame %>% .[w, ]

names(dt_pt) <- c("StaName", "Date","Time","LON","LAT")


library(raster)
fn <- "C:\\Users\\Shun Bi\\Desktop\\L3_Taihu\\S3B_OL_1_EFR____20200818T014826.img"
im <- brick(fn)
if(crs(im) %>% as.character != "+proj=longlat +datum=WGS84 +no_defs"){
  im <- projectRaster(im, crs = "+proj=longlat +datum=WGS84 +no_defs", method="ngb")
}

xy_extract <- extract(im, SpatialPoints(dt_pt[,c("LON", "LAT")]))

result <- cbind(StaName = dt_pt$StaName, xy_extract) %>% as.data.frame
