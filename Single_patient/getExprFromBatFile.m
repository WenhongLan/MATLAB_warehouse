function [outExpr] = getExprFromBatFile(batFile,expr)
%Get Command from Batch file
%Example call flag: getExprFromBatFile('C:\PathToFile\File.bat','--fltr 4,5')
fid=fopen(batFile,'r');
tmp=textscan(fid,'%s','delimiter','\n'); %scan batch file to rows
txtArray=tmp{1};
outExpr=0;
command=regexp(expr,'--[a-zA-z]*','match'); %get the command e.g. --fltr without the parameters but whitespace at the end
command=[command{:} ' ']; %add white space for regexp fit e.g. that --f does not trigger --fltr

for k=1:size(txtArray,1) %loop over batch file lines
    
    iscommand=regexp(txtArray(k),command);
    if ~isempty(iscommand{:}) %if the command is already existing it will be replaced
        outExpr=txtArray{k};
        break;
    end
end
fclose(fid);
end

