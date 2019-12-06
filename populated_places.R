
library(rnaturalearth)
library(rgdal)
?check_data_exist
existence = rnaturalearth::check_data_exist(scale = 10, type = "populated_places", category = "cultural")
cities = ne_download(scale = 10, type = "populated_places", category = "cultural")
cities_sf = cities %>% st_as_sf()
cities_sf = dplyr::select(cities_sf, name_de)
plot(cities_sf)

