function [ features ] = extractGMag( image, class, nonEmptyIdx ) 

%%
image = (single(image));
 
% Gradient Magnitude w trzech kierunkach - x y z gradient components
[Gx,Gy,Gz] = imgradientxyz(image);
% extract Gabor magnitude features from source image.
[Gmag,~] = imgradient3(image, 'sobel');

GmagFeatures = cell(size(image, 1), size(image, 2), size(image, 3));
%%
for row = 1 : size(image, 1)
    row
    for col = 1 : size(image, 2)
        for vol = 1 : size(image, 3) 
            
            if class(row,col,vol) > 0             
                A = [Gx(row, col, vol)^2 Gx(row, col, vol)*Gy(row, col, vol) Gx(row, col, vol)*Gz(row, col, vol); ...
                    Gx(row, col, vol)*Gy(row, col, vol) Gy(row, col, vol)^2 Gy(row, col, vol)*Gz(row, col, vol); ...
                    Gx(row, col, vol)*Gz(row, col, vol) Gy(row, col, vol)*Gz(row, col, vol) Gz(row, col, vol)^2]; 

                H = det(A) - 0.04*trace(A)^2;
                S = min(eig(A));
                N = 2*det(A)/trace(A);

                feature_vec = [Gmag(row, col, vol) H S N]; 
                GmagFeatures{row, col, vol} = feature_vec;
            end
            
        end
    end
end
         
% przekszta³cenie features z komórki do wektora
features = [GmagFeatures{nonEmptyIdx}];
features = reshape(features,[4,length(features)/4])';      
    
end


