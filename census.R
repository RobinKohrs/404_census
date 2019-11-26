
#################
##  CENSUS DATA
#################

library(dplyr)
library(tidyr)
library(raster)
library(sf)
library(ggplot2)

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


p_1 = spplot(rast_stack, col.regions = RColorBrewer::brewer.pal(6, "GnBu"),
             main = list("Classes", cex = 0.5),
             layout = c(4, 1),
             # Leave some space between the panels
             between = list(x = 0.5),
             colorkey = list(space = "top", width = 0.8, height = 0.2,
                             # make tick size smaller
                             tck = 0.5,
                             labels = list(cex = 0.4)),
             strip = strip.custom(bg = "white",
                                  par.strip.text = list(cex = 0.5),
                                  factor.levels = c("population", "women",
                                                    "mean age",
                                                    "household size")),
             sp.layout = list(
               list("sp.polygons", ger, col = gray(0.5),
                    first = FALSE)))