import pandas as pd
import numpy as np
import tensorflow as tf

from tensorflow.keras.models import Sequential 
from tensorflow.keras.layers import Dense, Flatten

from preprocessor import features_pipeline

from sklearn.model_selection import train_test_split
from sklearn.preprocessing import OneHotEncoder

data = pd.read_csv(
    "~/Documents/Projects/Various/ECommerce/Data/features_ready.csv"
).drop("order_id", axis=1)

X_train, X_test, y_train, y_test = train_test_split(
    np.array(data.drop("review_score", axis=1)),
    np.array(data["review_score"]).reshape(-1, 1),
    test_size = 0.2,
    random_state = 42
)

one_hot = OneHotEncoder()

y_train = one_hot.fit_transform(y_train) 
y_test = one_hot.fit_transform(y_test) 

train_p = 0.9

lX = X_train.shape[0]
n_train = round(lX * train_p)
X_train, X_valid = X_train[:n_train], X_train[n_train:]

ly = y_train.shape[0]
n_train = round(ly * train_p)
y_train, y_valid = y_train[:n_train], y_train[n_train:]

# Model 0

## Build 
model_0 = Sequential()
model_0.add(Dense(300, input_shape=[data.shape[1]-1], activation="relu"))
model_0.add(Dense(100, activation="relu"))
model_0.add(Dense(5, activation="softmax"))

## Compile/Fit
model_0.compile(
    loss="categorical_crossentropy",
    optimizer="adam",
    metrics=["accuracy"]
)

model_0.fit(
    X_train, y_train, 
    epochs=30,
    validation_data=(X_valid, y_valid)
)

print("DONE")