#!/usr/bin/bash
./tools/train_net.py --gpu 0 --solver models/CaffeNet/solver_AlexKaggle.prototxt --weights data/imagenet_models/CaffeNet.v2.caffemodel --imdb AlexKaggle_train
