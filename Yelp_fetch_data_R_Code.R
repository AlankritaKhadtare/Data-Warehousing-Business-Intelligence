#Sentiment
#require(RSentiment)
install.packages('futile.logger', repos='http://cran.us.r-project.org')

#DOM and HTTP Request Processing
require(rvest)
require(httr)
require(httpuv)
require(XML)
require(jsonlite)

#String Manipulation
require(stringr)

#Database
library(RODBC)
#library(RSQLServer)

#Logger
require(futile.logger)

#Other
library(magrittr)

#Variables
api_base_url <- 'https://api.yelp.com/'
access_token <- NULL
restaurant_id <- NULL
restaurant_list <- c()

#Login Credentials
credentials <- list(
  'grant_type' = 'client_credentials',
  'client_id' = '2feX-HoiFo0XAKemgKxlTw',
  'client_secret' = 'shADXwgL8hMQkqYFr5udQFXfnwcYZuGXwIdpap0pdEdHXd7BLNQeofBRYmstnYtxZRZDllJKuRWHpDA-prjpCEXUByFPhY-GHfz9tqywGrCCk9P9mri2adnK3bvrW3Yx'
)

#get Access token
print('Getting access token')
access_token <- content(POST(paste(api_base_url, "oauth2/token", sep = ""), body = credentials))$access_token

#get Access token
csv_restaurant_list <-  read.csv('C:\\Users\\Alankrita\\Documents\\Data Warehouse\\Stock_2005-2017.csv', stringsAsFactors = FALSE)
recordCount <- length(csv_restaurant_list$Company)

#for each restaurant in the list get the Latitude and Longitude using API call
for (i in 1:recordCount) {
  flog.info(paste("Getting Latitude and Longitude for restaurant ",'\n'))
  #Framing request URL
  Search_url <- modify_url(
    api_base_url,
    path = c("v3", "businesses", "search"),
    query = list(
      term = as.character('starbucks'),
      location =as.character( csv_store_list$ï..location[i]),
      radius = "100",
      limit = 1
    )
  )
 
   #Send Request and Get the search result
  restaurant_detail <- GET(Search_url, add_headers('Authorization' = paste("bearer", access_token)))
  restaurant_Name <- as.character(csv_restaurant_list$Company[i])
  tryCatch({
    reviews <- content(restaurant_detail)$businesses[[1]]$reviews  #get Review Count
  }, error = function(e) {
    flog.error('Error occured while searching for values')
    review_Count <- 'NULL'
  })
  #Consolidate all the Column  into one consolidated list
  restaurant_list <- rbind(restaurant_list, restaurant)
  flog.info(paste('Processed', i, '....\n'))
}
#Assign column names to the list
colnames(restaurant_list) <-  c("Name", "id", "Latitude", "Longitude", "Review")
flog.info('Done with retriving Restaurant parameters')
#write.csv(restaurant_list, paste(EnvProp["output_file_location", 1], "Restaurant_Location_Details.csv", sep = ""))
flog.info('Stored data in csv file')

}


write.csv(restaurant_list, file="restaurant.csv")

restaurant_list <- read.csv("restaurant.csv")
restaurant_list$review = gsub('https://','',restaurant_list$review)
restaurant_list$review = gsub('http://','',restaurant_list$review)
restaurant_list$review=gsub('[^[:graph:]]', ' ',restaurant_list$review) 
restaurant_list$review = gsub('[[:punct:]]', '', restaurant_list$review)
restaurant_list$review = gsub('[[:cntrl:]]', '', restaurant_list$review)
restaurant_list$review = gsub('\\d+', '', restaurant_list$review)
restaurant_list$review=str_replace_all(restaurant_list$review,"[^[:graph:]]", " ") 

restaurant_list$review<- calculate_score(restaurant_list$review,1)
write.csv(restaurant_list, file="sentiment.csv")
