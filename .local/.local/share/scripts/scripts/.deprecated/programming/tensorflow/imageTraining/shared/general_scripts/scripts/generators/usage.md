
# generate label map file

- python generate_pbtxt.py csv images/test.csv annotations/label_map.pbtxt

You may need to edit this code:
```
def pbtxt_from_csv(csv_path, pbtxt_path):
    class_list = list(pd.read_csv(csv_path)['class'].unique())
    class_list.sort()
```
changing 'class' for whatever the class label column is named

# generate record file

- python generate_tfrecord.py images/train.csv annotations/label_map.pbtxt images/train annotations/train.record

- python generate_tfrecord.py images/test.csv annotations/label_map.pbtxt images/test annotations/test.record

