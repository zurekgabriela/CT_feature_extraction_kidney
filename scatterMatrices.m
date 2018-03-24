function [Sw, Sb, Sm] = scatterMatrices(data, response)
%   FUNCTION THAT CALCULATES SCATTER MATRIX - Sw the within-class, Sb the
%   between-class and the mixture (Sm) for a c-classification problem

%   Scatter Matrix
    [n, l] = size(data);         %CALCULATE SIZE OF DATA
    classes = unique(response);          %GET VECTOR OF CLASSES
    tot_classes = length(classes); %HOW MANY CLASSES
    
    Sb = zeros(l,l);              %INIT B AND W
    Sw = zeros(l,l);           
    overallmean = mean(data);    %MEAN OVER ALL DATA
    
    for i = 1 : tot_classes
        classei = find(response == classes(i)); %GET DATA FOR EACH CLASS
        xi = data(classei,:);
        
        mci = mean(xi);                       %MEAN PER CLASS
        xi = xi - repmat(mci, length(classei), 1); %Xi-MeanXi
        Sw = Sw + xi'*xi;                         %CALCULATE W
        Sb = Sb + length(classei)*(mci - overallmean)'*(mci - overallmean); %CALCULATE B
    end
    
    % Computation of Sm 
    Sm = Sw + Sb;
end 

    



