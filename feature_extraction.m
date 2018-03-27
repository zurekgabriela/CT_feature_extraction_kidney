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
% CT = CT(3:length(list));
% Roboczo jeden pacjent, by nie zajmowaæ zbyt du¿o pamiêci
CT = CT(4:4);
clear list;

%% PRZEKSZTA£CENIE DANYCH

for i = 1:length(CT)
    
    %% Przekszta³cenie klas obrazów tak, by nerka by³a oznaczona wartoœci¹ 1, a guz wartoœci¹ 2
    % class: nerka = 1; guz = 2
    CT(i).mask = CT(i).class;    
    for a = 1:size(CT(i).class,1)
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

for i = 1:length(CT)   
    
    %% Przekszta³cenie próbek w wektor do klasyfikacji
    % znalezienie indeksów oznaczaj¹cych nerkê i guza (bez t³a)
    nonEmptyIdx = find(~(CT(i).class == 0));
    [nonEmptyRow,nonEmptyCol,nonEmptyVol] = ind2sub(size(CT(i).norm),nonEmptyIdx);
    %nonEmptyRow = int16(nonEmptyRow); nonEmptyCol = int16(nonEmptyCol); nonEmptyVol = int16(nonEmptyVol); nonEmptyIdx = int16(nonEmptyIdx);
    CT(i).samples = [nonEmptyRow nonEmptyCol nonEmptyVol single(CT(i).class(nonEmptyIdx)-1) single(CT(i).norm(nonEmptyIdx))];
    
    sprintf('wyszukano indeksy i zapisano dane Row, Col, Vol, class, norm do wektora cech %s',CT(i).patient)
    
    %% 3D Local Binary Pattern 
    [CT(i).LBP] = extractLBP( CT(i).norm, CT(i).class, 3 ); 
    sprintf('obliczono LBP %s',CT(i).patient)
    
    % przekszta³cenie lbp z komórki do wektora
    LBP_to_write = [CT(i).LBP{nonEmptyIdx}];
    sprintf('wpisano LBP %s',CT(i).patient)
    LBP_to_write = reshape(LBP_to_write,[14,length(LBP_to_write)/14])';
    sprintf('przekszta³cono w tablicê %s',CT(i).patient)
    
    % zapisanie danych LBP do wektora cech
    CT(i).patientID = [repelem([CT(i).patient],length(nonEmptyIdx),1)];
    CT(i).samples = [CT(i).samples single(LBP_to_write)];
    sprintf('zapisano dane LBP w wektorze samples %s',CT(i).patient)
    
    CT(i).LBP = []; CT(i).LBPnum = []; clear LBP_to_write;
    
    %% Stats  - œrednia, odchylenie standardowe, wariancja, entropia,
    % asymetria, rozproszenie z ramki o wymiarach (2r + 1)
    CT(i).stats = extractStats( double(CT(i).norm), CT(i).class, 3 );
    sprintf('obliczono statystyki 3D %s',CT(i).patient)
    
    % przekszta³cenie stats z komórki do wektora
    stats_to_write = [CT(i).stats{nonEmptyIdx}];
    sprintf('wpisano stats %s',CT(i).patient)
    stats_to_write = reshape(stats_to_write,[5,length(stats_to_write)/5])';
    sprintf('przekszta³cono w tablicê %s',CT(i).patient)
    
    % zapisanie danych do wektora
    CT(i).samples = [CT(i).samples single(stats_to_write)];
    sprintf('zapisano dane stats w wektorze samples %s',CT(i).patient)
    
    CT(i).stats = []; clear stats_to_write;
    
    %% GLCM -contrast, homogenity, correlation, energy
    CT(i).GLCM = extractGLCM( double(CT(i).norm), CT(i).class, 11 );
    sprintf('obliczono GLCM %s',CT(i).patient)

    % przekszta³cenie stats z komórki do wektora
    GLCM_to_write = [CT(i).GLCM{nonEmptyIdx}];
    sprintf('wpisano GLCM %s',CT(i).patient)
    GLCM_to_write = reshape(GLCM_to_write,[4,length(GLCM_to_write)/4])';
    sprintf('przekszta³cono w tablicê %s',CT(i).patient)

    % zapisanie danych do wektora
    CT(i).samples = [CT(i).samples single(GLCM_to_write)];
    sprintf('zapisano dane GLCM w wektorze samples %s',CT(i).patient)

    CT(i).GLCM = []; clear GLCM_to_write;
   
    %% 3D Histogram Zorientowanych Gradientów
    CT(i).HOG = extract3DHOG( single(CT(i).norm), CT(i).class, [2 2]);
    
    % przekszta³cenie HOG z komórki do wektora
    HOG_to_write = [CT(i).HOG{nonEmptyIdx}];
    HOG_to_write = reshape(HOG_to_write,[18,length(HOG_to_write)/18])';
    sprintf('wpisano HOG %s',CT(i).patient);
    sprintf('przekszta³cono w HOG tablicê %s',CT(i).patient)
    
    % zapisanie danych do wektora
    CT(i).samples = [CT(i).samples single(HOG_to_write)];
    sprintf('zapisano dane HOG w wektorze samples %s',CT(i).patient)
    
    CT(i).HOG = []; clear HOG_to_write;
     
    %% Filtry Gabora
    [CT(i).GaborMag] = extractGaborFilter( single(CT(i).norm), nonEmptyRow, nonEmptyCol, nonEmptyVol );
    sprintf('obliczono filtry Gabora %s',CT(i).patient)
    
    % zapisanie danych do wektora
    CT(i).samples = [CT(i).samples single(CT(i).GaborMag)];
    sprintf('zapisano filtry Gabora w wektorze samples %s',CT(i).patient)
    
    CT(i).GaborMag = [];
    
    %% Laplacian of Gaussian

    [CT(i).LoG] = extractLoG( single(CT(i).norm), nonEmptyRow, nonEmptyCol, nonEmptyVol );
    sprintf('obliczono LoG %s',CT(i).patient)

    % zapisanie danych do wektora
    CT(i).samples = [CT(i).samples single(CT(i).LoG)];
    sprintf('zapisano LoG w wektorze samples %s',CT(i).patient)

    CT(i).LoG = [];
    
end

%% Zapisanie danych
% do folderu samples
for i = 1:length(CT)
    fname = sprintf('samples_%s', CT(i).patient);
    % vname = genvarname(sprintf('samples_%s', CT(i).patient));
    vname = 'features';
    vname = genvarname(sprintf('samples_%s', CT(i).patient));
    eval([vname '= CT(i).samples;']);
    save(strcat('samples\', fname), vname);
end

% Czyszczenie pamiêci z niepotrzebnych danych
clear fname vname i nonEmptyIdx nonEmptyRow nonEmptyCol nonEmptyVol
CT = rmfield(CT, {'LBP', 'LBPnum', 'stats', 'HOG', 'GaborMag', 'LoG', 'GLCM', 'class', 'norm', 'patientID'}); 