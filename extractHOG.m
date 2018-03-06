function hog1 = extractHOG(image_gray,rect)

[hog_gradient_x,hog_gradient_y]=gradient(double(image_gray));
hog_gradient_x=-hog_gradient_x;
hog_gradient_y=-hog_gradient_y;
gradient_norm=sqrt(hog_gradient_x.^2+hog_gradient_y.^2);

S=size(image_gray);
rows=S(1);
cols=S(2);
rows_div=rows/rect(1);
cols_div=cols/rect(2);
%compute gradient

degrees=pi/180*[0 20 40 60 80 100 120 140 160 180];
bins=zeros(rows,cols);
hog_bins_h=zeros(rows,cols);
hog_bins_l=zeros(rows,cols);
hog_modules_h=zeros(rows,cols);
hog_modules_l=zeros(rows,cols);
hog_bins_valid=zeros(rows,cols);

for i=1:rows
    for j=1:cols
        i
        if hog_gradient_x(i,j)~=0 | hog_gradient_y(i,j)~=0
            % bin_raw to obliczony k¹t
            bin_raw=atan2(hog_gradient_y(i,j),hog_gradient_x(i,j))*9/pi;
            bins(i,j)=bin_raw;
            if bin_raw>0
                bin_mod=bins(i,j);
                hog_bins_h(i,j)=mod(round(bin_raw),9);
                hog_bins_l(i,j)=mod(round(bin_raw-1),9);
                hog_modules_h(i,j)=(bin_mod-round(bin_raw-1)-0.5)*gradient_norm(i,j);
                hog_modules_l(i,j)=(round(bin_raw)+0.5-bin_mod)*gradient_norm(i,j);
            else
                bin_mod=bins(i,j)+9;
                hog_bins_h(i,j)=mod(round(bin_raw+9),9);
                hog_bins_l(i,j)=mod(round(bin_raw+8),9);  
                hog_modules_h(i,j)=(bin_mod-round(bin_raw+8)-0.5)*gradient_norm(i,j);
                hog_modules_l(i,j)=(round(bin_raw+9)+0.5-bin_mod)*gradient_norm(i,j);
            end
            
            %check those abs
            hog_bins_valid(i,j)=1;
        else
            hog_bins_valid(i,j)=0;
            hog_bins_h(i,j)=10;
            hog_bins_l(i,j)=10;
        end
    end
end
bins1=(bins~=0).*(bins-1)*20;

% histogram=zeros(1,9);
% for j=1:cols
%     if hog_bins_valid(1,j)==1
%         histogram(hog_bins_h(1,j)+1)=histogram(hog_bins_h(1,j)+1)+hog_modules_h(1,j);
%         histogram(hog_bins_l(1,j)+1)=histogram(hog_bins_l(1,j)+1)+hog_modules_l(1,j);
%     end
% end

histograms=cell(rows_div,cols_div);
for cell_y=0:rows_div-1
    for cell_x=0:cols_div-1
        histograms{cell_y+1,cell_x+1}=zeros(1,9);
        for row=1:rect(1)
            for column=1:rect(2)
                if hog_bins_valid(cell_y*rect(1)+row,cell_x*rect(2)+column)~=0    %od 0 do 8, wiêc trzeba +1!
                    histograms{cell_y+1,cell_x+1}(hog_bins_h(cell_y*rect(1)+row,cell_x*rect(2)+column)+1)=histograms{cell_y+1,cell_x+1}(hog_bins_h(cell_y*rect(1)+row,cell_x*rect(2)+column)+1)+hog_modules_h(cell_y*rect(1)+row,cell_x*rect(2)+column);
                    histograms{cell_y+1,cell_x+1}(hog_bins_l(cell_y*rect(1)+row,cell_x*rect(2)+column)+1)=histograms{cell_y+1,cell_x+1}(hog_bins_l(cell_y*rect(1)+row,cell_x*rect(2)+column)+1)+hog_modules_l(cell_y*rect(1)+row,cell_x*rect(2)+column);
                end
            end
        end
    end
end

hog1=[];
for i=1:rows_div-1
    for j=1:cols_div-1
        temp_hist=[histograms{i,j} histograms{i,j+1} histograms{i+1,j} histograms{i+1,j+1}];
        temp_hist=temp_hist/sqrt(norm(temp_hist)^2+1);
        hog1=[hog1 temp_hist];
    end
end

% [hog1, gDir] = extractHOGFeature(image_gray,'CellSize',[8 8], 'BlockSize',[2 2], 'BlockOverlap', [1 1], 'NumBins', 9);
% plot(visualization);                    