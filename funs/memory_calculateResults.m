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
## @deftypefn {Function File} {@var{retval} =} calculateResults (@var{input1}, @var{input2})
##
## @seealso{}
## @end deftypefn

## Author: oscann <oscann@oscann-260-p103ns>
## Created: 2018-01-15

function [latency,velocitypeak,amplitudeErrorPositivo,amplitudeErrorNegativo,peakmaxstimmax,peakmaxstimmed,peakmaxstimmin,gain,memorySuccess, memory, anticipatedPoints, nAnticipated, latency_v, velocitypeak_v] = memory_calculateResults (indexInitialPoints, indexStimChange, stimulus, time, velocidad, finalFixations, gaze, indexFixations)

################################################################################
##############################MEMORY SUCCESS####################################
################################################################################

memory=zeros(length(indexInitialPoints),1);
memorySuccess=0;
latency=-1;
velocitypeak=-1;
amplitudeErrorPositivo=-1;
amplitudeErrorNegativo=-1;
peakmaxstimmax=-1;
peakmaxstimmed=-1;
peakmaxstimmin=-1;
gain=-1;
anticipatedPoints=-1;
nAnticipated=0;
latency_v=-1;
velocitypeak_v=-1;

if finalFixations!=-1 && indexInitialPoints!=-1 % Si no tiene fijaciones finales o puntos iniciales

  for i=3:4:length(indexInitialPoints) % Solo en las de ida de memoria, cada 4 empezando por la 3.
    
    if indexInitialPoints(i)!=1 && finalFixations(i)!=0 %Para que sea correcta se necesita que tenga punto inicial y fijacion final de la mirada.
      reference=stimulus(indexStimChange(i)+1);
      referenceCenter=0;
      gazeRange=gaze(indexStimChange(i):indexStimChange(i+1));
      gazeRangeCenter=gaze(indexStimChange(i-1):indexStimChange(i));
      margin=abs(stimulus(indexStimChange(i+1))*0.5);
      
      for j=1:length(gazeRange)
        if gazeRange(j)<reference+margin && gazeRange(j)>reference-margin
          for jj=1:length(gazeRangeCenter)
            if gazeRangeCenter(jj)<referenceCenter+2 && gazeRangeCenter(jj)>referenceCenter-2
              memorySuccess++;
              memory(i)=1;
              if (i<length(indexInitialPoints))
                memory(i+1)=1;
              endif
              break;
            endif
          endfor
          break;
        endif
      endfor
    endif
  endfor

  ##############################ANTICIPATED POINTS################################
  [anticipatedPoints, nAnticipated, nAnticipated_v] = memory_AnticipatedInitPoints (indexInitialPoints, indexStimChange, time, memory); 
endif

################################################################################
#####################LATENCY AND VELOCITY PEAK##################################
################################################################################

#IDA
l=0;
v=0;
latency=-1;
velocitypeak=-1;

#VUELTA
latency_v=-1;
velocitypeak_v=-1;
lv=0;
vv=0;

i=3;

if indexInitialPoints!=-1
  while i<=length(indexStimChange) -1
    if mod(i,2) ~= 0 %numero impar ##SÁCADAS DE IDA
      if indexInitialPoints(i)!=1 && memory(i)==1 && anticipatedPoints(i)!=1
      
        %LATENCY
        l++;
        latency(l)=time(indexInitialPoints(i))-time(indexStimChange(i));
        
        %VELOCITY PEAK
        vMax=0;
        for j=1:15
          if j+indexInitialPoints(i)<length(velocidad)
            if vMax<abs(velocidad(j+indexInitialPoints(i)))
              vMax=abs(velocidad(j+indexInitialPoints(i)));
            endif 
          endif  
        endfor
        v++;
        velocitypeak(v)=vMax;
      endif
      
      i++;
    else %numero par ##SÁCADAS DE VUELTA
      if indexInitialPoints(i)!=1 && memory(i)==1 && anticipatedPoints(i)!=1
        lv++;
        latency_v(lv)=time(indexInitialPoints(i))-time(indexStimChange(i));
        
        %VELOCITY PEAK
        vMax=0;
        for j=1:15
          if j+indexInitialPoints(i)<length(velocidad)
            if vMax<abs(velocidad(j+indexInitialPoints(i)))
              vMax=abs(velocidad(j+indexInitialPoints(i)));
            endif 
          endif  
        endfor
        vv++;
        velocitypeak_v(vv)=vMax;
      endif
      i=i+3;
    endif   
  endwhile
endif

################################################################################
#####################AMPLITUDE ERROR, GAIN AND PEAKMAX##########################
################################################################################


apos=0;
aneg=0;
amplitudeErrorPositivo=-1;
amplitudeErrorNegativo=-1;

stimMax=max(abs(stimulus(stimulus!=0)));
stimMin=min(abs(stimulus(stimulus!=0)));
emax=0;
emin=0;
emed=0;
peakmaxstimmax=-1;
peakmaxstimmed=-1;
peakmaxstimmin=-1;

n=0;
gain=-1;

jj=3;

if finalFixations!=-1 && indexInitialPoints!=-1 % Si no tiene fijaciones finales o puntos iniciales no se obtienen errores de las sacadas, NI LOS PICOS MAXIMOS NI LA GANANCIA.
  while jj<=length(indexStimChange) -1
    if finalFixations(jj)!=0 && memory(jj)==1 && anticipatedPoints(jj)!=1 && indexInitialPoints(jj)!=1 %Si no tiene fijacion final no puede tener error.
    
      %AMPLITUDE ERROR
      if stimulus(indexStimChange(jj)+1)<stimulus(indexStimChange(jj)-1) %depende de el sentido de la sacada.
        Error=stimulus(indexStimChange(jj)+1)-mean(gaze(indexFixations(finalFixations(jj),1):indexFixations(finalFixations(jj),2)));
      else
        Error=mean(gaze(indexFixations(finalFixations(jj),1):indexFixations(finalFixations(jj),2)))-stimulus(indexStimChange(jj)+1);
      endif 
      if Error>=0
        apos++;
        amplitudeErrorPositivo(apos)=Error;
      elseif Error<0
        aneg++;
        amplitudeErrorNegativo(aneg)=Error;
      endif
      
      %PEAK MAX
      region=gaze(indexFixations(finalFixations(jj),1):indexFixations(finalFixations(jj),2));
      if stimulus(indexStimChange(jj)-1)<stimulus(indexStimChange(jj)+1)
      peakmax=abs(max(region)-stimulus(indexStimChange(jj)-1));
      else
      peakmax=abs(min(region)-stimulus(indexStimChange(jj)-1));
      endif
      if abs(stimulus(indexStimChange(jj)-1)-stimulus(indexStimChange(jj)+1))> stimMax-1 %estimulo Máximo
        emax++;
        peakmaxstimmax(emax)=peakmax;
      elseif abs(stimulus(indexStimChange(jj)-1)-stimulus(indexStimChange(jj)+1))<stimMax-1 && abs(stimulus(indexStimChange(jj)-1)-stimulus(indexStimChange(jj)+1))>stimMin+1
        emed++;
        peakmaxstimmed(emed)=peakmax;
      elseif abs(stimulus(indexStimChange(jj)-1)-stimulus(indexStimChange(jj)+1))<stimMin+1
        emin++;
        peakmaxstimmin(emin)=peakmax;
      endif
      
      %GAIN
      stimulusAmplitude=stimulus(indexStimChange(jj)+10)-stimulus(indexStimChange(jj)-10);
      amplitudegaze=mean(gaze(indexFixations(finalFixations(jj),1):indexFixations(finalFixations(jj),2)))-gaze(indexInitialPoints(jj));
      n++;
      gain(n)=amplitudegaze/stimulusAmplitude;
      
    endif
    jj+=4; %Cada 4 empezando por la 3, solo se analizan las de ida
  endwhile
endif

endfunction
