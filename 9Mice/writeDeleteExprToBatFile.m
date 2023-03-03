function [] = writeDeleteExprToBatFile(batFile,expr,varargin)
%WRITEPARAMETERTOBATCHFILE
%Add command to the batch file
%Example call flag: writeExprToBatFile('C:\PathToFile\File.bat','--fltr 4,5')
%Example call VR Version writeExprToBatFile([file.folder '\' file.name],['C:\Siemens\PET\bin.win64-' VR20]);
%Example call for changing name of output File writeExprToBatFile('C:\PathToFile\File.bat','--oi NewName.mhdr')

%Added Delete feature
%Example call delete psf flag writeExprToBatFile('C:\PathToFile\File.bat','--psf','Delete',1)
%Added feature for -- and - flags, which was not supported in previous
%version
p=inputParser;
addParameter(p,'Delete',0,@isnumeric)
parse(p,varargin{:});


fid=fopen(batFile,'r');
tmp=textscan(fid,'%s','delimiter','\n'); %scan batch file to rows
txtArray=tmp{1};
% expr='--mat (2,3,4,5) '; %the expression to search for
if expr(1)=='-'
    %old
    %command=regexp(expr,'-[a-zA-z]*','match'); %get the command e.g. --fltr without the parameters but whitespace at the end
    %command=[command{:} ' ']; %add white space for regexp fit e.g. that --f does not trigger --fltr
    
    command=regexp(expr,'-+[a-zA-z]*','match'); %get the command e.g. --fltr without the parameters but whitespace at the end
    command=command{1};
    
    for k=1:size(txtArray,1) %loop over batch file lines
        
        iscommand=regexp(txtArray(k),command);
        ispushd=regexp(txtArray(k),'pushd');
        if ~isempty(iscommand{:}) %if the command is already existing it will be replaced (or deleted)
            lineInd=k;
            fprintf('Old (L:%.0f) %s\n',lineInd,txtArray{lineInd});
            if p.Results.Delete==1
            txtArray{lineInd}=[]; 
            else
            txtArray{lineInd}=['set cmd= %cmd% ' expr];
            end
            fprintf('New (L:%.0f) %s\n',lineInd,txtArray{lineInd});
            break;
            
        elseif ~isempty(ispushd{:}) %if the command is not existing it will be added before the pushd command
            lineInd=k;
            tmptxtArray=txtArray;
            txtArray{lineInd-1}=['set cmd= %cmd% ' expr];
            [txtArray{lineInd:(numel(txtArray)+1)}]=deal(tmptxtArray{lineInd-1:numel(tmptxtArray)}); %old lines after the new expression are shifte by 1
            break;
        end
    end
    
elseif regexp(expr,'C:\\Siemens\\PET\\bin.win64-*') %if not a -- flag is passed but instead  the version of bin.win64-VR10
    if expr(end)=='\' %take care if accidently a '\' is passed
        expr(end)=[];
    end
    for k=1:size(txtArray,1) %loop over batch file lines
        
        isline=regexp(txtArray(k),'C:\\Siemens\\PET\\bin.win64-*');
        if ~isempty(isline{:})
            tmpExpr=txtArray(k);
            myExprOld=tmpExpr{1};
            %           startReplace=strfind(myExpr,'\bin.win')+1;
            stopReplace=max(strfind(myExprOld,'\'));%'set cmd= C:\Siemens\PET\bin.win64-VR20\e7_histogramming'
            txtArray{k}=['set cmd= ' expr myExprOld(stopReplace:end)];
        end
    end
    
    
   
    
end
 fclose(fid);
    fid=fopen(batFile,'w');
    fprintf(fid,'%s\n',txtArray{:});
    fclose(fid);
end

