# PACKAGES USED
get_packages <- function() {
  
  packages <- c("dplyr", "purrr", "tidyr", "ggplot2", "caret")
  
  lapply(packages, require, character.only=TRUE)
  
}

# GET DATASETS
# orders
# customers
# order_items 
# order_payments
# products

# DROP COLUMNS
orders <- orders %>% select(-c(order_status, order_approved_at:order_estimated_delivery_date))
customers <- customers %>% select(-c(customer_unique_id, customer_zip_code_prefix, customer_state))
order_items <- order_items %>% select(-c(shipping_limmit_date, freight_value))
# order_payments as it is
products <- products %>% select(c(product_id, product_category_name))

# MERGE DATA
df <- orders

## Merge order data
order_new <- order_items

### merge payments
order_new <- order_new %>% inner_join(order_payments, by="order_id")

### merge product category
order_new <- order_new %>% left_join(products, by="product_id")

### clean
order_new <- order_new %>% select(-c(product_id, payment_sequential)) %>% rename(order_sequential=order_item_id)

## merge all
df <- df %>% left_join(order_new, by="order_id") %>% left_join(customers, by="customer_id")
remove(order_new)
# MAKE DUMMY VARIABLES

## make factors
factors <- c("customer_id", "seller_id", "payment_type", "product_category_name", "customer_city")

# filter data for testing #
df <- df %>%
      
###############

df <- as.data.frame(df)
for (i in seq_along(factors)) {
  print(paste("Factorizing: ", factors[i]))
  df[, factors[i]] <- as.factor(df[, factors[i]])
}
df <- as_tibble(df)

remove(factors)
## create dummy variables
dmy <- dummyVars(" ~ .", data=df)
df <- data.frame(predict(dmy, newdata = df))