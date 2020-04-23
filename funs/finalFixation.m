## Copyright (C) 2018 oscann
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
## @deftypefn {Function File} {@var{retval} =} finalFixation (@var{input1}, @var{input2})
##
## @seealso{}
## @end deftypefn

## Author: oscann <oscann@oscann-260-p103ns>
## Created: 2018-01-15

function [finalFixations] = finalFixation (indexInitialPoints, indexFixations, time, gaze, indexStimChange)
  %defines
  minimaDuracion=200;
  maxDuration=0;
  fixationEnd=1;
  compareValue=0;
  m=0;
 
  finalFixations=-1; 
  if indexFixations!=-1 && indexInitialPoints!=-1 %si no hay fijaciones no hay finales de fijacion
    %Se inicializa fixationEnd, como la primera fijacion despues del primer punto inicial encontrado
    for k=1:length(indexInitialPoints)
        if (indexInitialPoints(k)!=1)
            for j=1:length(indexFixations(:,1))
                if indexFixations(j,1)>=indexInitialPoints(k)
                    fixationEnd=j;
                    break;
                endif
            endfor
            break;   
        endif
    endfor

    finalFixations=zeros(length(indexInitialPoints),1);
    for i=1:length(indexInitialPoints) 
      %inicializar outputs 
      maxDuration=0;
%      finalFixations(i)=0; 
      if indexInitialPoints(i)==1 % si no hay punto inicial no hay fijacion final
        continue;
      end
      if fixationEnd>length(indexFixations(:,1)) %seguridad para que no de error en el caso que fixationEnd sea mayor que el limite
        break;
      endif
%      %se coge la primera fijacion despues del punto inicial como final de fijacion de esa sacada
%      finalFixationsStart(i)=indexFixations(fixationEnd,1); 
%      finalFixationsEnd(i)=indexFixations(fixationEnd,2); 
%      finalFixationsMean(i)=mean(gaze(indexFixations(fixationEnd,1):indexFixations(fixationEnd,2)));
%      maxDuration=time(finalFixationsEnd(i))-time(finalFixationsStart(i));
      
      if i<length(indexInitialPoints) 
        if indexInitialPoints(i+1)!=1
            compareValue=indexInitialPoints(i+1);
        else
            compareValue=indexStimChange(i+1);
        end
      else
        compareValue=indexInitialPoints(i);
      endif
      %se evaluan todas las fijaciones hasta el siguiente punto inicial( si no tiene punto inicial hasta el siguiente cambio de estimulo) o en el caso del ultimo punto inicial hasta el limite del vector
      while(indexFixations(fixationEnd,2)<=compareValue || i==length(indexInitialPoints) && fixationEnd<=length(indexFixations(:,1)))
        if indexFixations(fixationEnd,1)>=indexInitialPoints(i) %El comienzo de la fijacion debe estar despues del punto inicial
          if(time(indexFixations(fixationEnd,2))-time(indexFixations(fixationEnd,1))) > maxDuration && (time(indexFixations(fixationEnd,2))-time(indexFixations(fixationEnd,1))) > minimaDuracion%Prevalece la que tiene mas duracion
             finalFixations(i)=fixationEnd;
             maxDuration=time(indexFixations(fixationEnd,2))-time(indexFixations(fixationEnd,1));
          endif
        endif
        
        fixationEnd++;
        if fixationEnd>length(indexFixations(:,1))
          break;
        endif
      endwhile 
    endfor
  endif
  
endfunction
