function [reflexiva, correct, AntiWPro, wrong, AntisaccadeLatency, tiempoReflexiva, RleflexiveLatency, type,latency_v,velocitypeak_v] = Categorization (indexInitialPoints, indexStimChange, indexFixations, peakColor, peakInds, x0, time, velocidad, anticipatedPoints)
#IN
    %indexInitialPoints: Array which contain the initial points of the saccades.
    %indexStimChange: Array which contain the change in the stimulus.
    %indexFixations: Array which contain the start and end of fixations.
    %peakColor: Array which contain the peaks categozation. '1' is green, '2' is red, '3' is blue and '4' is orange.
    %peaksInds: Array which contain indices of peaks
    %x0: data.gaze
    %time: data.time
    %velocidad: data.velocity
#OUT
    %reflexiva: number of reflexive saccades
    %correct: number of correct saccades
    %AntiWPro: number of Second order reflexive antisaccade
    %wrong: number of wrong saccades
    %AntisaccadeLatency: Latency of any saccade either pro or anti.
    %tiempoReflexiva: reflexive fixation time
    %RleflexiveLatency: latency of 
    %type:  1--Reflexiva
    %       2--correcta
    %       3--SORa
    %       4--Incorrecta
    %       5--none

%Reflexivas, Correct, Anti with Pro (back to the stimulus point) and wrong(r).
type=zeros(1,length(indexInitialPoints));
reflexiva=0;
correct=0;
AntiWPro=0;
wrong=0;
tiempoReflexiva=-1;
AntisaccadeLatency=-1;
RleflexiveLatency=-1;
velocitypeak_v=-1;
latency_v=-1;
if peakInds!=-1 && indexFixations!=-1 && indexInitialPoints!=-1
nTRefl=1;
nLatenc=1;
  for g=1:2:length(indexInitialPoints)
    type(g)=5;
    if anticipatedPoints(g)==1 || indexInitialPoints(g)==1 % si esta delantada o no tiene punto inicial no cuenta en los conteos
        continue;
     end
    %Endpoint Dependiendo de si:
    if g+2>length(indexInitialPoints)  %ultima fijacion
      Endpoint=length(time);
    elseif indexInitialPoints(g+1)==1 %no tiene punto inicial
      Endpoint=indexStimChange(g+2);
    else %tiene punto inicial y no es la ultima fijacion
      Endpoint=indexInitialPoints(g+1);
    end

    
    %StartPoint depende de:
    if indexInitialPoints(g)==-1 %no tiene punto inicial
      continue;
    elseif indexInitialPoints(g)!=1
      Startpoint=indexInitialPoints(g);
    else
      %Startpoint=indexInitialPoints(g);
      Startpoint=indexStimChange(g);
    end

      peaks=peakColor((Startpoint<=peakInds) & (peakInds<=Endpoint));
      peaksI=peakInds((Startpoint<=peakInds) & (peakInds<=Endpoint));
      fixationini=indexFixations((Startpoint<=indexFixations(:,1)) & (indexFixations(:,1)<=Endpoint),1);
      if length(fixationini)==0
        continue; % si no tiene ninguna fijacion no entra dentro de los conteos
      else
        fixationEnd=indexFixations((fixationini(1)<=indexFixations(:,1)) & (indexFixations(:,1)<=fixationini(end)),2);
      end    
    #####################################################################   REFLEXIVAS
    if (length(peaks)>1 && peaks(1)==2 && peaks(2)==1) %CON ADELANTADAS(NARANJA)|| (length(peaks)>2 && peaks(1)==4 && peaks(2)==2 && peaks(3)==1)
      reflexiva++;
      type(g)=1;
      #########################################REFLEXIVE SACCADE DURATION AND CORRECTED ANTISACCADE LATENCY
      estado=0;
      if peaks(2)==2
        reflev=peaksI(2);
      elseif peaks(1)==2
        reflev=peaksI(1);
      endif
      for i=1:length(fixationini)
        if time(fixationini(i))<=time(reflev) && time(fixationEnd(i))>=time(reflev) && estado==0;
          estado=1;
          inicio=fixationini(i);
        elseif estado==1 && (x0(inicio)*x0(fixationEnd(i)))<0
          tiempoReflexiva(nTRefl)=time(fixationEnd(i-1))-time(inicio);
          RleflexiveLatency(nTRefl)=time(fixationEnd(i-1))-time(indexStimChange(g));
          nTRefl++;
          break;
        elseif estado==0 && i==length(fixationini) %Tiene reflexiva pero el algoritmo no lo detecta
          fin=0;
          ini=0;
          for j=1:100
            %por la izquierda
            if abs(velocidad(reflev+j-1))>30 && fin==0
              fin=reflev+j-1;
            endif
            if abs(velocidad(reflev-j))>30 && ini==0
              ini=reflev-j;
            endif
            if fin~=0 && ini~=0
              tiempoReflexiva(nTRefl)=time(fin)-time(ini);
              RleflexiveLatency(nTRefl)=time(fin)-time(indexStimChange(g));
              nTRefl++;
              break;
            endif
          endfor
          break;
        endif
      endfor 
    endif
    
    #####################################################################   CORRECTAS
    c=0;
    for i=1:length(peaks)
      if peaks(i)==1 
        c=1;
      endif
      if peaks(i)==2
        break;
      elseif i==length(peaks) && c==1
        correct++;
        type(g)=2;
        #########################  ANTISACCADE LATENCY
        AntisaccadeLatency(nLatenc)=time(indexInitialPoints(g))-time(indexStimChange(g));
        nLatenc++;
      endif
    endfor
  %  if (length(peaks)==1 && peaks(1)==1) || (length(peaks)>1 && (peaks(1)==1 && peaks(2)==3)) %|| (peaks(1)==4 && peaks(2)==1))) %CON ADELANTADAS|| (length(peaks)==3 && peaks(1)==4 && peaks(2)==1 && peaks(3)==3)
  %    correct++;
  %    
  %    #########################  ANTISACCADE LATENCY
  %    AntisaccadeLatency(nLatenc)=time(indexInitialPoints(g))-time(indexStimChange(g));
  %    nLatenc++;
  %  end 
    
    #####################################################################  SORa (Second order reflexive antisaccade) 
    for k=1:length(peaks)-1
      if peaks(k)==1 && peaks(k+1)==2
        AntiWPro++;
        type(g)=3;
        break;
      endif
    endfor
   
    #####################################################################   INCORRECTAS 
    int=0;
    for kk=1:length(peaks)
      if peaks(kk)==2 
        int=1; 
      endif
      if (peaks(kk)==1)
        break;
      endif
      if kk==length(peaks) && int==1
        wrong++;
        type(g)=4;
      endif   
    endfor
  endfor % for g=1:2:length(indexInitialPoints)
  
   ########################################sácadas de vuelta
  estadotype=0;
  lv=0;
  
  vv=0;
  
  for i=1:length(indexInitialPoints)
    if mod(i,2) ~= 0 %IMPAR SACADA DE IDA
      if type(i) ~= 5 %Hace un tipo de sacada
        estadotype = 1;
      endif
    elseif estadotype==1 %sacadas de vuelta cuando hay un tipo de ida.
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
    estadotype = 0;
    endif
  endfor
  
endif %if peakInds!=-1 && indexFixations!=-1 
endfunction 
