import pandas as pd
import numpy as np

import sys

sys.path.insert(1, "/home/renato/Documents/Projects/pdpipe")

import pdpipe as pdp

# Date column processing
add_date_features = (
    pdp.ApplyByCols(
        ["order_purchase_timestamp", "review_creation_date"],
        pd.Timestamp,
        drop=True
    ) + \
    pdp.ApplyByCols("order_purchase_timestamp", 
                    lambda x: x.weekday,
                    result_columns="weekday",
                    drop=False
    ) + 
    pdp.ApplyByCols("order_purchase_timestamp",
                    lambda x: x.hour,
                    result_columns="hour",
                    drop=False
    ) + 
    pdp.ColByFrameFunc(
        pdp.time_diff(
            cols=(
                "review_creation_date",
                "order_purchase_timestamp"
            ),
            units="D"
        ),
        result_columns="purch_to_rev"
    ) +  \
    pdp.ColDrop([
        "order_purchase_timestamp", 
        "review_creation_date"
    ])
)

date_transformer = add_date_features

# Numerical columns processing
numeric_transformer = ( 
    pdp.ColDrop(["order_sequential", "payment_installments"]) + 
    pdp.DropNa(columns="price") + 
    pdp.Impute(columns=["freight_value", "payment_value"], imputer=0) +
    pdp.Scale(
        scaler="StandardScaler", 
        exclude_columns=["review_score", "weekday", "hour"]
    )
)
# if no price, assume 0 paid
# price too important to be imputed, better to drop row if is na

# Categorical columns processing
categorical_transformer = (
    pdp.ApplyByCols(
        "customer_city",
        (lambda x: x.replace(" ", "_")),
        drop=True
    ) +
    pdp.CatReduce(
        columns="seller_id",
        strategy="quantile",
        n=0.9,
        other_label="other_seller"
    ) +
    pdp.CatReduce(
        columns="customer_city",
        strategy="top",
        n=20,
        other_label="other_city"
    ) +
    pdp.OneHotEncode(
        columns=[
            "seller_id",
            "product_category_name", 
            "customer_city",
            "weekday",
            "hour"
                ]
    ) +
    pdp.PivotCols(
        values="payment_value", 
        index="order_id",
        columns="payment_type", 
        fill_value=0
    ) + 
    pdp.GroupApply(
        group_by="order_id",
        func=np.mean,
        columns= (
            lambda x: 
                x not in  [
                    "order_purchase_timestamp", 
                    "review_creation_date"
                          ]
        ),
        drop=True
    ) +
    pdp.ValDrop(
        lambda x: True if (x % 1) != 0 else False,
        columns="review_score"
    )
)

# Extra cleaning 
drop_columns = (
    pdp.ColDrop([
        "freight_value"
    ])
)

cleaning_transformer = drop_columns

# Create features pipeline
features_pipeline = (
    date_transformer +
    numeric_transformer +
    categorical_transformer +
    cleaning_transformer +
    pdp.ConditionCheck(
        lambda df: df.shape[0]==len(df["order_id"].unique())
    )
)

if __name__ == "__main__":

    import os

    os.chdir("..")

    features_0 = pd.read_csv("Data/features.csv").head(100)

    # df = features_0

    # features_1 = numeric_transformer(features_0)

    # features_2 = categorical_transformer(features_1)

    # features_3 = date_transformer(features_2)

    # features_4 = cleaning_transformer(features_3)

    df = features_pipeline(features_0, verbose=True)

    # df.to_csv("Data/features_ready.csv")

    print(df.head())