## Explore magnetometer data using rgl and ggplot2.
library(rgl)
library(lubridate)  # Helpful package for dealing with dates.
library(ggplot2)
library(scales)  # Needed to make a manual (cosine) scale

## Load data
load('Data/dat2_ful.RData')   # Takes <10 seconds
(n <- nrow(dat2_ful))  # On the bigger side...

## Take a look:
head(dat2_ful)

##
## 1. 3D viewing with rgl
##

## (A) Let's see the accelerometer data (aX, aY, aZ).
with(dat2_ful, plot3d(aX, aY, aZ))  # Fairly quick!

## It's way too overplotted, can't see what's going on in the middle. Let's both:
##  1. subset the data, and
##  2. add alpha-transparency (my favourite way to deal with overplotting)
frac <- 1/500
subdat <- dat2_ful[1:(n*frac)/frac, ]
with(subdat, plot3d(aX, aY, aZ, alpha = 0.2))
## Notice the two "rings".

## Let's "add an aesthetic": view time as colour (higher frequency colours =>
##  later dates)
qplot(26:31, 1, colour = I(rainbow(6)), size = I(10)) +    # Quick legend
    xlab("Date") + ylab("")
with(subdat, plot3d(aX, aY, aZ, alpha = 0.2, col=rainbow(nrow(subdat))))
axis3d('x',pos=c(NA, 0, 0))
axis3d('y',pos=c(0, NA, 0))
axis3d('z',pos=c(0, 0, NA))

## Any pattern by connecting-the-dots?
with(subdat, plot3d(aX, aY, aZ, type = "l", alpha = 0.1))  # Nope.

## (B) Let's see the magnetometer data (mX, mY, mZ).
with(dat2_ful, plot3d(mX, mY, mZ)) 

## Deal with overplotting, and add colour:
with(subdat, plot3d(mX, mY, mZ, alpha = 0.2, col=rainbow(nrow(subdat))))
axis3d('x',pos=c(NA, 0, 0))
axis3d('y',pos=c(0, NA, 0))
axis3d('z',pos=c(0, 0, NA))
## Most of the data are on the surface of the "egg".

## Any pattern by connecting-the-dots?
with(subdat, plot3d(mX, mY, mZ, type = "l", alpha = 0.1))  # Nope.

##
## 2. View Magnetometer data in 2D with ggplot2
##

## We can reduce the magnetometer data to spherical coordinates, of which
##  two dimensions are informative -- the angles, which are analagous
##  to latitude and longitude on the earth. After transforming the data,
##  we'll progress from a basic scatterplot to a more informative plot,
##  using most components of the grammar of graphics.

## Preliminaries ---------

## Convert rectangular to spherical coords.
## The new coordinates are: 
##  'angle_lon' -- angle in (0,360) or (0, 2*pi) on the xy-plane (similar
##    to longitude, hence the name)
##  'angle_lat' -- angle in (-90,90) or (-pi/2, pi/2) away from the xy-plane
##    (similar to latitude, hence the name)
##  'r' -- distance from the origin.
rec2pol <- function(x, y, z, degrees = TRUE){
    res <- data.frame(angle_lon = atan(y/x) + pi*(x<=0) + 2*pi*(x>0 & y<0),
                      angle_lat = atan(z / sqrt(x^2 + y^2)),
                      r = sqrt(x^2 + y^2 + z^2)) 
    if (degrees) res[, 1:2] <- res[, 1:2] * 180/pi
    res
}
spheric <- with(dat2_ful, cbind(time, rec2pol(mX, mY, mZ)))
head(spheric)

## Add "hemisphere" -- it'll come in handy later
hemi <- rep(NA, nrow(spheric))
hemi[spheric$angle_lat < 0] <- "Lower 'Hemisphere'"  # Below xy-plane
hemi[spheric$angle_lat >= 0] <- "Upper 'Hemisphere'" # Above xy-plane
spheric$hemisphere <- hemi

## Note: ggplot seems to be having a hard time putting dates on the colour
##   scale, as we'll do later. So I'll convert the dates to something 
##   continuous (seconds; POSIXct).
spheric$sec <- as.numeric(spheric$time)

## Subset the data:
frac <- 1/100
subspheric <- spheric[1:(n*frac)/frac, ]

## We can see that the data don't lie perfectly on a sphere. This may suggest
##  that the data need calibrating, but it's good enough for our purposes.
## (Use *statistical transformation* of the data to see distribution of r)
#### "Count" transform for histogram.
qplot(r, data = subspheric, binwidth = 1)
#### "Density" transform for kernel density plots.
ggplot(subspheric, aes(r)) +
    geom_density(aes(group = hemisphere, fill = hemisphere), alpha = 0.25)

## (I) Basic scatterplot ---------

## Display the two spherical angles as a scatterplot.
ggplot(subspheric, aes(angle_lon, angle_lat, colour = sec)) +
    geom_point(alpha = 0.2)

## Would like to change the colour scale (and the labels)
## Need to know about grammar component #3: scales.

## (II) Add rainbow colour scale to the plot ---------

## Make a manual scale:
#### Change the labels 
scale_dates <- unique(day(subspheric$time))
my_labs <- paste("Aug.", scale_dates)  # The labels I want on the scale.
my_breaks <- as.integer(ymd_hms(paste0("2011-08-", scale_dates, " 00:00:00"))) 
    # Breaks are *where* on the scale I want to put labels.

#### Construct the scale:
date_legend <- scale_colour_gradientn("Date",
                                      colours = rainbow(7),
                                      breaks = my_breaks,
                                      labels = my_labs)
## Add scale to the scatterplot
ggplot(subspheric, aes(angle_lon, angle_lat, colour = sec)) +
    geom_point(alpha = 0.2) +
    date_legend

## Nice, but the upper portion (at 90 degrees) actually represents one point.
##  Likewise with the lower portion (at -90 degrees).

## Solution: convert to polar coordinates.
##  We'll use grammar component #4: "coordinates"

## (III) Change to polar coordinates ---------

p <- ggplot(subspheric, aes(angle_lon, abs(angle_lat))) +
    coord_polar() +
    date_legend +
    ylab("Inclination / Declination\n(degrees)") +
    scale_x_continuous("Bearing (degrees)", 
                       breaks = 0:7*45, 
                       limits = c(0, 360))

p + geom_point(aes(colour = sec), alpha = 0.1) + 
    scale_y_reverse()

## Now it would be nice to differentiate between points above the xy-plane
##  and below the xy-plane -- use the "hemisphere" variable created.
##  Grammar component being used: *layering/facetting*.

## (IV) Add facetting for different "hemispheres" ---------

p + facet_wrap(~ hemisphere) +
    geom_point(aes(colour = sec), alpha = 0.1) + 
    scale_y_reverse()

## (V) Final touches ---------

## Would be nice to:
##  1. Spread out the center -- cosine *scale* transform would be ideal, since
##       that provides a projection of the sphere onto the plane.
##  2. Make "upper hemisphere" less translucent, via *aesthetics* (since it's
##       less crowded)
my_cosine <- trans_new("my_cos", 
                       transform = function(y) cos(y*pi/180), 
                       inverse = function(theta) acos(theta)*180/pi)
p + facet_wrap(~ hemisphere) +
    geom_point(aes(colour = sec, alpha = hemisphere)) + # Notice alpha is in aes
    scale_y_continuous(trans = my_cosine) +
    scale_alpha_discrete(range = c(0.1, 0.3), guide=FALSE)
