function [ features ] = extractLoG( image, nonEmptyRow, nonEmptyCol, nonEmptyVol ) 

image = (single(image)); 
nonEmptyVolsingle = nonEmptyVol(diff([0 nonEmptyVol'])~=0);
nonEmptyVolfirst = nonEmptyVol(1);
features = [];

%% do obliczenia statystyk bierzemy bloki 3x3
radius = 2;

for vol = nonEmptyVolsingle(1) : nonEmptyVolsingle(end)
    vol
    % obliczenie indeksów od 1 do ...
    idx = find(nonEmptyVol == nonEmptyVolsingle(vol+1-nonEmptyVolfirst));
    
    % Laplacian of Gaussian
    width = [0.25 0.50 1 2];
    hsize = size(image,1);
    LoGArray = zeros(size(image,1), size(image,2), size(width, 2));
    for i = 1 : size(width, 2)
        % Filtrowanie obrazu w zale¿noœci od orientacji i szerokoœci
        filter = fspecial('log', hsize, width(i));
        LoG = imfilter(image(:,:,vol),filter);
        LoGArray(:,:,i) = LoG;
    end
        
    %% obliczenie statystyk z ka¿dego przefiltrowanego przekroju w
    % zale¿noœci od filtra -> 16 features - œrednia, odchylenie, asymetria,
    % rozproszenie
    tic
    LoGStats = cell(size(image, 1), size(image, 2));
    for row = (1 + radius) : (size(image, 1) - radius)
        for col = (1 + radius) : (size(image, 2) - radius)
            stats_vec = zeros(1, size(width,2)*4);
            for i = 1 : size(width,2) 
                stats_vec(1,i*4-3) =  mean(mean(LoGArray( row-radius:row+radius, col-radius:col+radius, i )));
                stats_vec(1,i*4-2) = std(std(LoGArray( row-radius:row+radius, col-radius:col+radius, i )));
                stats_vec(1,i*4-1) = skewness(skewness(LoGArray( row-radius:row+radius, col-radius:col+radius, i )));
                stats_vec(1,i*4) = kurtosis(kurtosis(LoGArray( row-radius:row+radius, col-radius:col+radius, i )));
            end
            LoGStats{row, col} = stats_vec;
        end
    end
    toc
            
    linearVol = sub2ind([ size(LoGArray,1), size(LoGArray,2)], nonEmptyRow(idx),nonEmptyCol(idx));
    toWrite = [LoGStats{linearVol}];
    features = [features; reshape(toWrite,[size(width,2)*4,length(toWrite)/(size(width,2)*4)])'];      
end
    
end


