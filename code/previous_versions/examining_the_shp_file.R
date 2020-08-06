
# Libraries #### 

# this installs (if necessary) and loads all requires packages

if (!require("pacman")) install.packages("pacman");
  library(pacman)
p_load(tidyverse, sf, tidycensus, tigris, tmap, spdplyr)





#loading in the Shape file 
root_dir <- "C:/Users/fehi7/Documents/Projects/county_level_chloreopleth/tl_2017_us_county/"
og_shp <- st_read(paste0(root_dir, "tl_2017_us_county.shp")) %>%
  filter(STATEFP != 1, STATEFP != 15)
  




# get joinable feature 
og_shp$state_and_county_FP <- str_c(og_shp$STATEFP, og_shp$COUNTYFP)


# getting the csv 
unemployment_csv <- read_csv(
  paste0("C:/Users/fehi7/Documents/Projects/county_level_chloreopleth/", 
         "original_data_unemployment.csv"))

# joinable <- og_shp %>% 
#   inner_join(unemployment_csv, by = c("state_and_county_FP" =
#                "FIPStxt")) 
# 
# ggplot() + 
#   geom_sf(data = joinable)+
#   ggtitle("joinable")
# 
# ggplot()+ 
#   geom_sf(data = og_shp)
# 
# counties <- counties()
# 
# qtm(counties)


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



# Palettes
library(viridisLite)
vir <- viridis(9)
mag <- magma(9)


# potential idea for viewing 

# library(mapview)
# mapview(joinable2["Unemployed_2019"], col.regions = sf.colors(10))


tm_shape(joinable2) +
  tm_fill(col = "scaled_unemployment_2019", 
          title = paste("Severity of County Unemployment", 
                        "Relative to State Average in 2019",
                        sep = "\n"), 
          palette = viridis()) +
  tm_borders(lwd = 0.5) + 
  tm_shape(states) + 
  tm_borders(lwd = 2.0, col = "white") + 
  tm_text(text = "STUSPS", size = 0.5, col = "white")



