
######################
##  404 Präsentation
##  Robin Kohrs
######################

# Load libraries ---------------------------------------------------------------
library(sf)
library(here)
library(dplyr)
library(ggplot2)




##################################################################
##                       ger_utm in WGS84                       ##
##################################################################

# Set download parameter
url = "https://www.zensus2011.de/SharedDocs/Downloads/DE/Shapefile/VG250_1Jan2011_WGS84.zip?__blob=publicationFile&v=29"
destfile = "data/shape/ger_utm_wgs84.zip"

# Check if file already exists ------------------------------------------------
if (!file.exists(destfile)) {
  dir.create("data/shape")
  download.file(url ,destfile, mode='wb')} else {
    print("file already exists")
  }
# Extract Zip-File -------------------------------------------------------------
if (!file.exists("data/shape/ger_utm_wgs84")){
  unzip(
    zipfile = destfile,
    exdir = "data/shape/ger_utm_wgs84")
} else {
  print("also already zipped")
}


##################################################################
##                       ger_utm in UTM32                       ##
##################################################################

# Set download parameter
url2 = "https://www.zensus2011.de/SharedDocs/Downloads/DE/Shapefile/VG250_1Jan2011_UTM32.zip?__blob=publicationFile&v=25"
destfile2 = "data/shape/ger_utm_utm32.zip"

# Check if file already exists ------------------------------------------------
if (!file.exists(destfile2)) {
  download.file(url ,destfile2, mode='wb')} else {
    print("file already exists")
  }
# Extract Zip-File -------------------------------------------------------------
if (!file.exists("data/shape/ger_utm_utm32")){
  unzip(
    zipfile = destfile2,
    exdir = "data/shape/ger_utm_utm32")
} else {
  print("also already zipped")
}



# Read Shapefile
ger_utm = st_read("data/shape/ger_utm_utm32/VG250_Bundeslaender.shp")
ger_utm = st_transform(ger_utm, 3035)
ger_utm


# What have we got?
str(ger_utm)
head(ger_utm$GEN)

# PLot the shapefile
ggplot(ger_utm) +
  geom_sf(data = ger_utm, col = "black", fill = "lightblue") +
  ggtitle("Deutschland in 3035")

# Plot Hamburg
hamburg = ger_utm %>%
  dplyr::filter(GEN == "Hamburg")

st_crs(hamburg)
names(hamburg)

# Plot Hmamburg and Warnemünde
ggplot(hamburg) +
  geom_sf(data = hamburg, color = "black", fill = "blue") +
  coord_sf(crs = st_crs(hamburg)) +
  ggtitle("Hamburg", subtitle = "und seine Inseln")

ggplot(data = hamburg) +
  geom_sf( color = "black", fill = "blue") +
  coord_sf(xlim = c(9.5, 10.5), ylim = c(53.3, 53.8), expand = TRUE)

# draw a polygon in the southeastern corner of the map
poly = data.frame(x = c(9.5, 10.5, 10.5, 9.5),
                  y = c(53.3, 53.3, 53.8, 53.8))

# Order the points in clockwise direction
poly = as.matrix(poly[c(4, 1, 2, 3, 4), ])

poly = st_polygon(list(poly)) %>%
# convert simple feature into a sfc
  st_sfc(crs = 3035)

st_crs(poly)

plot(hamburg$geometry)
st_crs(poly)

# add polygon
plot(poly, add = TRUE,
     border = "red",
     lwd = 2)


