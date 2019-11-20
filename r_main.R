
######################
##  404 Präsentation
##  Robin Kohrs
######################

# Load libraries ---------------------------------------------------------------
library(sf)
library(here)
library(dplyr)
library(ggplot2)


# Set download parameter
url = "https://www.zensus2011.de/SharedDocs/Downloads/DE/Shapefile/VG250_1Jan2011_WGS84.zip?__blob=publicationFile&v=29"
destfile = "data/germanyplz.zip"

# Check if file already exists ------------------------------------------------
if (!file.exists(destfile)) {
  download.file(url ,destfile, mode='wb')} else {
    print("file already exists")
  }

# Extract Zip-File -------------------------------------------------------------
unzip(
  zipfile = destfile,
  exdir = "data/germany")

# Read Shapefile
germany = st_read("data/germany/VG250_Bundeslaender.shp")

# What have we got?
str(germany)
head(germany$GEN)

# PLot the shapefile
plot(st_geometry(germany))

# Plot Hamburg
hamburg = germany %>%
  dplyr::filter(GEN == "Hamburg")

class(hamburg)
names(hamburg)

# Plot Hmamburg and Warnemünde
ggplot(hamburg) +
  geom_sf(data = hamburg, color = "black", fill = "blue") +
  xlab("Longitude") + ylab("Latitude") +
  coord_sf(crs = st_crs(hamburg)) +
  ggtitle("Hamburg", subtitle = "und seine Inseln")

# draw a polygon in the southeastern corner of the meuse
poly = data.frame(x = c(9.5, 10.5, 10.5, 9.5),
                  y = c(53.3, 53.3, 53.8, 53.8))

# Order the points in clockwise direction
poly = as.matrix(poly[c(4, 1, 2, 3, 4), ])

poly = st_polygon(list(poly)) %>%
# convert simple feature into a sfc
  st_sfc(crs = 4326)

class(poly)


