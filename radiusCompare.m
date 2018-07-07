clc;    % Clear the command window.
close all;  % Close all figures 
imtool close all;  % Close all imtool figures.
clear;  % Erase all existing variables.
workspace;  % Make sure the workspace panel is showing.

%% WCZYTYWANIE DANYCH

path = 'Data';
list = dir(path);
[~,index] = sortrows({list.name}.'); list = list(index); clear index
CT = struct('patient', [], 'image', [], 'class',[]);

for i = 1:length(list);
    patientPath = [path '\' list(i).name];    
    if ~strcmp(list(i).name, '.') && ~strcmp(list(i).name, '..')
        infoCT = mha_read_header([patientPath '\CT.mhd']);
        dim = infoCT.Dimensions;
        I = imread_RawData([patientPath '\CT.raw'], dim(1), dim(2), dim(3), 'int16');
        M = imread_RawData([patientPath '\Nerka i guz.raw'], dim(1), dim(2), dim(3), 'int16');
        CT(i).image = I;
        CT(i).class = M;
        CT(i).patient = list(i).name;       
    end    
    clear patientPath; clear infoCT; clear dim; clear i; clear I; clear M; 
end
%CT = CT(3:length(list));
% Roboczo jeden pacjent, by nie zajmowaæ zbyt du¿o pamiêci
CT = CT(7:7);
clear list i;

%% PRZEKSZTA£CENIE DANYCH

for i = 1:length(CT)
    i
    nonEmptyIdx = find(~(CT(i).class==0));
    [nonEmptyRow,nonEmptyCol,nonEmptyVol] = ind2sub(size(CT(i).image),nonEmptyIdx);
    % Przekszta³cenie klas obrazów tak, by nerka by³a oznaczona wartoœci¹ 1, a guz wartoœci¹ 2
    % class: nerka = 1; guz = 2 
    for j = 1 : length(nonEmptyIdx)
        row = nonEmptyRow(j);
        col = nonEmptyCol(j);
        vol = nonEmptyVol(j);
        if (CT(i).class(row, col, vol) == 1) || (CT(i).class(row, col, vol) == 6)
            CT(i).class(row, col, vol) = 1;
        elseif (CT(i).class(row, col, vol) == 2) || (CT(i).class(row, col, vol) == 3)
            CT(i).class(row, col, vol) = 2;
        end
    end

    CT(i).class = single(CT(i).class);
    clearvars row col vol; 
    sprintf('przekszta³cono klasê %s',CT(i).patient)

    % Normalizacja typu Z   
    [~, mu, sigma] = zscore(CT(i).image(nonEmptyIdx), 1);
    CT(i).norm = zeros(size(CT(i).image));
    CT(i).norm = (CT(i).image-mu)./sigma;
    sprintf('znormalizowano dane %s',CT(i).patient) 
    CT(i).norm = single(CT(i).norm);
     
    % Czyszczenie pamiêci
    CT(i).image = [];  
end
clear i j mu sigma path; CT = rmfield(CT, {'image'});


%% EKSTRAKCJA CECH CHARAKTERYSTYCZNYCH

% zmieniamy rozmiar promienia
for i = 1 : length(CT)  
    % Przekszta³cenie próbek w wektor do klasyfikacji
    % znalezienie indeksów oznaczaj¹cych nerkê i guza (bez t³a)
    nonEmptyIdx = find(~(CT(i).class == 0));
    [nonEmptyRow,nonEmptyCol,nonEmptyVol] = ind2sub(size(CT(i).norm),nonEmptyIdx);
    CT(i).samples = [nonEmptyRow nonEmptyCol nonEmptyVol single(CT(i).class(nonEmptyIdx)-1) single(CT(i).norm(nonEmptyIdx))];

    sprintf('wyszukano indeksy i zapisano dane Row, Col, Vol, class, norm do wektora cech %s',CT(i).patient)

    for radius = 1 : 5 : 26
        radius
        % Feature extraction
        %% Filtry Gabora
        [CT(i).GaborMag] = extractGaborFilter( single(CT(i).norm), nonEmptyRow, nonEmptyCol, nonEmptyVol, radius );
        sprintf('obliczono filtry Gabora %s',CT(i).patient)

        % zapisanie danych do wektora
        CT(i).samples = [CT(i).samples single(CT(i).GaborMag)];
        sprintf('zapisano filtry Gabora w wektorze samples %s',CT(i).patient)

        CT(i).GaborMag = [];
    end
    
    fname = sprintf('samples_%s', CT(i).patient);
    vname = 'features';
    eval([vname '= CT(i).samples;']);
    save(strcat('features\', fname), vname);
end
    
%% Load data

myFolder = 'CT_feature_extraction_kidney'; % Define your working folder
if ~isdir(myFolder)
  errorMessage = sprintf('Error: The following folder does not exist:\n%s', myFolder);
  uiwait(warndlg(errorMessage));
  return;
end

list = dir('samples');
iter = 1;
for i = 1:length(list);
    if ~strcmp(list(i).name, '.') && ~strcmp(list(i).name, '..')
        tempStruct = load(fullfile('..', 'CT_feature_extraction_kidney', 'samples', list(i).name));
        featureStruct(iter).name = list(i).name(1:end-4);
        featureStruct(iter).samples = tempStruct(1).samples;
        iter = iter + 1;
    end
end

clear i list myFolder tempStruct iter;

%% Feature processing
% Po³¹czenie danych z kilku zdjêæ
samples = [];
for i = 1 : length(featureStruct)
    samples = [samples; featureStruct(i).features];
end

% Mix kolejnoœci danych
r = randperm(size(samples,1));
samples = samples(r,:);

%% Missing data
samples(isinf(samples)) = NaN; % Inf is treated as missing data
[nanrows, ~, ~] = find(isnan(samples));
samples(nanrows, :) = [];

%% Normalizacja wektora cech - normalizujemy dane powy¿ej kolumny 4 oznaczaj¹cej klasê
sumOut = 0;
for k = 5 : size(samples, 2)
    k
    % Normalizacja
    samples(:,k) = zscore(samples(:,k));
    
    % Median Absolute Deviation
%     threshold = 10;
%     medianValue = median(samples(:, k));
%     MAD = median(abs(samples(:, k) - medianValue));
%     outliers = 0.6745*(samples(:, k) - medianValue)/MAD > threshold;
%     samples(find(outliers == 1), :) = [];
% 
%     sumOut = sumOut + sum(outliers);
end

samples(isinf(samples)) = 0; 
samples(isnan(samples)) = 0; 
clear k nanrows r i featureStruct threshold medianValue MAD outliers;

% Do klasyfikacji bierzemy np co 20 próbkê, aby zmniejszyæ z³o¿onoœæ obliczeniow¹

ind = 1 : 50 : size(samples);
samples = samples(ind, :);
clear ind clear;

%% dlugosc wektora cech
feature_length = 56;
response = samples(:, 4);
smallest_error = 1;
% pierwsza kolumna w wektorze cech oznaczaj¹ca LBP
first = 6;

for i = 1 : 5 : 6
    i
    predictors = samples(:, first : (first + feature_length - 1));
    [err, CM] = fastclassify(predictors, response);
    first = first + feature_length;
    ERROR(i).radius = i;
    ERROR(i).err = err;
    if err < smallest_error
        smallest_error = err;
        best_radius = i;
    end  
end
%%
figure;
plot([ERROR.radius], [ERROR.err])
