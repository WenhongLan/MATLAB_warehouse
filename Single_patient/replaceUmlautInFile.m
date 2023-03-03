function [] = replaceUmlautInFile(mfile)
%replaces all Umlaute in txt file
%mfile : 'C:\Users\Quadra\Desktop\TEst.txt'


fid=fopen(mfile,'r');
tmp=textscan(fid,'%s','delimiter','\n'); %scan batch file to rows
txtArray=tmp{1};

    for k=1:size(txtArray,1) %loop over batch file lines
        
        
txtArray{k} = strrep(txtArray{k}, 'ä', 'ae');
txtArray{k} = strrep(txtArray{k}, 'ü', 'ue');
txtArray{k} = strrep(txtArray{k}, 'ö', 'oe');
txtArray{k} = strrep(txtArray{k}, 'Ä', 'Ae');
txtArray{k} = strrep(txtArray{k}, 'Ü', 'Ue');
txtArray{k} = strrep(txtArray{k}, 'Ö', 'Oe');
    end
 fclose(fid);
    fid=fopen(mfile,'w');
    fprintf(fid,'%s\n',txtArray{:});
    fclose(fid);
end

