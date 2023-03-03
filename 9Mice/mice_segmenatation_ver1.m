clear; close all; clc;

% set the segmentation window
parent_folder= ...
     "C:\Users\wenlan\Documents\wenlan\Projects\Docs_animal_expriments\DICOM_9mice";
type_mice = "9mice_stacked";
folder= fullfile(parent_folder,type_mice);


% set the segmentation window (load the offset from Excel sheet);
sheet_offset_slice = xlsread(fullfile(parent_folder,...
    "seg_factor",append(type_mice,"_seg_factor")));
[M, N] = size(sheet_offset_slice);

% restore the start and end slices for each mouse:
% the first element is the number of start slice, while the second column 
% element is the # if end slice.
% for x-y plane (z-axis direction)
index_slice_xy = index_slice_restore(sheet_offset_slice(:,1), M);
index_slice_xz = index_slice_restore(sheet_offset_slice(:,2), M);
index_slice_yz = index_slice_restore(sheet_offset_slice(:,3), M);


% to control and refer the parameters for segmentation:
clear m n p;valid_ind=0; ind_mice = 1;
for m = 1:length(index_slice_xz(:,1))
    for n = 1:length(index_slice_yz(:,1))
        for p = 1:length(index_slice_xy(:,1))
            start_slice1 = index_slice_xz(m,1);
            end_slice1 = index_slice_xz(m,2);
            start_slice2 = index_slice_yz(n,1);
            end_slice2 = index_slice_yz(n,2);
            start_slice3 = index_slice_xy(p,1);
            end_slice3 = index_slice_xy(p,2);
            % group the parameters:
            matrix_slices_st = [start_slice1, start_slice2, start_slice3];
            matrix_slices_ed = [end_slice1, end_slice2, end_slice3];
            
            % write the DICOM files:
            DICOM_process(parent_folder, type_mice,ind_mice,...
                matrix_slices_st,matrix_slices_ed,valid_ind)
            ind_mice = ind_mice + 1;
        end
    end
end
clear ind_mice;


%% functions:
% this function is to restore a matrix for offset slices for segmentation.
% "sheet" should a single column vector!
function index_slice = index_slice_restore(sheet, M)
for m = 1:M-1
    if sheet(m+1,1) ~=-1
        index_slice(m,1) = sheet(m);
        index_slice(m,2) = sheet(m+1);
    else
        break;
    end
end
end


function DICOM_process(parent_folder,type_mice,ind_mice,matrix_slices_st,...
    matrix_slices_ed,valid_ind)
% read the original DICOM files.
folder= fullfile(parent_folder,type_mice);

DICOM_original = dicomreadVolume(folder);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% To get the dicom info: (From Fabian)
dirFiles = dir(folder);
dirFiles = dirFiles([dirFiles.isdir] == 0);
dicom_info=dicominfo(fullfile(folder,dirFiles(3).name));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% decompress the start- and end- slices:
start_slice1 = matrix_slices_st(1);
end_slice1 = matrix_slices_ed(1);
start_slice2 = matrix_slices_st(2);
end_slice2 = matrix_slices_ed(2);
start_slice3 = matrix_slices_st(3);
end_slice3 = matrix_slices_ed(3);

% create the output folder, if nou exist:
output_f = append("mice",string(ind_mice));
outputFolder = fullfile(parent_folder,"output",type_mice,output_f);
if ~exist(outputFolder,"dir")
    mkdir(outputFolder);
end

%segment the DICOM Volumn:
myImageNifti = DICOM_original(start_slice1:end_slice1,...
    start_slice2:end_slice2,:,...
    start_slice3:end_slice3);

% prepare the meta data for the DICOM:
metadata_dcm = dicom_info(1);
[P, Q,~, ~]=size(myImageNifti);
metadata_dcm.Width = P*ones(1,P);
metadata_dcm.Height = Q;
metadata_dcm.Rows = P;
metadata_dcm.Columns = Q;
DICOM_name = append("mice",string(ind_mice),".dcm");
metadata_dcm.Filename = fullfile(outputFolder,DICOM_name);

% write the dicom file to folder:
dicomwrite(myImageNifti,fullfile(outputFolder,DICOM_name),metadata_dcm,'CreateMode','copy');


%% validation:
%valid_ind =0; % here is to switch on/off for validation image display.
if valid_ind == 1
    figure; imagesc(squeeze(myImageNifti(round((end_slice1 - start_slice1)/2),:,:)));
    colormap(flipud(gray));title("view on X-Z plane");clim([0 1000]);axis image;
    
    figure; imagesc(squeeze(myImageNifti(:,round((end_slice2 - start_slice2)/2),:,:)));
    colormap(flipud(gray));title("view on Y-Z plane");clim([0 1000]);axis image;
    
    figure; imagesc(squeeze(myImageNifti(:,:,:,round((end_slice3 - start_slice3)/2))));
    colormap(flipud(gray));title("view on X-Y plane");clim([0 1000]);axis image;
else
end
end