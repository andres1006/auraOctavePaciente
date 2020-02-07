function [anticipatedPoints,nAnticipated] = AnticipatedInitPoints (indexInitialPoints, indexStimChange, time)
  nAnticipated=0;
  anticipatedPoints=-1;
  if indexInitialPoints!=-1
    anticipatedPoints=zeros(1,length(indexInitialPoints));
    for i=1:2:length(indexStimChange) -1
      if indexInitialPoints(i)!=1 
        if time(indexStimChange(i))+80>time(indexInitialPoints(i))
          anticipatedPoints(i)=1;
          nAnticipated++;
        endif
      endif
    endfor
  endif
endfunction
