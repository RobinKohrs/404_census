
library(lobstr)

# Link for data at 1km resolution
url = "https://www.zensus2011.de/SharedDocs/Downloads/DE/Pressemitteilung/DemografischeGrunddaten/csv_Bevoelkerung_100m_Gitter.zip?__blob=publicationFile&v=3"
destfile = "data/raster/census_100m/census_100m.zip"

# Download the data
if (!file.exists(destfile)) {
  dir.create("data/raster/census_100m", recursive = TRUE)
  download.file(url ,destfile, mode='wb')
  unzip(
    zipfile = destfile,
    exdir = "data/raster/census_100m")}else {
      print("file already exists")
    }

# Read in CSV-File
census100 = read.csv("data/raster/census_100m/Zensus_Bevoelkerung_100m-Gitter.csv", sep = ";")

# Check names
class(census100)
obj_size(census100)
names(census100)

# clean up
census100 = dplyr::select(census100, x = x_mp_100m, y = y_mp_100m, Einwohner)

# Encode all NAs
census100_tidy = mutate_all(census100, list(~ifelse(. %in% c(-1), NA, .)))

# Convert it into rasterbrick
brick_100 = rasterFromXYZ(census100_tidy, crs = st_crs(3035)$proj4string)
writeRaster(brick_100, "data/raster/tif/gridcell_100m.tif")

# read in saved raster
singleband_100 = raster("data/raster/tif/gridcell_100m.tif")
file.size("data/raster/tif/gridcell_100m.tif") # size on disk
object.size("data/raster/tif/gridcell_100m.tif") # size in memory. Doesn't read in values
inMemory(singleband_100)
plot(singleband_100)

plot(brick_100)
h = raster::select(brick_100)
plot(h)



###############################
##  download clip shapefile  ##
###############################
ger_wgs = st_read("data/shape/ger_utm_wgs84/VG250_Bundeslaender.shp")
ger_3035 = st_transform(ger_wgs, 3035)
hamburg = ger_3035 %>% dplyr::filter(GEN == "Hamburg")
hamburg = st_crop(hamburg, xmin = 4300000, ymin = 3360000, xmax = 4345000, ymax = 3410000)
sf::write_sf(hamburg, "data/shape/hamburg.shp")


###########################
##  read crop shapefile  ##
###########################

crop = st_read("data/shape/hamburg.shp")
crop_sp = as(crop, Class = "Spatial")
class(crop_sp)

#################################
##  crop to extent of Hamburg  ##
#################################
ham_crop = crop(brick_100, crop_sp)
ham_mask = mask(ham_crop, crop_sp)
plot(ham_mask)


#####################################
##  calcualte mean density for HH  ##
#####################################
mean_dens_ham = extract(brick_100, crop_sp, fun = mean)
mean_dens_ham
