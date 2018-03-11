clc;    % Clear the command window.
close all;  % Close all figures (except those of imtool.)
imtool close all;  % Close all imtool figures.
clear;  % Erase all existing variables.
workspace;  % Make sure the workspace panel is showing.

%% Load data

myFolder = 'CT_feature_extraction_kidney'; % Define your working folder
if ~isdir(myFolder)
  errorMessage = sprintf('Error: The following folder does not exist:\n%s', myFolder);
  uiwait(warndlg(errorMessage));
  return;
end

list = dir('samples');
iter = 1;
for i = 1:length(list);
    if ~strcmp(list(i).name, '.') && ~strcmp(list(i).name, '..')
        tempStruct = load(fullfile('..', 'CT_feature_extraction_kidney', 'samples', list(i).name));
        featureStruct(iter).name = list(i).name(1:end-4);
        featureStruct(iter).features = tempStruct(1).features;
        iter = iter + 1;
    end
end

clear i; clear list; clear myFolder; clear tempStruct; clear iter;

% Po³¹czenie danych z kilku zdjêæ

samples = [];
for i = 1:length(featureStruct)
    samples = [samples; featureStruct(i).features];
end

clear featureStruct; clear i;

%% Feature selection

% normalizacja wektora cech
% outlier removal
% missing data
% dimention reduction - PCA, FDR
% licznoœæ zbiorów
% crossvalidation, generalization
% sprawdzenie w³aœciwoœci dyskryminacyjnych cech


%% Mix kolejnoœci danych
r = randperm(size(classifyData,1));
classifyData = classifyData(r,:);

clear i; clear r; clear stats_to_write;

%% CROSS - VALIDATION

test_size = 3000;
[Train, ~] = crossvalind('LeaveMOut', size(classifyData,1), test_size);
 
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

clear Train; clear i; clear count_test; clear count_train; clear test_size; % clear classifyData;

%% SVM

% Train a training set
tic
SVMtrain = fitcsvm(single(train(1:12000,6:end)), train(1:12000,4));
toc

% Classify a testing set
tic
SVMclass = predict(SVMtrain, single(test(1:1000,6:end)));
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
validation_err.ALL = 1 - x/size(SVMclass,1);
clear i; clear x;

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