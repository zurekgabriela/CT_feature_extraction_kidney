function [test_features, test_class, predict_class, err] = optimalFeature(features, class)

% Funtion returns an error calculated from prediction and test set of the
% features. 

%% Dividing dataset for a training set and test set. 
% Training set:
train_features = features(1:490,:);
train_class = class(1:490,:);

% Test set
test_features = features(491:699,:);
test_class = class(491:699,:);

%%  Compute cost and gradient
[m, n] = size(train_features);

% Initialize fitting parameters
initial_theta = zeros(n + 1, 1);

% Compute and display initial cost and gradient
[cost, grad] = costFunction(initial_theta, train_features, train_class);

%%  Optimizing using fminunc 
%  Set options for fminunc
options = optimset('GradObj', 'on', 'MaxIter', 400);

%  Run fminunc to obtain the optimal theta. This function will return theta and the cost 
[theta, cost] = ...
	fminunc(@(t)(costFunction(t, train_features, train_class)), initial_theta, options);

%% Predict and Accuracies
prob = sigmoid([ones(size(test_features,1), 1) test_features] * theta);

% Compute accuracy on our training set
predict_class = predict(theta, [ones(size(test_features,1), 1) test_features]);

%% Calculating error on prediction.
err = 0;
for i = 1:size(predict_class,1)
    
    err = err + (predict_class(i)-test_class(i))^2;
   
end
end

