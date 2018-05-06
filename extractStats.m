function [ stats_to_write ] = extractStats( image, class, margin ) 
% obliczamy dane statystyczne dla wokseli w ramce o wymiarze (margin x 2 + 1)
% margin = 1 -> ramka jest szeœcianem o wymiarach 3 x 3 x 3, minimalny
% margin = 0

if ~isa(image,'numeric') || ~isa(class,'numeric') || ~isa(margin,'numeric')
    error('extractStats:InputMustBeNumeric', ...
        'Coefficients must be numeric.');
end

%% Pobranie wymiarów obrazu.

image = cat(3, repmat(image(:,:,1), 1, 1, margin), image);
image = cat(3, image, repmat(image(:, :, size( image, 3 )), 1, 1, margin));
image = cat(2, repmat(image(:,1,:), 1, margin, 1), image);
image = cat(2, image, repmat(image(:, size( image, 2 ), :), 1, margin, 1));
image = cat(1, repmat(image(1,:,:), margin, 1, 1), image);
image = cat(1, image, repmat(image(size( image, 1 ), :, :), margin, 1, 1));

class = cat(3, repmat(class(:,:,1), 1, 1, margin), class);
class = cat(3, class, repmat(class(:, :, size( class, 3 )), 1, 1, margin));
class = cat(2, repmat(class(:,1,:), 1, margin, 1), class);
class = cat(2, class, repmat(class(:, size( class, 2 ), :), 1, margin, 1));
class = cat(1, repmat(class(1,:,:), margin, 1, 1), class);
class = cat(1, class, repmat(class(size( class, 1 ), :, :), margin, 1, 1));

nonEmptyIdx = find(~(class == 0));
[nonEmptyRow,nonEmptyCol,nonEmptyVol] = ind2sub(size(image),nonEmptyIdx);

%% Inicjalizacja komórki, do której bêdzie pobierany wektor z danymi statystycznymi
stats = cell(size(image));
% stats(find(cellfun(@isempty, stats))) = {[0 0 0 0 0]};

for i = 1 : length(nonEmptyIdx)
    i
    row = nonEmptyRow(i);
    col = nonEmptyCol(i);
    vol = nonEmptyVol(i);

    % pobranie ramki z obrazu dla kolejnych indeksów
    block = image( row-margin:row+margin, col-margin:col+margin, vol-margin:vol+margin );

    % Œrednia
    Mean = mean(mean(mean(block)));

    % Odchylenie standardowe
    StandardDev = std(std(std(block)));

    % Entropia
    Entropy = entropy(block);

    % Asymetria
    Skewness = skewness(skewness(skewness(block)));

    % Rozproszenie
    Kurtosis = kurtosis(kurtosis(kurtosis(block)));        

    % Dane statystyczne w wektorze 
    stats{row, col, vol} = [Mean StandardDev Entropy Kurtosis Skewness];    
end 

% przekszta³cenie stats z komórki do wektora
stats_to_write = [stats{nonEmptyIdx}];
stats_to_write = reshape(stats_to_write,[5,length(stats_to_write)/5])';

end                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             