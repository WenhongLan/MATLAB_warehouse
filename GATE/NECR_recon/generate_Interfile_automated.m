% This script is for MATLAB with Windows OS;
clc;clear;% script test:
close all;

current_folder = pwd;
%parent folder:
parent_folder = "H:\WenhongTestFolder\GATE\noise_equivalent_count_rate";

%inter file folder:
sensitivity_mode = "VR10";
data_folder = ["norm_2023_02_02_IQ"];
for m = 1:length(data_folder)
int_file_f = fullfile(parent_folder, "data",sensitivity_mode , data_folder(m), "interfile_d");
if ~exist(int_file_f,"dir")
    mkdir(int_file_f);
end
addpath(int_file_f);

%% .bat file location:
name_bat = "Run-04-GATESim-LM-00-PSFTOF_new.bat";
locs_bat = fullfile(parent_folder, "data",sensitivity_mode , data_folder(m));
cd(locs_bat);
cmd = append("!",fullfile(locs_bat,name_bat));
eval(cmd);
cd(current_folder);
end
