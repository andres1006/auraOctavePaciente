function [fixationsFinal] = tasvSaccadeFixations (time,gaze,stimulus,indexInitialPoints,fixationsF, indexStimChange, fixDuration)
#IN
  %indexInitialPoints: Initial points of each saccade
  %fixationsF: Fixations vector of the processed test
  %time: data.time of the test
#OUT
  %fixationsFinal: Final fixations vector for TASV test type containing each saccade fixation

  minimaDuracion=200;
%LONGEST CORRECT FIXATION DETECTION FOR TASV TEST TYPE
fixationsFinal=-1;
if fixationsF!=-1 && indexInitialPoints!=-1
  %Mean value of each fixation
  for i = 1 : length(fixationsF(:,1))
    meanFixations(i) = mean(gaze(fixationsF(i,1):fixationsF(i,2)));
  end

  %for i = 1:length(fixationsF(:,1))
  %  fprintf("%i , %i , %f\n",fixationsF(i,1),fixationsF(i,2),meanFixations(i));
  %end

  %Get the value of the stimulus for each change
  %ind = 2;
  %stimulusChanges = 0;
  %for i = 2 : length(stimulus)
  %  if(stimulus(i) != stimulus(i-1))
  %    stimulusChanges(ind) = stimulus(i);
  %    ind += 1;
  %  end
  %end
  fixationEnd=-1;
  %Detection of final fixations according to the criteria
  %Look for the first fixations after the first initial point
  for k=1:length(indexStimChange) -1
        if (indexInitialPoints(k)!=1)
            for j=1:length(fixationsF(:,1))
                if fixationsF(j,1)>=indexInitialPoints(k) && fixDuration(j)>minimaDuracion
                    fixationEnd=j;
                    break;
                endif
            endfor
            break;   
        endif
    endfor
    
if fixationEnd!=-1   
  for i = 1 : length(indexStimChange) -1
    if indexInitialPoints(i)==1
      fixationsFinal(i)=0;
      continue;
    endif
%    for j=1:length(fixationsF(:,1))
%        if fixationsF(j,1)>=indexInitialPoints(i) && fixDuration(j)>minimaDuracion
%            fixationEnd=j;
%            break;
%        endif
%    endfor
    %Indexes needed for the correct and incorrect fixations vectors
    indc = 1;
    indi = 1;
    %Set the correct and incorrect fixations vector to empty (0)
    correctFixations = 0;
    incorrectFixations = 0;
    %In case of no correct nor incorrect fixations detected use this index
    fixationIni = fixationEnd;
    
    %In case of the iteration being lower than the number of initial points continue
    if(i < length(indexInitialPoints))
      %Correct and incorrect fixations detection loop
      while (fixationEnd < length(fixationsF(:,1))) && ((fixationsF(fixationEnd,2) <= indexInitialPoints(i+1)) || (fixationsF(fixationEnd,2)<=indexStimChange(i+1)))
   %      fprintf("Result: %d\n",meanFixations(fixationEnd)*stimulusChanges(i));
        if(meanFixations(fixationEnd)*stimulus(indexStimChange(i)+1) > 0) && fixDuration(fixationEnd)>minimaDuracion
          correctFixations(indc) = fixationEnd;
          indc += 1;
   %        fprintf("Correct: %i\n",i);
        elseif fixDuration(fixationEnd)>minimaDuracion
          incorrectFixations(indi) = fixationEnd;
          indi += 1;
   %        fprintf("Incorrect: %i\n",i);
        endif
        fixationEnd += 1; 
      endwhile
      %If no vector is filled use the initial fixation
      if(correctFixations == 0 && incorrectFixations == 0)
   %      fprintf("None\n");
        fixationsFinal(i) = 0;
      %If there are no correct fixations keep the longest one from the incorrect ones
      elseif(correctFixations == 0)
   %      fprintf("Incorrect only\n");
        %Use the first fixation for initial values
        fixationsFinal(i) = incorrectFixations(1);
        maxDuration = time(fixationsF(incorrectFixations(1),2))-time(fixationsF(incorrectFixations(1),1));
        for j = 2 : length(incorrectFixations)
          %If a fixation is longer than the previous longest one keep it
          if(time(fixationsF(incorrectFixations(j),2))-time(fixationsF(incorrectFixations(j),1)) > maxDuration)
            fixationsFinal(i) = incorrectFixations(j);
            maxDuration = time(fixationsF(incorrectFixations(j),2))-time(fixationsF(incorrectFixations(j),1));
          endif
        endfor
      %If there are multiple correct fixations keep the one with the lowest error
      %TODO: Make a weighted system to choose the best fitted fixation according to the criteria
      %TODO: Specify the criteria
      else
   %      fprintf("Rest of them\n");
        fixationsFinal(i) = correctFixations(1);
        maxDuration = time(fixationsF(correctFixations(1),2))-time(fixationsF(correctFixations(1),1));
        for j = 2 : length(correctFixations)
          if(time(fixationsF(correctFixations(j),2))-time(fixationsF(correctFixations(j),1)) > maxDuration)
            fixationsFinal(i) = correctFixations(j);
            maxDuration = time(fixationsF(correctFixations(j),2))-time(fixationsF(correctFixations(j),1));
          endif
        endfor
      endif
    %In case of the iteration being the last one continue
    else
      while(fixationEnd <= length(fixationsF(:,1)))
        if(meanFixations(fixationEnd)*stimulus(indexStimChange(i)+1) > 0) && fixDuration(fixationEnd)>minimaDuracion
          correctFixations(indc) = fixationEnd;
          indc += 1;
        elseif fixDuration(fixationEnd)>minimaDuracion
          incorrectFixations(indi) = fixationEnd;
          indi += 1;
        end
        fixationEnd += 1;
        if(fixationEnd > length(fixationsF(:,1)))
          break;
        end
      end
      %If no vector is filled use the initial fixation
      if(correctFixations == 0 && incorrectFixations == 0)
        fixationsFinal(i) = 0;
      %If there are no correct fixations keep the longest one from the incorrect ones
      elseif(correctFixations == 0)
        %Use the first fixation for initial values
        fixationsFinal(i) = incorrectFixations(1);
        maxDuration = time(fixationsF(incorrectFixations(1),2))-time(fixationsF(incorrectFixations(1),1));
        for j = 2 : length(incorrectFixations)
          %If a fixation is longer than the previous longest one keep it
          if(time(fixationsF(incorrectFixations(j),2))-time(fixationsF(incorrectFixations(j),1)) > maxDuration)
            fixationsFinal(i) = incorrectFixations(j);
            maxDuration = time(fixationsF(incorrectFixations(j),2))-time(fixationsF(incorrectFixations(j),1));
          end
        end
      %If there are multiple correct fixations keep the one with the lowest error
      %TODO: Make a weighted system to choose the best fitted fixation according to the criteria
      %TODO: Specify the criteria
      else
        fixationsFinal(i) = correctFixations(1);
        maxDuration = time(fixationsF(correctFixations(1),2))-time(fixationsF(correctFixations(1),1));
        for j = 2 : length(correctFixations)
          if(time(fixationsF(correctFixations(j),2))-time(fixationsF(correctFixations(j),1)) > maxDuration)
            fixationsFinal(i) = correctFixations(j);
            maxDuration = time(fixationsF(correctFixations(j),2))-time(fixationsF(correctFixations(j),1));
          endif
        endfor
      endif
    endif
  endfor
endif
  %for i=1:length(fixationsFinal)
  %  fprintf("%i: %i , %i\n",i,fixationsF(fixationsFinal(i),1),fixationsF(fixationsFinal(i),2));
  %end
endif %if fixationsF!=-1
endfunction
