
% Function for detecting swj from a time series of eye movements.
%
% Inputs:
%    gazex   - Time series of eye movements in x
%    gazey   - Time series of eye movements in y
%    type - Type of the frame, saccade or fixation.
%    onset - Point where a fixation or a saccade starts
%    finish - Point where a fixation or a saccade terminates
%    amplitud - Amplitude of each saccade or fixation
%    time - The sampling rate of the time series of eye movements.

%
% Outputs:
%          SqWavwJ - Column one: Amplitude of the swj
%                    Column two: Time of the swj
%                    Column three: Number of monophase swj
%                    Column four: Number of biphase swj
%                    Column five: Start and finish of a swj
% 
function [ampl_swj,time_swj,numero_mono, numero_bi,plotonset] = SqWaveJ(gazex, gazey, type, onset, finish, amplitud, time)

%%Calculo de SWJ

plotonset=[];
swjd=[];
swja=[];
swjt=[];
onsetSWJ=[];
finishSWJ=[];
first=[];
second=[];
i=1;
j=1;
%Almacenar los parametros del tiempo, direccion y amplitud de cada sacada con menos de 5º y mas de 0.20
while i < (length(onset)-2)
  if type(onset(i))==1 && amplitud(i)<5 && amplitud(i)>0.20 && amplitud(i+2)<5
    direction1=mod((atan2(gazey(finish(i))-gazey(onset(i)),gazex(finish(i))-gazex(onset(i)))*180/pi())+360,360);
    ampl1=amplitud(i);
    time1=time(finish(i));
    direction2=mod((atan2(gazey(finish(i+2))-gazey(onset(i+2)),gazex(finish(i+2))-gazex(onset(i+2)))*180/pi())+360,360);
    ampl2=amplitud(i+2);
    time2=time(onset(i+2));
    if abs(direction1-direction2)>90 && abs(direction1-direction2)<270 %&& (time2-time1)<800
      first=vertcat(first,i);
      second=vertcat(second,i);
      onsetSWJ=vertcat(onsetSWJ,onset(i));
      onsetSWJ=vertcat(onsetSWJ,onset(i+2));
      finishSWJ=vertcat(finishSWJ,finish(i));
      finishSWJ=vertcat(finishSWJ,finish(i+2));
      swjd=vertcat(swjd,mod(acos(cos((direction1-direction2)*pi()/180))*180/pi.*sign((direction1-direction2))+90,360));
      swja=vertcat(swja,(ampl1-ampl2)/(ampl2+ampl1));
      swjt=vertcat(swjt,time2-time1);
    endif
  endif
  i++;
endwhile

%{
%Distribucion normal con pesos
fd=[];
for i=1:length(swjd)
  if(swjd(i)>180)
    fd=vertcat(fd,[0.4*normpdf(swjd(i),180,30)+0.6*normpdf(swjd(i),180,7)]);
  else
    fd=vertcat(fd,[1-0.4*normpdf(swjd(i),180,30)+0.6*normpdf(swjd(i),180,7)]);
  endif
endfor

%Distribucion normal con pesos
fm=[];
for i=1:length(swja)
  if abs(swja(i))>0
    fm=vertcat(fm,[0.4*normpdf(swja(i),0,0.39)+0.6*normpdf(swja(i),0,0.16)]);
  else
    fm=vertcat(fm,[1-0.4*normpdf(swja(i),0,0.39)+0.6*normpdf(swja(i),0,0.16)]);
  endif
endfor
%Distribucion normal exponencial
fi=[];
for i=1:length(swjt)
  if(swjt(i)>200)
    fi=vertcat(fi,[ex_gaussian(swjt(i),1,120,60,180)]);
  else
    fi=vertcat(fi,[1-ex_gaussian(swjt(i),1,120,60,180)]);
  endif
endfor
%}
indiceSWJ=[];
type_SWJ=[];
ampl_swj=[];
time_swj=[];
numero_mono=0;
numero_bi=0;

if length(swja)==0 return; end
[relmagfitParams] = fitdata( swja, 'Mix-2-Gaussian'  );
[dirdiffitParams] = fitdata( swjd, 'Mix-2-Gaussian'  );
%[isifitParams] = fitdata( swjt, 'Ex-gaussian' );


parameters.DM = dirdiffitParams([1 2]);
parameters.DS = dirdiffitParams([3 4]);
parameters.DR = dirdiffitParams([5 6]);

if(isnan(parameters.DM))
  parameters.DM=[270 270];
  parameters.DS=[30 7];
  parameters.DR=[0.4 0.6];
end

parameters.RM = relmagfitParams([1 2]);
parameters.RS = relmagfitParams([3 4]);
parameters.RR = relmagfitParams([5 6]);


if(isnan(parameters.RM))
  parameters.RM=[0 0];
  parameters.RS=[0.39 0.16];
  parameters.RR=[0.4 0.6];
end

parameters.ISIP = [125 60 180];

f1 = 1-normcdf( abs(swjd-parameters.DM(1)), 0, parameters.DS(1))*parameters.DR(1)-normcdf( abs(swjd-parameters.DM(2)), 0, parameters.DS(2))*parameters.DR(2);
f2 = 1-normcdf( abs(swja-parameters.RM(1)), 0, parameters.RS(1))*parameters.RR(1)-normcdf( abs(swja-parameters.RM(2)), 0, parameters.RS(2))*parameters.RR(2);
f3 = ( double(swjt>=200).*(1-exgausscdf( swjt,parameters.ISIP))+double(swjt<200).*(exgausscdf( swjt, parameters.ISIP)));

%Calculo del indice SWJ
indiceSWJ=[];
type_SWJ=[];
ampl_swj=[];
time_swj=[];
for i=1:length(f1)
  if (f1(i)*f2(i)*f3(i))>0
    indiceSWJ=vertcat(indiceSWJ,f1(i)*f2(i)*f3(i));%fd(i)*fi(i)*fm(i)
  endif
endfor
%indiceSWJ


if length(indiceSWJ)>2
  
  %Determinar el threshold para dividir en dos grupos
  minI=9999;
  maxI=9999;
  numidx=0;
  
  for i=1:30
    idx = kmeans(log(indiceSWJ),2);%'start' ' uniform'
    if max(indiceSWJ(idx==1)) < maxI || max(indiceSWJ(idx==2)) < maxI %%Hallar el menor threshold, dado que con kmeans cada vez que iteramos obtenemos una solucion posible
      if  mean(indiceSWJ(idx==1)) < mean(indiceSWJ(idx==2))
      
        minI=min(indiceSWJ(idx==2));
        maxI=max(indiceSWJ(idx==1));
      
      else 
        minI=min(indiceSWJ(idx==1));
        maxI=max(indiceSWJ(idx==2));
      endif
    endif
  endfor
  j=1;
  %Determinar si el indice est´a por encima del threshold
  for i=1:length(indiceSWJ)
    if indiceSWJ(i) > min(minI,maxI) && swjt(i)<1000%%(abs(minI-maxI)/2)
      type_SWJ=vertcat(type_SWJ,1);
      ampl_swj=vertcat(ampl_swj,mean(amplitud(first(i):second(i))));
      time_swj=vertcat(time_swj,swjt(i));
      
      plotonset=vertcat(plotonset,onsetSWJ(j));
      plotonset=vertcat(plotonset,finishSWJ(j));
      plotonset=vertcat(plotonset,onsetSWJ(j+1));
      plotonset=vertcat(plotonset,finishSWJ(j+1));
      
    else 
      type_SWJ=vertcat(type_SWJ,0);
    endif
    j=j+2;
  endfor
  j=1;
  %Si solo hay un punto que puede ser SWJ, utilizamos el threshold de la literatura
elseif length(indiceSWJ)>0 
  for i=1:length(indiceSWJ)
    if indiceSWJ(i) > 0.0014 %%threshold literatura
      type_SWJ=vertcat(type_SWJ,1);
      ampl_swj=vertcat(ampl_swj,mean(amplitud(first(i):second(i))));
      time_swj=vertcat(time_swj,swjt(i));
      
      plotonset=vertcat(plotonset,onsetSWJ(j));
      plotonset=vertcat(plotonset,finishSWJ(j));
      plotonset=vertcat(plotonset,onsetSWJ(j+1));
      plotonset=vertcat(plotonset,finishSWJ(j+1));
      
    else
      type_SWJ=vertcat(type_SWJ,0);
    endif
    j=j+2;
  endfor
endif


numero_mono=0;
numero_bi=0;
j=1;
i=1;

%Conteo de numero de SWJ monofasicas y bifasicas
while j<=length(indiceSWJ) && length(indiceSWJ)>1
  if type_SWJ(j)==1
  %0000
    if j>1 && j<(length(indiceSWJ)-1)
      %1111111
      if type_SWJ(j+1)==1 && onsetSWJ(i+1)==onsetSWJ(i+2) %%|| type_SWJ(j-1)==1
        %1
        j++;
        numero_bi++;
        i=i+2;
      else
        %2
        numero_mono++;
      endif
    elseif j==(length(indiceSWJ)-1)
      %33333333
      if type_SWJ(j+1)==1 && onsetSWJ(i+1)==onsetSWJ(i+2) %%onsetSWJ(i-1)==onsetSWJ(i)
       % 5
        numero_bi++;
        j++;
        i=i+2;
      else
        %6
        numero_mono++;
      endif
    elseif j==length(indiceSWJ)
      %7
      numero_mono++;
    endif
  endif
  i=i+2;
  j++;
endwhile

end
