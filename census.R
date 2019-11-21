
#################
##  CENSUS DATA
#################

library(dplyr)
library(tidyr)
library(raster)
library(sf)

url = "https://www.zensus2011.de/SharedDocs/Downloads/DE/Pressemitteilung/DemografischeGrunddaten/csv_Zensusatlas_klassierte_Werte_1km_Gitter.zip;jsessionid=1C3BBC82F13D65F0DC4689BA428846F4.1_cid380?__blob=publicationFile&v=8"
destfile = "data/raster/census.zip"

# Download the data
if (!file.exists(destfile)) {
  download.file(url ,destfile, mode='wb')} else {
    print("file already exists")
  }

# Extract Zip-File -------------------------------------------------------------
if (!file.exists("data/raster/census")){
  unzip(
    zipfile = destfile,
    exdir = "data/raster/census")
} else {
  print("also already zipped")
}

census = read.csv("data/raster/census/Zensus_klassierte_Werte_1km-Gitter.csv", sep = ";")
names(census)

# pop = population, hh_size = household size
input = dplyr::select(census, x = x_mp_1km, y = y_mp_1km, pop = Einwohner,
                      women = Frauen_A, mean_age = Alter_D,
                      hh_size = HHGroesse_D)

input_tidy = mutate_all(input, list(~ifelse(. %in% c(-1, -9), NA, .)))


# Convert it into rasterstack
input_ras = rasterFromXYZ(input_tidy, crs = st_crs(4326)$proj4string)
class(input_ras)


ggplot() +
  geom_raster(data = input_ras , aes(x = x, y = y, fill = women)) +
  coord_quickmap()
