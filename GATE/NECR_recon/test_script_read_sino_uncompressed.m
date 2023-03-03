% This script is for MATLAB with Windows OS;
clc;clear;% script test:

%parent folder:
parent_folder = "H:\WenhongTestFolder\GATE\noise_equivalent_count_rate";

%uncompressed file folder:
data_folder = "norm_2021_10_20_IQ";
sensitivity_mode = "VR10";
int_file_f = fullfile(parent_folder, "data",sensitivity_mode , data_folder,"interfile_d");
addpath(int_file_f);

% To input all files with sinogram;
k_word = "GATESim-LM-00-sino-0-u";
k_format = "*.s"; % in order;

% get the sinogram of emission etc.:

file_name_sino_data = get_file_name(int_file_f,k_format, k_word);
file_name_header_data = get_file_name(int_file_f,"*.hdr", k_word);

% read the header file to a table; And get the size of sino file (bytes).
file_content = read_file(fullfile(int_file_f,file_name_header_data));
sino_file_info = dir(fullfile(int_file_f,file_name_sino_data));
sino_size = sino_file_info.bytes;
% extract the infos:

num_byte_pixel = 2;
matrix_size1 = 520;
matrix_size2 = 50;
matrix_size3 = 11559;
matrix_size4 = 35;
matrix_multiple = matrix_size1 * matrix_size2 * matrix_size3 * matrix_size4;

% calculate the last parameter for sino extract:
last_para = sino_size./num_byte_pixel ./ matrix_multiple;
if last_para == 1
    %
    current_folder = pwd;
    cd(int_file_f);
    extracted_result = read_sinoF(file_name_sino_data,matrix_size1,matrix_size2,...
        matrix_size3,matrix_size4);
    cd(current_folder);
    size_extracted_result = size(extracted_result);
else
    disp("ERROR!, size is not matched.");
end





%% functions:
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