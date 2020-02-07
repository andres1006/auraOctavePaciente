function result = antisaccades(fileName)

result = [];


% Cargar datos prueba
structIn=loadOscannCSV(strcat(fileName,'.csv'));

if numfields(structIn) == 0
    result = ones(1,54)*-99;
    return
endif

% Separa mirada eje correspondiente
if(sum(diff(structIn.data(2:end,4))!=0))
  testIn=0;
else
  testIn=1;
endif

time=structIn.data(:,1);
gaze=structIn.data(:,2+testIn);
stimulus=structIn.data(:,4+testIn);
blinks=structIn.data(:,13);
velocidad=structIn.gazeVel(:,1+testIn);
sesion=structIn.sesion;


%isNan or isinf
i=1;
while i<=length(velocidad)
  if isnan(velocidad(i))==1 || isnan(gaze(i))==1 || isinf(velocidad(i))==1 || isinf(gaze(i))==1
    velocidad(i) = [];
    time(i) = [];
    gaze(i) = [];
    stimulus(i) = [];
    blinks(i) = [];
  else
    i++;
  end
endwhile

if (length(gaze)==0)
  result = NaN(1,54);
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

% Separar por cambio de estimulo
indexStimChange=find(diff(stimulus)~=0);
indexStimChange(end+1)=length(stimulus);

if (length(indexStimChange)<4)
  result = NaN(1,54);
  return
endif
#####################################################################PROCESADO

%Peak Identification 
  sel=2;
  threshold=1.3;
  %% Minima Analysis
  gaze = -1*gaze(:);
  [peakIndsMin,peakMagsMin]=peakIdentification(gaze,threshold,sel);
  peakMagsMin = -peakMagsMin;

  gaze = -gaze;
  %% Maxima Analysis
  [peakIndsMax,peakMagsMax]=peakIdentification(gaze,threshold,sel);

 
%merge all peaks (max and min)
lenmin=length(peakIndsMin);
lenmax=length(peakIndsMax);
lentotal=length(peakIndsMin)+length(peakIndsMax);
peakInds=zeros(lentotal,1);
peakMag=zeros(lentotal,1);
peakColor=zeros(lentotal,1);

k=1;
i=1;
j=1;
while(i<lenmin+1 || j<lenmax+1)
  if(i>lenmin)
    peakInds(k)=peakIndsMax(j);
    peakMag(k)=peakMagsMax(j);
    k++;
    j++;
  elseif (j>lenmax)
    peakInds(k)=peakIndsMin(i);
    peakMag(k)=peakMagsMin(i);
    k++;
    i++; 
  elseif (peakIndsMin(i)<peakIndsMax(j))
    peakInds(k)=peakIndsMin(i);
    peakMag(k)=peakMagsMin(i);
    i++; 
    k++;
  else
    peakInds(k)=peakIndsMax(j);
    peakMag(k)=peakMagsMax(j);
    j++;  
    k++;
  endif
endwhile

% Detectar fijaciones
[indexFixations, fixType, fixDuration] = fixationDetection(time, gaze, blinks, velocidad);


%Detectar Picos Significativos
[sigPeaks]=significatedPeaks(indexStimChange, peakInds, gaze, stimulus, indexFixations, time);

% Extraer puntos iniciales
[indexInitialPoints] = extractInitialPoints(time,gaze,stimulus,indexStimChange,indexFixations,fixType,true, sigPeaks);

%Puntos anticipados
[anticipatedPoints, nAnticipated] = AnticipatedInitPoints (indexInitialPoints, indexStimChange, time);

%TODO: plot 
%for i=1:length(indexInitialPoints)
%  figure(1);
%  hold on;
%  plot(time(indexInitialPoints(i)),gaze(indexInitialPoints(i)),'mx','linewidth',2);
%endfor
 
%Categorizar los puntos
[peakColor] = peakCategorization_total (peakInds, peakMag, stimulus, gaze, time, indexStimChange, indexInitialPoints);

[fixationsFinal] = tasvSaccadeFixations (time,gaze,stimulus,indexInitialPoints,indexFixations, indexStimChange, fixDuration);
%[fixationsFinal] = tasvSaccadeFixations_david (time,gaze,stimulus,indexInitialPoints,indexFixations);
%[fixationsFinal] = finalFixationTASV (indexInitialPoints, indexFixations, time, gaze, stimulus, indexStimChange)

if fixationsFinal!=-1
  for b=1:length(fixationsFinal)
    if fixationsFinal(b)!=0
      finalFixationsMean(b)=mean(gaze(indexFixations(fixationsFinal(b),1):indexFixations(fixationsFinal(b),2)));
    else
      finalFixationsMean(b)=-99;
    endif
  endfor
endif
%for ii=1:length(fixationsFinal)
% figure(1);
% hold on;
% plot(time(indexFixations(fixationsFinal(ii),1):indexFixations(fixationsFinal(ii),2)),finalFixationsMean(ii), 'r');
%endfor

%
[reflexiva, correct, AntiWPro, wrong, AntisaccadeLatency, tiempoReflexiva, RleflexiveLatency, type,latency_v,velocitypeak_v] = Categorization (indexInitialPoints, indexStimChange, indexFixations, peakColor, peakInds, gaze, time, velocidad, anticipatedPoints);

%%AMPLITUDE ERROR
apos=0;
aneg=0;
amplitudeErrorPositivo=-1;
amplitudeErrorNegativo=-1;
if fixationsFinal!=-1 && indexInitialPoints!=-1
  for jj=1:2:length(indexStimChange)-1
    if fixationsFinal(jj)!=0 && anticipatedPoints(jj)==0 && (type(jj)==1 || type(jj)==2 || type(jj)==3) && indexInitialPoints(jj)!=1
      if stimulus(indexStimChange(jj)+1)<stimulus(indexStimChange(jj)-1)
        Error=stimulus(indexStimChange(jj)+1)-finalFixationsMean(jj);
      else
        Error=finalFixationsMean(jj)-stimulus(indexStimChange(jj)+1);
      endif
      if Error>=0
      apos++;
      amplitudeErrorPositivo(apos)=Error;
      elseif Error<0
      aneg++;
      amplitudeErrorNegativo(aneg)=Error;
      endif
    endif
  endfor
endif

##################################################################RESULT


total=length(indexStimChange)/2;
success=correct/total*100;
corrected=reflexiva/total*100;
error=wrong/total*100;
SORa=AntiWPro/total*100;
anticipat=nAnticipated/total*100;

result = [result nBlinks];      %1
result = [result correct];      %2
result = [result reflexiva];    %3
result = [result wrong];        %4
result = [result AntiWPro];     %5
result = [result nAnticipated]; %6
result = [result success];      %7
result = [result corrected];    %8
result = [result error];        %9
result = [result SORa];         %10
result = [result anticipat];    %11


if amplitudeErrorNegativo!=-1
  amplitudeErrorNegativomax=max(amplitudeErrorNegativo);
  amplitudeErrorNegativomin=min(amplitudeErrorNegativo);
  amplitudeErrorNegativomean=mean(amplitudeErrorNegativo);
  amplitudeErrorNegativomedian=median(amplitudeErrorNegativo);
  if length(amplitudeErrorNegativo)==1
    amplitudeErrorNegativostd=NaN;
  else
    amplitudeErrorNegativostd=std(amplitudeErrorNegativo);
  end
else
  amplitudeErrorNegativomax=NaN;
  amplitudeErrorNegativomin=NaN;
  amplitudeErrorNegativomean=NaN;
  amplitudeErrorNegativomedian=NaN;
  amplitudeErrorNegativostd=NaN;
end
result = [result amplitudeErrorNegativomax];    %12
result = [result amplitudeErrorNegativomin];    %13
result = [result amplitudeErrorNegativomean];   %14
result = [result amplitudeErrorNegativomedian]; %15
result = [result amplitudeErrorNegativostd];    %16
 
if amplitudeErrorPositivo!=-1
  amplitudeErrorPositivomax=max(amplitudeErrorPositivo);
  amplitudeErrorPositivomin=min(amplitudeErrorPositivo);
  amplitudeErrorPositivomean=mean(amplitudeErrorPositivo);
  amplitudeErrorPositivomedian=median(amplitudeErrorPositivo);
  if apos==1
    amplitudeErrorPositivostd=NaN;
  else
    amplitudeErrorPositivostd=std(amplitudeErrorPositivo);
  end
else
  amplitudeErrorPositivomax=NaN;
  amplitudeErrorPositivomin=NaN;
  amplitudeErrorPositivomean=NaN;
  amplitudeErrorPositivomedian=NaN;
  amplitudeErrorPositivostd=NaN;
end
result = [result amplitudeErrorPositivomax];    %17
result = [result amplitudeErrorPositivomin];    %18
result = [result amplitudeErrorPositivomean];   %19
result = [result amplitudeErrorPositivomedian]; %20
result = [result amplitudeErrorPositivostd];    %21


    %Latencias
    %%AntisaccadeLatency
    existLatency=0;
    meanAntisaccadeLatencyTotal=NaN;
    medianAntisaccadeLatencyTotal=NaN;
    minAntisaccadeLatencyTotal=NaN;
    stdAntisaccadeLatencyTotal=NaN;
    meanAntisaccadeLatency=NaN;
    mediaAntisaccadeLatency=NaN;
    maxAntisaccadeLatency=NaN;
    minAntisaccadeLatency=NaN;
    stdAntisaccadeLatency=NaN;
    if AntisaccadeLatency~=-1
        meanAntisaccadeLatencyTotal=mean(AntisaccadeLatency);
        medianAntisaccadeLatencyTotal=median(AntisaccadeLatency);
        minAntisaccadeLatencyTotal=min(AntisaccadeLatency);
        if length(AntisaccadeLatency)==1
          stdAntisaccadeLatencyTotal=NaN;
        else
          stdAntisaccadeLatencyTotal=std(AntisaccadeLatency);
        end
        for j=1:length(AntisaccadeLatency)
            if AntisaccadeLatency(j)>80
                existLatency=1;
            endif
        endfor
        if existLatency==1
            meanAntisaccadeLatency=mean(AntisaccadeLatency(AntisaccadeLatency>80));
            mediaAntisaccadeLatency=median(AntisaccadeLatency(AntisaccadeLatency>80));
            maxAntisaccadeLatency=max(AntisaccadeLatency(AntisaccadeLatency>80));
            minAntisaccadeLatency=min(AntisaccadeLatency(AntisaccadeLatency>80));
            if length(AntisaccadeLatency(AntisaccadeLatency>80))==1
              stdAntisaccadeLatency=NaN;
            else
              stdAntisaccadeLatency=std(AntisaccadeLatency(AntisaccadeLatency>80));
            end
        endif
    endif
    result = [result,meanAntisaccadeLatency,mediaAntisaccadeLatency,minAntisaccadeLatency,maxAntisaccadeLatency,stdAntisaccadeLatency,meanAntisaccadeLatencyTotal,medianAntisaccadeLatencyTotal,minAntisaccadeLatencyTotal,stdAntisaccadeLatencyTotal];
                        %22                        23                      24                     25                   26                   27                          28                          29                               30

    %%RleflexiveLatency
    existLAtencyRefl=0;
    meanRleflexiveLatencyTotal=NaN;
    medianRleflexiveLatencyTotal=NaN;
    minRleflexiveLatencyTotal=NaN;
    stdRleflexiveLatencyTotal=NaN;
    meanRleflexiveLatency=NaN;
    mediaRleflexiveLatency=NaN;
    maxRleflexiveLatency=NaN;
    minRleflexiveLatency=NaN;
    stdRleflexiveLatency=NaN;

    if RleflexiveLatency~=-1
        meanRleflexiveLatencyTotal=mean(RleflexiveLatency);
        medianRleflexiveLatencyTotal=median(RleflexiveLatency);
        minRleflexiveLatencyTotal=min(RleflexiveLatency);
        if length(RleflexiveLatency)==1
          stdRleflexiveLatencyTotal=NaN;
        else
          stdRleflexiveLatencyTotal=std(RleflexiveLatency);
        end
        for j=1:length(RleflexiveLatency)
            if RleflexiveLatency(j)>80
                existLAtencyRefl=1;
            endif
        endfor
        if existLAtencyRefl==1
            meanRleflexiveLatency=mean(RleflexiveLatency(RleflexiveLatency>80));
            mediaRleflexiveLatency=median(RleflexiveLatency(RleflexiveLatency>80));
            maxRleflexiveLatency=max(RleflexiveLatency(RleflexiveLatency>80));
            minRleflexiveLatency=min(RleflexiveLatency(RleflexiveLatency>80));
            if length(RleflexiveLatency(RleflexiveLatency>80))==1
              stdRleflexiveLatency=NaN;
            else
              stdRleflexiveLatency=std(RleflexiveLatency(RleflexiveLatency>80));
            end
        endif
    endif
    result = [result,meanRleflexiveLatency,mediaRleflexiveLatency,minRleflexiveLatency,maxRleflexiveLatency,stdRleflexiveLatency,meanRleflexiveLatencyTotal,medianRleflexiveLatencyTotal,minRleflexiveLatencyTotal,stdRleflexiveLatencyTotal];
                %         31                         32                 33                  34                       35                         36                 37                           38                          39                                 
                

    %%tiempoReflexiva
    meantiempoReflexiva=NaN;
    mediatiempoReflexiva=NaN;
    maxtiempoReflexiva=NaN;
    mintiempoReflexiva=NaN;
    stdtiempoReflexiva=NaN;
    if tiempoReflexiva~=-1
        meantiempoReflexiva=mean(tiempoReflexiva);
        mediatiempoReflexiva=median(tiempoReflexiva);
        maxtiempoReflexiva=max(tiempoReflexiva);
        mintiempoReflexiva=min(tiempoReflexiva);
        if length(tiempoReflexiva)==1
          stdtiempoReflexiva=NaN;
        else
          stdtiempoReflexiva=std(tiempoReflexiva);
        end
    endif
    result = [result,meantiempoReflexiva,mediatiempoReflexiva,mintiempoReflexiva,maxtiempoReflexiva,stdtiempoReflexiva];
                %         40                   41                        42                 43              44         
    %%LATENCY vuelta 

  ltnc=0;
  latencypos=-1;
  for p=1:length(latency_v)
    if latency_v(p)>80
      ltnc++;
      latencypos(ltnc)=latency_v(p);
    endif
  endfor
  if latencypos==-1 && length(latencypos)==1  
    latencymaxv=NaN;
    latencyminv=NaN;
    latencymeanv=NaN;
    latencymedianv=NaN;
    latencystdv=NaN;  
  else
    latencymaxv=max(latencypos);
    latencyminv=min(latencypos);
    latencymeanv=mean(latencypos);
    latencymedianv=median(latencypos);
    if (ltnc==1)
      latencystdv=NaN;
    else
      latencystdv=std(latencypos);
    end
  endif
      result = [result latencymaxv];   %45
      result = [result latencyminv];   %46
      result = [result latencymeanv];  %47
      result = [result latencymedianv];%48
      result = [result latencystdv];   %49


  %%VELOCITY PEAK vuelta
  if velocitypeak_v==-1 && length(velocitypeak_v)==1
    velocitypeakmaxv=NaN;
    velocitypeakminv=NaN;
    velocitypeakmeanv=NaN;
    velocitypeakmedianv=NaN;
    velocitypeakstdv=NaN; 
  else
    velocitypeakmaxv=max(velocitypeak_v);
    velocitypeakminv=min(velocitypeak_v);
    velocitypeakmeanv=mean(velocitypeak_v);
    velocitypeakmedianv=median(velocitypeak_v);
    if length(velocitypeak_v)==1
      velocitypeakstdv=NaN;
    else
      velocitypeakstdv=std(velocitypeak_v);
    end  
  endif
      result = [result velocitypeakmaxv];     %50
      result = [result velocitypeakminv];     %51
      result = [result velocitypeakmeanv];    %52
      result = [result velocitypeakmedianv];  %53
      result = [result velocitypeakstdv];     %54
      
endfunction