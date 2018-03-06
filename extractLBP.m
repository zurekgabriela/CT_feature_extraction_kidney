function [ LBPhist ] = extractLBP( image, class, radius ) 
%extractLBP 
% Radius of circular pattern used to select neighbors for each pixel in the input image

%% Pobranie wymiarów obrazu. 
[x, y, z] = size(image);

%% Obliczenie obrazu LBP
% LBPimage = zeros(size(image), 'uint8');
LBPimage = cell(size(image));
LBPnum = zeros(size(image));

for row = (radius + 1) : (x - radius)
	for col = (radius + 1) : (y - radius)
        for vol = (radius + 1) : (z - radius)
            % sprawdzenie, czy piksel nie nalezy do t³a
            if class(row,col,vol) > 0
                centerPixel = image(row, col, vol);

                pixel1 = image(row, col, vol-radius) > centerPixel;
                pixel2 = image(row, col+radius, vol-radius) > centerPixel;
                pixel3 = image(row-radius, col, vol-radius) > centerPixel;
                pixel4 = image(row, col-radius, vol-radius) > centerPixel;
                pixel5 = image(row+radius, col, vol-radius) > centerPixel;

                pixel6 = image(row, col+radius, vol) > centerPixel;
                pixel7 = image(row-radius, col, vol) > centerPixel;
                pixel8 = image(row, col-radius, vol) > centerPixel;
                pixel9 = image(row+radius, col, vol) > centerPixel;

                pixel10 = image(row, col+radius, vol+radius) > centerPixel;
                pixel11 = image(row-radius, col, vol+radius) > centerPixel;
                pixel12 = image(row, col-radius, vol+radius) > centerPixel;
                pixel13 = image(row+radius, col, vol+radius) > centerPixel;
                pixel14 = image(row, col, vol+radius) > centerPixel;

                % Przekszta³cenie liczby binarnej w liczbê dziesiêtn¹
                BitNumber = uint16(...
                    pixel14 * 2^13 + pixel13 * 2^12 + ...
                    pixel12 * 2^11 + pixel11 * 2^10 + ...
                    pixel10 * 2^9 + pixel9 * 2^8 + ...
                    pixel8 * 2^7 + pixel7 * 2^6 + ...
                    pixel6 * 2^5 + pixel5 * 2^4 + ...
                    pixel4 * 2^3 + pixel3 * 2^2 + ...
                    pixel2 * 2 + pixel1);           

                % Przypisanie liczby LBP do piksela
                LBPnum(row, col, vol) = BitNumber;
                LBPimage{row, col, vol} = [pixel1 pixel2 pixel3 pixel4 pixel5 pixel6 pixel7 pixel8 pixel9 pixel10 pixel11 pixel12 pixel13 pixel14];
            end
        end
	end  
end 

%% Obliczenie histogramu LBP dla ca³ego obrazu
% [pixelCounts, GLs] = imhist(uint8(LBPimage));

LBPhist = cell(size(image));
BinNum = 14;
hist = zeros(1, BinNum);
hist_size = 3;
small_image = cell(hist_size,hist_size,hist_size);

for row = (radius + 1) : (x - radius)
	for col = (radius + 1) : (y - radius)
        for vol = (radius + 1) : (z - radius)
            
            % bierzemy pod uwage LBPimage bez tla
            if class(row,col,vol) > 0
                
                small_image = LBPimage(row:(row+(hist_size-1)), col:(col+(hist_size-1)), vol:(vol+(hist_size-1)));
                
                for r = 1:size(small_image,1)
                    for c = 1: size(small_image, 2)
                        for v = 1: size(small_image, 3)
                                
                            if isempty(small_image{r, c, v}) == 1
                                small_image{r, c, v} = [0 0 0 0 0 0 0 0 0 0 0 0 0 0];
                            end
                                
                                hist = hist + small_image{r, c, v};
                                            
                        end
                    end
                end
                               
                LBPhist{row, col, vol} = hist;
                hist = zeros(1, BinNum);
                
            end
        end
    end
end

end

