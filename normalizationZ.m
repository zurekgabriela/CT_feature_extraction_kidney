function [ normImage ] = normalizationZ( mask ) 
% Normalization to Zero Mean and Unit of Energy

normImage = zeros(size(mask));
    
% wyciamy dane bez t³a
sample = ~(mask == 0);
sample = zeros(sum(sum(sum(sample))),1);
count = 1;

for j = 1:size(mask,1)
    for k = 1:size(mask,2)  
        for m = 1:size(mask,3)
            if mask(j,k,m) ~= 0
                sample(count,1) = mask(j,k,m);
                count = count + 1;
            end            
        end
    end
end   

mean_Z = mean(sample);
std_Z = std(sample);

for j = 1:size(normImage,1)
    for k = 1:size(mask,2)
        for m = 1:size(mask,3)
            if mask(j,k,m) ~= 0
                % do maski nadpisywana jest wartoœæ znormalizowana
                normImage(j,k,m) = (mask(j,k,m)-mean_Z)/std_Z;          
            end            
        end
    end
end    


end


%%

nonEmptyIdx = find(~(CT(i).class==0));
CT(i).norm = zeros(size(CT(i).mask));
CT(i).norm(nonEmptyIdx) = zscore(CT(i).mask(nonEmptyIdx), 1);

