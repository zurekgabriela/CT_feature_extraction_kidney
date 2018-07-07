function [ features ] = extractGaborFilter( image, class, radius ) 
%% Pobranie wymiarów obrazu.

image = cat(3, repmat(image(:,:,1), 1, 1, radius), image);
image = cat(3, image, repmat(image(:, :, size( image, 3 )), 1, 1, radius));
image = cat(2, repmat(image(:,1,:), 1, radius, 1), image);
image = cat(2, image, repmat(image(:, size( image, 2 ), :), 1, radius, 1));
image = cat(1, repmat(image(1,:,:), radius, 1, 1), image);
image = cat(1, image, repmat(image(size( image, 1 ), :, :), radius, 1, 1));

class = cat(3, repmat(class(:,:,1), 1, 1, radius), class);
class = cat(3, class, repmat(class(:, :, size( class, 3 )), 1, 1, radius));
class = cat(2, repmat(class(:,1,:), 1, radius, 1), class);
class = cat(2, class, repmat(class(:, size( class, 2 ), :), 1, radius, 1));
class = cat(1, repmat(class(1,:,:), radius, 1, 1), class);
class = cat(1, class, repmat(class(size( class, 1 ), :, :), radius, 1, 1));

nonEmptyIdx = find(~(class == 0));
[nonEmptyRow, nonEmptyCol, nonEmptyVol] = ind2sub(size(image),nonEmptyIdx);

nonEmptyVolsingle = nonEmptyVol(diff([0 nonEmptyVol'])~=0);

%% Design gabor filter bank
[numRows, numCols, ~] = size(image);

wavelengthMin = 4/sqrt(2);
wavelengthMax = hypot(numRows,numCols);
n = floor(log2(wavelengthMax/wavelengthMin));
wavelength = 2.^(0:(n-2)) * wavelengthMin;

deltaTheta = 45;
orientation = 0:deltaTheta:(180-deltaTheta);

g = gabor(wavelength,orientation);

%% Do obliczenia statystyk bierzemy bloki 3x3
features = [];

for i = 1 : size(nonEmptyVolsingle, 1);
    vol = nonEmptyVolsingle(i);
    vol
 
    %% obliczenie indeksów od 1 do ...
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
            for j = 1 : size(g,2) 
                stats_vec(1,j*2-1) = mean(mean(GaborMag( row-radius:row+radius, col-radius:col+radius, j )));
                stats_vec(1,j*2) = std(std(GaborMag( row-radius:row+radius, col-radius:col+radius, j )));
            end
            GaborMagStats{row, col} = stats_vec;
        end
    end
    toc
    
    %% Zapisanie cech do wektora
    linearVol = sub2ind([ size(GaborMag,1), size(GaborMag,2)], nonEmptyRow(idx), nonEmptyCol(idx));
    toWrite = [GaborMagStats{linearVol}];
    features = [features; reshape(toWrite,[size(g,2)*2,length(toWrite)/(size(g,2)*2)])'];      
    
end

end


