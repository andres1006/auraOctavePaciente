## Copyright (C) 2017 oscann
## 
## This program is free software; you can redistribute it and/or modify it
## under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 3 of the License, or
## (at your option) any later version.
## 
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
## 
## You should have received a copy of the GNU General Public License
## along with this program.  If not, see <http://www.gnu.org/licenses/>.

## -*- texinfo -*- 
## @deftypefn {Function File} {@var{retval} =} peakIdentification (@var{input1}, @var{input2})
##
## @seealso{}
## @end deftypefn

## Author: oscann <oscann@oscann-260-p103ns>
## Created: 2017-09-14

function [peakInds,peakMags] = peakIdentification (x0,threshold,sel)

#IN
  %x0: data.gaze
  %threshold: minimum value of peaks
  %sel:specify selectivity
#OUT
  %peaksInds: Array which contain indices of peaks
  %peaksMags: Array which contain magnitude of peaks
thrpeak=1;
s = size(x0); %get size of data to compare number of rows and columns
flipData =  s(1) < s(2); %Check if data needs to be flipped (if it's horizontal instead of vertical array)
len0 = numel(x0); %calculate total number of elements in data
dx0 = diff(x0); % Find derivative

dx0(dx0 == 0) = -eps; % Make 0 values be called this so we find the 1st of repeated values
ind = find(dx0(1:end-1).*dx0(2:end) < 0)+1; % Find indices where derivative changes sign

% Include endpoints in potential peaks and valleys
%save data values at points where derivative changes sign and endpoints
x = [x0(1);x0(ind);x0(end)]; % x only has peaks, valleys (points where derivative changed signs but don't qualify as peaks), and endpoints
%(Silvia) Es necesario meter los endpoints por si hay un pico en ellos o en el anterior pico, ya que si no, el while de mas abajo no los cuenta como tales.
ind = [1;ind;len0]; %save their indices
minMag = min(x); %find the smallest magnitude of x, to initiate tempMag 
leftMin = minMag; %initiate the left minimum as the absolute minimum calculated above
len = numel(x);%calculate number of elements in x
%ii=0;
% if len > 2 % If x has more than 2 elements it's a function with peaks and valleys
%   % Set initial parameters for loop as no peak found and absolute minimum magnitude of x
%   tempMag = minMag;
%   foundPeak = false;
%end

%(Silvia) Como se han añadido los endpoints, se necesita evaluarlos (puede que el punto metido sea un peak), para ellos:
%-> si los 3 puntos son crecientes se elimina el primero x(1) (El mas pequeño de los dos)
%-> si los 3 puntos son decrecientes se elimina el segundo x(2) (El mas pequeño de los dos)
%-> si hay alternancia decreciente/creciente o hay dos iguales no se elimina ningun numero, puede que sean peak.
peakInds=-1;
peakMags=-1;

if len > 2 % If x has more than 2 elements it's a function with peaks and valleys
   % Set initial parameters for loop as no peak found and absolute minimum magnitude of x
   tempMag = minMag;
   foundPeak = false;
   % Deal with 1st point separately since tacked it on
   % Calculate sign of derivative since tacked pt on, it doesn't neccessarily alternate like rest
   signDx = sign(diff(x(1:3)));
   if signDx(1) <= 0 % The 1st point is larger or equal to 2nd
      if signDx(1) == signDx(2) % exclude 2nd point since want alternating signs, so count endpt only
         x(2) = [];
         ind(2) = [];
         len = len-1;%new length is 1 less
      end
   else % derivative is positive, so 1st point is smaller than 2nd
       if signDx(1) == signDx(2) % exclude 1st pt since want alternating signs
          x(1) = [];
          ind(1) = [];
          len = len-1;%new length is 1 less
       end
   end



  % Skip the 1st point if it is smaller so we always start on maxima
  if x(1) >= x(2)
      ii = 0; %set ii to use as index in loop below
  else
      ii = 1;
  end
  % Preallocate max number of maxima as half the # of elements in x rounded up
  maxPeaks = ceil(len/2);
  peakLoc = zeros(maxPeaks,1); %initiate peak index array
  peakMag = zeros(maxPeaks,1); %initiate peak magnitude array
  cInd = 1; %initiate index for peak locations and magnitudes
  % Loop through extrema which should be peaks and then valleys

  while ii < len
        ii = ii+1; % This is the index of a peak (which is always followed by valley)
        % Reset peak finding if found a peak before, so that future loops can run
        %make temp mag be the absolute minimum of x again, to compare points to it 
        if foundPeak
           tempMag = minMag;
           foundPeak = false;
        end

        % Check if found new point larger than temp mag (absolute minimum or previous point if it wasn't a peak) and
        % than selectivity plus minimum to its left (1st it is the minimum of x, and for rest of loop it becomes the value of the previous valley)
        if x(ii) > tempMag && x(ii) > leftMin + sel
           tempLoc = ii; %store index and magnitude of point to compare in future loop to the valley that follows
           tempMag = x(ii);
        end

        % Make sure we don't iterate past the length of our vector
        if ii == len
           break; % Assign the last point differently out of the loop
        end

        ii = ii+1; % Move onto the valley
        % Check if the point found is at least sel bigger than the valley that follows it
        if ~foundPeak && tempMag > sel + x(ii)
          if tempMag>threshold
            threshigh=x0(ind(tempLoc))+thrpeak;
            threshlow=x0(ind(tempLoc))-thrpeak;
              if(length(ind)<200) indice=200; else indice=length(ind); endif
               for j=1:indice
                  if tempLoc == 1
                    foundPeak = true; % Found a peak
                    leftMin = x(ii); %make the valley the new left minimum
                    peakLoc(cInd) = ind(tempLoc); % Save peak magnitude and its index
                    peakMag(cInd) = x0(ind(tempLoc));
                    cInd = cInd+1; %update the index for the peak locations and magnitudes
                    break;
                  else
                    if j==indice
                       foundPeak = true; % Found a peak
                       leftMin = x(ii); %make the valley the new left minimum
                       peakLoc(cInd) = ind(tempLoc-j); % Save peak magnitude and its index
                       peakMag(cInd) = x0(ind(tempLoc-j));
                       cInd = cInd+1; %update the index for the peak locations and magnitudes
                       break;
                    elseif tempLoc-j<1
                       foundPeak = true; % Found a peak
                       leftMin = x(ii); %make the valley the new left minimum
                       peakLoc(cInd) = ind(1); % Save peak magnitude and its index
                       peakMag(cInd) = x0(ind(1));
                       cInd = cInd+1; %update the index for the peak locations and magnitudes
                       break;
                    elseif ((threshlow>x0(ind(tempLoc-j))) || (threshigh<x0(ind(tempLoc-j))))
                       foundPeak = true; % Found a peak
                       leftMin = x(ii); %make the valley the new left minimum
                       peakLoc(cInd) = ind(tempLoc-j+1); % Save peak magnitude and its index
                       peakMag(cInd) = x0(ind(tempLoc-j+1));
                       cInd = cInd+1; %update the index for the peak locations and magnitudes
                       break;
                    end
                  end
               end
          end
          
        elseif x(ii) < leftMin % Store valley as new left minimum
              leftMin = x(ii);
        end
  end

  % Check end point of data and of x against absolute minimum (or previous point if it wasn't a peak) and previous valley
  %check endpoint of data, which is also endpoint of x
  if x(end) > tempMag && x(end) > leftMin + sel %compare to previous valley and absolute minimum
      peakLoc(cInd) = len; %store endpoint index as a peak
      peakMag(cInd) = x(end); %store its magnitude
      cInd = cInd + 1; %update the index for the peak locations and magnitudes
  elseif ~foundPeak && tempMag > minMag %If endpoint isn't peak check previous point, if it wasn't considered peak before
      peakLoc(cInd) = ind(tempLoc); %save its magnitude and index if bigger than the absolute minimum
      peakMag(cInd) = tempMag;
      cInd = cInd + 1; %update the index for the peak locations and magnitudes
  end

  % Create output
  if cInd > 1 %if found any peaks, store the indices and magnitudes in new arrays
      peakInds = peakLoc(1:cInd-1); %save all data indices corresponding to peakLoc values of peaks, only have values up to cInd-1 since cInd was updated after endpoint and past that left as 0s
      peakMags = peakMag(1:cInd-1); %save magnitudes of those peaks, including up to last element that isn't 0 in peakMag
  else %if didn't find peaks then make empty arrays
      peakInds = [];
      peakMags = [];
  end

  %% Minima Analysis - Threshold Filtering
  % Apply threshold value. Since adjusted sign for minima, it will always be larger than threshold for either maxima
  m = peakMags>threshold; %only keep magnitudes larger than threshold
  peakInds = peakInds(m);
  peakMags = peakMags(m);

  % Rotate data if needed
  if flipData
      peakMags = peakMags.';
      peakInds = peakInds.';
  end
endif
endfunction
