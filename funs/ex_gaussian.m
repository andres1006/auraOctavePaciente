% Function for obtaining the Exponentially modified Gaussian distribution
% Inputs:
%    x   - Point to calculate
%    h - Amplitude of the gaussian distribution (1).
%    mean - Mean od the gaussian distribution
%    SD - Standar Desviation for the gaussian distribution
%    ErelaxTime - is exponent relaxation time.

%
% Outputs:
%    microsaccades - Column one: Result




function [result] = ex_gaussian(x,h,mean,SD,ErelaxTime)

result=(h*SD/ErelaxTime)*sqrt(pi()/2)*exp(0.5*(SD/ErelaxTime)^2 - (x-mean)/ErelaxTime)*erfc(1/(sqrt(2))*(SD/ErelaxTime - (x-mean)/SD));
