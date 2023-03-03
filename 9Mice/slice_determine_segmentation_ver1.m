clear all;
close all;
clc

% set the segmentation window
parent_folder= ...
     "C:\Users\wenlan\Documents\wenlan\Projects\Docs_animal_expriments\DICOM_9mice";
type_mice = "9mice_stacked";
folder= fullfile(parent_folder,type_mice);

dirFiles = dir(folder);
dirFiles = dirFiles([dirFiles.isdir] == 0);
dicom_info=dicominfo(fullfile(folder,dirFiles(3).name));
Image1 = zeros(dicom_info.Rows,dicom_info.Columns,length(dirFiles));
Image2 = zeros(dicom_info.Rows,dicom_info.Columns,length(dirFiles));
FOV = dicom_info.PixelSpacing.*double([dicom_info.Rows;dicom_info.Columns]);
SliceThickness = dicom_info.SliceThickness;

slicePos = zeros(1,length(dirFiles));
for i=1:length(dirFiles)
    dicom_info(i)=dicominfo(fullfile(folder,dirFiles(i).name));
    slicePos(i) = dicom_info(i).SliceLocation;
    Image1(:,:,i)=double(dicomread(dicom_info(i)));
    Image2(:,:,i)=Image1(:,:,i)*dicom_info(i).RescaleSlope+dicom_info(i).RescaleIntercept;
end
% Image2 is with the correct voxel size.

[~,index] = sort(slicePos);
Image2 = Image2(:,:,index);

%% acquire the segmentation offset:
[L, W, H] = size(Image2);
% x, y direction is the plane prependicular to the axis of PET.

% crop the matrix size:
% (on z-axis direction):
for h = 1:H
    sum_xyplane(h)=sum(Image2(:,:,h),"all");
end

for l = 1:L
    sum_xzplane(l)=sum(Image2(l,:,:),"all"); % X-Z plane
end

for w = 1:W
    sum_yzplane(w)=sum(Image2(:,w,:),"all");
end
pic_draw =1;
if pic_draw ==1
    %plot the curve for determine the offset:
    figure; plot(sum_xyplane); title("view on X-Y plane");
    xlabel("number of slice on Z-axis direction");
    ylabel("signal strength");grid on;
    
    figure; plot(sum_yzplane); title("view on Y-Z plane");
    xlabel("number of slice on X-axis direction");
    ylabel("signal strength");grid on;
    
    figure; plot(sum_xzplane); title("view on X-Z plane");
    xlabel("number of slice on Y-axis direction");
    ylabel("signal strength");grid on;
else
    disp("No curve display");
end
% for validation:
figure; imagesc(squeeze(Image2(220,:,:)));colormap(flipud(gray));
title("view on X-Z plane");clim([0 15000]);
figure; imagesc(squeeze(Image2(:,220,:)));colormap(flipud(gray));
title("view on Y-Z plane");clim([0 15000]);
figure; imagesc(squeeze(Image2(:,:,325)));colormap(flipud(gray));
title("view on X-Y plane");clim([0 15000]);
