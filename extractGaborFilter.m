function [ features ] = extractGaborFilter( image, nonEmptyRow, nonEmptyCol, nonEmptyVol ) 
%%
image = (single(image));

nonEmptyVolsingle = nonEmptyVol(diff([0 nonEmptyVol'])~=0);

% design gabor filter bank
[numRows, numCols, ~] = size(image);

wavelengthMin = 4/sqrt(2);
wavelengthMax = hypot(numRows,numCols);
n = floor(log2(wavelengthMax/wavelengthMin));
wavelength = 2.^(0:(n-2)) * wavelengthMin;

deltaTheta = 45;
orientation = 0:deltaTheta:(180-deltaTheta);

g = gabor(wavelength,orientation);

% do obliczenia statystyk bierzemy bloki 3x3
radius = 1;
features = [];

for i = 1 : size(nonEmptyVolsingle, 1);
    vol = nonEmptyVolsingle(i);
    vol
    % obliczenie indeksów od 1 do ...
    idx = find(nonEmptyVol == vol);
    
    % extract Gabor magnitude features from source image. 
    GaborMag = imgaborfilt( image(:,:,vol), g );
    GaborMagStats = cell(size(image, 1), size(image, 2));

    % obliczenie statystyk z ka¿dego przefiltrowanego przekroju w
    % zale¿noœci od filtra -> 56 features
    tic
    for row = (1 + radius) : (size(GaborMag, 1) - radius)
        for col = (1 + radius) : (size(GaborMag, 2) - radius)
            stats_vec = zeros(1, size(g,2)*2);
            for i = 1 : size(g,2) 
                stats_vec(1,i*2-1) =  mean(mean(GaborMag( row-radius:row+radius, col-radius:col+radius, i )));
                stats_vec(1,i*2) = std(std(GaborMag( row-radius:row+radius, col-radius:col+radius, i )));
            end
            GaborMagStats{row, col} = stats_vec;
        end
    end
    toc
            
    linearVol = sub2ind([ size(GaborMag,1), size(GaborMag,2)], nonEmptyRow(idx),nonEmptyCol(idx));
    toWrite = [GaborMagStats{linearVol}];
    features = [features; reshape(toWrite,[56,length(toWrite)/(56)])'];      
end
    
end


