function [test_features, test_class, predict_class, err] = optimalFeature(features, class)

%% Dividing dataset for a training set and test set. 
% Training set:
train_features = features(1:490,:);
train_class = class(1:490,:);

% Test set
test_features = features(491:699,:);
test_class = class(491:699,:);

%% Training Linear SVM 
%  The following code will train a linear SVM on the dataset and plot the
%  decision boundary learned.

C = 1;
model = svmTrain(train_features, train_class, C, @linearKernel, 1e-3, 20);

%% Prediction on the data:

predict_class = svmPredict(model, test_features);

%% Calculating error on prediction.

err = 0;
for i = 1:size(predict_class,1)
    
    err = err + (predict_class(i)-test_class(i))^2;
   
end
end
