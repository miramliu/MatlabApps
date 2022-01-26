function [] = DicomSort(varargin)
%Function to sort dicoms into new folders based on sequence
%This version uses dicominfo on every scan. it makes it slow, but reduces
%error that can be found when sorting specifically processed images (WIP)
%Inputs: none, user selects DICOM folder
%Outputs: none, creates DICOM_sorted folder in DICOM
%-------------------------------------------------------------------------
%
%Created by AH
%edited by Mira Liu, 1/13/22 for Mac.



warning('off','all')
foldName = varargin{1,1}; %input folder path to dicom directory. e.g. ('/Users/neuroimaging/Desktop/DICOM'
oldFold = cd(foldName);
cd ..
preDICOM = pwd;
DICOM = sprintf('%s//DICOM',preDICOM);
[status, msg, msgID] = mkdir('DICOM_sorted');
cd('DICOM_sorted')
SORTED = pwd;
dirInfo = dir(foldName);
scanTypePrev = 'NOTHING';
count = 0;
fprintf('Sorting in progress\n')

%Do all of the loose files first
for i = 3:length(dirInfo) %first 2 are '.' and '..'
    filePath = sprintf('%s//%s', foldName, dirInfo(i).name);
    if isdir(filePath) == 0 && strncmp(dirInfo(i).name, 'IM_',3) == 1
        %if filePath is not a folder && it contains the IM in name
        try
            scanInfo = dicominfo(filePath);
            scanType = scanInfo.SeriesDescription;
            try
                scanNumber = scanInfo.AcquisitionNumber;
            catch
                scanNumber = scanNumber;
            end
            if strcmp(scanType, scanTypePrev) == 0 %Meaning we need a new folder because the scan changed
                count = count + 1;
                cd(SORTED)
                if scanNumber < 10
                    newFolderName = sprintf('Scan 0%i %s', scanNumber, scanType);
                else
                    newFolderName = sprintf('Scan %i %s', scanNumber, scanType);
                end
                if length(strfind(newFolderName, '/')) > 0
                    ind = strfind(newFolderName, '/');
                    newFolderName(ind) = '_';
                elseif length(strfind(newFolderName, '*')) > 0
                    ind = strfind(newFolderName, '*');
                    newFolderName(ind) = '_';
                end
                mkdir(newFolderName)
                cd(newFolderName)
            end
            numFiles = length(dir) - 1;%number of files + 1 (because if there are two files, want this to be IM_0003
            numFilesStr = num2str(numFiles);
            if length(numFilesStr) == 1 && length(strfind(scanType, 'CVR')) == 1
                fileName = 'IM_0000';
            elseif (length(numFilesStr) == 2 && length(strfind(scanType, 'CVR')) == 1 )|| (length(numFilesStr) == 1 && length(strfind(scanType, 'CVR')) == 0)
                fileName = 'IM_000';
            elseif (length(numFilesStr) == 3 && length(strfind(scanType, 'CVR')) == 1 )|| (length(numFilesStr) == 2 && length(strfind(scanType, 'CVR')) == 0)
                fileName = 'IM_00';
            elseif (length(numFilesStr) == 4 && length(strfind(scanType, 'CVR')) == 1 )|| (length(numFilesStr) == 3 && length(strfind(scanType, 'CVR')) == 0)
                fileName = 'IM_0';
            elseif (length(numFilesStr) == 5 && length(strfind(scanType, 'CVR')) == 1 )|| (length(numFilesStr) == 4 && length(strfind(scanType, 'CVR')) == 0)
                fileName = 'IM_';
            end
            newFileNameNum = sprintf('%s%s.dcm', fileName, numFilesStr);
            %fprintf('Copying %s\n', filePath)
            %fprintf('Writing to %s//%s//%s\n', SORTED, newFolderName, newFileNameNum)
            copyfile(filePath, newFileNameNum);
            scanTypePrev = scanType;
        catch ME
            disp(['Error in copying ' filePath '. ' ME.message])
        end
    end
end


%if this is the folder
for i = 3:length(dirInfo) %first 2 are '.' and '..'
    filePath = sprintf('%s//%s', foldName, dirInfo(i).name);
    if isdir(filePath) == 1
        newDirInfo = dir(filePath);
        for j = 3:length(newDirInfo)
            dicomFilePath = sprintf('%s//%s',filePath, newDirInfo(j).name);
            if strncmp(newDirInfo(j).name, 'IM_',3) == 1
                try
                    scanInfo = dicominfo(dicomFilePath);
                    scanType = scanInfo.SeriesDescription;
                    try
                        scanNumber = scanInfo.AcquisitionNumber;
                    catch
                        scanNumber = scanNumber;
                    end
                    if strncmp(newDirInfo(j).name, 'IM_',3) == 1
                        if strcmp(newDirInfo(j).name, 'IM_00001') == 1
                            if strcmp(scanType, scanTypePrev) == 1
                                toGo = sprintf('%s//%s', SORTED, newFolderName);
                                cd(toGo)
                            else
                                count = count + 1;
                                if scanNumber < 10
                                    newFolderName = sprintf('Scan 0%i %s',scanNumber, newScanType);
                                else
                                    newFolderName = sprintf('Scan %i %s', scanNumber, newScanType);
                                end
                                cd(SORTED)
                                if length(strfind(newFolderName, '/')) > 0
                                    ind = strfind(newFolderName, '/');
                                    newFolderName(ind) = '_';
                                elseif length(strfind(newFolderName, '/')) > 0
                                    ind = strfind(newFolderName, '/');
                                    newFolderName(ind) = '_';
                                elseif length(strfind(newFolderName, '*')) > 0
                                    ind = strfind(newFolderName, '*');
                                    newFolderName(ind) = '_';
                                end
                                mkdir(newFolderName)
                                cd(newFolderName)
                            end
                        else
                            if strcmp(scanType, scanTypePrev) == 0
                                count = count + 1;
                                cd(SORTED)
                                if scanNumber < 10
                                    newFolderName = sprintf('Scan 0%i %s', scanNumber, scanType);
                                else
                                    newFolderName = sprintf('Scan %i %s', scanNumber, scanType);
                                end
                                if length(strfind(newFolderName, '/')) > 0
                                    ind = strfind(newFolderName, '/');
                                    newFolderName(ind) = '_';
                                elseif length(strfind(newFolderName, '/')) > 0
                                    ind = strfind(newFolderName, '/');
                                    newFolderName(ind) = '_';
                                elseif length(strfind(newFolderName, '*')) > 0
                                    ind = strfind(newFolderName, '*');
                                    newFolderName(ind) = '_';
                                end
                                mkdir(newFolderName)
                                cd(newFolderName)
                            end
                        end
                        numFiles = length(dir) - 1;%number of files + 1 (because if there are two files, want this to be IM_0003
                        numFilesStr = num2str(numFiles);
                        %                 if mod(numFiles, 1000) == 0
                        %                     pause(10)
                        %                 end
                        if length(numFilesStr) == 1 && length(strfind(scanType, 'CVR')) == 1
                            fileName = 'IM_0000';
                        elseif (length(numFilesStr) == 2 && length(strfind(scanType, 'CVR')) == 1 )|| (length(numFilesStr) == 1 && length(strfind(scanType, 'CVR')) == 0)
                            fileName = 'IM_000';
                        elseif (length(numFilesStr) == 3 && length(strfind(scanType, 'CVR')) == 1 )|| (length(numFilesStr) == 2 && length(strfind(scanType, 'CVR')) == 0)
                            fileName = 'IM_00';
                        elseif (length(numFilesStr) == 4 && length(strfind(scanType, 'CVR')) == 1 )|| (length(numFilesStr) == 3 && length(strfind(scanType, 'CVR')) == 0)
                            fileName = 'IM_0';
                        elseif (length(numFilesStr) == 5 && length(strfind(scanType, 'CVR')) == 1 )|| (length(numFilesStr) == 4 && length(strfind(scanType, 'CVR')) == 0)
                            fileName = 'IM_';
                        end
                        newFileNameNum = sprintf('%s%s.dcm', fileName, numFilesStr);
                        %fprintf('Copying %s\n', dicomFilePath)
                        %fprintf('Writing to %s//%s//%s\n', SORTED, newFolderName, newFileNameNum)
                        copyfile(dicomFilePath, newFileNameNum);
                        scanTypePrev = scanType;
                    end
                catch ME
                    disp(['Error in copying ' dicomFilePath '. ' ME.message])
                end
            end
        end
    end
end
fprintf('********Sorting Completed************\n')
cd(oldFold)




end

    