function [sigFix] = significatedPeaks (indexStimChange, peakInds, gaze, stimulus, indexFixations, time)
#IN
  %indexStimChange: Array which contain the change in the stimulus.
  %peakInds:Array which contain indices of peaks
  %gaze: data.gaze
  %stimulus: data.stimulus
  %indexFixations: Array which contain the start and end of fixations.
  %time:data.time
#OUT
  %sigFix: Array which contain the last fixation of the saccade movement
sigFix=-1;
if peakInds!=-1
  n=0;
  p=0;
  for i=1:length(indexStimChange)-1
    n++;
    peak(n)=indexStimChange(i); %si no se encuentra pico se establece de referencia el estimulo
      if(i==1) %Se establece un zona donde buscar los picos significativos
        rangoInicio=1;
      else
        rangoInicio=indexStimChange(i-1);
      endif
      if (i==length(indexStimChange))
        rangoFin=indexStimChange(i);
      else
        rangoFin=indexStimChange(i+1);
      endif
      
      if stimulus(indexStimChange(i))==0
        p++;
        sigFix(p)=stimulus(indexStimChange(i));
        continue;
      end
      ###########################ENCONTRAR EL PICO SIGNIFICATIVO
      sigPeaks=peakInds((rangoInicio<=peakInds) & (peakInds<=rangoFin)); %Vector que contiene todos los picos del rango elegido
      if length(sigPeaks)==1 %Si solo hay un pico se establece como significativo
        peak(n)=sigPeaks(1);
      elseif length(sigPeaks)>1 %Si hay mas de un pico:
        for j=1:length(sigPeaks)
          if gaze(sigPeaks(end-j+1))*stimulus(rangoFin)>0 || gaze(sigPeaks(end-j+1))*stimulus(indexStimChange(i))>0 %El primer pico por atras que tenga el mismo signo que el estimulo (antisacada)
           %En el siguiente if se compara con el pico anterior, si este esta dentro de un estimulo(~=0) y tiene el mismo signo que el estimulo, se establece como pico significativo
           if length(sigPeaks)-j>=1 && stimulus(sigPeaks(end-j))~=0 && (gaze(sigPeaks(end-j))*stimulus(rangoFin)>0 || gaze(sigPeaks(end-j))*stimulus(indexStimChange(i))>0)
              peak(n)=sigPeaks(end-j);
            else % si no cumple el if se establece el primer pico encontrado como pico significativo
              peak(n)=sigPeaks(end-j+1);
            endif
            break;
          elseif j==length(sigPeaks) && peak(n)==indexStimChange(i)
            %tiene dos picos prosacadicos
            peak(n)=sigPeaks(end);
          endif
        endfor
      endif 
     ################################ENCONTRAR LA FIJACION SIGNIFICATIVA
     if indexFixations!=-1 
       p++;
       sigFix(p)=1;
      for k=1:length(indexFixations(:,1))
        if peak(n)>=indexFixations(k,1)-3 && peak(n)<=indexFixations(k,2)+3 %-3 y +3 para evitar que el pico cogido por alguna razon este fuera de la fijacion
          peakFixIni=indexFixations(k,1); %Encontrar la fijacion donde se encuntra el pico establecido arriba.
          sigFix(p)=gaze(peakFixIni);
          for m=k:length(indexFixations(:,1))-1 %SE COMPARA LAS SIGUIENTES FIJACIONES A LA ENCONTRADA
            if time(indexFixations(m+1,1))<time(indexStimChange(i)) % Se compara si el inicio de la fijacion empieza antes del cambio del estimulo al centro
              sigDur=time(indexFixations(m,2))-time(indexFixations(m,1));
              sigDur2=time(indexFixations(m+1,2))-time(indexFixations(m+1,1));
              if  sigDur<=sigDur2 % si la duracion del estimulo siguiente es mayor que la anterior
                if gaze(peakFixIni)*gaze(indexFixations(m+1,2))<0 %&& sigDur2>1200)
                  sigFix(p)=gaze(indexFixations(m,1));
                else 
                  % y si no cumple que el final de la fijacion esta despues del cambio del estimulo al centro y esta fijacion es mayor que 1200, se establece la siguiente fijacion.
                  %las fijaciones que se comparan siempre tienen que tener el mismo signo que la fijacion inicial donde se encuentra el peak(n).
                  sigFix(p)=gaze(indexFixations(m+1,1));
                end
              endif 
            else
              break;
            endif
          endfor
          break;
        elseif k==length(indexFixations(:,1)) && sigFix(p)==1
          sigFix(p)=gaze(peak(n));
        endif
      endfor
    endif
  endfor

  if sigFix==-1
    sigFix=peak;
  endif
endif
endfunction
