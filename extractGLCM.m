function [ stats ] = extractGLCM( image, class, radius ) 
% obliczamy dane statystyczne dla vokseli 3x3x3 lub 5x5x5 -> radius = 1 lub
% radius = 2

%% Pobranie wymiarów obrazu. 
[x, y, z] = size(image);

%% Obliczenie œredniej dla wokseli 
stats = cell(size(image));
stats(find(cellfun(@isempty,stats))) = {[nan nan nan nan]};

for vol = (radius + 1) : (z - radius)
    vol
	for col = (radius + 1) : (y - radius)
        for row = (radius + 1) : (x - radius)       
            % sprawdzenie, czy piksel nie nalezy do t³a
            if class(row,col,vol) > 0     
                
                centerPixel = image(row, col, vol);
                block = image( row-radius:row+radius, col-radius:col+radius, vol );               
                GLCM = graycomatrix(block);                
                Graycoprops = graycoprops(GLCM, {'all'});
                
                % Kontrast
                Contrast = Graycoprops.Contrast;
                
                % Korelacja
                Correlation = Graycoprops.Correlation;
                
                % Energia
                Energy = Graycoprops.Energy;
                
                % Jednorodnoœæ
                Homogeneity = Graycoprops.Homogeneity;
                               
                % Dane statystyczne w wektorze
                stats{row, col, vol} = [Contrast Correlation Energy Homogeneity];                             
            end
        end
	end  
end 

end

