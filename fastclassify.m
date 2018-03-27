function [ err, CM ] = fastclassify( predictors, response )
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here
    numericPredictors = predictors;

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

    SVMclass(:,1) = single(response(testind));
    SVMclass(:, 2) = predict(classificationSVM, test);

    CP = classperf(SVMclass(:,1)', SVMclass(:,2)');
    err = CP.ErrorRate;
    
    CM = figure();
    plotconfusion(SVMclass(:,1)', SVMclass(:,2)')
end

