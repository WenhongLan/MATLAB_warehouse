% this code is to decompress the sinogram directly from the compressed
% sinogram generated by Histogramming.bat.
clc;clear;
parent_folder = "H:\WenhongTestFolder\GATE\noise_equivalent_count_rate";
data_folder = fullfile(parent_folder, "data", "VR10");
list_folder = dir(data_folder);list_folder(~[list_folder.isdir])=[];
list_folder = list_folder(3:end);

% modify the command and execute it.
executed_file = "!C:\Siemens\PET\bin.win64-VR10\intfcompr.exe";
for k = 1:length(list_folder)
    file_input = fullfile(list_folder(1).folder,...
        list_folder(k).name,"GATESim-LM-00-sino-0.s.hdr");
    file_input = append(" -e ",file_input);
    
    file_output = fullfile(list_folder(1).folder,...
        list_folder(k).name,"GATESim-LM-00-sino-0-u.s.hdr");
    file_output = append(" --oe ",file_output);
    cmd = append(executed_file,file_input, file_output);
    eval(cmd);
end

