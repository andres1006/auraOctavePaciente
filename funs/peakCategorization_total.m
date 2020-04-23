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
## @deftypefn {Function File} {@var{retval} =} peakCategorization_total (@var{input1}, @var{input2})
##
## @seealso{}
## @end deftypefn

## Author: oscann <oscann@oscann-260-p103ns>
## Created: 2017-09-27

function [peakColor] = peakCategorization_total (peakInds, peakMag, stimulus, x0, time, indexStimChange, Initialpoints)
#IN
  %peaksInds: Array which contain indices of peaks
  %peaksMag: Array which contain magnitude of peaks
  %stimulus: data.stimulus
  %anticipatedpoints: Array which contain '1' if the initial point is anticipated or '0' if isn't.
  %x0: data.gaze
  %time: data.time
  %indexStimChange: Array which contain the change in the stimulus.
  %Initialpoints: Array which contain the initial points of the saccades. 
#OUT
  %peakColor: Array which contain the peaks categozation. '1' is green, '2' is red, '3' is blue and '4' is orange. 
  
  peakColor=-1;
 if peakInds!=-1
  %calculate index difference of endpoints to get length of stimulus + center fixation before it
  threshold=1.75;
  range_length=indexStimChange(4)-indexStimChange(2)-1;
  %decide if pro or antisaccade by comparing to stimulus sign at the point it occurs
  %if it occurs with large latency, past stimulus (where=0), compare to stimulus before it
  for t=1:length(peakInds)
      if stimulus(peakInds(t))*peakMag(t)>0
        peakColor(t)=1;             
      elseif stimulus(peakInds(t))*peakMag(t)<0 %if peak has not same sign as stimulus then it's pro
        peakColor(t)=2;
      elseif stimulus(peakInds(t))==0 && peakInds(t)>(range_length)% && any(stimulus((peakInds(t)-(range_length)):peakInds(t))*peakMag(t)>0)
        for i=peakInds(t)-range_length:peakInds(t)   
          if stimulus(i)*peakMag(t)>0
            peakColor(t)=1;
            break;
          elseif stimulus(i)*peakMag(t)<0
            peakColor(t)=2;
            break;
          endif
        endfor
     endif
  endfor 

  %noAnticipated=zeros(length(peakInds));
  for h=1:length(peakInds)
    %noAnticipated(h)=0;
    if peakInds(h)<=round(range_length/2) %before the first stimulus change
        peakColor(h)=3;
    elseif h~=1 %it's not the first peak
        stimpeak=peakInds(h);
        if(stimulus(peakInds(h))==0) %referir al picos con estimulo 0 al estimulo anterior
          stimpeak=peakInds(h)-round(range_length/2);
          if stimpeak<0
            stimpeak=1;
          end
        endif
        stimpeakant=peakInds(h-1);
        if(stimulus(peakInds(h-1))==0) %referir al picos con estimulo 0 al estimulo anterior
          stimpeakant=peakInds(h-1)-round(range_length/2);
          if stimpeakant<0
            stimpeakant=1;
          end
        endif
      if(stimulus(peakInds(h))==0) && (stimulus(stimpeak)*peakMag(h)<0) && (stimulus(stimpeakant)*peakMag(h-1)>0) %the peak is red with stimulus 0 and the peak before is green
        %REFLEXIVA DE SEGUNDO ORDEN: Si el tiempo entre que entra al threshold y sale es menor que 300ms y si el pico se da antes de 250s una vez pasado el cambio de estimulo
        estado=0;
        t2=-1;  
        t1=-1;
        change=-1;
        for k=1:100 %for para encontrar la salida y la entrada del umbral
          if x0(peakInds(h)-k)>-threshold && x0(peakInds(h)-k)<threshold %Cuando entra a la franja de umbrales
            if estado==0
              t1=time(peakInds(h)-k);
              estado=1;
            endif
          elseif estado==1 %Cuando sale de la franja de umbrales
            t2=time(peakInds(h)-k);
            estado=0;
            break;
          endif
        endfor
        dif=10000;
        for kk=1:length(indexStimChange) %for para encontrar el cambio de estimulo correspondiente
          if(time(peakInds(h))-time(indexStimChange(kk))<dif) && (time(peakInds(h))-time(indexStimChange(kk))>0)
            diff=time(peakInds(h))-time(indexStimChange(kk));
            change=time(indexStimChange(kk));
            %Se busca el cambio de estimulo mas cercano por atras.
          endif
        endfor
        if (t2~=-1 && t1~=-1 && (abs(t2-t1)>300)) || (change!=-1 && (time(peakInds(h))-change>250)) %si entre el tiempo del pico y el cambio de estimulo hay mas de 250 
          peakColor(h)=3;                                                           %Si el tiempo que esta entre la franja de umbrales es mayor que 300ms
        %else
          %noAnticipated(h)=1;
        endif
       endif %the peak is red with stimulus 0 and the peak before is green %REFLEXIVA DE SEGUNDO ORDEN
      if h-1~=0 && peakColor(h-1)==peakColor(h) && stimpeak-round(range_length/2)<stimpeakant %si es pico anterior tiene la misma direccion y estan dentro del mismo estimulo
        peakColor(h)=3;
      elseif peakColor(h-1)==3 %si es pico anterior es AZUL
        if h-2~=0 && peakColor(h-2)==peakColor(h) && stimpeak-round(range_length/2)<stimpeakant %si el pico anterior tiene la misma direccion que este y estan dentro del mismo estimulo
          peakColor(h)=3;
        endif   
      endif
    endif %it's not the first peak
  endfor % for h=1:length(peakInds)

  %%Anticipated
  %for jj=1:length(anticipatedpoints)
  %  if anticipatedpoints(jj)==1
  %    for n=1:length(peakInds) %Si hay un punto de inicio anticipado se tiene que encontrar el pico correcpondiente a ese adelanto
  %      if time(Initialpoints(jj))<time(peakInds(n)) && time(peakInds(n))<time(indexStimChange(jj+1)) && noAnticipated==0
  %        %el pico sea mayor que el punto inicial adelantado, el pico no sea mayor que el siguiente estimulo y que no sea una reflexiva de segundo orden. ??
  %        peakColor(n)=4;
  %        break;
  %      end
  %    end
  %  end
  %end
  
endif %if peakInds!=-1
endfunction
