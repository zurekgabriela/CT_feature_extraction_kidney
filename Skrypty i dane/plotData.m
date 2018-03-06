function plotData(X, y)
%PLOTDATA Plots the data points X and y into a new figure 
%   PLOTDATA(x,y) plots the data points with red square for the benign examples
%   and green circle for the malignant examples. X is assumed to be a Mx3 matrix.

hold on;

% Find indices of beign and malignant examples
benign = find(y == 0); 
malignant = find(y == 1);

% Plot Examples
plot3(X(benign, 1), X(benign, 2), X(benign, 3), 'ks', 'MarkerFaceColor', 'g', ...
    'MarkerSize', 6);
plot3(X(malignant, 1), X(malignant, 2), X(malignant, 3), 'ko', 'MarkerFaceColor', 'r', ...
    'MarkerSize', 6);
view(3)
grid on

hold off;

end
