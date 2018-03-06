close all; clear all;

%% Wizualizacja obrazu orginalnego

Image = load('CTsmall1.mat');
I = Image.CTsmall;
figure(); imshow(I(:,:,20), []); title('Original image');

% kontur nerki z nowotworem
Contour = load('Obrys_small1.mat');
C = Contour.Obrys_small;
figure(); imshow(C(:,:,20), []); title('Contour image');

%% Wizualizacja nerki wraz z obrysem nowotworu

% kontur nerki z nowotworem
Contour = load('Obrys_small1.mat');
C = Contour.Obrys_small(:,:,36);
figure(); imshow(C,[]);

% kontur nowotworu
ctumor = zeros(size(C));
for i = 1:size(C,1)
    for j = 1:size(C,2)
        if C(i,j) == 2
            ctumor(i,j) = 1;
        else 
            ctumor(i,j) = 0;
        end
    end
end

figure(); imshow(ctumor,[]);

% kontur nerki
ckidney = zeros(size(C));
for i = 1:size(C,1)
    for j = 1:size(C,2)
        if C(i,j) == 1
            ckidney(i,j) = 1;
        else 
            ckidney(i,j) = 0;
        end
    end
end

figure(); imshow(ckidney,[]);
%% Maskowanie obrazu

ikidney = I.*int16(ckidney);
figure(); imshow(ikidney,[min(min(I))  max(max(I))]); title('Segmented kidney without tumor')

itumor = I.*int16(ctumor);
figure(); imshow(itumor,[min(min(I))  max(max(I))]); title('Segmented tumor of kidney')

image = I.*int16(ckidney+ctumor);
figure(); imshow(image,[min(min(I))  max(max(I))]); title('Segmented kidney with tumor')

%% Wizualizacja wszystkich przekrojów

% za³adowanie wszystkich obrazów i przekrojów
images = Image.CTsmall;
contours = Contour.Obrys_small;

% rozmiar przekroju 
ImgSize = int16(size(images, 3));

% inicjalizacja przetworzonego przekroju
SlicesCut = zeros(size(images));

% Segmentacja obrazów od numeru œrodkowego do koñca
for i = 1:ImgSize   
    % Wczytywanie kolejnych przekroi i konturów od œrodka
    slice = images(:,:,i);
    contour = contours(:,:,i);
    % Zapisywanie wysegmentowanych przekrojów do macierzy
    SlicesCut(:,:,i) = slice.*int16(contour);
end

% Wizualizacja 3D konturów

segments = squeeze(SlicesCut);
contourslice(segments,[],[],1:size(segments,3))
view(3), axis tight

% Wizualizacja 3D wysegmentowanej nerki

figure()
%# visualize the volume
p = patch( isosurface(segments,0) );                 %# create isosurface patch
isonormals(segments, p)                              %# compute and set normals
set(p, 'FaceColor',[0.5 0.5 0.5], 'EdgeColor','none')   %# set surface props
% daspect([1 1 1])                              %# axes aspect ratio
view(3), axis vis3d tight, box on, grid on    %# set axes props                          
camlight, lighting phong, alpha(.5)           %# enable light, set transparency

%%
%%----------------- Przygotowanie bazy treningowej i testowej--------------

% baza treningowa - zdjêcie, klasa, docelowo LBP histogram
train_set(1).image = I(:,:,36);
train_set(1).contour = C(:,:,36);
train_set(1).class = 1;

train_set(2).image = I(:,:,24);
train_set(2).contour = C(:,:,24);
train_set(2).class = 0;

train_set(3).image = I(:,:,40);
train_set(3).contour = C(:,:,40);
train_set(3).class = 1;

train_set(4).image = I(:,:,42);
train_set(4).contour = C(:,:,42);
train_set(4).class = 1;

train_set(5).image = I(:,:,18);
train_set(5).contour = C(:,:,18);
train_set(5).class = 0;

train_set(6).image = I(:,:,22);
train_set(6).contour = C(:,:,22);
train_set(6).class = 0;


%% Detekcja ROI i Ekstrakcja cech - maskowanie obrazu nerki i ekstrakcja cech LBP

for im_num = 1:size(train_set,2)
    % Apply mask to the image
    train_set(im_num).mask = train_set(im_num).image.*int16(train_set(im_num).contour);
    
    train_set(im_num).LBPfeatures = extractLBPFeatures(train_set(im_num).mask,'Upright',false);
    figure
    bar(train_set(im_num).LBPfeatures)
    title(num2str(train_set(im_num).class))
%     % Extract unnormalized LBP features so that you can apply a custom normalization.
%     lbpFeatures = extractLBPFeatures(train_set(im_num).mask,'CellSize',[32 32],'Normalization','None');
%     % Reshape the LBP features into a number of neighbors -by- number of cells array to access histograms for each individual cell.
%     numNeighbors = 8;
%     numBins = numNeighbors*(numNeighbors-1)+3;
%     lbpCellHists = reshape(lbpFeatures,numBins,[]);
%     % Normalize each LBP cell histogram using L1 norm.
%     lbpCellHists = bsxfun(@rdivide,lbpCellHists,sum(lbpCellHists));
%     % Reshape the LBP features vector back to 1-by- N feature vector.
%     train_set(im_num).LBP = reshape(lbpCellHists,1,[]);
%     % Draw histogram
%     figure(im_num)
%     bar(train_set(im_num).LBP','grouped')
%     % imhist(train_set(im_num).LBP)
%     title(num2str(train_set(im_num).class))
end

%% Analiza dyskryminacyjna cech

regions = detectMSERFeatures(I);
figure; imshow(I, []); hold on;
plot(regions,'showPixelList',true,'showEllipses',false);

%% Klasyfikacja
% SVM
% Skrypty w Skrypty i dane

