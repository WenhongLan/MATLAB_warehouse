%% MultiPatient_JSReconScript
close all; clearvars; clc
%Never use # in filepath!
ParentFolder = 'H:\WenhongTestFolder\9Mouse\test_2_recon'; %highest folder containing all patient folder
MultiDataFolder=dir(ParentFolder);
MultiDataFolder = MultiDataFolder(cellfun(@(x) x==1, {MultiDataFolder.isdir})); %delete all no folder files e.g. xls
MultiDataFolder=MultiDataFolder(3:end); %delete '.' and '..' folder
for k=1:numel(MultiDataFolder)
    fprintf('[%2d]: %s\n',k,MultiDataFolder(k).name);
end

%% SELECT which scans to process
clc;
iSelectScans=[]; % []:= take all; [1 5 9]:= only specific
    if ~isempty(iSelectScans)
tmpMultiDataFolder=MultiDataFolder(iSelectScans);
    else
        tmpMultiDataFolder=MultiDataFolder;
    end
    
    fprintf('Selected Scans for Reconstruction\n');
for k=1:numel(tmpMultiDataFolder)
    fprintf('[%2d]: %s\n',k,tmpMultiDataFolder(k).name);
end
sMultiDataFolder=cellfun(@fullfile,{tmpMultiDataFolder.folder},{tmpMultiDataFolder.name},'UniformOutput',false);% generate FullPathFile

%%
for kp=1:numel(sMultiDataFolder)

    cd(sMultiDataFolder{kp}); %go into the selected patient folder

    % Read MultiParameterFile
    reconParamsFile=dir('MultiReconParam*.xlsx'); %or set direct name, must be in specific folder for patient
    iCell=readcell(reconParamsFile.name);

    reconParams={'FrameDuration','VRVersion','SensitivityMode','IterationSubset','PSF','ImageMatrix'};
    defaultReconParams={0,'VR20','MRD322',{'4,5'},1,440}; %FrameDuration 0 in excel is entire acquisition time

    nRecons=size(iCell,1)-1;
    for k=1:numel(reconParams) %set default rpm (reconparameter lookup struct)
        eval(['rpm.' reconParams{k} '=repmat(defaultReconParams{k},nRecons,1)'])
    end

    % this is to process the xlsx file (commented by wenlan)
    fieldNames=fields(rpm)
    for k=1:numel(fieldNames) %write xls recon params to lookup struct
        [~,ind]=find(strcmp(iCell,fieldNames{k})); %get index of colum matching field name
        if ind
            if strcmp(fieldNames{k},'IterationSubset') %this needs to be stored in cell array as 4,5 and 10,5 not the same char elements
             eval(['rpm.' fieldNames{k} '=iCell(2:end,ind)'])
            else
                eval(['rpm.' fieldNames{k} '=vertcat(iCell{2:end,ind})']) %this is either double or char array
            end
        end
    end

    % JSRecon processing (3.5min)
    DataFolder=sMultiDataFolder{kp};
    ForceJSRecon = 0;   % forced redo of JSRecon, even if already done
    % run JSRecon unless already run
    fdrconv= sprintf('%s-Converted',DataFolder);
    files = dir(fdrconv);
    if isempty(files) || ForceJSRecon
    paramsFile=dir([ParentFolder '\*JSRecon_params*.txt']); %find params file just take the first in there, its the same for all patients
    % paramsFile='JSRecon_params4i5sAllpass.txt' % or assign direct
    cmd = sprintf('!C:\\JSRecon12\\JSRecon12 %s %s',DataFolder,fullfile(paramsFile.folder,paramsFile.name)); %JSReconParams file must be in parent folder!
    eval(cmd);
    else
        fprintf('JSRecon already done...\n');
    end
    % - JSRecon Finished
    
    % Processing with Batch Files
    myWait=waitbar(0); elTime=0; %elapsed time
    tmp=dir([fdrconv '\*-LM-00*']);
    fdrlist = fullfile(fdrconv,tmp.name);
    cd(fdrlist); % move to the desired folder, ie the listmode folder
    tic
    for k=1:nRecons
        % Histogrammer (2min)
        file = dir('Run*Histogramming.bat');
        copyfile([file.folder '\' file.name],[file.folder '\tmpCopyHist.bat']);%create temporary copy of batch file
        writeDeleteExprToBatFile('tmpCopyHist.bat',['C:\Siemens\PET\bin.win64-' rpm.VRVersion(k,:)]); %VR Version
        
        if rpm.FrameDuration(k)==0 %get original acquistion duration
            tmpS=getExprFromBatFile([file.folder '\' file.name],'--frame');
            rpm.FrameDuration(k)=str2num(tmpS(find(tmpS==':')+1:end)); clearvars tmpS;
        end
        writeDeleteExprToBatFile('tmpCopyHist.bat',['--frame 0:' num2str(rpm.FrameDuration(k))]); %set frame duration
        cmd = sprintf('!%s','tmpCopyHist.bat');
        eval(cmd);
        
        % Make mumaps (9s)
        file = dir('Run*Makeumap.bat');
        cmd = sprintf('!%s',file.name);
        fprintf('%s\n',cmd);
        eval(cmd);
        
        % Recon PSFTOF (8min) 
        file = dir('Run*PSFTOF.bat');
        copyfile([file.folder '\' file.name],[file.folder '\tmpCopyPSFTOF.bat']);%create temporary copy of batch file
        
        writeDeleteExprToBatFile('tmpCopyPSFTOF.bat',['C:\Siemens\PET\bin.win64-' rpm.VRVersion(k,:)]); %VR Version
        
        if rpm.SensitivityMode(k,:)==85 %Sensitivity Mode
            writeDeleteExprToBatFile('tmpCopyPSFTOF.bat','--seg 9');
        end
        
        writeDeleteExprToBatFile('tmpCopyPSFTOF.bat',['--is ' rpm.IterationSubset{k,:}]); %IterationSubset
        
        if rpm.PSF(k)==0 %PSF enable/disable
            writeDeleteExprToBatFile('tmpCopyPSFTOF.bat','--psf','Delete',1);
        end
        
        writeDeleteExprToBatFile('tmpCopyPSFTOF.bat',['-w ' num2str(rpm.ImageMatrix(k))]); %ImageMatrix
        
         %set recon output file name
        itsub=rpm.IterationSubset{k,:}; %changed as cell array now used
        itsub=[strrep(itsub,',','i') 's']; %rename 4,5 to 4i5s 
        writeDeleteExprToBatFile('tmpCopyPSFTOF.bat',...
          sprintf('--oi %.0fs_%s_MRD%.0f_%s_PSF%.0f_size%.0f.mhdr',...
              rpm.FrameDuration(k), rpm.VRVersion(k,:),rpm.SensitivityMode(k),itsub,...
              rpm.PSF(k),rpm.ImageMatrix(k))) %create mhdr with parameter naming
        cmd = sprintf('!%s','tmpCopyPSFTOF.bat');
        fprintf('%s\n',cmd);
        
        eval(cmd); %run recon
 
        elTime=elTime+toc;
        waitbar(k/nRecons,myWait,sprintf('recon %.0f of %.0f in %.1f min ',k,nRecons,elTime/60));
        tic
    end
    
    % to DICOM when still in folder and all recons are completed
    file=dir('*.v.hdr')
    cond=~cellfun(@isempty,regexp({file.name},regexptranslate('wildcard','*umap*.v.hdr'))); %exclude u-maps
    file(cond)=[];
    % exclude already previously converted xx
    DICOMfolder=dir('*.v-DICOM')
    condDICOM=[];
    for k=1:numel(file)
        for m=1:numel(DICOMfolder)
            if strcmp(file(k).name(1:end-4),DICOMfolder(m).name(1:end-6))
    condDICOM=[condDICOM k];
            end
        end
    end
    file(condDICOM)=[];
    
    txtFile=dir('*-IF2Dicom.txt'); %thereplaceUmla
    replaceUmlautInFile([txtFile.folder '\' txtFile.name]); %here a Umlaut replacement in this file needs to be done otherwise DICOM cannot be read
    for k=1:numel(file)
        cmd = sprintf('!cscript C:\\JSRecon12\\IF2Dicom.js "%s" "%s"',[file(k).folder '\' file(k).name],[txtFile.folder '\' txtFile.name]);
        eval(cmd);      
    end
end
