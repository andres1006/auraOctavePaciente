function [anticipatedPoints,nAnticipated,nAnticipated_v] = memory_AnticipatedInitPoints (indexInitialPoints, indexStimChange, time, memory)
  nAnticipated=0;
  nAnticipated_v=0;
  anticipatedPoints=-1;
  if indexInitialPoints!=-1
    i=3;
    anticipatedPoints=zeros(1,length(indexInitialPoints));
    while i<=length(indexStimChange) -1
      if mod(i,2) ~= 0 %Número impar sácada de ida
        if indexInitialPoints(i)!=1 && memory(i)==1
          if(time(indexStimChange(i))+80>time(indexInitialPoints(i)))
            anticipatedPoints(i)=1;
            nAnticipated++;
          endif
        endif
        i++;
      else %sacada de vuelta
        if indexInitialPoints(i)!=1 && memory(i)==1
          if(time(indexStimChange(i))+80>time(indexInitialPoints(i)))
            anticipatedPoints(i)=1;
            nAnticipated_v++;
          endif
        endif
        i=i+3; %Cada 4 empezando por la 3, solo se analizan las de ida
      end
    endwhile
  endif
endfunction
