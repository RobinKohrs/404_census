
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
                      Frauen_A, Alter_D,
                      hh_gr = HHGroesse_D)


summary(input[1:5])

# Encode all NAs
input_tidy = mutate_all(input, list(~ifelse(. %in% c(-1, -9), NA, .)))

# Convert it into rasterstack
rast_brick = rasterFromXYZ(input_tidy, crs = st_crs(3035)$proj4string)

# How many NAs are still there
summary(rast)
ok = complete.cases(input_tidy)
class(ok)
sum(!ok)

# Convert Brick into Stack
rast_stack = stack(rast_brick)
class(rast_stack)

# Convert to discrete Raster Layers
for (i in names(rast_stack)) {
  rast_stack[[i]] = ratify(rast_stack[[i]])
  values(rast_stack[[i]]) = as.factor(values(rast_stack[[i]]))
}

names(rast_stack)


# stack_1 = spplot(rast_stack, col.regions = RColorBrewer::brewer.pal(6, "GnBu"),
#              main = list("Classes", cex = 0.5),
#              layout = c(4, 1),
#              # Leave some space between the panels
#              between = list(x = 0.5),
#              colorkey = list(space = "top", width = 0.8, height = 0.2,
#                              # make tick size smaller
#                              tck = 0.5,
#                              labels = list(cex = 0.4)),
#              strip = strip.custom(bg = "white",
#                                   par.strip.text = list(cex = 0.5),
#                                   factor.levels = c("Einwohner", "Anteil Frauen",
#                                                     "Durchschn. Alter",
#                                                     "HH Größe")),
#              sp.layout = list(
#                list("sp.polygons", ger, col = gray(0.5),
#                     first = FALSE)))
# stack_1

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

plot(hamburg2,
     main = "Shapefile that'll be the crop extent",
     axes = TRUE,
     border = "blue",
     col = NA)

ger_crop = crop(rast_einwohner, extent(hamburg3))
ham_mask = mask(ger_crop, hamburg3)
plot(ham_mask)
plot(hamburg3, border = "blue", lwd = 7, add = T, col = NA)


###################
##  leaflet map  ##
###################

class(ham_mask)
crs(ham_mask, asText = FALSE)
projectRaster()


leaflet() %>%
