function [present,ind]=isAreaPresent(labels,thisName)
%return 1 if area thisName is present
%ind contains the IDs that part of this area name

ind=[];
present=0;
for ii=1:length(labels.name)
    t=regexpi(labels.name{ii},['^',thisName]);

    if ~isempty(t)
        ind = [ind,labels.id(ii)];
        present=1;
    end
end

