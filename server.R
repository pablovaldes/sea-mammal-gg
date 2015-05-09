## This is the "server" file of the shiny app.
library(shiny)
library(ggplot2)
library(ggmap)
library(scales)
library(lubridate)
library(ggmap)

## Load data
## (The 'dat1Hz' has the 'dat1_gps' GPS data in it, interpolated between
##   observed GPS locations, but the latter data file is smaller)
load('Data/dat1_gps.RData') # Loads data frame with name 'dat1_gps'
load('Data/dat1Hz.RData')  # Loads data frame with name 'dat1Hz'
load('Data/magplot.RData') # Loads a pre-made version of magnetometer plot

## 
dat1_gps$sec <- as.numeric(dat1_gps$time)

## Get maps:
my_map_osm <- get_openstreetmap(c(-170.5, 56.5, -168, 57.75))
my_map_goo <- get_map(c(mean(dat1_gps$lon), mean(dat1_gps$lat)), 
                      zoom = 8, maptype = "satellite")

## Overview map
overview <- get_googlemap(c(mean(dat1_gps$lon), mean(dat1_gps$lat)),
                          zoom = 4, maptype = "satellite",
                          markers = data.frame(longitude=mean(dat1_gps$lon), 
                                               latitude=mean(dat1_gps$lat)))

## Get interpolation functions for GPS locations:
lat_intpol <- with(dat1_gps, approxfun(sec, lat))
lon_intpol <- with(dat1_gps, approxfun(sec, lon))


## Make a manual scale.
# scale_dates <- 26:31
# orig <- ymd_hms("1970-01-01 00:00:00")
# my_labs <- paste("Aug.", scale_dates)
# my_breaks <- as.integer(
#     seconds(ymd_hms(paste0("2011-08-", scale_dates, " 00:00:00"))) - 
#         seconds(orig))
# date_legend <- scale_colour_gradientn("Date",
#                                       colours = rainbow(7),
#                                       breaks = my_breaks,
#                                       labels = my_labs)

## Sunrise and sunset times for August 25-31, 2011.
##  (sunrise/set times at http://www.sunrisesunset.com/)
sunrise <- ymd_hms(c("2011-08-25 08:07:00",
                     "2011-08-26 08:09:00", 
                     "2011-08-27 08:11:00", 
                     "2011-08-28 08:13:00", 
                     "2011-08-29 08:15:00", 
                     "2011-08-30 08:17:00", 
                     "2011-08-31 08:19:00",
                     "2011-09-31 08:21:00"))
sunset <- ymd_hms(c("2011-08-25 22:40:00",
                    "2011-08-26 22:37:00", 
                    "2011-08-27 22:35:00", 
                    "2011-08-28 22:32:00", 
                    "2011-08-29 22:29:00", 
                    "2011-08-30 22:27:00", 
                    "2011-08-31 22:24:00"))

## Starting GPS location (to represent Saint Paul Island, AK, since shiny
##  seems to have a glitch with ggmap)
lon0 <- dat1_gps$lon[1]
lat0 <- dat1_gps$lat[1]

## Here's the start of the shiny "machinery".
shinyServer(function(input, output) {
    
    ## Get "seconds" range in POSIXct for which to subset.
    sec_rng <- reactive({
        t0 <- input$current_t - 1 # decimal days since the month started
        delT <- input$delta_t
        ## Convert from "day of the month" to "seconds since 1970-01-01 00:00:00".
        t0sec <- as.numeric(ymd_hms("2011-08-01 00:00:00") + seconds(t0*24*60*60))
        delTsec <- delT*60
        list(lower = t0sec - delTsec, upper = t0sec)
    })
    
    ## Subset the data to the specified time.
    thisdat <- reactive({
        secrng <- sec_rng()
        subset(dat1Hz, sec > secrng$lower & sec < secrng$upper)
    })
    thisgps <- reactive({
        secrng <- sec_rng()
        res <- subset(dat1_gps, sec > secrng$lower & sec < secrng$upper)
        res2 <- as.data.frame(matrix(NA, ncol = ncol(res), nrow = nrow(res) + 2))
        names(res2) <- names(res)
        res2[2:nrow(res), ] <- res
        ## interpolate:
        res2$lat[1] <- lat_intpol(secrng$lower)
        res2$lat[nrow(res2)] <- lat_intpol(secrng$upper)
        res2$lon[1] <- lon_intpol(secrng$lower)
        res2$lon[nrow(res2)] <- lon_intpol(secrng$upper)
       na.omit(res[c("lon", "lat")])
    })
    
    ## The overhead plot:
    ## NOTE: There seems to be a glitch with ggmap -- the background
    ##  map can't be displayed. I'll put a red dot where Saint Paul Island is.
    output$mapPlot <- renderPlot({
        plotdat2 <- thisdat()
        plotdat2$alpha <- log(1:nrow(plotdat2))
        activex <- plotdat2$lon[nrow(plotdat2)]
        activey <- plotdat2$lat[nrow(plotdat2)]
        ggplot(aes(lon, lat), data = dat1_gps) +
            geom_path(linetype = "dotted")  +
            geom_path(data=plotdat2) +
            xlim(-170.2955, -168.3307) +
            ylim(57.02646, 57.55096) +
            geom_point(x=lon0, y=lat0, size = 4, colour = "red") +
            geom_point(x=activex, y=activey) +
            labs(title = "Overview\n(Due to potential glitch, red dot = Saint Paul Island)")
    })
    
    ## The magnetometer plot
    output$magPlot <- renderPlot({
        plotdat <- thisdat()
        plotdat <- na.omit(plotdat[c("time", "sec", "angle_lon", "angle_lat", 
                                     "hemisphere", "speed")])
        plotdat$alpha <- sqrt(1:nrow(plotdat))
        magplot + 
            geom_point(data=plotdat, 
                       mapping=aes(size = speed, alpha = alpha)) +
            scale_alpha_continuous(guide=FALSE) +
            scale_size_continuous(trans = trans_new("", 
                                                    transform = log,
                                                    inverse = exp)) +
            labs(title = "Magnetometer data in polar coordinates,\nprojected onto the plane.")
    })
    
    ## The depth plot
    output$depthPlot <- renderPlot({
        plotdat <- thisdat()
        plotdat <- na.omit(plotdat[c("time", "depth", "night", "lightLev")])
        maxdepth <- max(plotdat$depth)
        alphanight <- 0.3
        ## Add night bands to the plot?
        if (input$yes_night) {
           night_ann <- list(
               annotate(geom = "rect", xmin = sunset[1], xmax = sunrise[2], 
                        ymin = -maxdepth, ymax = 0, fill = "black", alpha = alphanight),
               annotate(geom = "rect", xmin = sunset[2], xmax = sunrise[3], 
                        ymin = -maxdepth, ymax = 0, fill = "black", alpha = alphanight),
               annotate(geom = "rect", xmin = sunset[3], xmax = sunrise[4], 
                        ymin = -maxdepth, ymax = 0, fill = "black", alpha = alphanight),
               annotate(geom = "rect", xmin = sunset[4], xmax = sunrise[5], 
                        ymin = -maxdepth, ymax = 0, fill = "black", alpha = alphanight),
               annotate(geom = "rect", xmin = sunset[5], xmax = sunrise[6], 
                        ymin = -maxdepth, ymax = 0, fill = "black", alpha = alphanight),
               annotate(geom = "rect", xmin = sunset[6], xmax = sunrise[7], 
                        ymin = -maxdepth, ymax = 0, fill = "black", alpha = alphanight),
               ylim(-maxdepth, 0),
               xlim(min(plotdat$time), max(plotdat$time)) )
        } else {
            night_ann <- list()
        }
        ggplot(plotdat, aes(time, -depth)) +
            night_ann +
            geom_line(aes(colour = lightLev)) +
            scale_colour_continuous("Light\nLevel") +
            labs(y = "Depth", 
                 title = "Depth plot")
        
    })
    
})