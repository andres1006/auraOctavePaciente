%------------------------------------------------
%Análisis seguimiento lento
%Genera los datos resultantes a partir de los csv de cualquier seguimiento lento
%Resultados:
%Smooth pursuit Latency
%SPEMtime: time during it is done smooth pursuit. 
%TRMSE: Total root mean square error. including smooth pursuit and saccades.
%SRMSE: Smooth root mean square error. including only smooth pursuit.
%Gain: Measure of the eye/dot velocity match and hence of tracking accuracy.
%VRMSE: Velocity root mean square error. including only smooth pursuit.
%Number of blinks.

%Silvia Gomez Martin
%Aura innovative Robotics
%Version: 25/Octubre/2018

%%%COMENTARIO ULTIMA VERSIÓN:
%Modificación del filtro del estimulo, debido a un error out of bound.
%--------------------------------------------------


function result = tsl(fileName)

result = [];

structIn=loadOscannCSV(strcat(fileName,'.csv'));

if numfields(structIn) == 0
    result = ones(1,10)*-99;
    return
endif



%diferenciar si es en X o en Y
if(sum(diff(structIn.data(:,4))!=0))
  testIn=0;
else
  testIn=1;
endif

time=structIn.data(:,1);
gaze=structIn.data(:,2+testIn);
stimulus=structIn.data(:,4+testIn);
gazeVel=structIn.data(:,6+testIn);
blinks=structIn.data(:,13);
screenWidth=structIn.screenWidth;
resolutionx=structIn.screenResolution(1);
screenDist=structIn.screenDist;


%%plot
%figure;
%plot(time,gaze,time,stimulus);
%title(fileName);
%gazeVel(isnan(gazeVel(:,1))) = [];

type=zeros(length(time),1);

%isNan or isinf
i=1;
while i<=length(gazeVel)
  if isnan(gazeVel(i))==1 || isnan(gaze(i))==1 || isinf(gazeVel(i))==1 || isinf(gaze(i))==1
    gazeVel(i) = [];
    time(i) = [];
    gaze(i) = [];
    stimulus(i) = [];
    blinks(i) = [];
  else
    i++;
  end
endwhile

if (length(gaze)==0)
  result = NaN(1,10);
  return
endif

%contarParpadeos
estado=0;
nBlinks=0;
for k=1:length(blinks)
  if blinks(k)==1 && estado==0
    nBlinks++;
    estado=1;
  endif;
  if blinks(k)==0 && estado==1
    estado=0;
  endif
endfor


result = [result nBlinks];   %1
#################### STIMULUS FILTER

if time(1)!=time(2) % I found a test with the same data in line 1 and line 1 of CSV
  stimulusf(1)=stimulus(1);
  i=1;
else
  stimulusf(1)=0;
  stimulusf(2)=stimulus(2);
  i=2;
end
while i<=length(time)-2
  i++;
  if stimulus(i-1)==stimulus(i) && stimulus(i+1)==stimulus(i) %sometimes there is a three equal value
    stimulusf(i)=stimulus(i);
    if(i==2)
      stimulusf(i-1)=0;
    else    
      stimulusf(i-1)=stimulus(i-2)+((time(i-1)-time(i-2))*((stimulus(i)-stimulus(i-2))/(time(i)-time(i-2))));
    end  
    if i+2>length(time)
      stimulusf(i+1)=0;
    else  
      aux=stimulusf(i)+((time(i+1)-time(i-1))*((stimulus(i+2)-stimulus(i))/(time(i+2)-time(i-1))));
      i++;
      stimulusf(i)=aux;
    endif 
    
  elseif stimulus(i-1)==stimulus(i) 
    stimulusf(i)=stimulus(i-1)+((time(i)-time(i-1))*((stimulus(i+1)-stimulus(i-1))/(time(i+1)-time(i-1))));
  else 
    stimulusf(i)=stimulus(i);
  endif
endwhile

if(length(stimulusf)<length(time))
  i++;
  stimulusf(i)=0;
endif

############ SIMULUS VELOCITY
f=0;
for i=1:length(stimulusf)-1
  if time(i+1)!=time(i)
    f++;
    stimfvel(f)=(stimulusf(i+1)-stimulusf(i))/(time(i+1)-time(i));
  end
endfor

%CUANDO SE CONSIDERA SEGUIMIENTO LENTO?
%CUANDO SU VELOCIDAD ES MENOR QUE 5 VECES LA MAXIMA VELOCIDAD DEL PUNTO.

####################################################PROCESADO
###ITERATIVE THRESHOLD############
%smooth pursuit velocity less than 30-40º/s
threshold=mean(gazeVel)+7*std(gazeVel);
if threshold>max(abs(gazeVel)) threshold=mean(abs(gazeVel)); endif

for i=1:100 %iteraciones para encontrar el umbral
  n=0;
  for m=1:length(gazeVel)
    if abs(gazeVel(m))<threshold && blinks(m)==0
      n=n+1;
      gazeVelIn(n)=abs(gazeVel(m));
    endif
  endfor
  if n == 0
    break
  endif
  thold=mean(gazeVelIn)+5*std(gazeVelIn);
  clear gazeVelIn;
  if abs(thold-threshold)<5
    threshold=thold;
    break;
  else
    threshold=thold;
  endif;
endfor

####first clasification of point according to threshold
%SPEM=0;
for j=1:length(gazeVel)
  if blinks(j)==1
    type(j)=2; %-----------------------------------type=2 there's blink
  elseif blinks(j)==2
    type(j)=3; %-----------------------------------type=3 there isn't pupil detection
  elseif abs(gazeVel(j))>threshold 
    type(j-1)=1; %it's identificated only the peak, it's added the two adjacent point because these point also are saccade.
    type(j)=1; %-----------------------------------type=1 there's saccade
    if j<length(gazeVel)
     type(j+1)=1;
    endif
  else
    if type(j)!=1 %Por si se ha establecido como 1 en el punto anterior a causa de abarcar todo el pico de velocidad que coge el umbral.
      type(j)=0;  %-----------------------------------type=0 there's smooth pursuit
    endif
  endif 
endfor

##############PROCESS
  



%------------------------------filtration of saccades
i=1;
saccade =struct('start',[],'fin',[],'amplitude',[],'sense',[],'type',[]);
ind=0;
possibleStart=-1;
while i<=length(time)
  if time(i)>80
    if type(i)==1 && type(i-1)!=1  %beginning of the saccade
      possibleStart=i-1;  
    endif
    if type(i)!=1 && type(i-1)==1 && possibleStart!=-1 %end of the saccade
      possibleFin=i;
      possibleAmplitude= abs(gaze(possibleFin)-gaze(possibleStart));
      if (i>length(time)-5) %Avoid segmentation fault, it's checked if there are blinks and no pupil detection in the 5 (or up to end of the array) next point.
        rfin=length(time);
      else  
        rfin=i+5;
      endif
      if (i<5) %Avoid segmentation fault, it's checked if there are blinks and no pupil detection in the 5 (or up to end of the array) next point.
        rstart=1;
      else  
        rstart=possibleStart-5;
      endif
      if isempty(find(type(rstart:rfin)==2))%Avoid the noise. >1º and teher isn't blinks 
        if (possibleAmplitude>=1) 
          ind++;
          saccade.fin(ind)=possibleFin;
          saccade.start(ind)=possibleStart;
          saccade.amplitude(ind)=abs(gaze(saccade.fin(ind))-gaze(saccade.start(ind)));
          saccade.sense(ind)=sign(gaze(saccade.fin(ind))-gaze(saccade.start(ind)));
          saccade.type(ind)=-1; % type of saccade   
        else %make smooth pursuit the saccades below 1º if there aren't blinks and no pupil detection.
          for j=possibleStart:possibleFin
            type(j)=0; 
          endfor
        endif  
      else %if there are blinks and no pupil detection, it's classificated as -1, out of smooth pursuit and saccades.
        for j=possibleStart:possibleFin
          type(j)=-1;
        endfor
      endif
      possibleStart=-1;
    endif 
 else
  type(i)=-99;
 endif 
  i++; 
endwhile

%----------------------------initial saccade. Latency
latency=-1;
for i=2:length(time)
  if time(i)>80
    if type(i)==1 && type(i-1)!=1   %there is a point considered saccade
      latency=time(i); %(ms)
      i++;
      break;
    endif
  endif
endfor

if latency==-1
  latency=NaN;
endif
  result = [result latency];  %2



indcat=0;
indback=0;
indswj=0;
if ~isempty(saccade.start)
    %---------------------------categorization of saccades
    %catch-up saccades. Saccade in the same way as stimulus with an amplitude over 1º 
    %back-up saccades. Saccades in the opposite direction as stimulus with an amplitude over 1º

    for i=1:length(saccade.start)
      if saccade.type(i)!=3 && saccade.type(i)!=2
        if (sign(saccade.sense(i)*(stimulus(saccade.start(i))-stimulus(saccade.start(i)-2)))>0) % it's a catch-up saccade 
          indcat++;
          saccade.type(i)=1;
        elseif (sign(saccade.sense(i)*(stimulus(saccade.start(i))-stimulus(saccade.start(i)-2)))<0) % it's a back-up saccade
          indback++;;
          saccade.type(i)=2;
        endif 
       endif
    endfor
    
       %--------------------------categorization of Square-wave jerks
    %max range for considered SWJ (AURA CRITERIA)
    rango = 500; %Predefinir la variable  para evitar error por no estar definida
    for i=1:length(stimulusf)
      if ((sign(stimulusf(2)*stimulusf(i))<0) || (sign(stimulusf(4)*stimulusf(i))<0))
        rango=time(round(i/8));
        break;
      endif
    endfor
    %printf("Rango= %d\n",time(rango));

    i=1;
    while i<=length(saccade.start)-1  
      if saccade.type(i)+saccade.type(i+1)==3 && (time(saccade.start(i+1))-time(saccade.fin(i)))<(rango) && sign(saccade.sense(i)*saccade.sense(i+1))<0 && isempty(find(type(saccade.fin(i):saccade.start(i+1))==3)) && isempty(find(type(saccade.fin(i):saccade.start(i+1))==2))
        %Se asegura que una sacada sea catch-up y otra back-up
        %Se asegura que el tiempo entre una sacada y otra no sea mas que al rededor de 500ms
        %Se asegura que el sentido sin tener en cuenta referencias sea opuesto 
        %se asegura que entre las sacadas no haya un parpadeo o no detecte la pupila
        %if saccade.amplitude(i)<3 && saccade.amplitude(i+1)<3 &&  %its amplitude are lower than 3º
        indswj++;
        indback--;
        indcat--;
        saccade.type(i)=3;
        saccade.type(i+1)=3;
        i=i+2;
       % endif
      else
        i++;
      endif
    endwhile
    
endif%-----------------~isempty(saccade)
result = [result indcat];  %3
result = [result indback];  %4
result = [result indswj];  %5


################################################################RESULT

%%%%%%%%%%%%%%%%%    SPEM time
%measure the tracking ability with the task as it represent the amount of time spent in appropriate tracking of the dot.
SPEM=nnz(~type);
t=0;
for i=1:length(time)
  if blinks(i)!=2
    t++;
  endif
endfor
if t!=0
  SPEMtime=(SPEM/t)*100;
else
  SPEMtime=NaN;
end

result = [result SPEMtime];  %6

%%%%%%%%%%%%%%%%%%   Total root mean square(TRMS)
%Measure of the error between the positions of the eye and dot both duting smooth pursuit movement and faster eye movement.

TRMSn=0;
m=0;
for k=1:length(time)
  if type(k)!=2 && type(k)!=3 && blinks(k)!=2 && blinks(k)!=1
    TRMSn=TRMSn+((gaze(k)-stimulusf(k))^2);
    %TRMSd=TRMSd+(stimulusf(k)^2);
    m++;
  endif
endfor
if (m!=0)
  TMSE=TRMSn/m; %(deg^2)
  TRMSE=sqrt(TMSE); %(deg)
else
  TRMSE=NaN;
end

result = [result TRMSE];    %7

%%%%%%%%%%%%%%%%%% SPEM root mean square (SRMS)
%Measure of the error between the position of the eye and the dot in the sections of the tracing qualified as SPEM.

SRMSn=0;
n=0;
for k=1:length(time)
  if type(k)==0 && blinks(k)!=2 && blinks(k)!=1%solo cuando es considerado smooth pursuit
    SRMSn=SRMSn+((gaze(k)-stimulusf(k))^2);
    %SRMSd=SRMSd+(stimulusf(k)^2);
    n++;
  end
endfor
if n!=0
  SMSE=SRMSn/n; %(def^2)
  SRMSE=sqrt(SMSE); %(deg)
else
  SRMSE=NaN;
endif

result = [result SRMSE]; %8

%%%%%%%%%%%%%%%%  Gain
%Measure of the eye/dot velocity match and hence of tracking accuracy. 
  %Gain < 1 Slow eye movement, the eye lags behind the dot.
  %Gain > 1 Fast eye movement, the eye anticipates dot motion.
difvel=0;
g=0;
for k=1:length(stimfvel)
  if type(k)==0 && stimfvel(k)!=0 && blinks(k)!=2 && blinks(k)!=1%solo cuando es considerado smooth pursuit
    difvel=difvel+((gazeVel(k)/1000)/stimfvel(k));
    g++;
  end
endfor
if g!=0
  Gain=difvel/g;
else
  Gain=NaN;
endif
result = [result Gain]; %9

%%%%%%%%%%%%%%%% Gain2
  %ranging from 0 to 1, qualified abnormal performance in one direction only.
  
%Gain2=(1-Gain)^2

%%%%%%%%%%%%%%% velocity mean square error (vmse)
%indicates the fidelity of smooth pursuit tracking and reflects the reduction of saccades during good performance
VMSEn=0;
nv=0;
for k=1:length(stimfvel)
  if type(k)==0 && blinks(k)!=2 && blinks(k)!=1%solo cuando es considerado smooth pursuit
    VMSEn=VMSEn+((gazeVel(k)-(stimfvel(k)*1000))^2);
    nv++;
  end
endfor

if nv!=0
  VMSE=VMSEn/nv; %(deg^2)
  VRMSE=sqrt(VMSE); %(deg)
else
  VRMSE=NaN;
endif

result = [result VRMSE];    %10












