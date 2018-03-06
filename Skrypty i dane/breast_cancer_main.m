%% Initialization
clear ; close all; clc

%% The data is loaded and classes set to 0 for benign cancer and 1 for malignant cancer. 

data = load('breast-cancer-wisconsin.txt');
class = data(:, 11);

for i=1:size(class);
    if class(i) == 2;
        class(i) = 0;
    else class(i) == 4;
        class(i) = 1;
    end
end

%% SVM - Looking for set of features, which predict classes with the less error.

opt_err = 100;
for i = 2:(size(data,2)-3)
    for j = (i+1):(size(data,2)-2)
        for k = (j+1):(size(data,2)-1)
            
            features = data(:, [i, j, k]); 
            
            % Clasiffication on the following set of features and
            % calculating error
            
            % SVM
            [test_features, test_class, predict_class, err] = optimalFeatureSVM(features, class);
            
            % Taking out the most accurate feature set.
            if err < opt_err
                opt_err = err;
                opt_features = features;
                svm_opt_test_features = test_features;
                svm_opt_test_class = test_class;
                svm_opt_predict_class = predict_class;
                opt_f = [i,j,k];
            end
            fprintf('%d %d %d \n',i,j,k);
        end
    end
end

%% SVM - Visualize data on test set and prediction set

figure();
subplot(1,3,1)
plotData(svm_opt_test_features, svm_opt_test_class);

% Put some labels 
hold on;
% Labels and Legend
title('Real classification')
xlabel('clump thickness')
ylabel('single epithelial cell size')
zlabel('mitoses')

% Specified in plot order
legend('Benign cancer' ,'Malignant cancer')
hold off;

subplot(1,3,2)
plotData(svm_opt_test_features, svm_opt_predict_class);

% Put some labels 
hold on;
% Labels and Legend
title('Prediction effect')
xlabel('clump thickness')
ylabel('single epithelial cell size')
zlabel('mitoses')

% Specified in plot order
legend('Benign cancer' ,'Malignant cancer')
hold off;

%% Confusion matrix

%SVM
svm_conf_matrix = zeros(2,2);

for i = 1:size(svm_opt_predict_class,1)
if double(svm_opt_predict_class(i)) == svm_opt_test_class(i)
    if svm_opt_predict_class(i) == 1
        % True Positives
        svm_conf_matrix(1,1) = svm_conf_matrix(1,1) + 1;
    else
        % True Negatives
        svm_conf_matrix(2,2) = svm_conf_matrix(2,2) + 1;
    end
else
    if svm_opt_predict_class(i) == 0
        % False Positives
        svm_conf_matrix(1,2) = svm_conf_matrix(1,2) + 1;
    else
        % False Negatives
        svm_conf_matrix(2,1) = svm_conf_matrix(2,1) + 1;
    end
end
end
