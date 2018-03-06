function VolumeData = imread_RawData(filename, nx, ny, nz, dataType, varargin)

% This function is to read raw data
%   VolumeData = imread_RawData(filename, nx, ny, nz, dataType)
%   VolumeData = imread_RawData(filename, nx, ny, nz, dataType, header_length)
%
% INPUT:
%   filename -  the file name and path
%   [nx, ny, nz] - dimensions
%   dataType - {uint8, uint16,}
%   header_length 
%
% OUTPUT:
%   VolumeData  
%
% Notes:
%   the X and Y might be transposed.
%

if ~ischar(filename) | ~ischar(dataType) 
    error(' Require the filename and dataType in char');
end
if any([nx ny nz] <= 0)
    error(' the length in each dimension cannot be less than and equal to 0 ..');
end

if length(varargin)>1
    error(' only support for 6 parameter');
else
    if length(varargin) == 1
        header_length = varargin{1};
        if header_length < 0
            header_length = 0;
            warning('header_length cannot be negative, it has been forced to 0');
        end
    else
        header_length = 0;
    end
end

fid = fopen(filename,'rb');
if fid == -1
    error(['Cannot open the file: ' filename]);
else
    header = fread(fid, header_length, 'uchar');
    [VolumeData, Count] = fread(fid, nx*ny*nz, dataType);
    if strcmpi(dataType,'uint8')
        VolumeData = reshape(uint8(VolumeData), nx, ny, nz);
    elseif strcmpi(dataType, 'uint16')
        VolumeData = reshape(uint16(VolumeData), nx, ny, nz);
    elseif strcmpi(dataType, 'uchar')
        VolumeData = reshape(uchar(VolumeData), nx, ny, nz);
    elseif strcmpi(dataType, 'single')  
        VolumeData = reshape(single(VolumeData), nx, ny, nz);
    else
        VolumeData = reshape(VolumeData, nx, ny, nz);
    end      
end

fclose(fid);
