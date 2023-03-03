% This script is for MATLAB with Windows OS;
clc;clear;% script test:
close all;

%parent folder:
parent_folder = "H:\WenhongTestFolder\GATE\noise_equivalent_count_rate";

%inter file folder:
sensitivity_mode = "VR10";
data_folder = "norm_2023_02_02_tube_100cm";
int_file_f = fullfile(parent_folder, "data",sensitivity_mode , data_folder, "interfile_d");
addpath(int_file_f);

% Prerequisite: check the avalibilty of function read_sinoF.m at the interfile_d
% folder:
template_folder = fullfile(parent_folder,"scripts");
if exist(fullfile(int_file_f,"read_sinoF.m","file"))
    disp("read_sinoF.m file exists.");
else
    disp("read_sinoF.m file does NOT exist.");
    original_file = fullfile(template_folder,"read_sinoF.m");
    target_file = int_file_f;
    state_copy = copyfile(original_file, target_file);
    if state_copy == 1
        disp("copy successful.");
    else
        disp("Error.");
        return;
    end
end
% To input all files with sinogram;
keyword_table = ["emis", "scatter_estim2d", "smoothed_rand", "norm3d"];
keyformat = ["*.s", "*.s", "*.s", "*.s"]; % in order;

% get the sinogram of emission etc.:
emis = extract_sino(int_file_f,keyformat(1),keyword_table(1));
image = extract_sino(int_file_f,"*.i","image");
scatter_2d = extract_sino(int_file_f,"*.s","scatter_estim2d");
norm = extract_sino(int_file_f,"*.a","norm3d");
smooth_rand = extract_sino(int_file_f,"*.s","smoothed");
acf = extract_sino(int_file_f,"*.a","acf");

size_acf = size(acf);
size_emis = size(emis);
size_norm = size(norm);
size_scatter2d = size(scatter_2d);
size_smooth = size(smooth_rand);
size_image = size(image);

%% get the correct bin (accumulated bins)
emis_rebinned = sino_rebin(emis, parent_folder);
norm_rebinned = sino_rebin(norm, parent_folder);
smooth_rand_rebinned = sino_rebin(smooth_rand,parent_folder);

%% write the rebinned matrix to a mat file (*.mat):
save(fullfile(int_file_f,"emis_rebinned.mat"),"emis_rebinned");
save(fullfile(int_file_f,"norm_rebinned.mat"),"norm_rebinned");
save(fullfile(int_file_f,"smooth_rebinned.mat"),"smooth_rand_rebinned");


%% functions:
function sino_needed = sino_rebin(sino, parent_folder)
X=size(sino);
if size(X)~=4
    disp("ERROR!");
    return;
end

if X(end) == 34
    extracted_sino = sum(sino(:,:,:,1:end-1),4);
else if X(end) == 33 
        extracted_sino = sum(sino(:,:,:,1:end),4);
else
    disp("ERROR!");
    return;
    end
end
% separate the segements based on michelogram map (VR10);
mich_map_VR10 = [645, 625, 625, 587, 587, 549, 549, 511, 511];
% correlated segments: 0 +/-1, +/-2, +/-3, +/-4;
ind_mich = 1:length(mich_map_VR10);
for m = 1:length(ind_mich)
    ac_mich_map_VR10(m) = sum(mich_map_VR10(1:ind_mich(m)));
end
mich_map_VR10 = ac_mich_map_VR10; clear ac_mich_map_VR10 m;
mich_map_VR10 = [0, mich_map_VR10];
n = 1;
for m = 1:(length(mich_map_VR10)-1)
    sino_sparated(n) = {extracted_sino(:,:,(mich_map_VR10(m)+1):mich_map_VR10(m+1))};
    n=n+1;
end
sino_sparated = sino_sparated';
clear m n;
% read the mich_map_index (the excel files);
mich_name_data = "QuadraMRD85_data_map.xlsx";
mich_name_seg = "QuadraMRD85_seg_map.xlsx";
mich_data = xlsread(fullfile(parent_folder,"ref_files_michelogram",mich_name_data));
mich_seg = xlsread(fullfile(parent_folder,"ref_files_michelogram",mich_name_seg));
% comment: the crystal index started at the matrix is 1; while the
% extracted segment index starts from 0; 

[M,N]=size(mich_data);
for n = 1 : N
ind_nan(:,n)=isnan(mich_data(:,n));
end
ind_ele = find(ind_nan==0);

ind_raw = mod(ind_ele, N); ind_raw(find(ind_raw==0))=323;
ind_column = (ind_ele-ind_raw)/N+1;
mich_data_re = reshape(mich_data,[M*N,1]);
ind_nan_re = reshape(ind_nan,[M*N,1]);
ind = [mich_data_re(find(ind_nan_re==0)),ind_nan_re(find(ind_nan_re==0))];
ind_raw_column = [ind_raw, ind_column];
ind = [ind, ind_raw_column]; ind(:,3)=ind(:,3)-1; ind(:,4)=ind(:,4)-1;
ind(:,5)=(ind(:,3)-ind(:,4))./2; 
clear ind_raw_column ind_raw ind_column ind_nan_re mich_data_re m n M N;

sym_int = unique(ind(:,5));sym_int = sym_int';% get the signal value for location;
for m = 1: length(sym_int)
    ind_uni = find(ind(:,5)==sym_int(m));
    frame_seg(m) = {unique(ind(ind_uni,1))+1};
end
frame_seg=frame_seg'; % the physical location (single prependicular) is linked to
% the matrix index (at matrix of extracted_emis)
clear m;
%% rebin:
[M, ~] = size(frame_seg);
for m = 1 : M
    temp = 0;
    for n = 1:length(frame_seg{m})
        temp = extracted_sino(:,:,frame_seg{m}(n))+temp;
    end
    frame_x{m} = temp;
    clear temp n;
end
frame_x = frame_x';
sino_needed = cat(3, frame_x{:});
end


function extracted_result = extract_sino(int_file_f, k_format, k_word)
% get specific file and its header:
%file_format = "*.hdr";
file_name_sino_data = get_file_name(int_file_f,k_format, k_word);
file_name_header_data = get_file_name(int_file_f,"*.h33", k_word);

% read the header file to a table; And get the size of sino file (bytes).
file_content = read_file(fullfile(int_file_f,file_name_header_data));
sino_file_info = dir(fullfile(int_file_f,file_name_sino_data));
sino_size = sino_file_info.bytes;
% extract the infos:
num_of_dims = double(extract_data(file_content,"number of dimensions"));
num_byte_pixel = double(extract_data(file_content,"number of bytes per pixel"));
if num_of_dims == 3
    matrix_size1 = double(extract_data(file_content,"matrix size [1]"));
    matrix_size2 = double(extract_data(file_content,"matrix size [2]"));
    matrix_size3 = double(extract_data(file_content,"matrix size [3]"));
    %matrix_size3 = matrix_size3*2;
    matrix_multiple = matrix_size1 * matrix_size2 * matrix_size3;
else
    if num_of_dims == 4
        matrix_size1 = double(extract_data(file_content,"matrix size [1]"));
        matrix_size2 = double(extract_data(file_content,"matrix size [2]"));
        matrix_size3 = double(extract_data(file_content,"matrix size [3]"));
        %matrix_size3 = matrix_size3*2;
        matrix_size4 = double(extract_data(file_content,"matrix size [4]"));
        matrix_multiple = matrix_size1 * matrix_size2 * matrix_size3 * matrix_size4;
    else
        disp("ERROR!");
    end
end
% calculate the last parameter for sino extract:
last_para = sino_size./num_byte_pixel ./ matrix_multiple;

%
current_folder = pwd;
cd(int_file_f);
extracted_result = read_sinoF(file_name_sino_data,matrix_size1,matrix_size2,...
    matrix_size3,last_para);
cd(current_folder);
end

function file_name = get_file_name(parent_folder,file_format, key_str)
%file_format = "*.hdr";
files_info = struct2cell(dir(fullfile(parent_folder,file_format)));
file_names = files_info(1,:);

m = 1;
for kk = 1:length(file_names)
    str1 = string(file_names{kk});
    ref_str =key_str;
    logi_index = strfind(str1, ref_str);
    if ~isempty(logi_index)
        file_index(m) = kk; m=m+1;
    end
end
file_name = string(file_names{file_index}); % get the file name of sino.s.hdr
end

function file_content = read_file(file_full_path)
% this function is to read the files
file_content = strsplit(string(fileread(file_full_path)),'\n')';
end

function extracted_value = extract_data(table_for_extract,key_str)
m = 1;
for k = 1:length(table_for_extract)
    str1 = table_for_extract(k);
    logi_index = strfind(str1, key_str);
    if ~isempty(logi_index)
        str_index(m) = k; m=m+1;
    end
end
extracted_value = extractAfter(table_for_extract(str_index),":= ");
end