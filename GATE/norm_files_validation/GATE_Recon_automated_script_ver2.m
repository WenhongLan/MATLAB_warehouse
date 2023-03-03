clc;clear;
%%Here try to automate the reconstruction of GATE:
% This script only can run on the version later than MATLAB 2016b Windows
% Version.
parent_folder = "H:\WenhongTestFolder\GATE\norm_file_validation\data"; % modify here for
% data location (folder with data, automated group data processing). 
list_dir = dir(parent_folder);
list_dir = list_dir(3:end);
for k = 1:length(list_dir)
    data_folder = fullfile(parent_folder,list_dir(k).name);
end
template_folder = "H:\WenhongTestFolder\GATE\Template_files";
automated_script_GATE(data_folder, template_folder);

%% function:
function automated_script_GATE(parent_folder, template_folder)
root_folder = pwd;
cd(parent_folder);
% to get the study time from listmode header file.
study_time = get_study_time(parent_folder);

% to calculate the DCR for modifying the bat file.
t_DCR = DCR_calculate(study_time);

% This function is to modify the bat file with correct frame number (Histogramming)
t_duration = t_duration_calculate(parent_folder);
new_bat_name_hist = modify_hist_bat(parent_folder, template_folder, t_duration);

% run the .bat file (Histogramming)
eval(append("!",fullfile(parent_folder,new_bat_name_hist)));

%modify the sino.mhdr file based on the result of histogramming:
file_name_mhdr_sino = modify_sino_mhdr(parent_folder, template_folder);

% This funtion is modify the bat file with correct DCR time: (PSFTOF).
new_bat_name_PSFTOF = modify_PSTTOF_bat(parent_folder, template_folder, t_DCR);

% run the .bat file (PSFTOF)
eval(append("!",fullfile(parent_folder,new_bat_name_PSFTOF)));
cd(root_folder);
end

%% functions:
function text_need = find_files(parent_folder, file_format,ref_str)
% this function is to find and read the correct file from the folder.
% the input:    parent_folder is the folder that the file is within;
%               file_format: the format of file, e.g: '*.hdr'.
%               ref_str: the keywords at the file name. e.g.: "listmode". 
    files_info = struct2cell(dir(fullfile(parent_folder,file_format)));
    file_names = files_info(1,:);

    m = 1;
    for kk = 1:length(file_names)
        str1 = string(file_names{kk});
        logi_index = strfind(str1, ref_str);
        if ~isempty(logi_index)
            file_index(m) = kk; m=m+1;
        end
    end
    text_need = strsplit(string(fileread(fullfile(string(files_info{2,file_index}),...
        string(files_info{1,file_index})))),'\n')';
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

function new_command_table = replace_command(old_command_table, new_command, command_hint)
m =1;
for kk = 1:length(old_command_table)
    str1 = old_command_table(kk);
    ref_str = command_hint;
    logi_index = strfind(str1, ref_str);
    if ~isempty(logi_index)
        file_index(m) = kk; m=m+1;
    end
end
old_command_table(file_index)= append("set cmd= %cmd% ", command_hint," ",new_command);
new_command_table = old_command_table;
end

function study_time = get_study_time(parent_folder)
%this function is to get the study time and date from the header file of
%listmode. The output format is string which is suitable as the input to
%calculate the DCR.
    text_need = find_files(parent_folder, '*.hdr',"listmode");
   
    % study date is at row 10; study time is at row 11;
    study_date = extractAfter(text_need(10),'=');
    study_time = extractAfter(text_need(11),'=');
    study_time = append(study_date,' ',study_time);
end

function t_DCR = DCR_calculate(study_time)
% DCR claculation:
% The reference time of DCR is 01.01.1970 at 00:00:00. So, DCR is the
% temporal period from the reference time to the study time in seconds.
    ref_time = '1970:01:01 00:00:00';
        %study_time = '2000:01:01 10:00:01';
    t_ref = datevec(ref_time, 'yyyy:mm:dd HH:MM:SS');
    t_study = datevec(study_time, 'yyyy:mm:dd HH:MM:SS'); 
    t_DCR = abs(etime(t_ref, t_study));
end

function t_duration = t_duration_calculate(parent_folder)
% This function is to extract the scan duration from the listmode file. 
file_format_listmode = "*.hdr";
ref_str_listmode = "listmode";
text_need_listmode = find_files(parent_folder, file_format_listmode,ref_str_listmode);
t_duration = extractAfter(text_need_listmode(end-1),"=");
end

function new_bat_file_name = modify_hist_bat(parent_folder,template_folder, t_duration)
% This function is to modify the histogramming .bat file, based on the
% template.
file_format_hist = "*.bat";
ref_str_hist = "Histogramming_template.bat";
text_need = find_files(template_folder, file_format_hist,ref_str_hist);

new_bat_file_name = "Run-00-GATESim-LM-00-Histogramming_new.bat";

%get the name of listmode file:
files_info = struct2cell(dir(fullfile(parent_folder,"*.hdr")));
file_names = files_info(1,:); file_names = file_names';

m = 1;
for kk = 1:length(file_names)
    str1 = string(file_names{kk});
    ref_str ="listmode";
    logi_index = strfind(str1, ref_str);
    if ~isempty(logi_index)
        file_index(m) = kk; m=m+1;
    end
end
name_listmode = string(file_names{file_index}); % get the file name of list mode.
clear m kk str1 ref_str logi_index file_index;

%modify the command line of "--lmhd" with the correct listmode file name
text_need = replace_command(text_need, append('"',name_listmode,'"'), "--lmhd ");

%Here is to modify the "--frame" parameter
text_need = replace_command(text_need, append("0:",t_duration), "--frame");

% write the file to destination (hist. .bat file)
current_folder = pwd;
cd(parent_folder);
if exist(new_bat_file_name)
    delete(new_bat_file_name);
end
fileID = fopen(new_bat_file_name,'w');
    for kk = 1:length(text_need)
        fprintf(fileID,'%s\n',text_need(kk));
    end
fclose(fileID);
cd(current_folder);
end

function new_bat_file_name = modify_PSTTOF_bat(parent_folder,template_folder, t_DCR)
%This funtion is modify the bat file with correct DCR time:
    text_need = find_files(template_folder, '*.bat',"PSFTOF_template.bat");
    new_bat_file_name = "Run-04-GATESim-LM-00-PSFTOF_new.bat";
    
    % modify the command of " -n " with correct urls/paths
    ds1 = get_file_name(parent_folder,"*.hdr", "norm"); % get the file name of sino.s.hdr.
    text_need = replace_command(text_need, ds1, " -n");
    
    % modify the command of " -n " with correct urls/paths
    ds2 = get_file_name(parent_folder,"*.mhdr", "umap"); % get the file name of sino.s.hdr.
    text_need = replace_command(text_need, ds2, " -u");
    
    % modify the command of " -e " with correct urls/paths
    ds3 = get_file_name(parent_folder,"*.mhdr", "sino"); % get the file name of sino.s.hdr.
    text_need = replace_command(text_need, ds3, " -e");
    
    % modify the command of "--dcr" with correct value.
    text_need = replace_command(text_need, append(string(t_DCR),".00"), "--dcr");
    
    % write to the .bat file. (PSTTOF).
    current_folder = pwd;
    cd(parent_folder);
    if exist(new_bat_file_name)
        delete(new_bat_file_name);
    end
    
    fileID = fopen(new_bat_file_name,'w');
    for kk = 1:length(text_need)
        fprintf(fileID,'%s\n',text_need(kk));
    end
    fclose(fileID);
    cd(current_folder);
end

function file_name_mhdr_sino = modify_sino_mhdr(parent_folder, template_folder)
ds1 = get_file_name(parent_folder,"*.hdr", "sino"); % get the file name of sino.s.hdr.
ds2 = get_file_name(parent_folder,"*.s", "sino"); % get the file name of sino.s.
% get the name for sino.mhdr file:
file_name_mhdr_sino = get_file_name(template_folder,"*.mhdr", "sino"); 

text_need = find_files(template_folder, '*.mhdr',"sino");

% modify the command on sino.mhdr. Because the command format is different
% than others, it cannot use function <replace_command()>.
m =1;
for kk = 1:length(text_need)
    str1 = text_need(kk);
    ref_str = "%data set [1]:=";
    logi_index = strfind(str1, ref_str);
    if ~isempty(logi_index)
        file_index(m) = kk; m=m+1;
    end
end
text_need(file_index)= append("%data set [1]:={30,", ds1,",",ds2,"}");

% write to the .bat file. (sino.mhdr).
current_folder = pwd;
cd(parent_folder);
if exist(file_name_mhdr_sino)
   delete(file_name_mhdr_sino);
end
    
fileID = fopen(file_name_mhdr_sino,'w');
for kk = 1:length(text_need)
    fprintf(fileID,'%s\n',text_need(kk));
end
fclose(fileID);
cd(current_folder);
end

