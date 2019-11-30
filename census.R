
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

# Link for data at 1km resolution
url = "https://www.zensus2011.de/SharedDocs/Downloads/DE/Pressemitteilung/DemografischeGrunddaten/csv_Zensusatlas_klassierte_Werte_1km_Gitter.zip;jsessionid=1C3BBC82F13D65F0DC4689BA428846F4.1_cid380?__blob=publicationFile&v=8"
destfile = "data/raster/census.zip"

# Download the data
if (!file.exists(destfile)) {
  dir.create("data/raster", recursive = TRUE)
  download.file(url ,destfile, mode='wb')
  unzip(
    zipfile = destfile,
    exdir = "data/raster/census")}else {
    print("file already exists")
  }

# Read in CSV-File
census = read.csv("data/raster/census/Zensus_klassierte_Werte_1km-Gitter.csv", sep = ";")

# download German border polygon using "get data", which is also a function from the raster package
ger = getData(country = "DEU", level = 0)


# 13 Variables
# for more than 13.000 Grid Cells
dim(census)

# What are the variable names?
names(census)



# pop = population, hh_size = household size
input = dplyr::select(census, x = x_mp_1km, y = y_mp_1km, Einwohner,
                      fr_a = Frauen_A, alt_d = Alter_D,
                      hh_gr = HHGroesse_D, u_18 = unter18_A, ue65 = ab65_A,
                      ausl = Auslaender_A, leer = Leerstandsquote)


names(input)

# Encode all NAs
input_tidy = mutate_all(input, list(~ifelse(. %in% c(-1, -9), NA, .)))

# Convert it into rasterbrick
rast_brick = rasterFromXYZ(input_tidy, crs = st_crs(3035)$proj4string)

# Convert Brick into Stack
rast_stack = stack(rast_brick)
class(rast_stack)

# Convert to discrete Raster Layers
for (i in names(rast_stack)) {
  rast_stack[[i]] = ratify(rast_stack[[i]])
  values(rast_stack[[i]]) = as.factor(values(rast_stack[[i]]))
}

names(rast_stack)

# Subset Raster to extract Einwohenr
rast_einwohner = raster::subset(rast_stack, "Einwohner")
plot(rast_einwohner)


###############################
##  download clip shapefile  ##
###############################

ger_wgs = st_read("data/shape/ger_utm_wgs84/VG250_Bundeslaender.shp")
ger_3035 = st_transform(ger_wgs, 3035)

hamburg = ger_3035 %>% dplyr::filter(GEN == "Hamburg")
plot(hamburg[0], axes = TRUE)

hamburg2 = st_crop(hamburg, xmin = 4300000, ymin = 3360000, xmax = 4345000, ymax = 3410000)
plot(hamburg2[0], border= "red", axes = T)

hamburg3 = dplyr::select(hamburg2, geometry, GEN)


####################
##  Clip Hamburg  ##
####################

plot(hamburg3,
     main = "Shapefile that'll be the crop extent",
     axes = TRUE,
     border = "blue",
     col = NA)

ger_crop = crop(rast_einwohner, extent(hamburg3))
ham_mask = mask(ger_crop, hamburg3)
plot(ham_mask)
plot(hamburg3, border = "blue", lwd = 7, add = T, col = NA)


recl_einw_hamburg = reclassify(x = ham_mask, rcl = rcl_pop, right = NA)




###################
##  leaflet map  ##
###################
#
# newproj <- "+proj=lcc +lat_1=48 +lat_2=33 +lon_0=-100 +ellps=WGS84"
# ham_wgs84 = projectRaster(ham_mask, crs=newproj)

pal <- colorNumeric(c("#00ff00", "#ffff00", "#ff0000"), values(recl_einw_hamburg),
                    na.color = "transparent")


leaflet() %>%
  addProviderTiles('Esri.WorldImagery',group='Imagery') %>%
  addProviderTiles('Esri.WorldStreetMap', group='Streets') %>%
  addRasterImage(recl_einw_hamburg, colors = pal, opacity = 0.7, group = "A") %>%
  addLayersControl(
    baseGroups = c("Imagery", "Streets"),
    overlayGroups = c("Hamburg Einwohner"),
    options = layersControlOptions(collapsed = FALSE)
  ) %>%
  addLegend(pal = pal, values = getValues(recl_einw_hamburg))

getValues(recl_einw_hamburg)
