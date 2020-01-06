import pandas as pd

import sys

sys.path.insert(1, "/home/renato/Documents/Projects/scikit_learn_pandas_tools")

from pandas_column_transformer import PandasColumnTransformer
from transformers import DropNA, Mutate, PivotCols 
from mutations import to_weekday, to_time_of_day, time_diff

from sklearn.pipeline import Pipeline
from sklearn.impute import SimpleImputer
from sklearn.compose import ColumnTransformer
from sklearn.preprocessing import OneHotEncoder

# Numerical columns processing

impute_cols = PandasColumnTransformer(transformers=[
    ("imp_seq_to_one", SimpleImputer(strategy="constant", fill_value=1), ["order_sequential"]), # assume one order if no known sequence
    ("imp_to_zero", SimpleImputer(strategy="constant", fill_value=0), ["freight_value", "payment_value"]) # if no price, assume 0 paid
])

numeric_transformer = PandasColumnTransformer(transformers=[
    ("drop_na_prices", DropNA(["price"]), None), # too important to be imputed, better to drop row if is na
    ("impute_cols", impute_cols, None)
])

# Categorical columns processing
one_hot = PandasColumnTransformer(transformers=[
    ("seller_id", OneHotEncoder(), ["seller_id"]), 
    ("product_category_name", OneHotEncoder(), ["product_category_name"]), 
    ("customer_city", OneHotEncoder(), ["customer_city"])
])

categorical_transformer = PandasColumnTransformer(transformers=[
    ("one_hot_encoding", one_hot, None),
    ("pivot_payments", PivotCols(["payment_type"], ["payment_value"], impute_with=0), None)
])

# Date column processing
add_date_features = PandasColumnTransformer(transformers=[
    ("add_weekdays", Mutate(to_weekday, new_colname="weekday", one_hot=True), ["order_purchase_timestamp"]),
    ("add_hour", Mutate(to_time_of_day, new_colname="hour", one_hot=True), ["order_purchase_timestamp"]),
    ("diff_purch_rev", Mutate(time_diff(units="D"), new_colname="purch_to_rev", one_hot=False), ["order_purchase_timestamp", "review_creation_date"]) 
    # difference in days between puchase date and date of review
])

date_transformer = PandasColumnTransformer(transformers=[
    ("add_features", add_date_features, None)
])

# Extra cleaning 
drop_columns = PandasColumnTransformer(transformers=[
    ("drop_cid", "drop", ["customer_id"]), # in this dataset, there is one customer per order, onehot this category will waste space
    ("drop_unnecessary", "drop", ["shipping_limit_date", "freight_value", "order_purchase_timestamp", "review_creation_date"]) # unnecessary columns for analysis
])

cleaning_transformer = PandasColumnTransformer(transformers=[
    ("drop_columns", drop_columns, None)
])

# Create features pipeline
features_pipeline = PandasColumnTransformer(transformers=[
    ("numerical", numeric_transformer, None),
    ("categocies", categorical_transformer, None),
    ("dates", date_transformer, None),
    ("clean", cleaning_transformer, None)
])

if __name__ == "__main__":

    import os

    os.chdir("..")

    df = features_0 = pd.read_csv("Data/features.csv").head(100)

    features_1 = numeric_transformer.fit_transform(features_0)

    features_2 = categorical_transformer.fit_transform(features_1)

    features_3 = date_transformer.fit_transform(features_2)

    features_4 = cleaning_transformer.fit_transform(features_3)

    features_new = features_pipeline.fit_transform(features_0)

    print(features_new.head())
