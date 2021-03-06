function [ LBP_to_write ] = extractLBP( image, class, radius ) 
% extractLBP wykorzystuje znormalizowany obraz (image), klas� (class), na podstawie
% kt�rej wybierane s� indeksy oznaczaj�ce nerk� i guza oraz zmienn� radius
% oznaczaj�cy promie� s�siedztwa, w jakim obliczne jest LBP

if ~isa(image,'numeric') || ~isa(class,'numeric') || ~isa(radius,'numeric')
    error('extractStats:InputMustBeNumeric', ...
        'Coefficients must be numeric.');
end
%% Pobranie wymiar�w obrazu. 
% [~, ~, z] = size(image);

%% Filtracja obrazu 
% h = fspecial('gaussian');
% h = fspecial('prewitt');
% for vol = 1 : z
%     % image(:, :, vol) = imfilter(image(:, :, vol), h);
%     % image(:, :, vol) = medfilt2(image(:, :, vol));
%     image(:, :, vol) = wiener2(image(:, :, vol), [2 2]);
% end
% image = imgaussfilt3(image);
%% Pobranie wymiar�w obrazu.

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

%% Inicjalizacja obrazu LBP (bianary)
LBPimage = cell(size(image));

% LBP obliczne jest w ramkach o wymiarze (radius x 2 + 1) x (radius x 2 +
% 1) x (radius x 2 + 1), a jego warto�� zapisywana jest do indeksu
% odpowiadaj�cemu wokselowi znajduj�cemu sie w centrum

for i = 1 : length(nonEmptyIdx)
    
    row = nonEmptyRow(i);
    col = nonEmptyCol(i);
    vol = nonEmptyVol(i);

    centerPixel = image(row, col, vol);

    % warto�� ka�dego piksela znajduj�cego si� wok� piksela
    % centralnego jest do niego por�wnywana i przypisywane jest
    % 1, je�li jest ona wi�ksza i 0 w przeciwnym wypadku
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

    % Przekszta�cenie liczby binarnej w liczb� dziesi�tn�
    BitNumber = uint16(...
        pixel14 * 2^13 + pixel13 * 2^12 + ...
        pixel12 * 2^11 + pixel11 * 2^10 + ...
        pixel10 * 2^9 + pixel9 * 2^8 + ...
        pixel8 * 2^7 + pixel7 * 2^6 + ...
        pixel6 * 2^5 + pixel5 * 2^4 + ...
        pixel4 * 2^3 + pixel3 * 2^2 + ...
        pixel2 * 2 + pixel1);           

    % Przypisanie liczby LBP do indeks�w piksela centralnego
    LBPimage{row, col, vol} = [pixel1 pixel2 pixel3 pixel4 pixel5 pixel6 pixel7 pixel8 pixel9 pixel10 pixel11 pixel12 pixel13 pixel14];
end 

%% Obliczenie histogramu LBP dla ca�ego obrazu odnosz�cego si� do warto�ci binarnych - 
% zliczanie warto�ci 1 i 0 w s�siedztwie sprawdzanego piksela 
% [pixelCounts, GLs] = imhist(uint8(LBPimage));

LBPhist = cell(size(image));
% LBPhist(find(cellfun(@isempty, LBPhist))) = {[0 0 0 0 0 0 0 0 0 0 0 0 0 0]};
BinNum = 14;
hist = zeros(1, BinNum);
hist_size = 3;
small_image = cell(hist_size, hist_size, hist_size);

for i = 1 : length(nonEmptyIdx)
    
    row = nonEmptyRow(i);
    col = nonEmptyCol(i);
    vol = nonEmptyVol(i);
            
            % sprawdzamy, czy badany piksel nie nale�y do t�a
            if class(row,col,vol) > 0
                
                % small_image oznacza obszar, w kt�rym zliczany jest
                % histogram - je�li hist_size = 3 -> histogram b�dzie
                % pobierany z sze�cianu o wymiarach 3 x 3 x 3
                small_image = LBPimage(row:(row+(hist_size-1)), col:(col+(hist_size-1)), vol:(vol+(hist_size-1)));
                
                for r = 1:size(small_image,1)
                    for c = 1: size(small_image, 2)
                        for v = 1: size(small_image, 3)
                            
                            % je�li LBPimage o podanych indeksach jest
                            % pusty - mo�e si� tak zdarzy� w przypadku pikseli granicz�cych z t�em -
                            % nadpisywane s� warto�ci 0
                            if isempty(small_image{r, c, v}) == 1
                                small_image{r, c, v} = [0 0 0 0 0 0 0 0 0 0 0 0 0 0];
                            end         
                            % histogram jest obliczany poprzez dodanie
                            % warto�ci binarnych wszystkich pikseli
                            % znajduj�cych si� w obr�bie badanego sze�cianu
                                hist = hist + small_image{r, c, v};                                            
                        end
                    end
                end
                
                % histogram jest wpisywany do odpowiedniego indeksu
                LBPhist{row, col, vol} = hist;
                hist = zeros(1, BinNum);                
            end
end

% przekszta�cenie lbp z kom�rki do wektora
LBP_to_write = [LBPhist{nonEmptyIdx}];
LBP_to_write = reshape(LBP_to_write,[14,length(LBP_to_write)/14])';

end

