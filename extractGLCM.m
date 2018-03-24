function [ GLCM ] = extractGLCM( image, class, radius ) 
% Gray Level Co-ocurrence Matrix dla ramki o wymiarach 2*radius + 1
% je�li radius = 1 -> ramka jest sze�cianem o wymiarach 3 x 3 x 3

%% Pobranie wymiar�w obrazu. 
[x, y, z] = size(image);

%% Inicjalizacja kom�rki, do kt�rej b�d� pobierane warto�ci GLCM za pomoc� warto�ci NaN
GLCM = cell(size(image));
GLCM(find(cellfun(@isempty, GLCM))) = {[nan nan nan nan]};

for vol = (radius + 1) : (z - radius)
    vol
	for col = (radius + 1) : (y - radius)
        for row = (radius + 1) : (x - radius)  
            
            % sprawdzenie, czy piksel nie nalezy do t�a
            if class(row,col,vol) > 0     
                
                centerPixel = image(row, col, vol);
                block = image( row-radius:row+radius, col-radius:col+radius, vol );  
                % Obliczenie GLCM dla ramki
                GLCM = graycomatrix(block);                
                Graycoprops = graycoprops(GLCM, {'all'});
                
                % Kontrast
                Contrast = Graycoprops.Contrast;
                
                % Korelacja
                Correlation = Graycoprops.Correlation;
                
                % Energia
                Energy = Graycoprops.Energy;
                
                % Jednorodno��
                Homogeneity = Graycoprops.Homogeneity;
                               
                % Dane GLCM wpisane do wektora
                GLCM{row, col, vol} = [Contrast Correlation Energy Homogeneity];                             
            end
        end
	end  
end 

end

