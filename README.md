# sea-mammal-gg
A demonstration of sea mammal tracking visualization in R, by [Vincenzo Coia](https://vincenzocoia.wordpress.com/), with data from [Tiphaine Jeanniard Du Dot](http://www.fisheries.ubc.ca/students/tiphaine-jeanniard-du-dot).

What is this?
==
This repository contains everything you need to reproduce the graphics and shiny app that I demonstrated in the [Sea Mammal Roundtable](http://bioanalytics.pwias.ubc.ca/) at the University of British Columbia, on May 6, 2015.

Goal of the demonstration
==
There are three goals of this demonstration:

1. *conceptual* -- how can one go about visualizing many variables?
2. *exposure* to handy R packages for visualization
3. *exploratory analysis* of a Northern Fur Seal's trip to sea

What exercises are in the demonstration?
==
There are three demonstrations in this repository:

1. Using `ggplot2` and `ggmap` to produce an overview map of the seal's path.
  * Go through 1-GPS_data.R

2. Using `rgl` to visualize the magnetometer/accelerometer data in 3D, and `ggplot2` to project the data in 2D.
  * Go through 2-mag_data.R

3. Using `shiny` to visualize all the data at once, interactively.
  * See the final app [here](https://vcoia.shinyapps.io/gg_demo/).
  * See the source code in the ui.R and server.R files.
    * Run with the `runApp` function in `shiny`, or RStudio's 'Run App' button.

You can find out more about concepts and resources in my slides, entitled presentation.pdf.

What about the data?
==
You can find the data in the 'Data' directory. To work with the exercises, you'll need to download them and make sure the `load` commands in the R code point to the directory you put the data in.

The data have been graciously made available by [Tiphaine Jeanniard Du Dot](http://www.fisheries.ubc.ca/students/tiphaine-jeanniard-du-dot), a PhD student at the University of British Columbia.

The data were recorded for a Norther Fur Seal on Saint Paul Island, Alaska, over her trip to sea between August 26, 2011 and August 31, 2011. The seal was equipped with tags, which produced data on:

* GPS locations when the seal was at the water surface;
* Accelerometer data
* Magnetometer data
* Speed of the seal
* Light level surrounding the seal
* Depth of the seal
