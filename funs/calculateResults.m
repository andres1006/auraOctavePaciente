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

function [latency,velocitypeak,amplitudeErrorPositivo,amplitudeErrorNegativo,peakmaxstimmax,peakmaxstimmed,peakmaxstimmin,gain, latency_v,velocitypeak_v,amplitudeErrorPositivo_v,amplitudeErrorNegativo_v,gain_v] = calculateResults (indexInitialPoints, indexStimChange, anticipatedPoints, stimulus, time, velocidad, finalFixations, gaze, indexFixations)

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

if (indexInitialPoints!=-1)
  for i=1:length(indexStimChange) -1
    if indexInitialPoints(i)!=1 && anticipatedPoints(i)!=1 % Si la sacada esta adelantada o no tiene punto inicial no se calcula la latencia ni la velocidad pico.
      if mod(i,2) ~= 0 %numero impar ##SÁCADAS DE IDA
        %LATENCY IDA
        l++;
        latency(l)=time(indexInitialPoints(i))-time(indexStimChange(i));
        
        %VELOCITY PEAK IDA
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
      else %numero par ##SÁCADAS DE VUELTA
        %LATENCY VUELTA
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
    endif
  endfor
endif

################################################################################
#####################AMPLITUDE ERROR, GAIN AND PEAKMAX##########################
################################################################################

#IDA
apos=0;
aneg=0;
amplitudeErrorPositivo=-1;
amplitudeErrorNegativo=-1;
n=0;
gain=-1;

#VUELTA
aposv=0;
anegv=0;
amplitudeErrorPositivo_v=-1;
amplitudeErrorNegativo_v=-1;
nv=0;
gain_v=-1;

stimMax=max(abs(stimulus(stimulus!=0)));
stimMin=min(abs(stimulus(stimulus!=0)));
emax=0;
emin=0;
emed=0;
peakmaxstimmax=-1;
peakmaxstimmed=-1;
peakmaxstimmin=-1;

if finalFixations!=-1 && indexInitialPoints!=-1 % Si no tiene fijaciones finales o puntos iniciales no se obtienen errores de las sacadas, NI LOS PICOS MAXIMOS NI LA GANANCIA.
  for jj=1:length(indexStimChange) -1
    if finalFixations(jj)!=0 && anticipatedPoints(jj)!=1 && indexInitialPoints(jj)!=1 % Nos aseguramos que tenga fijacion final, que no este adelantada y que tenga punto inicial.
      if mod(jj,2) ~= 0 %numero impar ##SÁCADAS DE IDA 
      
        %AMPLITUDE ERROR IDA
        if stimulus(indexStimChange(jj)+1)<stimulus(indexStimChange(jj)-1)
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
        
        %PEAKMAX IDA
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
        
        %GAIN IDA
        stimulusAmplitude=stimulus(indexStimChange(jj)+10)-stimulus(indexStimChange(jj)-10);
        amplitudegaze=mean(gaze(indexFixations(finalFixations(jj),1):indexFixations(finalFixations(jj),2)))-gaze(indexInitialPoints(jj));
        n++;
        gain(n)=amplitudegaze/stimulusAmplitude;
        
      else %numero par ##SÁCADAS DE VUELTA
      
         %AMPLITUDE ERROR VUELTA
        if stimulus(indexStimChange(jj)+1)<stimulus(indexStimChange(jj)-1)
          Error=stimulus(indexStimChange(jj)+1)-mean(gaze(indexFixations(finalFixations(jj),1):indexFixations(finalFixations(jj),2)));
        else
          Error=mean(gaze(indexFixations(finalFixations(jj),1):indexFixations(finalFixations(jj),2)))-stimulus(indexStimChange(jj)+1);
        endif 
        if Error>=0
        aposv++;
        amplitudeErrorPositivo_v(aposv)=Error;
        elseif Error<0
        anegv++;
        amplitudeErrorNegativo_v(anegv)=Error;
        endif
        
        %GAIN VUELTA
        stimulusAmplitude=stimulus(indexStimChange(jj)+10)-stimulus(indexStimChange(jj)-10);
        amplitudegaze=mean(gaze(indexFixations(finalFixations(jj),1):indexFixations(finalFixations(jj),2)))-gaze(indexInitialPoints(jj));
        nv++;
        gain_v(nv)=amplitudegaze/stimulusAmplitude;
      endif  
    endif
  endfor
endif

endfunction
