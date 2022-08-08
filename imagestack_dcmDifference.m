% uses imagestack, first gets path to folder of dicoms, creates mat file, and then displays it in natural order of number
% specifically for difference between IVIM scans... 
function imagestack_dcmDifference(varargin)

fulltargetpath = varargin{1};
fulltargetpath2 = varargin{2};

Start_Index = 28;
Images_Per_Slice = 37;
Num_Bvals = 10;


if exist(fulltargetpath,'dir') 
    dcmdir = dir([fulltargetpath '/*.dcm']); %get all dcm files (in folder P00N)
    fprintf('Organizing dicoms %s ...\n',fulltargetpath)
    dcmdirsorted = {dcmdir.name};
    dcmdirsorted = natsortfiles(dcmdirsorted); %sort in order
    [nx,ny] = size(dicomread(string(fullfile(fulltargetpath,dcmdirsorted(1))))); %get image dimensions
    Imagenums = Num_Bvals*size(dcmdirsorted,2)/Images_Per_Slice; %want all b values per slice. (so for example 10 slices, 37 images per slice, 10 b values... want 10*10 images shown)
    threeDarray = zeros(nx,ny,Imagenums); %created empty 3d array of dicoms per slice
    threeDarray2 = zeros(nx,ny,Imagenums); %created empty 3d array of dicoms
    j = 0;
    for Islice = 1:size(dcmdirsorted,2)/Images_Per_Slice %for all slices 
        i1 = Images_Per_Slice*(Islice-1)+Start_Index; %37*(1-1)+28 = 28
        i2 = i1 + Num_Bvals-1;%28 + 10-1 = 
        for i = i1:i2 %for all of the dsc files
            j = j +1; %to keep count of image stack number
            imagepath = string(fullfile(fulltargetpath,dcmdirsorted(i))); %path to ith image
            image = dicomread(imagepath);
            threeDarray(:,:,j) = image;
            if exist(fulltargetpath2,'dir')
                dcmdir = dir([fulltargetpath2 '/*.dcm']); %get all dcm files (in folder P00N)
                dcmdirsorted = {dcmdir.name};
                dcmdirsorted = natsortfiles(dcmdirsorted); %sort in order
                for i = i1:i2 %for all of the dsc files
                    imagepath = string(fullfile(fulltargetpath2,dcmdirsorted(i))); %path to ith image
                    image = dicomread(imagepath);
                    threeDarray2(:,:,j) = image;
                end
            else
                error('target path %s not found', fulltargetpath2)
            end
        end
    end
else
    error('target path %s not found', fulltargetpath)
end
disp('Displaying imagestack')

ThreeDdiff = threeDarray-threeDarray2;
size(ThreeDdiff)
% now use imagestack to show this with a title, if given
if numel(varargin) ==3
    title = varargin{3};
    imagestack(ThreeDdiff,title)
else
    imagestack(ThreeDdiff)
end