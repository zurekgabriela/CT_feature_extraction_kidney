function tests = extractTest
tests = functiontests(localfunctions);
end

function testExtractStats(testCase)
testimage = zeros(3, 3, 3);
testclass = zeros(3, 3, 3);
testimage(:,:,2) = [0 0 0; 0 10 5; 0 0 0];
testclass(:,:,2) = [0 0 0; 0 2 1; 0 0 0];
solution = extractStats(testimage, testclass, 1);
actLength = solution{2, 2, 2};
expLength = 5;
verifyLength(testCase, actLength, expLength);
end


% extractLoG
% extractLBP
% etractGLCM
% extractGaborFilter
% extract3DHOG

% scatterMatrices + Gmag - ?