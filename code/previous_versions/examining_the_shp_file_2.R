
# Libraries #### 

# this installs (if necessary) and loads all requires packages



if (!require("pacman")) install.packages("pacman");
library(pacman)
p_load(tidyverse, sf, tidycensus, tigris, tmap, spdplyr, 
       viridisLite, leaflet, rayshader, magick)





#loading in the Shape file 
root_dir <- paste0("C:/Users/fehi7/Documents/Projects/",
                    "county_level_chloreopleth/tl_2017_us_county/")
og_shp <- st_read(paste0(root_dir, "tl_2017_us_county.shp")) %>%
  filter(STATEFP != 1, STATEFP != 15)





# get joinable feature 
og_shp$state_and_county_FP <- str_c(og_shp$STATEFP, og_shp$COUNTYFP)


# getting the csv 
unemployment_csv <- read_csv(
  paste0("C:/Users/fehi7/Documents/Projects/county_level_chloreopleth/", 
         "original_data_unemployment.csv"))




st_num <- as.data.frame(og_shp$STATEFP)
colnames(st_num)  <- "STATEFP"

st_num <- st_num %>%
  group_by(STATEFP) %>%
  summarize(count = n()) %>% 
  arrange(count)


states_with_few_counties <- head(st_num$STATEFP)


fewer_counties <- og_shp %>% 
  filter(!STATEFP %in% states_with_few_counties)

ggplot()+ 
  ggtitle("fewer counties") + 
  geom_sf(data = fewer_counties)

# investigated state codes present in csv.

states <- og_shp %>% 
  filter(STATEFP <= 60, 
         STATEFP > 1,
         STATEFP != 15
  )


states <- states() %>% 
  filter(REGION != "9", 
         !STATEFP %in% c("02", "15"))

correct_stat_num <- states$STATEFP

retry_shp <-  st_read(paste0(root_dir, "tl_2017_us_county.shp"))

retry_shp <- retry_shp %>%
  filter(STATEFP %in% correct_stat_num, 
         !STATEFP %in% c("02", "15")
  ) %>% 
  mutate(state_and_county_FP = str_c(STATEFP, COUNTYFP))



# Join the CSV data in with the shapefile geometry 
joinable2 <- retry_shp  %>% 
  inner_join(unemployment_csv, by = c("state_and_county_FP" =
                                        "FIPStxt")) %>%
  group_by(STATEFP) %>% 
  mutate(state_unemployment_2019 = mean(Unemployment_rate_2019)) %>% 
  ungroup() %>% 
  mutate(scaled_unemployment_2019 = Unemployment_rate_2019/state_unemployment_2019)


joinable2_trans = st_transform(joinable2, 54032)

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
          # style = "cont") 
             )+
  tm_borders(alpha = 0.5) + 
  tm_shape(states) + 
  tm_borders(lwd = 2.25, col = "black") + 
  tm_text(text = "STUSPS", col = "white", size = 1.1, remove.overlap = TRUE) + 
  tm_layout(main.title = "Severity of Unemployment Rate in America (By County) in 2019", 
            bg.color = "grey65", fontfamily = "serif")  + 
  tm_legend(scale = 0.9, title.size = 0.9, 
            legend.position = c("right", "bottom"), 
            frame = "black", legend.bg.color = "grey85")

tmap_mode("plot")

map_1

ggplot(joinable2, aes(scaled_unemployment_2019)) + 
  geom_density()
 

map_2 <- tm_shape(joinable2_simp) +
  tm_fill(col = "Unemployment_rate_2019", 
          title = paste("County Unemployment Rate /", 
                        "State Unemployment Rate", 
                        sep = "\n"), 
          palette = viridis(10), 
          colorNA	= "grey85", 
          legend.reverse = TRUE) +
  tm_borders(lwd = 0.01) + 
  tm_shape(states) + 
  tm_borders(lwd = 2.25, col = "black") + 
  tm_text(text = "STUSPS", col = "white", size = 1.1, remove.overlap = TRUE) + 
  tm_layout(main.title = "Severity of Unemployment Rate in America (By County) in 2019", 
            bg.color = "grey65", fontfamily = "serif")  + 
  tm_legend(scale = 0.9, title.size = 0.9, 
            legend.position = c("right", "bottom"), 
            frame = "black", legend.bg.color = "grey85")

map_2



tmap_mode("view")



intr_map_1 <- tm_shape(joinable2_simp) +
  tm_fill(col = "scaled_unemployment_2019", 
          title = "Severity of Unemployment Rate for 2019",
          title.size = 0.8,
          palette = viridis(10), 
          colorNA	= "grey85", 
          legend.reverse = TRUE) +
  tm_borders(lwd = 0.2) + 
  tm_shape(states) + 
  tm_borders(lwd = 2.25, col = "black") + 
  tm_text(text = "STUSPS", col = "white",
          remove.overlap = TRUE) + 
  tm_layout(main.title = "Severity of Unemployment Rate in America (By County) in 2019", 
            bg.color = "grey65", fontfamily = "serif")  + 
  tm_legend(scale = 0.9, title.size = 0.9, 
            legend.position = c("right", "bottom"), 
            frame = "black", legend.bg.color = "grey85") 


intr_map_1

# 
# 2s2intr_map_1_w_labs <- intr_map_1 %>% 
#   addPopups()
#   


# 3D version 

ggmap1 <- ggplot(data = joinable2_simp) +
  geom_sf(aes(fill = scaled_unemployment_2019)) +
  scale_fill_viridis_c(option = "viridis") 


plot_gg(ggmap1, multicore = TRUE, raytrace = TRUE, width = 7, height = 4, 
        scale = 100, windowsize = c(1400, 866), zoom = 0.4, phi = 30, theta = 30, 
        invert = TRUE)


ggmap1
