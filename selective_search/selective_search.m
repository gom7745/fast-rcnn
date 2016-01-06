image_db = '/home/gom7745/MMAI/final/fast-rcnn/data/kaggle';
image_filenames = textread([image_db '/data/ImageSets/train.txt'], '%s', 'delimiter', '\n');
for i = 1:length(image_filenames)
    if exist([image_db '/data/Images/' image_filenames{i} '.jpg'], 'file') == 2
	image_filenames{i} = [image_db '/data/Images/' image_filenames{i} '.jpg'];
    end
    if exist([image_db '/data/Images/' image_filenames{i} '.png'], 'file') == 2
        image_filenames{i} = [image_db '/data/Images/' image_filenames{i} '.png'];
    end
end
selective_search_rcnn(image_filenames, 'output.mat')
