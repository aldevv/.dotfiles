#!/usr/bin/python3
import pandas as pd
import csv
import numpy as np
from shutil import copyfile

raw_images = pd.read_csv(filepath_or_buffer="all/Annotations-export.csv")

raw_caretas = pd.read_csv(filepath_or_buffer="all/Images-export.csv")

filtered_data = raw_images[
    (raw_images["label"] != "Vest") & (raw_images["label"] != "Glasses")
]
helmets = filtered_data[filtered_data["label"] == "Helmet"]
gloves = filtered_data[filtered_data["label"] == "Gloves"]
helmets = helmets.head(708)
gloves = gloves.head(700)
raw_caretas.columns = helmets.columns
processed_images = pd.concat([helmets, gloves, raw_caretas], axis=0)
processed_images = processed_images.sample(frac=1, random_state=42)

from sklearn.model_selection import train_test_split

train, test = train_test_split(processed_images, test_size=0.2)

# remove duplicates in train
train = (
    pd.merge(train, test, indicator=True, how="outer")
    .query('_merge=="left_only"')
    .drop("_merge", axis=1)
)

test.to_csv(
    "filtered/test.csv",
    index=False,
    header=True,
    quoting=csv.QUOTE_NONNUMERIC,
)

train.to_csv(
    "filtered/train.csv",
    index=False,
    header=True,
    quoting=csv.QUOTE_NONNUMERIC,
)
toCopy = test["image"].unique()
for row in toCopy:
    copyfile("all/" + row, "filtered/test/" + row)

toCopy = train["image"].unique()
for row in toCopy:
    copyfile("all/" + row, "filtered/train/" + row)
