## Exercise 1: Where did the seal go?
## Using the grammar of graphics.
library(ggplot2)
library(ggmap)

## Load data
load('Data/dat1_gps.RData')  # Loads data frame with name 'dat1_gps'
(n <- nrow(dat1_gps))  # It's not that large.

## Take a look:
head(dat1_gps )

##
## 1. Introduction to ggplot2
##

## Let's explore *geometries* by plotting the seal's path 
## (using ggplot2's "quick plot")
qplot(lon, lat, data = dat1_gps)
qplot(lon, lat, data = dat1_gps, geom = "path")
qplot(lon, lat, data = dat1_gps, geom = c("path", "point"))

## Explore *aesthetics* (and move to ggplot2's "full plotter")
#### Original plot:
ggplot(dat1_gps, aes(lon, lat)) + 
    geom_path() +
    geom_point()
#### Add colour for night/day; make points translucent.
#### --> Why are "size" and "alpha" not in the aesthetic mapping 'aes'?
p <- ggplot(dat1_gps, aes(lon, lat)) + 
    geom_path(aes(colour = night, group = 1), size = 1) +
    geom_point(alpha = 0.2)
p

## Change the *labels* and *look* of the plot
p + labs(x = "Longitude\n(Degrees)", 
         y = "Latitude\n(Degrees)", 
         title = "A Northern Fur Seal's Trip to Sea") +
    scale_colour_discrete("Time of Day", 
                          labels = c("Day-time", "Night-time")) +
    theme(axis.title.y = element_text(angle = 0),
          plot.title = element_text(face = "bold", size = 14),
          legend.position = "bottom")
#### There are many many looks you can change. Take a look at:
?theme

## Handy trick: save the "layers"
plus <- list(geom_path(aes(colour = night, group = 1), size = 1),
             geom_point(alpha = 0.2),
             labs(x = "Longitude\n(Degrees)", 
                  y = "Latitude\n(Degrees)", 
                  title = "A Northern Fur Seal's Trip to Sea"),
             scale_colour_discrete("Time of Day", 
                                   labels = c("Day-time", "Night-time")),
             theme(axis.title.y = element_text(angle = 0),
                   plot.title = element_text(face = "bold", size = 14),
                   legend.position = "bottom"))
#### Achieve the same plot by:
ggplot(dat1_gps, aes(lon, lat)) + plus

##
## 2. Introduction to ggmap
##

## Get a map:
#### From Google Maps (default):
my_map_goo <- get_map(c(mean(dat1_gps$lon), mean(dat1_gps$lat)), 
                        zoom = 8, maptype = "satellite")
ggmap(my_map_goo)   # View it.

#### From OpenStreetMap
#### (I'll use the osm-specific "get_" function)
my_map_osm <- get_openstreetmap(c(-170.5, 56.5, -168, 57.75))
ggmap(my_map_osm)   # View it.

## Overlay the original trackplot:
p2 <- ggmap(my_map_osm, base_layer = ggplot(dat1_gps, aes(lon, lat))) +
    plus
p2

## Finally, let's annotate the plot with an overview map
#### Get small-scale map
overview <- get_googlemap(c(mean(dat1_gps$lon), mean(dat1_gps$lat)),
                          zoom = 4, maptype = "satellite",
                          markers = data.frame(longitude=mean(dat1_gps$lon), 
                                               latitude=mean(dat1_gps$lat)))
#### Take a look:
ggmap(overview)
#### Add it to the original:
p2 + inset_raster(overview, xmin=-168.75, xmax=-168, ymin=56.5, ymax=56.875) +
    annotate("rect", xmin=-168.75, xmax=-168, ymin=56.5, ymax=56.875,
             colour="black", fill=NA)
