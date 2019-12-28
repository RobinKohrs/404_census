
#################
##  CENSUS DATA
#################

library(dplyr)
library(tidyr)
library(raster)
library(sf)
library(ggplot2)
library(lattice)
library(leaflet)
library(osmdata)
library(tmap)
library(mapview)
library(RColorBrewer)

# Read in CSV-File
census = read.csv("data/raster/census/Zensus_klassierte_Werte_1km-Gitter.csv", sep = ";")

# pop = population, hh_size = household size
input = dplyr::select(census, x = x_mp_1km, y = y_mp_1km, Einwohner,
                      fr_a = Frauen_A, alt_d = Alter_D,
                      hh_gr = HHGroesse_D, u_18 = unter18_A, ue65 = ab65_A,
                      ausl = Auslaender_A, leer = Leerstandsquote)

# Encode all NAs
input_tidy = mutate_all(input, list(~ifelse(. %in% c(-1, -9), NA, .)))

# Convert it into RasterBrick
rast_brick = rasterFromXYZ(input_tidy, crs = st_crs(3035)$proj4string)
object.size(rast_brick)

# Convert Brick into Stack
rast_stack = stack(rast_brick)


# Convert to discrete Raster Layers
for (i in names(rast_stack)) {
  rast_stack[[i]] = ratify(rast_stack[[i]])
  values(rast_stack[[i]]) = as.factor(values(rast_stack[[i]]))
}


###############################
##  download clip shapefile  ##
###############################
ger_wgs = st_read("data/shape/ger_utm_wgs84/VG250_Bundeslaender.shp")
ger_3035 = st_transform(ger_wgs, 3035)
hamburg = ger_3035 %>% dplyr::filter(GEN == "Hamburg")
hamburg = st_crop(hamburg, xmin = 4300000, ymin = 3360000, xmax = 4345000, ymax = 3410000)

#######################################
##  crop stack to extent of Hamburg  ##
#######################################

pal <- colorRampPalette(brewer.pal(9, "BrBG"))

hamburg_stack = crop(rast_stack, extent(hamburg))
hamburg = mask(hamburg_stack, hamburg)
mapview(hamburg, col.regions = pal)
