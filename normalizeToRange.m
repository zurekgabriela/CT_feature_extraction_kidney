function [ normalized ] = normalizeToRange( samples, x, y )
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here

    % Normalize to [0, 1]:
    m = min(samples);
    range = max(samples) - m;
    normalized = (samples - m) / range;
     
    % Then scale to [x,y]:
    range2 = y - x;
    normalized = (normalized*range2) + x;
end

