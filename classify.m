function [ err ] =  classify( samples, classifyData )
%CLASSIFY - klasyfikacja za pomoc¹ SVM

    %% Próbki do klasyfikacji -> wektor

    % Po³¹czenie danych z kilku zdjêæ
    classifyData = [classifyData; samples];

    % Mix kolejnoœci danych
    r = randperm(size(classifyData,1));
    classifyData = classifyData(r,:);
    

    %% CROSS - VALIDATION

    test_size = 3000;
    [Train, ~] = crossvalind('LeaveMOut', size(classifyData,1), test_size);

     train = zeros(size(classifyData,1)-test_size,size(classifyData,2));
     test = zeros(test_size,size(classifyData,2));
     count_test = 1;
     count_train = 1;

     for i = 1:size(classifyData,1)  
         if Train(i) == 1
             train(count_train,:) = classifyData(i,:);
             count_train = count_train + 1;
         else
             test(count_test,:) = classifyData(i,:);
             count_test = count_test + 1;
         end
     end
     
     sprintf('cross-walidacja zosta³a wykonana')

    %% SVM

    % Train a training set
    SVMtrain = fitcsvm(single(train(1:12000,6:end)), train(1:12000,4));
    sprintf('klasyfikator zosta³ nauczony')

    % Classify a testing set
    SVMclass = predict(SVMtrain, single(test(1:1000,6:end)));
    sprintf('predykcja zosta³a wykonana')

    % Verify classifier
    % pierwsza kolumna to wynik klasyfikacji, druga kolumna to rzeczywista
    % klasa: nerka = 0, guz = 1

    SVMclass(:,2) = test(1:1000,4);
    x = 0;
    for i = 1:size(SVMclass,1)
        if SVMclass(i,1) == SVMclass(i,2)
            x = x + 1;
        end
    end
    err = 1 - x/size(SVMclass,1);
    sprintf('obliczono b³¹d')

end

