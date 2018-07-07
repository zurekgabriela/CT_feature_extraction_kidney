clc;    % Clear the command window.
close all;  % Close all figures 
imtool close all;  % Close all imtool figures.
clear;  % Erase all existing variables.
workspace;  % Make sure the workspace panel is showing.

%% WCZYTYWANIE DANYCH
% Treningowe

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

% CT = CT(4:4);
CT = CT(3:length(list));
clear list;

%% WCZYTYWANIE DANYCH
% Testowe

path = 'Data_Test';
list = dir(path);
[~,index] = sortrows({list.name}.'); list = list(index); clear index
CT = struct('patient', [], 'image', [], 'class',[]);

for i = 1:length(list);
    patientPath = [path '\' list(i).name];    
    if ~strcmp(list(i).name, '.') && ~strcmp(list(i).name, '..')
        I = niftiread([patientPath '\CT.nii']);
        M = niftiread([patientPath '\Nerka i guz.nii']);
        CT(i).image = I;
        CT(i).class = M;
        CT(i).patient = list(i).name;       
    end    
    clear patientPath; clear i; clear I; clear M; 
end

CT = CT(3:length(list));
clear list;

%% PRZEKSZTA£CENIE DANYCH

for i = 1:length(CT)
    i
    nonEmptyIdx = find(~(CT(i).class==0));
    [nonEmptyRow,nonEmptyCol,nonEmptyVol] = ind2sub(size(CT(i).image),nonEmptyIdx);
    % Przekszta³cenie klas obrazów tak, by nerka by³a oznaczona wartoœci¹ 1, a guz wartoœci¹ 2
    % class: nerka = 1; guz = 2 
    for j = 1 : length(nonEmptyIdx)
        row = nonEmptyRow(j);
        col = nonEmptyCol(j);
        vol = nonEmptyVol(j);
        if (CT(i).class(row, col, vol) == 1) || (CT(i).class(row, col, vol) == 6)
            CT(i).class(row, col, vol) = 1;
        elseif (CT(i).class(row, col, vol) == 2) || (CT(i).class(row, col, vol) == 3)
            CT(i).class(row, col, vol) = 2;
        end
    end

    CT(i).class = single(CT(i).class);
    clearvars row col vol; 
    sprintf('przekszta³cono klasê %s',CT(i).patient)

    % Normalizacja typu Z   
    [~, mu, sigma] = zscore(CT(i).image(nonEmptyIdx), 1);
    CT(i).norm = zeros(size(CT(i).image));
    CT(i).norm = (CT(i).image-mu)./sigma;
    sprintf('znormalizowano dane %s',CT(i).patient) 
    CT(i).norm = single(CT(i).norm);
     
    % Czyszczenie pamiêci
    CT(i).image = [];  
end
clear i j mu sigma path; CT = rmfield(CT, {'image'});

%% EKSTRAKCJA CECH CHARAKTERYSTYCZNYCH

for i = 1:length(CT) 
    i   
    %% Przekszta³cenie próbek w wektor do klasyfikacji
    % znalezienie indeksów oznaczaj¹cych nerkê i guza (bez t³a)
    nonEmptyIdx = find(~(CT(i).class == 0));
    [nonEmptyRow,nonEmptyCol,nonEmptyVol] = ind2sub(size(CT(i).norm),nonEmptyIdx);
    %nonEmptyRow = int16(nonEmptyRow); nonEmptyCol = int16(nonEmptyCol); nonEmptyVol = int16(nonEmptyVol); nonEmptyIdx = int16(nonEmptyIdx);
    CT(i).samples = [nonEmptyRow nonEmptyCol nonEmptyVol single(CT(i).class(nonEmptyIdx)-1) single(CT(i).norm(nonEmptyIdx))];
    
    sprintf('wyszukano indeksy i zapisano dane Row, Col, Vol, class, norm do wektora cech %s',CT(i).patient)
    
%     %% 3D Local Binary Pattern 
%     [CT(i).LBP] = extractLBP( CT(i).norm, CT(i).class, 10 ); 
%     sprintf('obliczono LBP %s',CT(i).patient)
%     
%     % zapisanie danych LBP do wektora cech
%     CT(i).samples = [CT(i).samples single(CT(i).LBP)];
%     sprintf('zapisano dane LBP w wektorze samples %s',CT(i).patient)
%     
%     CT(i).LBP = [];
    
%     %% Stats  - œrednia, odchylenie standardowe, wariancja, entropia,
%     % asymetria, rozproszenie z ramki o wymiarach (2r + 1)
%     CT(i).stats = extractStats( double(CT(i).norm), CT(i).class, 35 );
%     sprintf('obliczono statystyki 3D %s',CT(i).patient)
%        
%     % zapisanie danych do wektora
%     CT(i).samples = [CT(i).samples single(CT(i).stats)];
%     sprintf('zapisano dane stats w wektorze samples %s',CT(i).patient)
%     
%     CT(i).stats = []; 
    
%     %% GLCM - contrast, homogenity, correlation, energy
%     CT(i).GLCM = extractGLCM( double(CT(i).norm), CT(i).class, 10 );
%     sprintf('obliczono GLCM %s',CT(i).patient)
% 
%     % zapisanie danych do wektora
%     CT(i).samples = [CT(i).samples single(CT(i).GLCM)];
%     sprintf('zapisano dane GLCM w wektorze samples %s',CT(i).patient)
% 
%     CT(i).GLCM = []; 
%     
%     %% 3D Histogram Zorientowanych Gradientów
%     CT(i).HOG = extract3DHOG( single(CT(i).norm), CT(i).class, 10);
%     sprintf('obliczono HOG %s',CT(i).patient)
%     
%     % zapisanie danych do wektora
%     CT(i).samples = [CT(i).samples single(CT(i).HOG)];
%     sprintf('zapisano dane HOG w wektorze samples %s',CT(i).patient)
%     
%     CT(i).HOG = []; 
%      
    %% Filtry Gabora

    [CT(i).Gabor] = extractGaborFilter( single(CT(i).norm), CT(i).class, 10 );
    sprintf('obliczono Gabor Filter %s',CT(i).patient)

    % zapisanie danych do wektora
    CT(i).samples = [CT(i).samples single(CT(i).Gabor)];
    sprintf('zapisano Gabor Filter w wektorze samples %s',CT(i).patient)

    CT(i).Gabor = [];
    
    %% Laplacian of Gaussian
% 
%     [CT(i).LoG] = extractLoG( single(CT(i).norm), CT(i).class, 10 );
%     sprintf('obliczono LoG %s',CT(i).patient)
% 
%     % zapisanie danych do wektora
%     CT(i).samples = [CT(i).samples single(CT(i).LoG)];
%     sprintf('zapisano LoG w wektorze samples %s',CT(i).patient)
% 
%     CT(i).LoG = [];
    
    %% Zapisanie danych
    % do folderu features
    fname = sprintf('samples_%s', CT(i).patient);
    vname = 'features';
    eval([vname '= CT(i).samples;']);
    save(strcat('features\', fname), vname);
    sprintf('zapisano dane w pliku samples_%s',CT(i).patient)
    
end

%% Czyszczenie pamiêci z niepotrzebnych danych
clear fname vname i nonEmptyIdx nonEmptyRow nonEmptyCol nonEmptyVol
CT = rmfield(CT, {'LBP', 'stats', 'HOG', 'GaborMag', 'LoG', 'GLCM', 'class', 'norm', 'patientID'}); 