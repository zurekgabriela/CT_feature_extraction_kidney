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

clear i list myFolder tempStruct iter;

%% Analiza ró¿nic pomiêdzy guzem i nerk¹
tumor = [];
kidney = [];
for i = 1 : length(featureStruct)
    
    featureStruct(i).kidney = zeros(4, size(featureStruct(1).features, 2));
    featureStruct(i).tumor = zeros(4, size(featureStruct(1).features, 2));
    
    tumorind = find(featureStruct(i).features(:,4) == 1); 
    kidneyind = find(featureStruct(i).features(:,4) == 0);

    for k = 5 : size(featureStruct(i).features, 2)
        featureStruct(i).tumor(1, k) = mean(featureStruct(i).features(tumorind, k));
        featureStruct(i).tumor(2, k) = std(featureStruct(i).features(tumorind, k));
        featureStruct(i).tumor(3, k) = min(featureStruct(i).features(tumorind, k));
        featureStruct(i).tumor(4, k) = max(featureStruct(i).features(tumorind, k));
        
        featureStruct(i).kidney(1, k) = mean(featureStruct(i).features(kidneyind, k));
        featureStruct(i).kidney(2, k) = std(featureStruct(i).features(kidneyind, k));
        featureStruct(i).kidney(3, k) = min(featureStruct(i).features(kidneyind, k));
        featureStruct(i).kidney(4, k) = max(featureStruct(i).features(kidneyind, k));
    end
    
    tumor = [tumor; featureStruct(i).tumor];
    kidney = [kidney; featureStruct(i).kidney];
end

clear i k tumorind kidneyind;
%% Feature processing

% Po³¹czenie danych z kilku zdjêæ
samples = [];
for i = 2:length(featureStruct)
    samples = [samples; featureStruct(i).features];
end

testsamples = []; % obraz spoza zbioru treningowego
for i = 1
    testsamples = [testsamples; featureStruct(i).features];
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
%     samples(:,k) = samples(:,k)/norm(samples(:,k));
%     testsamples(:,k) = testsamples(:,k)/norm(testsamples(:,k));
    
    samples(:,k) = normalizeToRange(samples(:,k), 0, 10);
    testsamples(:,k) = normalizeToRange(testsamples(:,k), 0, 10);
    
    % Outlier removal
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
ind = [1 : 20 : size(samples)];
samples = samples(ind, :);
clear ind clear;

% Feature selection
% Convert input to table
inputTable = array2table(samples, 'VariableNames', {'Row', 'Col', 'Vol', 'Class', 'norm', 'LBP_1', 'LBP_2', 'LBP_3', 'LBP_4', 'LBP_5', 'LBP_6', 'LBP_7', 'LBP_8', 'LBP_9', 'LBP_10', 'LBP_11', 'LBP_12', 'LBP_13', 'LBP_14', 'mean', 'std', 'entropy', 'skewness', 'kurtosis', 'contrast', 'correlation', 'energy', 'homogenity', 'HOG_1', 'HOG_2', 'HOG_3', 'HOG_4', 'HOG_5', 'HOG_6', 'HOG_7', 'HOG_8', 'HOG_9', 'HOG_10', 'HOG_11', 'HOG_12', 'HOG_13', 'HOG_14', 'HOG_15', 'HOG_16', 'HOG_17', 'HOG_18',...
    'Gabor_1', 'Gabor_2', 'Gabor_3', 'Gabor_4', 'Gabor_5', 'Gabor_6', 'Gabor_7', 'Gabor_8', 'Gabor_9', 'Gabor_10', 'Gabor_11', 'Gabor_12', 'Gabor_13', 'Gabor_14', 'Gabor_15', 'Gabor_16', 'Gabor_17', 'Gabor_18', 'Gabor_19', 'Gabor_20', 'Gabor_21', 'Gabor_22', 'Gabor_23', 'Gabor_24', 'Gabor_25', 'Gabor_26', 'Gabor_27', 'Gabor_28', 'Gabor_29', 'Gabor_30', 'Gabor_31', 'Gabor_32', 'Gabor_33', 'Gabor_34', 'Gabor_35', 'Gabor_36', 'Gabor_37', 'Gabor_38', 'Gabor_39', 'Gabor_40', 'Gabor_41', 'Gabor_42', 'Gabor_43', 'Gabor_44', 'Gabor_45', 'Gabor_46', 'Gabor_47', 'Gabor_48', 'Gabor_49', 'Gabor_50', 'Gabor_51', 'Gabor_52', 'Gabor_53', 'Gabor_54', 'Gabor_55', 'Gabor_56', ...
    'LoG_1', 'LoG_2', 'LoG_3', 'LoG_4', 'LoG_5', 'LoG_6', 'LoG_7', 'LoG_8', 'LoG_9', 'LoG_10', 'LoG_11', 'LoG_12', 'LoG_13', 'LoG_14', 'LoG_15', 'LoG_16'});
predictorNames = {'norm', 'LBP_1', 'LBP_2', 'LBP_3', 'LBP_4', 'LBP_5', 'LBP_6', 'LBP_7', 'LBP_8', 'LBP_9', 'LBP_10', 'LBP_11', 'LBP_12', 'LBP_13', 'LBP_14', 'mean', 'std', 'entropy', 'skewness', 'kurtosis', 'contrast', 'correlation', 'energy', 'homogenity', 'HOG_1', 'HOG_2', 'HOG_3', 'HOG_4', 'HOG_5', 'HOG_6', 'HOG_7', 'HOG_8', 'HOG_9', 'HOG_10', 'HOG_11', 'HOG_12', 'HOG_13', 'HOG_14', 'HOG_15', 'HOG_16', 'HOG_17', 'HOG_18',...
    'Gabor_1', 'Gabor_2', 'Gabor_3', 'Gabor_4', 'Gabor_5', 'Gabor_6', 'Gabor_7', 'Gabor_8', 'Gabor_9', 'Gabor_10', 'Gabor_11', 'Gabor_12', 'Gabor_13', 'Gabor_14', 'Gabor_15', 'Gabor_16', 'Gabor_17', 'Gabor_18', 'Gabor_19', 'Gabor_20', 'Gabor_21', 'Gabor_22', 'Gabor_23', 'Gabor_24', 'Gabor_25', 'Gabor_26', 'Gabor_27', 'Gabor_28', 'Gabor_29', 'Gabor_30', 'Gabor_31', 'Gabor_32', 'Gabor_33', 'Gabor_34', 'Gabor_35', 'Gabor_36', 'Gabor_37', 'Gabor_38', 'Gabor_39', 'Gabor_40', 'Gabor_41', 'Gabor_42', 'Gabor_43', 'Gabor_44', 'Gabor_45', 'Gabor_46', 'Gabor_47', 'Gabor_48', 'Gabor_49', 'Gabor_50', 'Gabor_51', 'Gabor_52', 'Gabor_53', 'Gabor_54', 'Gabor_55', 'Gabor_56', ...
    'LoG_1', 'LoG_2', 'LoG_3', 'LoG_4', 'LoG_5', 'LoG_6', 'LoG_7', 'LoG_8', 'LoG_9', 'LoG_10', 'LoG_11', 'LoG_12', 'LoG_13', 'LoG_14', 'LoG_15', 'LoG_16'};
% predictorNames = {'LoG_1', 'LoG_2', 'LoG_3', 'LoG_4', 'LoG_5', 'LoG_6', 'LoG_7', 'LoG_8', 'LoG_9', 'LoG_10', 'LoG_11', 'LoG_12', 'LoG_13', 'LoG_14', 'LoG_15', 'LoG_16'};
predictors = inputTable(:, predictorNames);
response = inputTable.Class;
numericPredictors = table2array(varfun(@double, predictors));

clear samples;

%% CROSS - VALIDATION - licznoœæ zbiorów, overfitting, generalizacja
% z wykorzystaniem walidacji krzy¿owej Kfold
K = 5;
indices = crossvalind('Kfold' ,response, K);
for i = 1 : K
    testind = (indices == i); trainind = ~testind;
end
clear i K indices;

train = numericPredictors(trainind, :);
test = numericPredictors(testind, :);

%% Sprawdzenie w³aœciwoœci dyskryminacyjnych cech - class separability za pomoc¹ FDR
% indeksy odpowiadaj¹ce za odpowiednie klasy
classTumor = numericPredictors(find(response(trainind) == 1), :); 
classKidney = numericPredictors(find(response(trainind) == 0), :);

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

clear meanKidney meanTumor varKidney varTumor i classTumor classKidney FDR;

features = predictorNames(FDR_feature_rank);
numericPredictors = inputTable(:, predictorNames(FDR_feature_rank));
numericPredictors = table2array(varfun(@double, numericPredictors));

% features to keep
FtoKeep = 114;
numericPredictors = numericPredictors(:, 1 : FtoKeep);
train = numericPredictors(trainind, :);
test = numericPredictors(testind, :);
features = features(1 : FtoKeep);

clear FDR_feature_rank;
%% Apply a PCA to the predictor matrix.

PCAtoKeep = 114;
% obliczenie PCA
[pcaCoefficients, pcaScores] = pca(...
    numericPredictors(trainind, :), ...
    'Centered', true);

reducedPCA = pcaCoefficients(:, 1:PCAtoKeep);
train = numericPredictors(trainind, :)*reducedPCA;
test = numericPredictors(testind, :)*reducedPCA;

clear pcaCoefficients pcaScores reducedPCA PCAtoKeep;

%% SVM
% Train a training set - cubic SVM
tic
classificationSVM = fitcsvm(...
    train, ...
    response(trainind), ...
    'KernelFunction', 'polynomial', ...
    'PolynomialOrder', 3, ...
    'KernelScale', 'auto', ...
    'BoxConstraint', 1, ...
    'Standardize', true, ...
    'ClassNames', [single(0); single(1)]);
toc

%% Classify a testing set

test = testsamples(:, 5:end); % testowanie obrazu, który jest spoza zbioru treningowego
SVMclass(:,1) = single(testsamples(:, 4));
% SVMclass(:,1) = single(response(testind));
SVMclass(:, 2) = predict(classificationSVM, test);

% Verify classifier
% pierwsza kolumna to rzeczywista klasa: nerka = 0, guz = 1, druga kolumna
% to wynik klasyfikacji

CP = classperf(SVMclass(:,1)', SVMclass(:,2)');
disp(CP.ErrorRate)
disp(CP.CorrectRate)

CM = figure();
plotconfusion(SVMclass(:,1)', SVMclass(:,2)')

ROC = figure();
plotroc(SVMclass(:,1)', SVMclass(:,2)')

figure;
plot(loss(classificationSVM, SVMclass(:,1)', SVMclass(:,2)', 'mode', 'cumulative'));

clear i; clear x;

%% RUSBoost - overfitting problem

tabulate(response)
rng(10,'twister')         % For reproducibility

part = cvpartition(response, 'Holdout', 0.5);

istrain = training(part); % Data for fitting
istest = test(part);      % Data for quality assessment

tabulate(response(istrain))

N = sum(istrain);         % Number of observations in the training sample
t = templateTree('MaxNumSplits', N);
% t = templateTree('Surrogate','On');
tic
rusTree = fitensemble(predictors(istrain,:), response(istrain), 'RUSBoost', 100, t);
toc

figure;
tic
plot(loss(rusTree, predictors(istest,:), response(istest), 'mode', 'cumulative'));
toc
grid on;
xlabel('Number of trees');
ylabel('Test classification error');
%
tic
% responsefit = predict(rusTree, predictors(istest,:));
responsefit = predict(rusTree, testsamples(:, 5:end));
toc

figure;
% plotconfusion(response(istest)', responsefit')
plotconfusion(testsamples(:, 4)', responsefit')
figure;
% plotroc(response(istest)', responsefit')
plotroc(testsamples(:, 4)', responsefit')
%% Wizualizacja otrzymanych wyników
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