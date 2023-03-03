clc;clear;

JSRecon_exe = "C:\JSRecon12\IF2Dicom.js";
parent_folder = "H:\WenhongTestFolder\GATE\norm_file_validation\data"; % modify here for
% data location (folder with data, automated group data processing). 
v_file_name = "GATESim-LM-00-PSFTOF-AC_000_000.v.hdr";
IF2DICOM_file_name = "Run-05-Sample_Patient_IQ-LM-00-IF2Dicom.txt";
template_file_JSRecon = "H:\WenhongTestFolder\GATE\norm_file_validation\Template_files\Run-05-Sample_Patient_IQ-LM-00-IF2Dicom.txt";

% construct the path to data folder:
list_dir = dir(parent_folder);
list_dir = list_dir(3:end);
for k = 1:length(list_dir)
    data_folder = fullfile(parent_folder,list_dir(k).name); % to the data folder<<.
    data_full_path = fullfile(data_folder,v_file_name);
    script_full_path = fullfile(data_folder,IF2DICOM_file_name);
    if exist(script_full_path) == 0
            copyfile(template_file_JSRecon, data_folder);
        else
    end
    
    data_full_path = append('"',data_full_path,'"');
    script_full_path = append('"',script_full_path,'"');
    cmd = append('!cscript', ' ', JSRecon_exe, ' ',data_full_path, ' ', script_full_path);   
    eval(cmd);
end
