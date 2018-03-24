clc;    % Clear the command window.
close all;  % Close all figures 
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

%% Feature processing

% Po³¹czenie danych z kilku zdjêæ
samples = [];
for i = 1:length(featureStruct)
    samples = [samples; featureStruct(i).features];
end

% Mix kolejnoœci danych
r = randperm(size(samples,1));
samples = samples(r,:);

% Missing data
[nanrows, ~, ~] = find(isnan(samples));
samples(nanrows, :) = [];

% Normalizacja wektora cech - normalizujemy dane powy¿ej kolumny 4 oznaczaj¹cej klasê
cidx = 0;
for k = 5 : size(samples, 2)
    % samples(:,k) = zscore(samples(:,k));
    samples(:,k) = samples(:,k)/norm(samples(:,k));
    
    % Outlier removal
    idx = outlier(samples(:, k), 2, 2);
    cidx = cidx + length(idx);
    samples(idx,:) = [];
end

clearvar cidx idx k nanrows r i featureStruct;

%% Do klasyfikacji bierzemy np co 20 próbkê, aby zmniejszyæ z³o¿onoœæ obliczeniow¹
ind = [1 : 75 : size(samples)];
trainingData = samples(ind, :);

clear ind;

%% Feature selection
% Convert input to table
inputTable = array2table(trainingData, 'VariableNames', {'Row', 'Col', 'Vol', 'Class', 'norm', 'LBP_1', 'LBP_2', 'LBP_3', 'LBP_4', 'LBP_5', 'LBP_6', 'LBP_7', 'LBP_8', 'LBP_9', 'LBP_10', 'LBP_11', 'LBP_12', 'LBP_13', 'LBP_14', 'mean', 'std', 'entropy', 'skewness', 'kurtosis', 'contrast', 'correlation', 'energy', 'homogenity', 'HOG_1', 'HOG_2', 'HOG_3', 'HOG_4', 'HOG_5', 'HOG_6', 'HOG_7', 'HOG_8', 'HOG_9', 'HOG_10', 'HOG_11', 'HOG_12', 'HOG_13', 'HOG_14', 'HOG_15', 'HOG_16', 'HOG_17', 'HOG_18',...
    'Gabor_1', 'Gabor_2', 'Gabor_3', 'Gabor_4', 'Gabor_5', 'Gabor_6', 'Gabor_7', 'Gabor_8', 'Gabor_9', 'Gabor_10', 'Gabor_11', 'Gabor_12', 'Gabor_13', 'Gabor_14', 'Gabor_15', 'Gabor_16', 'Gabor_17', 'Gabor_18', 'Gabor_19', 'Gabor_20', 'Gabor_21', 'Gabor_22', 'Gabor_23', 'Gabor_24', 'Gabor_25', 'Gabor_26', 'Gabor_27', 'Gabor_28', 'Gabor_29', 'Gabor_30', 'Gabor_31', 'Gabor_32', 'Gabor_33', 'Gabor_34', 'Gabor_35', 'Gabor_36', 'Gabor_37', 'Gabor_38', 'Gabor_39', 'Gabor_40', 'Gabor_41', 'Gabor_42', 'Gabor_43', 'Gabor_44', 'Gabor_45', 'Gabor_46', 'Gabor_47', 'Gabor_48', 'Gabor_49', 'Gabor_50', 'Gabor_51', 'Gabor_52', 'Gabor_53', 'Gabor_54', 'Gabor_55', 'Gabor_56', ...
    'LoG_1', 'LoG_2', 'LoG_3', 'LoG_4', 'LoG_5', 'LoG_6', 'LoG_7', 'LoG_8', 'LoG_9', 'LoG_10', 'LoG_11', 'LoG_12', 'LoG_13', 'LoG_14', 'LoG_15', 'LoG_16'});
predictorNames = {'norm', 'LBP_1', 'LBP_2', 'LBP_3', 'LBP_4', 'LBP_5', 'LBP_6', 'LBP_7', 'LBP_8', 'LBP_9', 'LBP_10', 'LBP_11', 'LBP_12', 'LBP_13', 'LBP_14', 'mean', 'std', 'entropy', 'skewness', 'kurtosis', 'contrast', 'correlation', 'energy', 'homogenity', 'HOG_1', 'HOG_2', 'HOG_3', 'HOG_4', 'HOG_5', 'HOG_6', 'HOG_7', 'HOG_8', 'HOG_9', 'HOG_10', 'HOG_11', 'HOG_12', 'HOG_13', 'HOG_14', 'HOG_15', 'HOG_16', 'HOG_17', 'HOG_18',...
   'Gabor_1', 'Gabor_2', 'Gabor_3', 'Gabor_4', 'Gabor_5', 'Gabor_6', 'Gabor_7', 'Gabor_8', 'Gabor_9', 'Gabor_10', 'Gabor_11', 'Gabor_12', 'Gabor_13', 'Gabor_14', 'Gabor_15', 'Gabor_16', 'Gabor_17', 'Gabor_18', 'Gabor_19', 'Gabor_20', 'Gabor_21', 'Gabor_22', 'Gabor_23', 'Gabor_24', 'Gabor_25', 'Gabor_26', 'Gabor_27', 'Gabor_28', 'Gabor_29', 'Gabor_30', 'Gabor_31', 'Gabor_32', 'Gabor_33', 'Gabor_34', 'Gabor_35', 'Gabor_36', 'Gabor_37', 'Gabor_38', 'Gabor_39', 'Gabor_40', 'Gabor_41', 'Gabor_42', 'Gabor_43', 'Gabor_44', 'Gabor_45', 'Gabor_46', 'Gabor_47', 'Gabor_48', 'Gabor_49', 'Gabor_50', 'Gabor_51', 'Gabor_52', 'Gabor_53', 'Gabor_54', 'Gabor_55', 'Gabor_56', ...
   'LoG_1', 'LoG_2', 'LoG_3', 'LoG_4', 'LoG_5', 'LoG_6', 'LoG_7', 'LoG_8', 'LoG_9', 'LoG_10', 'LoG_11', 'LoG_12', 'LoG_13', 'LoG_14', 'LoG_15', 'LoG_16'};
predictors = inputTable(:, predictorNames);
response = inputTable.Class;
numericPredictors = table2array(varfun(@double, predictors));

clear cSamples;

%% Sprawdzenie w³aœciwoœci dyskryminacyjnych cech - class separability za pomoc¹ FDR

% indeksy odpowiadaj¹ce za odpowiednie klasy
classTumor = numericPredictors(find(response == 1), :); 
classKidney = numericPredictors(find(response == 0), :);

% Fisher discriminant ratio
FDR = zeros(size(classKidney, 2), 1);
for i = 1 : size(classKidney, 2)
    % obliczenie œredniej dla klasy nerka i guz w zaleznoœci od wybranej
    % cechy (i)
    meanKidney = mean(classKidney(:, i));
    meanTumor = mean(classTumor(:, i));
    varKidney = var(classKidney(:, i));
    varTumor = var(classTumor(:, i));
    
    FDR(i) = ((meanKidney - meanTumor)/(varKidney^2 + varTumor^2))^2;
end

% obliczenie indeksów cech za pomoc¹ FDR -> wektor cech jest u³o¿ony w
% kolejnoœci malej¹cej od cech o FDR najwiêkszym do FDR najmniejszego
% Cechy odpowiadaj¹ce za lepsz¹ separowalnoœæ cech s¹ na pocz¹tku
[~, FDR_feature_rank] = sort(FDR, 'descend');

clearvar meanKidney meanTumor varKidney varTumor i classTumor classKidney FDR;

%% Rank Features based on Bhatta Charyya criterion
% dla porównania z FDR
BC = response == 1;
[BC_feature_rank, ~] = rankfeatures(numericPredictors', BC, 'CrossNorm', 'meanvar');

clear BC; 

%% Compare features rank
compare = [predictorNames(FDR_feature_rank)' predictorNames(BC_feature_rank)'];

predictors = inputTable(:, predictorNames(FDR_feature_rank));
response = inputTable.Class;
numericPredictors = table2array(varfun(@double, predictors));
% dataFDR = [response numericPredictors];

clear FDR_feature_rank BC_feature_rank compare;

%% Apply a PCA to the predictor matrix.
% 'inf' values have to be treated as missing data for PCA.
numericPredictors(isinf(numericPredictors)) = NaN;
% obliczenie PCA
[pcaCoefficients, pcaScores, ~, ~, explained, pcaCenters] = pca(...
    numericPredictors, ...
    'Centered', true);

% Keep enough components to explain the desired amount of variance.
explainedVarianceToKeepAsFraction = 95/100;
numComponentsToKeep = find(cumsum(explained)/sum(explained) >= explainedVarianceToKeepAsFraction, 1);
pcaCoefficients = pcaCoefficients(:,1:numComponentsToKeep);
PCApredictors = [array2table(pcaScores(:,1:numComponentsToKeep))];

clear explained explainedVarianceToKeepAsFraction numComponentsToKeep pcaCoefficients inputTable pcaCenters pcaScores predictorNames;

%% FDR - dimention reduction
% redukcja wymiarowoœci wektora cech z wykorzystaniem scatter matrix
% compute the Scatter Matrices
[Sw, Sb, ~] = scatterMatrices(numericPredictors, response);

[W, LAMBDA] = eig(Sb,Sw);
lambda = diag(LAMBDA);
[~, SortOrder] = sort(lambda,'descend');
W = W(:,SortOrder);
numericPredictors = numericPredictors*W;

clear W LAMBDA lambda Sw Sb SortOrder;

%% CROSS - VALIDATION - licznoœæ zbiorów, overfitting, generalizacja
% z wykorzystaniem walidacji krzy¿owej Kfold
K = 5;
indices = crossvalind('Kfold' ,response, K);
for i = 1 : K
    testind = (indices == i); trainind = ~testind;
end

test = numericPredictors(find(testind == 1), :);
test_response = response(find(testind == 1));
train = numericPredictors(find(trainind == 1), :);
train_response = response(find(trainind == 1));

clear Train i count_test count_train test_size K trainind testind; 

%% SVM

% Train a training set - cubic SVM
tic
classificationSVM = fitcsvm(...
    train, ...
    train_response, ...
    'KernelFunction', 'polynomial', ...
    'PolynomialOrder', 3, ...
    'KernelScale', 'auto', ...
    'BoxConstraint', 1, ...
    'Standardize', true, ...
    'ClassNames', [single(0); single(1)]);
toc

%% Classify a testing set
tic
SVMclass = predict(classificationSVM, test);
toc

% Verify classifier
% pierwsza kolumna to wynik klasyfikacji, druga kolumna to rzeczywista
% klasa: nerka = 0, guz = 1

SVMclass(:,2) = single(test_response);
x = 0;
for i = 1:size(SVMclass,1)
    if SVMclass(i,1) == SVMclass(i,2)
        x = x + 1;
    end
end
validation_accuracy.ALL = x/size(SVMclass,1)*100;
clear i; clear x;

%%
% %% Weryfikacja ró¿nic w obliczonych Features pomiêdzy guzem a nerk¹
% 
% verifyFeatures = struct('structure', [], 'LBPdata', [], 'bin_proc',[] , 'LBP', [], 'Z_norm', [], 'mean', [], 'std', []);
% verifyFeatures(1).structure = 'tumor';
% verifyFeatures(2).structure = 'kidney';
% 
% tumorData = zeros(size(classifyData));
% kidneyData = zeros(size(classifyData));
% count_t = 1;
% count_k = 1;
% 
% for i = 1:size(classifyData,1)
%     if classifyData(i,1) == 1
%         tumorData(count_t,:) = classifyData(i,:);
%         count_t = count_t + 1;
%     else
%         kidneyData(count_k,:) = classifyData(i,:);
%         count_k = count_k + 1;
%     end
% end
% 
% tumorData = tumorData(1:count_t,:);
% kidneyData = kidneyData(1:count_k,:);
% clear i, clear count_t, clear count_k;
% 
% % % histogramy feature dla raka i nerki
% figure
% subplot(2,1,1)
% histogram(tumorData(:,2))
% title('tumor')
% subplot(2,1,2)
% histogram(kidneyData(:,2))
% title('kidney')
% % % mo¿na odj¹æ histogramy, ¿eby zobaczyæ ró¿nice
% 
% clear kidneyData; clear tumorData;
% %% Wizualizacja otrzymanych wyników
% 
% train = [train train(:,5)];
% test = [test SVMclass];
% ValidationData = [train; test];
% 
% % wycinamy kolumny oznaczaj¹ce numer pacjenta, indeksy i wartoœci klasy
% % przed i po klasyfikacji i przyporz¹dkowyjemy do pacjenta
% CT(p).validation = [];
% for p = 1:length(CT)
%     
%     % inicjalizacja rekonstruowanego obrazu
%     CT(p).reconstr_SVMclass = zeros(max(CT(p).validation(:,3)), max(CT(p).validation(:,4), max(CT(p).validation(:,5))));   
%     CT(p).reconstr_class = zeros(max(CT(p).validation(:,3)), max(CT(p).validation(:,4), max(CT(p).validation(:,5))));
%     
%     for row = 1 : length(ValidationData)        
%         if ValidationData(row, 1) == CT(p).patient
%             % dane - klasa, indeksy, wynik klasyfikacji
%             CT(p).validation = [CT(p).validation; ValidationData(row, 2:5)  ValidationData(row, end)];
%         end
%         
%         if ValidationData(row, 2) ~= ValidationData(row, end)
%             ValidationData(row, end) = 5;
%         end
%         
%         % rekonstrukcja obrazów
%         CT(p).reconstr_SVMclass(CT(p).validation(:,3), CT(p).validation(:,4), CT(p).validation(:,5)) = ValidationData(row, end);
%         CT(p).reconstr_class(CT(p).validation(:,3), CT(p).validation(:,4), CT(p).validation(:,5)) = ValidationData(row, 2);
%         
%         clear CT(p).validation;
%     end
% end
% 
% 
% %% OCENA WYNIKÓW KLASYFIKACJI
% %%----KRZYWE roc, TABELE PORÓWNAWCZE 
% 
% % Wizualizacja Filtrów Gabora
% 
% for p = 1:length(g)
%         subplot(5,6,p);
%         imshow(real(g(p).SpatialKernel),[]);
%         lambda = g(p).Wavelength;
%         theta  = g(p).Orientation;
%         title(sprintf('Re[h(x,y)], \\lambda = %d, \\theta = %d',lambda,theta));
% end