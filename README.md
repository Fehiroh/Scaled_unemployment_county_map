# Scaled Unemployment County Map
This Repository contains the scripts and files used to create a scaled map of county unemployment rates in the US. <br>
Note: This is currently a preliminary version of the readme, and is largely pasted verbatim from the actual code. <br>
A cleaned-up version will be out by 2020-08-06. 

# The Abstract:
By normalizing each county's unemployment (within the context of contemporary unemployment rate within the state it belongs to) one can visualize the disproportionate performance of counties within each state, as well as variations in the distribution of unemployment rates between states.

The logic behind this is that the counties belonging the same state share at least some economic opportunities and policy, due to their inclusion within the overarching state-level government. By accounting for this, the visualization accentuates localized/granular variation in unemployment within each state, and allows for more equitable comparison at a national level.

It’s worth noting that county-level inferences are strictly contextualized to the containing state. In other words, a low-severity purple county can actually have a better (lower) unemployment rate than an adjacent high-severity green/yellow county, so long as they occupy states that have varied distributions of unemployment rates. It's about relative performance; a millionaire living with billionaires is still the poorest man on the street.

![Final Result](https://github.com/Fehiroh/Scaled_unemployment_county_map/blob/Fehiroh-patch-1/images/unemployment_map9.png)



# Background

For those of you who aren't familiar with manipulating or analyzing geospatial data, 
in order to make a geospatial visualization, one needs to have: 
  1) Geometry (points, lines, polygons) that represent the location, 
  size, and shape of the subject/subjects being visualized;
  2) Observations of features you'd like to investigate (AKA data), and;
  3) Some means of connecting the two, which can be either:
  i) Related geospatial data (usually latitude, and longitude) tied to each 
        observation; or, 
  ii ) A shared int/char primary key between sources. 
  
  Luckily, When you're learning how to  deal with geospatial data, these three
  things are almost always provided to you in one convenient package (the two
  dominant formatting choice for data transfer are;
     1) sending a zipped folderwith a shp file (geometry), a dbf file (data), and everything necessary for
 the two to communicate with each other and other geodata, or  
     2) as a single geodatabase [gdb]).
      
While this may already seem overwhelming, this is
unfortunately the easiest this process will ever be. In the professional
world, people and systems are fallible, and data is a cavalcade of messiness. 
Oftentimes there are some discepancies that require manipulation. 
(maybe the data is for counties but you're doing municipal or state-level 
analysis).These can be overcome with creative spatial reasoning and
decision-trees. What happens, however, when you need to use data and
geometries from two separate sources, or you don't have any geometries? 

For this exercise, I decided to eschew using tidycensus and tigris [two
packages that provide easily-joined socio-economic and geospatial
(respectively) data], and create a map by piecing together two disparate data
sources. Additionally, for the end-product, I wanted to achieve a balance
between nuance/grainular and readability while sticking to a static
visualization. This was achieved using feature engineering, deliberate graphics
choices, and using 2.5D visualizations to help the reader interpret, all of
 which I'll cover in due course. Firstly, let's discuss 
data sources, importation, cleaning, and wrangling.

# Tools Used:
  * R
       *(tidyverse, sf, tmap, spdplyr, viridisLite, rayshader, magick, cowplot, lintr)
  * GIMP
    *(Integration of plots)
  * Excel (briefly)
  * 7Zip


# Finding the Data:

Part of the challenge of this excercise

## The Shapefile
 The shapefile was obtained from the Homeland Infrastructure Foundation-Level
 Data (HIFLD) at the following address:
 https://hifld-geoplatform.opendata.arcgis.com/datasets/us-county-boundaries, 
 and was unzipped using 7zip. 
## The CSV
 the csv was obtained from the United States Department of Agriculture 
  Economic Research Service at: https://www.ers.usda.gov/data-products/county-level-data-sets/download-data/
  specifically, it's entitled "Unemployment and median household income for the U.S., States, and counties, 2000-19" 
  and is downloadable as an xlsx. Prior to any scripting, the xlsx was converted to a csv manually using some excel hotkeys. 

# Libraries 

The following code installs (if necessary) and loads all requires packages. 

```r 

if (!require("pacman")) install.packages("pacman");
library(pacman)
p_load(tidyverse, sf, tmap, spdplyr, 
       viridisLite, rayshader, magick, cowplot, 
       lintr)
```

# Importation  

```r
root_dir <- paste0("C:/Users/User/.../", # This would obviously need to be changed
                   "county_level_chloreopleth/")

# Loading in the shp
og_shp <- st_read(paste0(root_dir, "tl_2017_us_county/tl_2017_us_county.shp")
) %>%
  filter(STATEFP != 1, STATEFP != 15) #


# Loading in the csv
unemployment_csv <- read_csv(
  paste0(root_dir, 
         "original_data_unemployment.csv")
)
```

# Preparing the Data 

 ## Finding or Creating the Join 
  Because this data is not from the exact same source, whether they 
  natively share a primary key is up to RNGesus. The importance of 
  this is that (without a shared primary key) the information from the csv  
  has no way to be associated with the  shapefile's  geometries, and cannot be 
  visualized  geospatially. 
 I did some quick investigation of the features in both files, and 
 discovered that there was no shared key. Fortunately, by perusing 
 through the data dictionies provided for each file, I deduced
 that the STATEFP and CountyFP columns linked to the .shp could be
 concatinated together to form the unemployment csv's FIPStxt.


```r
og_shp$state_and_county_FP <- str_c(
  og_shp$STATEFP, og_shp$COUNTYFP
)
```



 ## Narrowing the Spatial Scope

 Looking at the native shapefile, it's pretty obvious that I'm going to need 
 to tighten my focus geospatially. As is, the addition of territories like 
 the Virgin Islands, and American Samoa made the scale unwieldy, and the 
 viewer is going to have a hard time making out details. This could be solved 
 by adding an interactive panning and zooming components  to the map via 
 leaflet, plotly, tmap, and/orShiny. Not a bad idea, but  I want to make 
 this fairly quickly, don't want to worry about the server costs to maintain 
 an interactive non-local version, and admittedly already have a 
 fair amount of practice designing customized interactive maps / dashboards 
 professionally;  I've developed a program that automatically 
 locates and fixes user-precision or projection-translation errors  that 
 were responsible for inefficient automatic routing of mobile assets. I also 
 made an interactive visualization that allowed us to quickly discover the 
 the cause of variation between predicted  and actual routing by scrapping 
 flatfishes for discrepancies and visualizing the data upon a satellite image 
 map. 

 Long story short, I wanted to challenge myself to work within the 
 context of a static visualization. However, returning to the problem at hand,
 the USA is too sprawled. There are many ways around this problem
 (for example, one could create separate panes for each non-contiguous 
 US landmass), but I opted to remove Alaska, Hawaii, and the territories from 
 the map altogether. My rationale is that these regions would add a significant 
 amount of design burden (due to scaling issues with the mainland, the
 frequent absence of county-level subdivisions, etc.), 
 while providing little information. 



 ## Getting the Right States  

```r
 # this is used to form a filter argument, 
 #but will also be used to generate the
 #state borders
states <- og_shp %>% 
  filter(STATEFP <= 60, 
         STATEFP > 1,
         STATEFP != 15
  )



states <- states() %>% 
  filter(REGION != "9",   region nine has the territores
         !STATEFP %in% c("02", "15"))  Alaska, and Hawaii, resp.

correct_stat_num <- states$STATEFP
 ```

## Reread and Clean the shp

```r
retry_shp <-  st_read(paste0(root_dir, "tl_2017_us_county.shp"))

retry_shp <- retry_shp %>%
  filter(STATEFP %in% correct_stat_num, 
         !STATEFP %in% c("02", "15")
  ) %>% 
  mutate(state_and_county_FP = str_c(STATEFP, COUNTYFP))
```

## Join the Data 
```r
joinable2 <- retry_shp  %>% 
  # Join the CSV data in with the shapefile geometry, using the new features. 
  inner_join(unemployment_csv, 
             by = c("state_and_county_FP" = "FIPStxt")) %>%
  # create variables to store the median unemployment of each state
  group_by(STATEFP) %>% 
  mutate(state_unemployment_2019 = mean(Unemployment_rate_2019), 
         state_unemployment_2009 = mean(Unemployment_rate_2009)) %>% 
  ungroup() %>% 
  # and get each county's unemployment rate ratio for the years
   2009 and 2019 
  mutate(scaled_unemployment_2019 = 
           Unemployment_rate_2019/state_unemployment_2019, 
         scaled_unemployment_2009 =
           Unemployment_rate_2009/scaled_unemployment_2009
  )
 ```
 ### Explaining the Mutations Above  
 Without the mutation above, the choropleth shows which are the worst counties for unemployment, 
 in relation to the entire country; this has a wide spread which 
 buries a lot of context. Additionally, we want to go with unemployment *rate*, 
 rather than unemployment count to make comparisons possible between counties 
 with large differences in populace.  By normalizing each county's  unemployment within the  
 context of the contemporary unemployment rate within the state it belongs to,
  we get to see if counties are performing poorly in a more equitable context. 
 In other words, a low-severity purple county can actually have a better 
 (lower) unemployment rate than an adjacent high-severity green/yellow county, 
 so long as they occupy different states. The logic behind this normalization 
 is that the  counties belonging the same state share economic opportunities 
 and policy at the state level.  By accounting for this, the visualization 
 accentuates localized/granular  variation in unemployment, 
 while also allowing the viewer to get a snap-shot of distribution 
 of variation in employment rates within each state. Here are some illustrations that highlight the change:
 
![No Scaling](https://github.com/Fehiroh/Scaled_unemployment_county_map/blob/Fehiroh-patch-1/images/original.png) 

*No Scaling* 

![State-Scaled](https://github.com/Fehiroh/Scaled_unemployment_county_map/blob/Fehiroh-patch-1/images/original_scaled.png)
*State-Scaled*

![Scaled and Continuous](https://github.com/Fehiroh/Scaled_unemployment_county_map/blob/Fehiroh-patch-1/images/original_continuous.png)
*Scaled and Continuous*


 # Simplify the Geometry 
     I decided to simplify the geometry by 0.01 decimal degree, this enables quicker rendering by lowering the geospatial precision.
     At this scale, you won't notice the imprecision, but computations will finish 5 times quicker. 
```r
joinable2_simp = st_simplify(joinable2, preserveTopology = TRUE,
                             dTolerance = 0.01)
 ```


# The Original Graph 
```r
map_1 <- tm_shape(joinable2_simp) +
  tm_fill(col = "scaled_unemployment_2019", 
          title = paste("County Unemployment Rate /", 
                        "State Unemployment Rate", 
                        sep = "\n"), 
          palette = viridis(10), 
          colorNA	= "grey85", 
          legend.reverse = TRUE, 
          style = "cont") +
  tm_borders(alpha = 0.5) + 
  tm_shape(states) + 
  tm_borders(lwd = 2.25, col = "black") + 
  tm_text(text = "STUSPS", col = "white", size = 1.1, remove.overlap = TRUE) + 
  tm_layout(main.title = "Severity of Unemployment Rate in America (By County)",
            bg.color = "grey65", fontfamily = "serif")  + 
  tm_legend(scale = 0.9, title.size = 0.9, 
            legend.position = c("right", "bottom"), 
            frame = "black", legend.bg.color = "grey85")

tmap_mode("plot")

map_1
```


# 3D Version 
```r
ggmap1 <- ggplot(data = joinable2_simp) +
  geom_sf(aes(fill = scaled_unemployment_2019)) +
  scale_fill_viridis_c(option = "viridis") 


plot_gg(ggmap1, multicore = TRUE, raytrace = TRUE, width = 7, height = 4, 
        scale = 100, windowsize = c(1400, 866), zoom = 0.4, phi = 30, 
        theta = 30)
```

# The Final Image 
plots of ggmap1, and map1 were exported and reopened in GIMP, where 
 further editing occurred. If similar maps were required in bulk, this would 
 have been automated (probably using magick), but as a one-off that wasn't 
 a sensical course of action. 

