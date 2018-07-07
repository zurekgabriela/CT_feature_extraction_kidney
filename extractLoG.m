function [ features ] = extractLoG( image, class, radius ) 

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
features = [];

%%
for i = 1 : size(nonEmptyVolsingle, 1);
    vol = nonEmptyVolsingle(i);
    vol
 
    %% obliczenie indeksów od 1 do ...
    idx = find(nonEmptyVol == vol);

    %% Laplacian of Gaussian
    width = [0.25 0.50 1 2];
    hsize = size(image,1);
    LoGArray = zeros(size(image,1), size(image,2), size(width, 2));
    for j = 1 : size(width, 2)
        % Filtrowanie obrazu w zale¿noœci od orientacji i szerokoœci
        filter = fspecial('log', hsize, width(j));
        LoG = imfilter(image(:,:,vol),filter);
        LoGArray(:,:,j) = LoG;
    end
        
    %% obliczenie statystyk z ka¿dego przefiltrowanego przekroju w
    % zale¿noœci od filtra -> 16 features - œrednia, odchylenie, asymetria,
    % rozproszenie
    tic
    LoGStats = cell(size(image, 1), size(image, 2));
    for row = (1 + radius) : (size(image, 1) - radius)
        for col = (1 + radius) : (size(image, 2) - radius)
            stats_vec = zeros(1, size(width,2)*4);
            for k = 1 : size(width,2) 
                stats_vec(1,k*4-3) =  mean(mean(LoGArray( row-radius:row+radius, col-radius:col+radius, k )));
                stats_vec(1,k*4-2) = std(std(LoGArray( row-radius:row+radius, col-radius:col+radius, k )));
                stats_vec(1,k*4-1) = skewness(skewness(LoGArray( row-radius:row+radius, col-radius:col+radius, k )));
                stats_vec(1,k*4) = kurtosis(kurtosis(LoGArray( row-radius:row+radius, col-radius:col+radius, k )));
            end
            LoGStats{row, col} = stats_vec;
        end
    end
    toc
    %%        
    linearVol = sub2ind([ size(LoGArray,1), size(LoGArray,2)], nonEmptyRow(idx), nonEmptyCol(idx));
    toWrite = [LoGStats{linearVol}];
    features = [features; reshape(toWrite,[size(width,2)*4,length(toWrite)/(size(width,2)*4)])']; 

end
    
end

% sigma = 30;
% G1 = fspecial('log',[round(6*sigma), round(6*sigma)], sigma);
% [X,Y] = meshgrid(1:size(G1,2), 1:size(G1,1));
% mesh(X, Y, G1);
% xlabel('X'); ylabel('Y'); zlabel('Amplitude');
% title('3D visualization of the LoG filter');
% colorbar;


