% uses imagestack, first gets path to folder of dicoms, creates mat file, and then displays it in natural order of number

function imagestack_dcm(varargin)

fulltargetpath = varargin{1};


if exist(fulltargetpath,'dir')
    dcmdir = dir([fulltargetpath '/*.dcm']); %get all dcm files (in folder P00N)
    fprintf('Organizing dicoms %s ...\n',fulltargetpath)
    dcmdirsorted = {dcmdir.name};
    dcmdirsorted = natsortfiles(dcmdirsorted); %sort in order
    [nx,ny] = size(dicomread(string(fullfile(fulltargetpath,dcmdirsorted(1))))); %get image dimensions
    threeDarray = zeros(nx,ny,size(dcmdirsorted,2)); %created empty 3d array of dicoms
    for i = 1:size(dcmdirsorted,2) %for all of the dsc files
        imagepath = string(fullfile(fulltargetpath,dcmdirsorted(i))); %path to ith image
        image = dicomread(imagepath);
        threeDarray(:,:,i) = image;
    end
else
    error('target path %s not found', fulltargetpath)
end
disp('Displaying imagestack')


% now use imagestack to show this with a title, if given
if numel(varargin) ==2
    title = varargin{2};
    imagestack(threeDarray,title)
else
    imagestack(threeDarray)
end