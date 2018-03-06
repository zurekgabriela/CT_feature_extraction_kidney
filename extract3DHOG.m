function [ HOGimage ] = extract3DHOG( image, class, radius ) 
% extract Histogram of Oriented Gradients from each voksel
% Radius of circular pattern used to select neighbors for each pixel in the input image

% % Oliczamy gradient wzgl�dem ka�dego piksela
% [gx, gy, gz] = gradient(single(image));
% gx = -gx;
% gy = -gy;
% gz = -gz;
% 
% % Obliczamy norm� z gradient�w
% gradient_norm = sqrt(gx.^2 + gy.^2 + gz.^2);

% Liczba bin�w w histogramie
SectionNum = 9;

% Inicjalizacja danych wyj�ciowych
HOGimage = cell(size(image));

% Przechodzimy przez ca�y du�y obraz
for row = (1 + radius) : (size(image, 1) - radius)
    row
	for col = (1 + radius) : (size(image, 2) - radius)
        for vol = (1 + radius) : (size(image, 3) - radius)
            
            % sprawdzenie, czy piksel nie nalezy do t�a
            if class(row,col,vol) > 0
                
                % Sprawdzany piksel
                centerPixel = image(row, col, vol);

                % Tworzymy sze�cian dooko�a badanego piksela
                CubicImage = image(row-radius:row+radius, col-radius:col+radius, vol-radius:vol+radius);
%                 CubicGradientNorm = gradient_norm(row-radius:row+radius, col-radius:col+radius, vol-radius:vol+radius);
%                 cubic_gx = gx(row-radius:row+radius, col-radius:col+radius, vol-radius:vol+radius);
%                 cubic_gy = gy(row-radius:row+radius, col-radius:col+radius, vol-radius:vol+radius);
%                 cubic_gz = gz(row-radius:row+radius, col-radius:col+radius, vol-radius:vol+radius);

                [cubic_gx, cubic_gy, cubic_gz] = gradient(CubicImage);
                CubicGradientNorm = sqrt(cubic_gx.^2 + cubic_gy.^2 + cubic_gz.^2);
                
                bins_acos = zeros(size(CubicImage));
                bins_atan = zeros(size(CubicImage));
                hog_bins_acos_h = zeros(size(CubicImage));
                hog_bins_atan_h = zeros(size(CubicImage));
                hog_bins_acos_l = zeros(size(CubicImage));
                hog_bins_atan_l = zeros(size(CubicImage));
                hog_mod_acos_h = zeros(size(CubicImage));
                hog_mod_atan_h = zeros(size(CubicImage));
                hog_mod_acos_l = zeros(size(CubicImage));
                hog_mod_atan_l = zeros(size(CubicImage));
                hog_bins_valid = zeros(size(CubicImage));
                histogram_atan = zeros(1,9);
                histogram_acos = zeros(1,9);

                % Liczymy k�ty (orientacj�) ka�dego piksela w sze�cianie
                for r = 1:size(CubicImage, 1)
                    for c = 1:size(CubicImage, 2)
                        for v = 1:size(CubicImage, 3)
                            
                            % sprawdzamy, czy kt�re� z gradient�w nie s� r�wne 0
                            if cubic_gx(r, c, v) ~= 0 || cubic_gy(r, c, v) ~= 0 || cubic_gz(r, c, v) ~= 0
                                % Obliczamy arccosinus i arctangens w
                                % radianach i dzielimy przez liczb�
                                % przedzia��w
                                bin_raw_acos = acos(cubic_gz(r, c, v)/CubicGradientNorm(r, c, v))*SectionNum/pi;
                                bin_raw_atan = atan2(cubic_gx(r, c, v), cubic_gy(r, c, v))*SectionNum/pi;
                                
                                bins_acos(r, c, v) = bin_raw_acos;
                                bins_atan(r, c, v) = bin_raw_atan;                                
                                if bin_raw_acos > 0 || bin_raw_atan > 0                                    
                                    bin_mod_acos = bin_raw_acos;
                                    bin_mod_atan = bin_raw_atan;
                                    
                                    % Sprawdzamy przedzia� w�a�ciwy naszemu
                                    % k�towi
                                    hog_bins_acos_h(r, c, v) = mod(round(bin_raw_acos), SectionNum);
                                    hog_bins_atan_h(r, c, v) = mod(round(bin_raw_atan), SectionNum);
                                    % sprawdzamy drugi przedzia� bliski
                                    % naszemu k�towi
                                    hog_bins_acos_l(r, c, v) = mod(round(bin_raw_acos)-1, SectionNum);
                                    hog_bins_atan_l(r, c, v) = mod(round(bin_raw_atan)-1, SectionNum);
                                    
                                    % obliczamy modulu, o ktore bedzie
                                    % powiekszony histogram - procentowo
                                    hog_mod_acos_h(r, c, v) = (bin_mod_acos - round(bin_raw_acos - 1) - 0.5)*CubicGradientNorm(r, c, v);
                                    hog_mod_atan_h(r, c, v) = (bin_mod_atan - round(bin_raw_atan - 1) - 0.5)*CubicGradientNorm(r, c, v);
                                    
                                    hog_mod_acos_l(r, c, v) = (round(bin_raw_acos)- bin_mod_acos + 0.5)*CubicGradientNorm(r, c, v);                            
                                    hog_mod_atan_l(r, c, v) = (round(bin_raw_atan) - bin_mod_atan + 0.5)*CubicGradientNorm(r, c, v);                                   
                                else                                    
                                    bin_mod_acos = bin_raw_acos + 9;
                                    bin_mod_atan = bin_raw_atan + 9;
                                    
                                    % Sprawdzamy przedzia� w�a�ciwy naszemu
                                    % k�towi
                                    hog_bins_acos_h(r, c, v) = mod(round(bin_raw_acos + 9), SectionNum);
                                    hog_bins_atan_h(r, c, v) = mod(round(bin_raw_atan + 9), SectionNum);
                                    % sprawdzamy drugi przedzia� bliski
                                    % naszemu k�towi
                                    hog_bins_acos_l(r, c, v) = mod(round(bin_raw_acos + 8), SectionNum);
                                    hog_bins_atan_l(r, c, v) = mod(round(bin_raw_atan + 8), SectionNum);
                                    
                                    % obliczamy modulu, o ktore bedzie
                                    % powiekszony histogram - procentowo
                                    hog_mod_acos_h(r, c, v) = (bin_mod_acos - round(bin_raw_acos + 8) - 0.5)*CubicGradientNorm(r, c, v);
                                    hog_mod_atan_h(r, c, v) = (bin_mod_atan - round(bin_raw_atan + 8) - 0.5)*CubicGradientNorm(r, c, v);
                                    
                                    hog_mod_acos_l(r, c, v) = (round(bin_raw_acos + 9)- bin_mod_acos + 0.5)*CubicGradientNorm(r, c, v);                            
                                    hog_mod_atan_l(r, c, v) = (round(bin_raw_atan + 9) - bin_mod_atan + 0.5)*CubicGradientNorm(r, c, v);                                    
                                end 
                                
                                % sprawdzamy, czy dane do histogramu
                                % zosta�y obliczone
                                hog_bins_valid(r, c, v) = 1;                                
                            else
                                hog_bins_valid(r, c, v) = 0;
                                hog_bins_acos_l(r, c, v) = 10;
                                hog_bins_atan_l(r, c, v) = 10;    
                                hog_bins_acos_h(r, c, v) = 10;
                                hog_bins_atan_h(r, c, v) = 10; 
                            end
                            
                            % dla obliczonych danych powi�kszamy histogramy
                            % dw�ch k�t�w w dw�ch s�siaduj�cych binach -
                            % high i low. Powi�kszamy adres o jeden, bo
                            % adresy talic numeruj� si� od 1 do 9 a nie od
                            % 0 do 8.
                            
                            if hog_bins_valid(r, c, v) ~= 0
                                histogram_acos(hog_bins_acos_h(r, c, v) + 1) = histogram_acos(hog_bins_acos_h(r, c, v) + 1) + hog_mod_acos_h(r, c, v);
                                histogram_acos(hog_bins_acos_l(r, c, v) + 1) = histogram_acos(hog_bins_acos_l(r, c, v) + 1) + hog_mod_acos_l(r, c, v);
                                histogram_atan(hog_bins_atan_h(r, c, v) + 1) = histogram_atan(hog_bins_atan_h(r, c, v) + 1) + hog_mod_atan_h(r, c, v);
                                histogram_atan(hog_bins_atan_l(r, c, v) + 1) = histogram_atan(hog_bins_atan_l(r, c, v) + 1) + hog_mod_atan_l(r, c, v);    
                            end

                        end
                    end
                end
                
                % Tworzenie histogram�w dla obu k�t�w, zapisywanych w
                % osobnych cellach
                
                HOGimage{row, col, vol} = [histogram_acos histogram_atan];
               
            end
        end
	end  
end 

end

