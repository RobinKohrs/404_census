# Filename: Zensus.R
# TO DO: Umwandlung der frei verfügbaren csv-Daten in ein raster stack 
#        und Visualisierung der Ergebnisse an einen Beispiel 
#        (z.B. Jena mit WMS Hintergrundkarte).
# Autor: Harald Lux

#**********************************************************
# INHALT---------------------------------------------------
#**********************************************************
# 1. DATEN UND VORBEREITUNG
# 2. RASTER UND STACKS BAUEN
# 3. VISUALISIERUNG
# 
#**********************************************************
# 1. DATEN UND VORBEREITUNG----------------------------------
#**********************************************************

library(sp)
library(raster)
library(mapview)
library(rgdal)
library(data.table)

maindir <- "C:/tmp2"
setwd("C:/Users/Harry/Desktop/Zensus/Daten")


#**********************************************************
# 2. RASTER UND STACKS BAUEN ------------------------------
#**********************************************************
#Bevölkerungsdaten einlesen
#Nur Einwohner, hohe Auflösung
#res100 <- fread("Zensus_Bevoelkerung_100m-Gitter.csv")

#mehrere Daten, geringere Auflösung
res1000 <- fread("Zensus_klassifizierte_Werte_1km-Gitter.csv")

# Erste Spalte löschen
#res100[,Gitter_ID_100m:= NULL]
res1000[,Gitter_ID_1km:= NULL]

#unbekannte oder geheime Werte löschen, um Anzeige nicht zu verfälschen
res1000 <- res1000[Einwohner != -1]

# in SPDF umwandeln
coordinates(res1000) <- c("x_mp_1km","y_mp_1km")
#coordinates(res100) <- c("x_mp_100m","y_mp_100m")

# Projection hinzufügen für ETRS89:
proj4string(res1000)=CRS("+init=epsg:3035")
#proj4string(res100)=CRS("+init=epsg:3035")

# R Sagen dass es sich um ein grid handelt...
gridded(res1000) = TRUE
#gridded(res100) = TRUE

#Zellmittelpunkt, für korrekte Darstellung je 500m nach links und unten verschieben.
res1000@coords -500
#res100@coords -500

# Alle Daten in ein eigenes Rasterlayer umwandeln
Einwohner <- raster(res1000[1])
#Einwohner_100m <- raster(res100[1])
Frauen <- raster(res1000[2])
Durchschnittsalter <- raster(res1000[3])
Auslaenderanteil <- raster(res1000[6])
Leerstandsquote <- raster(res1000[8])

#alles in ein Stack packen:
stack_ger <-stack(Einwohner,Frauen, Durchschnittsalter,Leerstandsquote)

#**********************************************************
# 3. VISUALISIERUNG MIT MAPVIEW----------------------------
#**********************************************************

Einwohner@data@values[Einwohner@data@values == "-1"] <- NA
Leerstandsquote@data@values[Leerstandsquote@data@values == "-1"] <- NA
Leerstandsquote@data@values[Leerstandsquote@data@values == "-9"] <- NA
Durchschnittsalter@data@values[Durchschnittsalter@data@values == "-1"] <- NA
Durchschnittsalter@data@values[Durchschnittsalter@data@values == "-9"] <- NA
Frauen@data@values[Frauen@data@values == "-1"] <- NA
Frauen@data@values[Frauen@data@values == "-9"] <- NA

#Deutschland komplett:
mapview(stack_ger)

#Bundesländer Shapefile laden
bld <- readOGR(dsn = maindir, layer = "vg2500_bld")
ger <- readOGR(dsn = maindir, layer = "vg2500_sta")
krs <- readOGR(dsn = maindir, layer = "vg2500_krs")

#Thüringen extrahieren:
thue <- bld[15,]
krs <- krs[380:402,]

#Projektion auf etrs89 angleichen:
thue <- spTransform(thue, CRS("+init=epsg:3035"))
ger <- spTransform(ger, CRS("+init=epsg:3035"))
krs <- spTransform(krs, CRS("+init=epsg:3035"))

#Nur die Umrisse behalten, für die Optik:
thuel <- as(thue, "SpatialLines")
ger <- as(ger, "SpatialLines")
krs <- as(krs, "SpatialLines")

#alle Daten auf Grenzen von Thüringen kürzen:
alt_cr <- crop(Durchschnittsalter, extent(thue))
Thueringen_Alter <- mask(x=alt_cr, mask=thue)

ew_cr <- crop(Einwohner, extent(thue))
Thueringen_Einwohner <- mask(x=ew_cr, mask=thue)

fra_cr <- crop(Frauen, extent(thue))
Thueringen_Frauenanteil <- mask(x=fra_cr, mask=thue)

leer_cr <- crop(Leerstandsquote, extent(thue))
Thueringen_Leerstandsquote <- mask(x=leer_cr, mask=thue)

#Für Einwohner 100m Auflösung
#ew_100 <- crop(Einwohner_100m, extent(thue))
#Thueringen_Einwohner_100 <- mask(x=ew_100, mask=thue)

#Einzelnen Thueringen Layer als Karte mit Ländergrenzen anzeigen:
mapview(Thueringen_Einwohner)+mapview(thuel)+mapview(krs)+mapview(ger)

#Stack Thueringen komplett anzeigen
Thueringen_st <- stack(Thueringen_Einwohner,Thueringen_Alter, 
                       Thueringen_Frauenanteil, Thueringen_Leerstandsquote)
mapview(Thueringen_st)+(krs)

#Einwohner in 100m Auflösung anzeigen
#mapview(Thueringen_Einwohner_100,maxpixels = 3135258)+(thuel)+(krs)

#brks= seq(0,500,100) <-- andere Darstellung
#mapview(Thueringen_Einwohner_100, at=brks, maxpixels = 3135258)+(thuel)+(krs)
