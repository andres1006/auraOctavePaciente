% Function for detecting microsaccades from a time series of eye movements.
%
% Inputs:
%    gaze   - Time series of eye movements
%    time - The sampling rate of the time series of eye movements.
%    gazeVel - Velocity of the eye movement.
%    type - Type of the frame, saccade or fixation.
%    pupilArea - The area of the Pupil during the test

%
% Outputs:
%    microsaccades - Column one: Time of onset of microsaccades
%                    Column two: Time at which the microsaccdes terminate
%                    Column three: Peak velocity of microsaccades
%                    Column four: amplitude of microsaccades
%                    Column five: return type, if the saccade is a microsaccade or not.
%                    Column six: the mean velocity of the microsaccade.
%                    



function [onset_mic , finish_mic , vpeak , ampl , tipo, v_mean] = micsaccdeg(time, gazeVel, type, onset, finish, amplitud)

N = length(onset);
v = zeros(N,2);

vel = sqrt(gazeVel(:,1).^2 + gazeVel(:,2).^2);
i=1;
onset_mic = [];
finish_mic = [];
vpeak = [];
ampl = [];
v_mean=[];
tipo=type;
while(i<N)
  if type(onset(i))==1
      %Ifs encadenados para considerar si es una microsacada o no.
      if (time(finish(i))-time(onset(i)))<=40 %52          
          if ((amplitud(i)))<0.083 || (time(finish(i))-time(onset(i))<10) 
            tipo(onset(i):finish(i))=0;
            i=i+1;
          elseif (amplitud(i))<0.83333 
            onset_mic = vertcat(onset_mic, onset(i));
            finish_mic = vertcat(finish_mic , finish(i));
            vpeak = vertcat(vpeak, max(vel(onset(i): finish(i))));% peak velocity
            v_mean=vertcat(v_mean,mean(vel(onset(i): finish(i))));
            ampl = vertcat(ampl,amplitud(i));  % amplitude
            tipo(onset(i):finish(i))=2;
            m=1;
            if(i+m)<=N
              while (time(finish(i+m))-time(onset(i)))<=20 %Condicion para que las microsacadas esten separadas 20 ms
                if(m+i)>N m=m-1;
                else m++; endif
                if((m+i)==N) break; endif
              endwhile
              i = i + m;
            endif
          else 
            i = i + 1;
          endif       
      else    
          i = i + 1;
      endif
      
  else
      i = i + 1;
  endif
    
endwhile


end