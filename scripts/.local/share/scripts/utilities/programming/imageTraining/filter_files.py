import pandas as pd
import csv
import numpy as np
from shutil import copyfile, move

raw_images = pd.read_csv(filepath_or_buffer="all/Annotations-export.csv")

raw_caretas = pd.read_csv(filepath_or_buffer="all/Images-export.csv")

# (raw_images["label"] != "Vest") & (raw_images["label"] != "Glasses")
filtered_data = raw_images[raw_images["label"] != "Vest"]

helmets = filtered_data[filtered_data["label"] == "Helmet"].head(708)
gloves = filtered_data[filtered_data["label"] == "Gloves"].head(700)
# solo hay 200 imagenes de gafas por ahora
glasses = filtered_data[filtered_data["label"] == "Glasses"].head(700)
raw_caretas.columns = helmets.columns

processed_images = pd.concat([helmets, gloves, raw_caretas, glasses], axis=0)
processed_images = processed_images.sample(frac=1, random_state=42)
processed_images.rename(columns={"image": "filename", "label": "class"}, inplace=True)

from sklearn.model_selection import train_test_split

train, test = train_test_split(processed_images, test_size=0.2)

# print(f"{train}")
# print(f"{test}")

# remove duplicates in train
EXCLUDE = test["filename"]
train = train[train["filename"].isin(EXCLUDE) == False]

import os

if os.path.exists("filtered"):
    if not os.path.exists("backups"):
        os.mkdir("backups")
    move("filtered", "backups")
    os.rmdir("filtered")

os.mkdir("filtered")
os.mkdir("filtered/train")
os.mkdir("filtered/test")

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
toCopy = test["filename"].unique()
for row in toCopy:
    copyfile("all/" + row, "filtered/test/" + row)

toCopy = train["filename"].unique()
for row in toCopy:
    copyfile("all/" + row, "filtered/train/" + row)
