function [] = trans_selective_search(type)
load([type '.mat']);
boxes_temp = all_boxes;
fileNames = textread(['data/ImageSets/', type, '.txt'], '%s');

for i = 1:size(boxes_temp,2)
    boxes_temp = uint16(all_boxes{1,i});
    boxes = boxes_temp(:, [2 1 4 3]) - 1;
    
    save([type, '_bbox/', fileNames{i,1} '_boxes.mat'], 'boxes');
end
