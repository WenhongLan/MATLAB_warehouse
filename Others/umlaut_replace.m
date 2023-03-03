function umlaut_replace(r)

% the input is the full pathway of the folder. The pathway is with string
% format.
% The output is null. And this function is to rename the umlaut letters in 
% German to General letters compatible with MATLAB
% It can be extended to the capital letter, if necessary.
d=dir(r); % get the pathway
addpath(r) % add the  full pathway to MATLAB pathway, if it is not added.
d=d(~ismember({d.name},{'.','..'})); % get all content in the folder; return a struct variable
d_cell = struct2cell(d);d_cell = d_cell'; % convert the data from struct to cell;

index_folder = cell2mat(d_cell(:,5)); % get the index of folder: folder is 1, file is 0;
name_d_old = d_cell(:,1); % convert the name of content to cell format.
for k = 1:size(d_cell(1:end,1))  
    %if index_folder(k) == 1
        name_str = string(name_d_old{k}); % get the name of folder in string format.
        % To replace ä, ö and ü to ae, oe and ue
        letter_DE = split(['ä','ö','ü', 'Ä','Ö','Ü'],'');letter_DE = letter_DE(2:end-1); % German umlaut letters 
        letter_GB = split(['a','o','u','A','O','U'],'');letter_GB = letter_GB(2:end-1); % related general letters in MATLAB.
        for k_letter = 1:length(letter_DE)
            name_str_sp = split(name_str,'')'; name_str_sp = name_str_sp(2:end);
            index_aou = flip(find(name_str_sp == string(letter_DE{k_letter}))); % get the index of umlaut letter.
            for k_aou = 1:length(index_aou)
                name_str_sp(index_aou(k_aou)) = string(letter_GB{k_letter});
                if k_letter >3 % recoginze lowercase of capital letters:
                    name_str_sp = [name_str_sp(1:index_aou(k_aou)), 'E', name_str_sp(index_aou(k_aou)+1:end)]; 
                else
                    name_str_sp = [name_str_sp(1:index_aou(k_aou)), 'e', name_str_sp(index_aou(k_aou)+1:end)];
            end
            end
            
            name_str = join(name_str_sp(1:end),''); % get the new name of folder.
        end
    %end
    name_d_new(k) = name_str;
end
name_d_new = name_d_new';
name_d_old = string(name_d_old);
clear k k_aou k_letter; % recycle the RAM.

% rename the folder
current_path = pwd;
cd(r);
index_cmp = strcmp(name_d_old,name_d_new); % identify the name changed or not.
for k = 1:length(name_d_old)
    if index_cmp(k) == 0
       movefile(fullfile(r,name_d_old(k)), fullfile(r, name_d_new(k)));
    end
end
cd(current_path);




