function [ stats ] = extractStats( image, class, radius ) 
% obliczamy dane statystyczne dla vokseli 3x3x3 lub 5x5x5 -> radius = 1 lub
% radius = 2

%% Pobranie wymiarów obrazu. 
[x, y, z] = size(image);

%% Obliczenie œredniej dla wokseli 
stats = cell(size(image));

for row = (radius + 1) : (x - radius)
    row
	for col = (radius + 1) : (y - radius)
        for vol = (radius + 1) : (z - radius)
            % sprawdzenie, czy piksel nie nalezy do t³a
            if class(row,col,vol) > 0     
                
                centerPixel = image(row, col, vol);
                block = image( row-radius:row+radius, col-radius:col+radius, vol-radius:vol+radius );
                
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
        end
	end  
end 

end                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             