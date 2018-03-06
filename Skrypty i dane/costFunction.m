function [J, grad] = costFunction(theta, X, y)
%COSTFUNCTION Compute cost and gradient for logistic regression
%   J = COSTFUNCTION(theta, X, y) computes the cost of using theta as the
%   parameter for logistic regression and the gradient of the cost
%   w.r.t. to the parameters.

% Initialize some useful values
m = length(y); % number of training examples
X = [ones(m, 1) X];

J = 0;
grad = zeros(size(theta));

% Implement sigmoid function
h = sigmoid(X*theta);

% Calculate cost
J = 1/m*sum(-y.*log(h)-(1-y).*log(1-h));

% Calculate gradient
grad=zeros(size(theta));

for i = 1:size(grad)
    grad(i) = (1/m)*sum((h - y)' * X(:,i));
end
