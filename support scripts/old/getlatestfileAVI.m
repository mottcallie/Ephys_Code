function latestfile = getlatestfileAVI(directory)
%This function returns the latest AVI file from the directory passsed as input
%argument

%Get the directory contents
dirc = dir(directory);

%Filter for ONLY .avi files
dirc = dirc(find(contains({dirc.name},'.avi')));

%I contains the index to the biggest number which is the latest file
[A,I] = max([dirc(:).datenum]);

if ~isempty(I)
    latestfile = dirc(I).name;
end

end