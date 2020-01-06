# PACKAGES USED
get_packages <- function() {
  
  packages <- c("dplyr", "purrr", "tidyr", "ggplot2", "caret", "xts", "readr")
  
  lapply(packages, require, character.only=TRUE)
  
}

# data
customers <- read_csv("~/Documents/Projects/Various/ECommerce/BR_EC/olist_customers_dataset.csv")
orders <- read_csv("~/Documents/Projects/Various/ECommerce/BR_EC/olist_orders_dataset.csv")
order_items <- read_csv("~/Documents/Projects/Various/ECommerce/BR_EC/olist_order_items_dataset.csv")
payments <- read_csv("~/Documents/Projects/Various/ECommerce/BR_EC/olist_order_payments_dataset.csv")
reviews <- read_csv("~/Documents/Projects/Various/ECommerce/BR_EC/olist_order_reviews_dataset.csv")

# complementary
products <- read_csv("~/Documents/Projects/Various/ECommerce/BR_EC/olist_products_dataset.csv")
sellers <- read_csv("~/Documents/Projects/Various/ECommerce/BR_EC/olist_sellers_dataset.csv")

# DROP COLUMNS
orders <- orders %>% select(-c(order_status, order_approved_at:order_estimated_delivery_date))
customers <- customers %>% select(-c(customer_unique_id, customer_zip_code_prefix, customer_state))
order_items <- order_items %>% select(-c(shipping_limmit_date, freight_value))
# order_payments as it is
products <- products %>% select(c(product_id, product_category_name))
reviews <- reviews %>% select(c(order_id, review_score, review_comment_title, review_comment_message, review_creation_date))

# MERGE DATA
df <- orders

## Merge order data
order_new <- order_items

### merge payments and reviews
order_new <- order_new %>% inner_join(payments, by="order_id") %>% inner_join(reviews, by="order_id")

### merge product category
order_new <- order_new %>% left_join(products, by="product_id")

### clean
order_new <- order_new %>% select(-c(product_id, payment_sequential)) %>% rename(order_sequential=order_item_id)

## merge all
df <- df %>% left_join(order_new, by="order_id") %>% left_join(customers, by="customer_id")
remove(order_new)
# MAKE DUMMY VARIABLES

## make factors
factors <- c("customer_id", "seller_id", "payment_type", "product_category_name", "customer_city", "review_score")

df <- as.data.frame(df)
for (i in seq_along(factors)) {
  print(paste("Factorizing: ", factors[i]))
  df[, factors[i]] <- as.factor(df[, factors[i]])
}
df <- as_tibble(df)

remove(factors)

