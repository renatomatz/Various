# data
customers <- read_csv("~/Documents/Projects/Various/ECommerce/BR_EC/olist_customers_dataset.csv")
order_items <- read_csv("~/Documents/Projects/Various/ECommerce/BR_EC/olist_order_items_dataset.csv")
payments <- read_csv("~/Documents/Projects/Various/ECommerce/BR_EC/olist_order_payments_dataset.csv")

# complementary
products <- read_csv("~/Documents/Projects/Various/ECommerce/BR_EC/olist_products_dataset.csv")
sellers <- read_csv("~/Documents/Projects/Various/ECommerce/BR_EC/olist_sellers_dataset.csv")

# customer states
customers %>% 
  group_by(customer_city, customer_state) %>% 
  count() %>% 
  arrange(desc(n)) %>% 
  filter(n>500) %>% 
  ggplot(aes(x=reorder(customer_city, -n), y=n, label=n, fill=customer_state)) + 
    geom_bar(stat="identity") +
    geom_text(aes(y=n+100), size=3, position = position_identity()) +
    theme(axis.text.x = element_text(angle=90))
## mostly Sao Paulo, followed by Rio, and BH
## number of customers decrease in a decreasing rate after city count goes below 1000
## smaller cities mostly SP

# average number of items bought
mean(order_items$order_item_id)
## not very informative

# number of people who ordered various numbers of items
order_items %>%
  group_by(order_item_id) %>%
  count() %>% 
## huge difference between buying quantities, most items are bought one at a time

# most popular products
order_items %>%
  group_by(product_id) %>%
  count() %>%
  arrange(desc(n)) %>%
  inner_join(products, by = "product_id") %>%
  select(c(product_id, product_category_name, n)) %>% 
  head(20) %>%
  ggplot(aes(x=reorder(product_id, -n), y=n, fill=product_category_name, label=n)) +
    geom_bar(stat = "identity") +
    geom_text(aes(y=n+10), size=3) +
    theme(axis.text.x = element_blank())
  
# top products seem to have en even enough product category quantity and close enough difference between top sellers
# gardening tools do seem to be popular enough items, which possibly are sold together

# top product categories by order numbers
order_items %>%
  inner_join(products, by = "product_id") %>%
  group_by(product_category_name) %>%
  count() %>%
  arrange(desc(n)) %>%
  head(20) %>%
  ggplot(aes(x=reorder(product_category_name, -n), y=n, label=n)) +
    geom_bar(stat = "identity") +
    geom_text(aes(y=n+200), size=3) +
    theme(axis.text.x = element_text(angle=90))
## bed and table wares are clear the clear winning category but not by a significant margin
## no significant margin between these top categories

# top preduct categories by revenue
order_items %>%
  inner_join(products, by = "product_id") %>%
  group_by(product_category_name) %>%
  summarise(revenue=round(sum(price)/1000)) %>% # PAY ATTENTION, NUMBERS IN THOUSANDS
  arrange(desc(revenue)) %>%
  head(20) %>%
  ggplot(aes(x=reorder(product_category_name, -revenue), y=revenue, label=revenue)) +
    geom_bar(stat = "identity") +
    geom_text(aes(y=revenue+100), size=3) +
    theme(axis.text.x = element_text(angle=90))
## fairly similar results to order numbers, though lets just see by how much

normalize <- function(x) {
  (x-mean(x)) / sd(x)
}

order_items %>%
  inner_join(products, by = "product_id") %>%
  group_by(product_category_name) %>%
  summarise(n=n(), revenue=sum(price)) %>% 
  transmute(product_category_name=product_category_name, revenue=normalize(revenue), n = normalize(n)) %>%
  arrange(desc(n)) %>%
  head(10) %>%
  ggplot(aes(fill=product_category_name)) +
    geom_bar(aes(x=product_category_name, y=n), alpha=0.4, col="black", stat = "identity") +
    geom_bar(aes(x=product_category_name, y=revenue), alpha=0.4, stat = "identity") +
    theme(axis.text.x = element_blank())
## I'll interpret this graph as the relative difference between a product's sales vs its revenues generated
### this can mean many things, though at first glance, it shows which products can bring the most revenue from fewer buys

# create orders time series
start=as.Date("2017-02-01")
end=as.Date("2018-09-01")

order_items %>%
  mutate(Date=as.Date(shipping_limit_date, format="%Y-%m-%d")) %>%
  group_by(Date) %>%
  summarise(revenue=sum(price)) %>%
  as.data.frame() -> sales_ts

rownames(sales_ts) <- sales_ts$Date

sales_ts %>%
  select(-Date) %>%
  as.xts() %>% 
  window(start = start, end = end) -> sales_ts