(Concerning to original README.md, please refer to README_ORIG.md.)
# Training Fast R-CNN on [Right Whale Recognition Dataset](https://www.kaggle.com/c/noaa-right-whale-recognition) 
Before starting to train your Fast-RCNN on another dataset with this tutorial, please note:
- In order to avoid unknown errors which are unrelated to below steps, ensure you've followed the original steps to reproduce the result of demo successfully. 
- For trouble-shooting, see the bottom of this file.

## Preparing Dataset
You may want to compare with similar steps listed on [Train Fast-RCNN on Another Dataset](https://github.com/zeyuanxy/fast-rcnn/tree/master/help/train) and [How to train fast rcnn on imagenet](http://sunshineatnoon.github.io/Train-fast-rcnn-model-on-imagenet-without-matlab/). Below is my dataset directory:
```
kaggle
|-- data
    |-- train.mat
    |-- Annotations
         |-- *.xml (Annotation files)
    |-- Images
         |-- *.JPEG (Image files)
    |-- ImageSets
         |-- train.txt
```
- train.mat: This is the selective search proposals file, which generated by `selective_search.m` in `$FRCNN_ROOT/selective_search`
- Annotations: This folder contains all annotation files of the images. In my implementation, it is in XML format. For each annotation file (each picture), there's only one class and also one object (right whale's face) I need to describe. Below is the example:
```
<? w_819.xml ?>
<annotation>
  <folder>kaggle</folder>
    <filename>
      <item>w_819.jpg</item>
    </filename>
    <object>
      <name>whale</name>
      <bndbox>
        <xmin>1277</xmin>
        <ymin>568</ymin>
        <xmax>1554</xmax>
        <ymax>961</ymax>
      </bndbox>
    </object>
</annotation>
```
If you use MATLAB to label the training image like me, or your dataset is in `.mat` format, for the conversion from `.mat` file to `.xml` file, see my [convert_mat_to_xml.m](https://github.com/coldmanck/fast-rcnn/blob/master/convert_mat_to_xml/convert_mat_to_xml.m) for more details.
- Images: This folder contains all your training images
- ImageSets: This folder originally only contains one file--trian.txt, which contains all the names of the images. It looks like this:
```
w_8762
w_3935
w_1087
...
```
while I add another file--test.txt having the same format as train.txt to store the file names of the test data.

## Construct IMDB File
There're a couple of files you have to modify.

### kaggle.py
We have to create a file `kaggle.py` in the directory `$FRCNN_ROOT/lib/datasets`, where `$FRCNN_ROOT` is your path to fast-rcnn directory, e.g. `/home/coldmanck/fast-rcnn`. This file defines some functions which tell fast rcnn how to read ground truth boxes and how to find images on disk. Following the example file [inria.py](https://github.com/EdisonResearch/fast-rcnn/blob/master/lib/datasets/inria.py) created by [zeyuanxy's instruction](https://github.com/zeyuanxy/fast-rcnn/tree/master/help/train) , I mainly modified some functions below. You may want to read below along with my [kaggle.py](https://github.com/coldmanck/fast-rcnn/blob/master/lib/datasets/kaggle.py).

**In function `__init__(self, image_set, devkit_path)`**

Modify the classes name and picture format to fit the dataset.
```
self._classes = ('__background__', 'whale')
self._image_ext = '.jpg'
```

**In function `image_path_from_index(self, index)`**

Revise the code to train on only **1 class**. Note that if you would like to detect multiple classes, do not modify anything here.
```
image_path = os.path.join(self._data_path,'Images',index+self._image_ext)
assert os.path.exists(image_path), 'Path does not exist: {}'.format(image_path)
return image_path
```

**In function `_load_imagenet_annotation`**

This is th function for parsing annotations which should be figured out carefully. Here, I follow the instruction of [sunshinearnoon](http://sunshineatnoon.github.io/Train-fast-rcnn-model-on-imagenet-without-matlab/), define a new inner-function to get the tags from xml files.
```
def get_data_from_tag(node,tag):
  return node.getElementsByTagName(tag)[0].childNodes[0].data
```
Then, modifying other codes to get annotations by this function. For detail, see my [kaggle.py](https://github.com/coldmanck/fast-rcnn/blob/master/lib/datasets/kaggle.py).

Also, in the for loop of process of loading object bounding boxes into a data frame, there're something should be modified. Refer to the [issue of selective search](https://github.com/rbgirshick/fast-rcnn/issues/26), you may find that 
- the format of proposal ROIs produced by matlab code is: [top, left, bottom, right], 1-based index.
- while the format of proposals in demo mat file is: [left, top, right, bottom], 0-based index.

In the training and testing process of Fast-RCNN, in fact, it follows the second format **[left, top, right, bottom], 0-based index**. You may see in function `_load_selective_search_roidb`, there's a line `box_list.append(raw_data[i][:, (1, 0, 3, 2)] - 1)` which dealing with this problem.

Also, because the data format of Right Whale dataset which coordinates start from zero is different from the original format, I need to minus one to fit:
```
x1 = float(get_data_from_tag(obj, 'xmin')) - 1
y1 = float(get_data_from_tag(obj, 'ymin')) - 1
x2 = float(get_data_from_tag(obj, 'xmax')) - 1
y2 = float(get_data_from_tag(obj, 'ymax')) - 1
```
Finally, do not forget to `import` your file: `import datasets.kaggle`

### factory.py
There're some lines you have to modify:
```
# Set up kaggle_<split> using selective search "fast" mode
kaggle_devkit_path = '/home/coldmanck/kaggle'
for split in ['train', 'test']:
    name = '{}_{}'.format('kaggle', split)
    __sets[name] = (lambda split=split: datasets.kaggle(split, kaggle_devkit_path))
```
If you have more than 1 class you have to deal with, there're `numbers_of_classes` for-loops you have to create. You can refer to my [factory.py](https://github.com/coldmanck/fast-rcnn/blob/master/lib/datasets/factory.py) (1 class) and original [factory_inria.py](https://github.com/coldmanck/fast-rcnn/blob/master/lib/datasets/factory_inria.py) (2 classes) created by zeyuanxy.
Also, do not forget to `import` your new file: `import datasets.kaggle`

### ＿init＿.py
Again, remember to import: `from .kaggle import kaggle`


## Run Selective Search
If you have MATLAB, you may find original approach easy for you to implement. Modify the matlab file `selective_search.m` in the directory `$FRCNN_ROOT/selective_search`, If you do not have that directory, you could find it [here](https://github.com/EdisonResearch/fast-rcnn/tree/master/selective_search)).
```
image_db = '/home/coldmanck/kaggle';
    image_filenames = textread([image_db '/data/ImageSets/train.txt'], '%s', 'delimite    r', '\n');
    for i = 1:length(image_filenames)
        if exist([image_db '/data/Images/' image_filenames{i} '.jpg'], 'file') == 2
        image_filenames{i} = [image_db '/data/Images/' image_filenames{i} '.jpg'];
    end
    if exist([image_db '/data/Images/' image_filenames{i} '.png'], 'file') == 2
        image_filenames{i} = [image_db '/data/Images/' image_filenames{i} '.png'];
    end
end
selective_search_rcnn(image_filenames, 'train.mat');
```
Then run this mat to generate proposals of training data, then move the output `train.mat` to the root of your dataset, e.g. `/home/coldmanck/kaggle` (Note that if you have follow the instruction of original fast-rcnn repository, you should have made an symbolic link under `$FRCNN_ROOT/data`). It's time-consuming and highly depends on performance of your machine, wait patiently :-)

If you don't have MATLAB, [dlib's slective search](http://dlib.net/) is recommended, you can find details in [sunshineatnoon's instruction](http://sunshineatnoon.github.io/Train-fast-rcnn-model-on-imagenet-without-matlab/).

## Modify Prototxt and Rename Layers
**Note steps of renaming layers are for those who may encountered error like `Check failed: ShapeEquals(proto) shape mismatch(reshape not set)` when detecting. However if it's your first time to train your Fast-RCNN, you may not have to follow my renaming layers steps below (but still be sure to change the class number)**. If you followed the instruction of [Train Fast-RCNN on Another Dataset](https://github.com/zeyuanxy/fast-rcnn/tree/master/help/train) or [How to train fast rcnn on imagenet](http://sunshineatnoon.github.io/Train-fast-rcnn-model-on-imagenet-without-matlab/) but still encountered the same error, consider to follow my instruction here. 

First, according to [Fast rcnn 訓練自己的數據庫問題小結](http://blog.csdn.net/hao529good/article/details/46544163), there're two types of pre-trained models provided in fast-rcnn. Take CaffeNet for example: (1) CaffeNet.v2.caffemodel and (2) caffenet_fast_rcnn_iter_40000.caffemodel. The first model is trained on Imagenet, while the second is also trained on Imagenet but finetuned on Fast-RCNN, which cause difference of number of classes and result in error. To deal with it, rename `cls_score` and `bbox_pred` in your `train.prototxt`. For instance, I rename it to `cls_score_kaggle` and `bbox_pred_kaggle`.

Since I have ony two classes(**background** and **kaggle**), I need to change the network structure. Depending on which pre-trained model you would like to train on, modify files in `$FRCNN_ROOT/models/{CaffeNet, VGG16, VGG_CNN_M_1024}/train.prototxt` to fit the dataset.

- For the input layer, I changed the input class to 2: param_str: `"'num_classes': 2"`
- For the `cls_score` layer, I changed the layer name to `cls_score_kaggle` and output class to 2: `numoutput: 2`
- For the `bbox_pred` layer, I changed the layer name to `bbox_pred_kaggle` and output to 2*4=8: `numoutput: 8`

(Just search for `cls_score` and `bbox_pred` in the file and rename all of them, there're about 6 attributes should be modified)

See my [train.prototxt](https://github.com/coldmanck/fast-rcnn/blob/master/models/VGG16/train.prototxt) file for reference.

The same remedy is needed to be applied to `test.prototxt` when testing your Fast-RCNN. See my [test_kaggle.prototxt](https://github.com/coldmanck/fast-rcnn/blob/master/models/VGG16/test_kaggle.prototxt) file for reference. Note that you don't need to rename `test.prototxt` to `test_DATASET.prototxt` as me.

**Rename layers in other files**

Following the renaming approach, you have to modify this two layers name in some files below. Similarly, in the specific file, search for `cls_score` and `bbox_pred` and rename all of them.
- `$FRCNN_ROOT/lib/fast_rcnn/train.py`
- `$FRCNN_ROOT/lib/fast_rcnn/test_train.py`
- `$FRCNN_ROOT/lib/fast_rcnn/test.py`

## Train your Fast-RCNN!
Finally, you can train your own dataset. At `$FRCNN_ROOT`, 
- On CaffeNet: run `./tools/train_net.py --gpu 0 --solver models/CaffeNet/solver.prototxt --weights data/imagenet_models/CaffeNet.v2.caffemodel --imdb kaggle_train`
- On VGG_CNN: run `./tools/train_net.py --gpu 1 --solver models/VGG_CNN_M_1024/solver.prototxt --weights data/imagenet_models/VGG_CNN_M_1024.v2.caffemodel --imdb kaggle_train`
- On VGG16: run `./tools/train_net.py --gpu 2 --solver models/VGG16/solver.prototxt --weights data/imagenet_models/VGG16.v2.caffemodel --imdb kaggle_train`

By default, 40,000 iterations will be performed on each training process with snapshots on every 10,000 iterations, e.g. for CaffeNet, there will be 4 files: `caffenet_fast_rcnn_iter_{1, 2, 3, 4}0000.caffemodel`. The model will be saved at `$FRCNN_ROOT/output/default/train`. Copy them to `$FRCNN_ROOT/data/fast_rcnn_models/` to use `demo.py` (or my `demo_kaggle.py`) to run detection (Don't forget to backup the old one). 

## Run detection
Before you run `$FRCNN_ROOT/tools/demo.py`, it should be modified to fit your dataset and models:
```
CLASSES = ('__background__','whale')

# if you want to restrict the detection numbers to the specific number like me (just one detection with highest confidence), 
# add some lines below in function vis_detections(im, class_name, dets, image_name, thresh=0.5):
max_score = 0
max_inds = 0
if len(inds) == 0:
    print('no target detected!')
    return
elif len(inds) > 1:
    print(str(len(inds)) + ' targets detected! Choose the highest one.')
    for i in inds:
        if(dets[i, -1] > max_score):
            max_inds = i
bbox = dets[max_inds, :4]
score = dets[max_inds, -1]

# if you copy the test.prototxt to test_DATASET.prototxt 
# and rename layers name like me, remember to modify this line
prototxt = os.path.join(cfg.ROOT_DIR, 'models', NETS[args.demo_net][0],'test_kaggle.prototxt')
```
You may want to see my [demo_kaggle.py](https://github.com/coldmanck/fast-rcnn/blob/master/tools/demo_kaggle.py) for detail. In addition, I trace all of my training data and save the resulting coordinate [left, top, right, bottom] into mat file. you can refer to my [demo_kaggle_all.py](https://github.com/coldmanck/fast-rcnn/blob/master/tools/demo_kaggle_all.py).

**Warning:** Concerning to your testing data's proposals, you may want to generate from the same `selective_search.m`. It's okay, however be careful of the same problem mentioned above (reversion of coordinates). To revise the output mat file into correct format, you can refer to my [trans_selective_search.m](https://github.com/coldmanck/fast-rcnn/blob/master/data/kaggle/trans_selective_search.m) (convert into mat file for each picture, e.g. w_1234.mat) or [trans_selective_search_allmat.m](https://github.com/coldmanck/fast-rcnn/blob/master/data/kaggle/trans_selective_search_allmat.m) (convert all into single mat file).

## Demo
<tr>
<td>
<img src="result/test_img/w_126_whale.png" width="45%" />
<img src="result/test_img/w_276_whale.png" width="45%" />
</td>
</tr>


## Trouble-Shooting
**Error message** `Gdk-CRITICAL **: gdk_cursor_new_for_display: assertion 'GDK_IS_DISPLAY (display)' failed`

if you use ssh to remote machine, try ssh with `-X` option to enables X11 forwarding. Then tell matplotlib not to try to load up GTK, you should insert code below into the python file, e.g. in `$FRCNN_ROOT/tools/demo.py`:
```
import matplotlib
matplotlib.use('Agg')
```

**Error message** `ImportError: libcudart.so.6.5: cannot open shared object file: No such file or directory`

Run `$ export LD_LIBRARY_PATH=/usr/local/cuda/lib64` in every session (every connection to remote machine).

**Error message** `Check failed: ShapeEquals(proto) shape mismatch(reshape not set)`

First, one of the [answer](http://stackoverflow.com/a/31251378/4447620) in stackoverflow saying that it's may caused by forgetting to change the number of classes in `test.prototxt` (same as `train.protxt`) to fit your dataset. If you've changed it but still encounterd the error, follow my renaming approach (rename layers `bbox_pred` and `cls_score`) descripted in this article to re-train your model.

## Reference
1. [Train Fast-RCNN on Another Dataset](https://github.com/zeyuanxy/fast-rcnn/tree/master/help/train)
2. [How to train fast rcnn on imagenet](http://sunshineatnoon.github.io/Train-fast-rcnn-model-on-imagenet-without-matlab/)
3. [Selective Search Configuration](https://github.com/rbgirshick/fast-rcnn/issues/26)
4. [Fast rcnn 訓練自己的數據庫問題小結](http://blog.csdn.net/hao529good/article/details/46544163)
5. [How to forward X over SSH from Ubuntu machine?](http://unix.stackexchange.com/questions/12755/how-to-forward-x-over-ssh-from-ubuntu-machine)
6. [[Caffe]: Check failed: ShapeEquals(proto) shape mismatch (reshape not set)](http://stackoverflow.com/a/31251378/4447620)
