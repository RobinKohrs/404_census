
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
destfile = "data/VG250_1Jan2011_WGS84.zip"

# Check if file already exists ------------------------------------------------
if (!file.exists(destfile)) {
  download.file(url ,destfile, method="auto")} else {
    print("file already exists")
  }

# Extract Zip-File -------------------------------------------------------------
unzip(
  zipfile = "data/verwaltungsgrenzen.zip",
  exdir = "data/verwaltungsgrenzen"
)

# Read Shapefile
germany = st_read("data/verwaltungsgrenzen/VG250_Bundeslaender.shp")

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

ggplot(hamburg) +
  geom_sf(aes(fill = "red"), show.legend = "GEN")

