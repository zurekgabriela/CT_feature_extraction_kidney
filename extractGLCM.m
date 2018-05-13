function [ GLCM_to_write ] = extractGLCM( image, class, radius ) 
% Gray Level Co-ocurrence Matrix dla ramki o wymiarach 2*radius + 1
% jeœli radius = 1 -> ramka jest szeœcianem o wymiarach 3 x 3 x 3

if ~isa(image,'numeric') || ~isa(class,'numeric') || ~isa(radius,'numeric')
    error('extractStats:InputMustBeNumeric', ...
        'Coefficients must be numeric.');
end

%% Pobranie wymiarów obrazu. 
% [x, y, z] = size(image);

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
[nonEmptyRow,nonEmptyCol,nonEmptyVol] = ind2sub(size(image),nonEmptyIdx);

%% Inicjalizacja komórki, do której bêd¹ pobierane wartoœci GLCM za pomoc¹ wartoœci NaN
GLCM = cell(size(image));

for i = 1 : length(nonEmptyIdx)
    row = nonEmptyRow(i);
    col = nonEmptyCol(i);
    vol = nonEmptyVol(i);

    centerPixel = image(row, col, vol);
    block = image( row-radius:row+radius, col-radius:col+radius, vol );  
    
    % Obliczenie GLCM dla ramki
    GLCM_small = graycomatrix(block);                
    Graycoprops = graycoprops(GLCM_small, {'all'});

    % Kontrast
    Contrast = Graycoprops.Contrast;

    % Korelacja
    Correlation = Graycoprops.Correlation;

    % Energia
    Energy = Graycoprops.Energy;

    % Jednorodnoœæ
    Homogeneity = Graycoprops.Homogeneity;

    % Dane GLCM wpisane do wektora
    GLCM{row, col, vol} = [Contrast Correlation Energy Homogeneity];                             

end 

% przekszta³cenie stats z komórki do wektora
GLCM_to_write = [GLCM{nonEmptyIdx}];
GLCM_to_write = reshape(GLCM_to_write,[4,length(GLCM_to_write)/4])';

end

