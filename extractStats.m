function [ stats ] = extractStats( image, class, radius ) 
% obliczamy dane statystyczne dla wokseli w ramce o wymiarze (radius x 2 + 1)
% radius = 1 -> ramka jest szeœcianem o wymiarach 3 x 3 x 3

%% Pobranie wymiarów obrazu. 
[x, y, z] = size(image);

%% Inicjalizacja komórki, do której bêdzie pobierany wektor z danymi statystycznymi
stats = cell(size(image));

for row = (radius + 1) : (x - radius)
    row
	for col = (radius + 1) : (y - radius)
        for vol = (radius + 1) : (z - radius)
            
            % sprawdzenie, czy badany woksel nie nale¿y do t³a
            if class(row,col,vol) > 0     
                
                % pobranie ramki z obrazu dla kolejnych indeksów
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