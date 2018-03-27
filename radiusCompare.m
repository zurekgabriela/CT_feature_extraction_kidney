clc;    % Clear the command window.
close all;  % Close all figures 
imtool close all;  % Close all imtool figures.
clear;  % Erase all existing variables.
workspace;  % Make sure the workspace panel is showing.

%% WCZYTYWANIE DANYCH

path = 'Data';
list = dir(path);
[~,index] = sortrows({list.name}.'); list = list(index); clear index
CT = struct('patient', [], 'image', [], 'class',[]);

for i = 1:length(list);
    patientPath = [path '\' list(i).name];    
    if ~strcmp(list(i).name, '.') && ~strcmp(list(i).name, '..')
        infoCT = mha_read_header([patientPath '\CT.mhd']);
        dim = infoCT.Dimensions;
        I = imread_RawData([patientPath '\CT.raw'], dim(1), dim(2), dim(3), 'int16');
        M = imread_RawData([patientPath '\Nerka i guz.raw'], dim(1), dim(2), dim(3), 'int16');
        CT(i).image = I;
        CT(i).class = M;
        CT(i).patient = list(i).name;       
    end    
    clear patientPath; clear infoCT; clear dim; clear i; clear I; clear M; 
end
CT = CT(3:length(list));
% Roboczo jeden pacjent, by nie zajmowaæ zbyt du¿o pamiêci
% CT = CT(4:4);
clear list;

%% PRZEKSZTA£CENIE DANYCH

for i = 1:length(CT)
    
    %% Przekszta³cenie klas obrazów tak, by nerka by³a oznaczona wartoœci¹ 1, a guz wartoœci¹ 2
    % class: nerka = 1; guz = 2
    CT(i).mask = CT(i).class;    
    for a = 1:size(CT(i).class,1)
        a
        for b = 1:size(CT(i).class,2)
            for c = 1:size(CT(i).class,3)
                if (CT(i).class(a,b,c) == 1) || (CT(i).class(a,b,c) == 6)
                    CT(i).class(a,b,c) = 1;
                    CT(i).mask(a,b,c) = 1;
                elseif (CT(i).class(a,b,c) == 2) || (CT(i).class(a,b,c) == 3)
                    CT(i).class(a,b,c) = 2;
                    CT(i).mask(a,b,c) = 1;
                end
            end
        end
    end
    CT(i).class = single(CT(i).class);
    clearvars a b c; 
    sprintf('przekszta³cono klasê %s',CT(i).patient)
   
    %% Nak³adanie maski na obraz - wyodrêbnienie wokseli, które zawieraj¹ tylko nerkê i guz
    CT(i).mask = CT(i).mask.*CT(i).image;  
    sprintf('na³o¿ono maskê na obraz %s',CT(i).patient)

    %% Normalizacja typu Z
    nonEmptyIdx = find(~(CT(i).class==0));
    CT(i).norm = zeros(size(CT(i).mask));
    CT(i).norm(nonEmptyIdx) = zscore(CT(i).mask(nonEmptyIdx), 1);
    sprintf('znormalizowano dane %s',CT(i).patient)   
    
    %% Czyszczenie pamiêci
    CT(i).image = []; CT(i).mask = [];
end
clear i; CT = rmfield(CT, {'image', 'mask'});


%% EKSTRAKCJA CECH CHARAKTERYSTYCZNYCH

radius_size = 20;
for i = 1:length(CT)   
    
    i
    %% Przekszta³cenie próbek w wektor do klasyfikacji
    % znalezienie indeksów oznaczaj¹cych nerkê i guza (bez t³a)
    nonEmptyIdx = find(~(CT(i).class == 0));
    [nonEmptyRow,nonEmptyCol,nonEmptyVol] = ind2sub(size(CT(i).norm),nonEmptyIdx);
    %nonEmptyRow = int16(nonEmptyRow); nonEmptyCol = int16(nonEmptyCol); nonEmptyVol = int16(nonEmptyVol); nonEmptyIdx = int16(nonEmptyIdx);
    CT(i).samples = [nonEmptyRow nonEmptyCol nonEmptyVol single(CT(i).class(nonEmptyIdx)-1) single(CT(i).norm(nonEmptyIdx))];
    
    sprintf('wyszukano indeksy i zapisano dane Row, Col, Vol, class, norm do wektora cech %s',CT(i).patient)
    
    %% 3D Local Binary Pattern 
    
    for radius = 16 : radius_size
        radius
        [CT(i).LBP] = extractLBP( CT(i).norm, CT(i).class, radius ); 
        sprintf('obliczono LBP %s',CT(i).patient)

        % przekszta³cenie lbp z komórki do wektora
        LBP_to_write = [CT(i).LBP{nonEmptyIdx}];
        sprintf('wpisano LBP %s',CT(i).patient)
        LBP_to_write = reshape(LBP_to_write,[14,length(LBP_to_write)/14])';
        sprintf('przekszta³cono w tablicê %s',CT(i).patient)

        % zapisanie danych LBP do wektora cech
        CT(i).patientID = repelem([CT(i).patient],length(nonEmptyIdx),1);
        CT(i).samples = [CT(i).samples single(LBP_to_write)];
        sprintf('zapisano dane LBP w wektorze samples %s',CT(i).patient)

        CT(i).LBP = []; CT(i).LBPnum = []; CT(i).patientID = []; clear LBP_to_write;
    end
    
end

%% Feature processing

% Po³¹czenie danych z kilku zdjêæ
samples = [];
for i = 1 : length(CT)
    samples = [samples; CT(i).samples];
end

% Mix kolejnoœci danych
r = randperm(size(samples,1));
samples = samples(r,:);

% Missing data
samples(isinf(samples)) = NaN; % Inf is treated as missing data
[nanrows, ~, ~] = find(isnan(samples));
samples(nanrows, :) = [];

% Normalizacja wektora cech - normalizujemy dane powy¿ej kolumny 4 oznaczaj¹cej klasê
sumOut = 0;
for k = 5 : size(samples, 2)
    k
    % samples(:,k) = zscore(samples(:,k));
    samples(:,k) = samples(:,k)/norm(samples(:,k));

    % Median Absolute Deviation
    threshold = 10;
    medianValue = median(samples(:, k));
    MAD = median(abs(samples(:, k) - medianValue));
    outliers = 0.6745*(samples(:, k) - medianValue)/MAD > threshold;
    samples(find(outliers == 1), :) = [];

    sumOut = sumOut + sum(outliers);
end

clear k nanrows r i featureStruct threshold medianValue MAD outliers;

% Do klasyfikacji bierzemy np co 20 próbkê, aby zmniejszyæ z³o¿onoœæ obliczeniow¹

ind = 1 : 75 : size(samples);
samples = samples(ind, :);
clear ind clear;

feature_length = 14;
response = samples(:, 4);
first = 6;
smallest_error = 10;

for i = 16 : radius_size
    i
    predictors = samples(:, first : (first + feature_length - 1));
    [err, CM] = fastclassify(predictors, response);
    first = first + feature_length;
    ERROR(i).radius = i;
    ERROR(i).err = err;
    if err < smallest_error
        smallest_err = err;
        best_radius = i;
    end
    
end

