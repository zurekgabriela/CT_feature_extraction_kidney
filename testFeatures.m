clc;    % Clear the command window.
close all;  % Close all figures (except those of imtool.)
imtool close all;  % Close all imtool figures.
clear;  % Erase all existing variables.
workspace;  % Make sure the workspace panel is showing.

%% WCZYTYWANIE DANYCH

path = 'Data';
list = dir(path);
[~,index] = sortrows({list.name}.'); list = list(index); clear index
CT = struct('patient', [], 'image', [], 'class',[]);

for i = 3 : 4%length(list);
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
% Roboczo jeden pacjent
CT = CT(3:3);
clear list;

%% PRZEKSZTA£CENIE DANYCH
i = 1;   
% Ujednolicenie klasy i maskowanie obrazu
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
clear a; clear b; clear c; 
sprintf('przekszta³cono klasê %s',CT(i).patient)

%% Nak³adanie maski na obraz  
CT(i).mask = CT(i).mask.*CT(i).image;  
sprintf('na³o¿ono maskê na obraz %s',CT(i).patient)

%% Normalizacja typu Z
nonEmptyIdx = find(~(CT(i).class==0));
CT(i).norm = zeros(size(CT(i).mask));
CT(i).norm(nonEmptyIdx) = zscore(CT(i).mask(nonEmptyIdx), 1);

sprintf('znormalizowano dane %s',CT(i).patient)

%% Czyszczenie pamiêci
CT(i).image = []; CT(i).mask = [];

clear i; CT = rmfield(CT, 'image'); CT = rmfield(CT, 'mask');
%% EKSTRAKCJA CECH CHARAKTERYSTYCZNYCH
% Przekszta³cenie próbek w wektor do klasyfikacji
% znalezienie indeksów, które nie s¹ t³em
nonEmptyIdx = find(~(CT(i).class==0));
[nonEmptyRow,nonEmptyCol,nonEmptyVol] = ind2sub(size(CT(i).norm),nonEmptyIdx);
nonEmptyRow = int16(nonEmptyRow); nonEmptyCol = int16(nonEmptyCol); nonEmptyVol = int16(nonEmptyVol);

sprintf('wyszukano indeksy %s',CT(i).patient)

%% 3D Local Binary Pattern 
[CT(i).LBP] = extractLBP( CT(i).norm, CT(i).class, 1 ); 
sprintf('obliczono LBP %s',CT(i).patient)

% przekszta³cenie lbp z komórki do wektora
LBP_to_write = [CT(i).LBP{nonEmptyIdx}];
sprintf('wpisano LBP %s',CT(i).patient)
LBP_to_write = reshape(LBP_to_write,[14,length(LBP_to_write)/14])';
sprintf('przekszta³cono w tablicê %s',CT(i).patient)

% zapisanie danych class, LBP, norm do wektora
CT(i).patientID = [repelem([CT(i).patient],length(nonEmptyIdx),1)];
CT(i).samples(:,:) = [nonEmptyRow nonEmptyCol nonEmptyVol single(CT(i).class(nonEmptyIdx)-1) single(CT(i).norm(nonEmptyIdx)) single(LBP_to_write)];
sprintf('zapisano dane class, norm, LBP w wektorze samples %s',CT(i).patient)

CT(i).LBP = []; CT(i).LBPnum = []; clear LBP_to_write;

%% Stats  - œrednia, odchylenie standardowe, wariancja, entropia,
% asymetria, rozproszenie, mediana - w zale¿noœci od promienia r
CT(i).stats = extractStats( double(CT(i).norm), CT(i).class, 5 );
sprintf('obliczono statystyki D %s',CT(i).patient)

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
CT(i).GLCM = extractGLCM( double(CT(i).norm), CT(i).class, 5 );
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
CT(i).HOG = extract3DHOG( single(CT(i).norm), CT(i).class, 3 );

% przekszta³cenie HOG z komórki do wektora
HOG_to_write = [CT(i).HOG{nonEmptyIdx}];
sprintf('wpisano HOG %s',CT(i).patient)
HOG_to_write = reshape(HOG_to_write,[18,length(HOG_to_write)/18])';
sprintf('przekszta³cono w HOG tablicê %s',CT(i).patient)

% zapisanie danych do wektora
CT(i).samples = [CT(i).samples single(HOG_to_write)];
sprintf('zapisano dane HOG w wektorze samples %s',CT(i).patient)

CT(i).HOG = []; clear HOG_to_write;

%% Filtry Gabora
[CT(i).GaborMag] = extractGaborFilter( single(CT(i).norm), nonEmptyRow, nonEmptyCol, nonEmptyVol );
sprintf('obliczono filtry Gabora %s',CT(i).patient)
toc

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

% CT(i).LoG = []

%% Memory cleaning
% CT(i).class = []; CT(i).norm = [];
sprintf('pobrano wszystkie cechy %s!',CT(i).patient)

clear i; clear nonEmptyIdx; clear clear nonEmptyRow; clear nonEmptyCol; clear nonEmptyVol;
CT = rmfield(CT, 'LBP'); CT = rmfield(CT, 'LBPnum'); CT = rmfield(CT, 'stats'); CT = rmfield(CT, 'HOG'); 
CT = rmfield(CT, 'GaborMag'); % CT = rmfield(CT, 'class'); CT = rmfield(CT, 'norm');

%% Próbki do klasyfikacji -> wektor

% Po³¹czenie danych z kilku zdjêæ
classifyData = [];
tic
for i = 1:length(CT)
    classifyData = [classifyData; CT(i).samples];
end
toc

% Mix kolejnoœci danych
r = randperm(size(classifyData,1));
classifyData = classifyData(r,:);

clear i; clear r; clear stats_to_write;

%% Weryfikacja ró¿nic w obliczonych Features pomiêdzy guzem a nerk¹
verifyFeatures = struct('structure', [], 'LBPdata', [], 'bin_proc',[] , 'LBP', [], 'Z_norm', [], 'mean', [], 'std', []);
verifyFeatures(1).structure = 'tumor';
verifyFeatures(2).structure = 'kidney';

tumorData = zeros(size(classifyData));
kidneyData = zeros(size(classifyData));
count_t = 1;
count_k = 1;

for i = 1:size(classifyData,1)
    if classifyData(i,1) == 1
        tumorData(count_t,:) = classifyData(i,:);
        count_t = count_t + 1;
    else
        kidneyData(count_k,:) = classifyData(i,:);
        count_k = count_k + 1;
    end
end

tumorData = tumorData(1:count_t,:);
kidneyData = kidneyData(1:count_k,:);
clear i, clear count_t, clear count_k;

% % histogramy feature dla raka i nerki
figure
subplot(2,1,1)
histogram(tumorData(:,2))
title('tumor')
subplot(2,1,2)
histogram(kidneyData(:,2))
title('kidney')
% % mo¿na odj¹æ histogramy, ¿eby zobaczyæ ró¿nice

clear kidneyData; clear tumorData;

%% ANALIZA DYSKRYMINACYJNA CECH
coeff = pca(classifyData);

%% CROSS - VALIDATION

test_size = 3000;
[Train, Test] = crossvalind('LeaveMOut', size(classifyData,1), test_size);
 
 train = zeros(size(classifyData,1)-test_size,size(classifyData,2));
 test = zeros(test_size,size(classifyData,2));
 count_test = 1;
 count_train = 1;
 
 tic
 for i = 1:size(classifyData,1)  
     if Train(i) == 1
         train(count_train,:) = classifyData(i,:);
         count_train = count_train + 1;
     else
         test(count_test,:) = classifyData(i,:);
         count_test = count_test + 1;
     end
 end
toc

clear Train; clear Test; clear i; clear count_test; clear count_train; clear test_size; clear classifyData;

%% SVM

% Train a training set
tic
SVMtrain = fitcsvm(single(train(1:12000,43:end)), train(1:12000,4));
toc

% Classify a testing set
tic
SVMclass = predict(SVMtrain, single(test(1:1000,43:end)));
toc

% Verify classifier

% pierwsza kolumna to wynik klasyfikacji, druga kolumna to rzeczywista
% klasa: nerka = 0, guz = 1

SVMclass(:,2) = test(1:1000,4);
x = 0;
for i = 1:size(SVMclass,1)
    if SVMclass(i,1) == SVMclass(i,2)
        x = x + 1;
    end
end
err = 1 - x/size(SVMclass,1);
clear i; clear x;

%% Wizualizacja otrzymanych wyników

train = [train train(:,5)];
test = [test SVMclass];
ValidationData = [train; test];

% wycinamy kolumny oznaczaj¹ce numer pacjenta, indeksy i wartoœci klasy
% przed i po klasyfikacji i przyporz¹dkowyjemy do pacjenta
CT(p).validation = [];
for p = 1:length(CT)
    
    % inicjalizacja rekonstruowanego obrazu
    CT(p).reconstr_SVMclass = zeros(max(CT(p).validation(:,3)), max(CT(p).validation(:,4), max(CT(p).validation(:,5))));   
    CT(p).reconstr_class = zeros(max(CT(p).validation(:,3)), max(CT(p).validation(:,4), max(CT(p).validation(:,5))));
    
    for row = 1 : length(ValidationData)        
        if ValidationData(row, 1) == CT(p).patient
            % dane - klasa, indeksy, wynik klasyfikacji
            CT(p).validation = [CT(p).validation; ValidationData(row, 2:5)  ValidationData(row, end)];
        end
        
        if ValidationData(row, 2) ~= ValidationData(row, end)
            ValidationData(row, end) = 5;
        end
        
        % rekonstrukcja obrazów
        CT(p).reconstr_SVMclass(CT(p).validation(:,3), CT(p).validation(:,4), CT(p).validation(:,5)) = ValidationData(row, end);
        CT(p).reconstr_class(CT(p).validation(:,3), CT(p).validation(:,4), CT(p).validation(:,5)) = ValidationData(row, 2);
        
        clear CT(p).validation;
    end
end


%% OCENA WYNIKÓW KLASYFIKACJI
%%----KRZYWE roc, TABELE PORÓWNAWCZE 

% Wizualizacja Filtrów Gabora

for p = 1:length(g)
        subplot(5,6,p);
        imshow(real(g(p).SpatialKernel),[]);
        lambda = g(p).Wavelength;
        theta  = g(p).Orientation;
        title(sprintf('Re[h(x,y)], \\lambda = %d, \\theta = %d',lambda,theta));
end