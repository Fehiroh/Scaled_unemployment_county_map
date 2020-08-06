
# Libraries #### 

# this installs (if necessary) and loads all requires packages

if (!require("pacman")) install.packages("pacman");
library(pacman)
p_load(tidyverse, sf, tidycensus, tigris, tmap, spdplyr, 
       viridisLite, leaflet, rayshader, magick, cowplot, 
       lintr)




#loading in the Shape file 
root_dir <- paste0("C:/Users/fehi7/Documents/Projects/",
                    "county_level_chloreopleth/tl_2017_us_county/")
og_shp <- st_read(paste0(root_dir, "tl_2017_us_county.shp")) %>%
  filter(STATEFP != 1, STATEFP != 15)





# getting the csv 
unemployment_csv <- read_csv(
  paste0("C:/Users/fehi7/Documents/Projects/county_level_chloreopleth/", 
         "original_data_unemployment.csv")
  )




# st_num <- as.data.frame(og_shp$STATEFP)
# colnames(st_num)  <- "STATEFP"
# 
# st_num <- st_num %>%
#   group_by(STATEFP) %>%
#   summarize(count = n()) %>% 
#   arrange(count)
# 
# 
# states_with_few_counties <- head(st_num$STATEFP)
# 
# 
# fewer_counties <- og_shp %>% 
#   filter(!STATEFP %in% states_with_few_counties)
# 
# ggplot()+ 
#   ggtitle("fewer counties") + 
#   geom_sf(data = fewer_counties)


# Narrowing the Spatial Scope

# Getting Rid of the States and territories that aren't part of the contiguous 
# Continental United States of America



states <- og_shp %>% 
  filter(STATEFP <= 60, 
         STATEFP > 1,
         STATEFP != 15
  )


states <- states() %>% 
  filter(REGION != "9",  # region nine has the territores
         !STATEFP %in% c("02", "15")) # Alaska, and Hawaii, resp.

correct_stat_num <- states$STATEFP

retry_shp <-  st_read(paste0(root_dir, "tl_2017_us_county.shp"))

retry_shp <- retry_shp %>%
  filter(STATEFP %in% correct_stat_num, 
         !STATEFP %in% c("02", "15")
         ) %>% 
  mutate(state_and_county_FP = str_c(STATEFP, COUNTYFP))


                     # Preparing the Data #####

# Get joinable feature between csv and shp. 
  #  Because this data is not from the exact same source, whether they 
  #  natively share a primary key is up to RNGesus. The importance of 
  #  this is that (without a shared primary key) the information from the csv  
  # has no way to be associated with the  shapefile's  geometries, and cannot be visualized  geospatially. 
  #  I did some quick investigation of the features in both files, and 
  # discovered that there was no shared key. Fortunately, by perusing 
  # through the data dictionies provided for each file, I was able to 
  # deduce that the  the STATEFP and CountyFP columns in the shp file c
#   could be  associated with the shp file form a primary 
  #

og_shp$state_and_county_FP <- str_c(
  og_shp$STATEFP, og_shp$COUNTYFP
)





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
  # 2009 and 2019 
  mutate(scaled_unemployment_2019 = 
           Unemployment_rate_2019/state_unemployment_2019, 
         scaled_unemployment_2009 =
           Unemployment_rate_2009/scaled_unemployment_2009
  )

# Map currently shows which are the worst counties for unemployment, 
# in relation to the entire country; this has a wide spread which 
# buries a lot of context. Additionally, we want to go with unemployment RATE, 
# rather than unemployment count to make comparisons possible between counties 
# with wide variations in populace.  By normalizing each county's  unemployment within the  
# context of contemporary unemployment rate state it belongs to,
#  we get to see if counties are performing poorly relative to it's state. 
# In other words, a low-severity purple county can actually have a better 
# (lower) unemployment rate than an adjacent high-severity green/yellow county, 
# so long as they occupy different states. The logic behind this normalization 
# is that the  counties belonging the same state share economic opportunities 
# and policy at the state level.  By accounting for this, the visualization 
# accentuates localized/granular  variation in unemployment, 
# while also allowing the viewer to get a snap-shot of distribution 
# of variation in employment rates within each state. 
# 

joinable2 <- retry_shp  %>% 
  inner_join(unemployment_csv, 
             by = c("state_and_county_FP" = "FIPStxt")) %>%
  group_by(STATEFP) %>% 
  mutate(state_unemployment_2019 = mean(Unemployment_rate_2019), 
         state_unemployment_2009 = mean(Unemployment_rate_2009)) %>% 
  ungroup() %>% 
  mutate(scaled_unemployment_2019 = 
           Unemployment_rate_2019/state_unemployment_2019, 
         scaled_unemployment_2009 =
           Unemployment_rate_2009/scaled_unemployment_2009
         )



# Simplify the geometry by 0.01 decimal degrees. 
#     This enables quicker rendering by lowering the geospatial precision.
#     At this scale, you won't notice the imprecision, but computations 
#     will finish 5 times quicker. 

joinable2_simp = st_simplify(joinable2, preserveTopology = TRUE,
                             dTolerance = 0.01)




# Palettes



# potential idea for viewing 

# library(mapview)
# mapview(joinable2["Unemployed_2019"], col.regions = sf.colors(10))


map_1 <- tm_shape(joinable2_simp) +
  tm_fill(col = "scaled_unemployment_2019", 
          title = paste("County Unemployment Rate /", 
                        "State Unemployment Rate", 
                        sep = "\n"), 
          palette = viridis(10), 
          colorNA	= "grey85", 
          legend.reverse = TRUE, 
          # midpoint = 1.0, 
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



# 3D version 

ggmap1 <- ggplot(data = joinable2_simp) +
  geom_sf(aes(fill = scaled_unemployment_2019)) +
  scale_fill_viridis_c(option = "viridis") 


plot_gg(ggmap1, multicore = TRUE, raytrace = TRUE, width = 7, height = 4, 
        scale = 100, windowsize = c(1400, 866), zoom = 0.4, phi = 30, 
        theta = 30)


ggmap1
