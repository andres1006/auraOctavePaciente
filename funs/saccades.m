function result = saccades(fileName)

%fileName

%printf("saccades.m: %s\n", strcat(fileName, ".csv"))
structIn=loadOscannCSV(strcat(fileName, ".csv"));
%printf(" saccades numfields: %d\n", numfields(structIn))
if numfields(structIn) == 0
    result = ones(1,64)*-99;
    return
endif


result = [];

% Separa mirada eje correspondiente
if(sum(diff(structIn.data(:,4))!=0))
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
  result = NaN(1,64);
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

%TODO plot
%figure(1, 'visible', 'off');
%plot(time,gaze,time,stimulus);
%hold on;
%plot(time(blinks~=0),gaze(blinks~=0),'r.','linewidth',2);


% Separar por cambio de estimulo
indexStimChange=find(diff(stimulus)~=0);
indexStimChange(end+1)=length(stimulus);
#####################################################################PROCESADO

% Detectar fijaciones
[indexFixations, fixType, fixDuration] = fixationDetection(time, gaze, blinks, velocidad);

% Extraer puntos iniciales
[indexInitialPoints] = extractInitialPoints(time,gaze,stimulus,indexStimChange,indexFixations,fixType,false);

%Puntos anticipados
[anticipatedPoints, nAnticipated] = AnticipatedInitPoints (indexInitialPoints, indexStimChange, time);

%TODO plot 
%for i=1:length(indexInitialPoints)
%  figure(1);
%  hold on;
%  plot(time(indexInitialPoints(i)),gaze(indexInitialPoints(i)),'mx','linewidth',2);
%endfor
%print(1,strcat(fileName, ".pdf"));

[finalFixations] = finalFixation (indexInitialPoints, indexFixations, time, gaze, indexStimChange);

[latency,velocitypeak,amplitudeErrorPositivo,amplitudeErrorNegativo,peakmaxstimmax,peakmaxstimmed,peakmaxstimmin,gain, latency_v,velocitypeak_v,amplitudeErrorPositivo_v,amplitudeErrorNegativo_v,gain_v] = calculateResults (indexInitialPoints, indexStimChange, anticipatedPoints, stimulus, time, velocidad, finalFixations, gaze, indexFixations);





result = [result nBlinks]; %1

result = [result nAnticipated]; %2


%%LATENCY IDA
ltnc=0;
latencypos=-1;
for p=1:length(latency)
  if latency(p)>80
    ltnc++;
    latencypos(ltnc)=latency(p);
  endif
endfor
if latencypos==-1 && length(latencypos)==1  
  latencymax=NaN;
  latencymin=NaN;
  latencymean=NaN;
  latencymedian=NaN;
  latencystd=NaN;  
else
  latencymax=max(latencypos);
  latencymin=min(latencypos);
  latencymean=mean(latencypos);
  latencymedian=median(latencypos);
  if (ltnc==1)
    latencystd=NaN;
  else
    latencystd=std(latencypos);
  end
endif
    result = [result latencymax];   %3
    result = [result latencymin];   %4
    result = [result latencymean];  %5
    result = [result latencymedian];%6
    result = [result latencystd];   %7


%%VELOCITY PEAK IDA
if velocitypeak==-1 && length(velocitypeak)==1
  velocitypeakmax=NaN;
  velocitypeakmin=NaN;
  velocitypeakmean=NaN;
  velocitypeakmedian=NaN;
  velocitypeakstd=NaN; 
else
  velocitypeakmax=max(velocitypeak);
  velocitypeakmin=min(velocitypeak);
  velocitypeakmean=mean(velocitypeak);
  velocitypeakmedian=median(velocitypeak);
  if length(velocitypeak)==1
    velocitypeakstd=NaN;
  else
    velocitypeakstd=std(velocitypeak);
  end  
endif
    result = [result velocitypeakmax];     %8
    result = [result velocitypeakmin];     %9
    result = [result velocitypeakmean];    %10
    result = [result velocitypeakmedian];  %11
    result = [result velocitypeakstd];     %12

%%AMPLITUDE ERROR POSITIVO IDA
if amplitudeErrorPositivo==-1 && length(amplitudeErrorPositivo)==1
  amplitudeErrorPositivomax=NaN;
  amplitudeErrorPositivomin=NaN;
  amplitudeErrorPositivomean=NaN;
  amplitudeErrorPositivomedian=NaN;
  amplitudeErrorPositivostd=NaN;  
else
  amplitudeErrorPositivomax=max(amplitudeErrorPositivo);
  amplitudeErrorPositivomin=min(amplitudeErrorPositivo);
  amplitudeErrorPositivomean=mean(amplitudeErrorPositivo);
  amplitudeErrorPositivomedian=median(amplitudeErrorPositivo);
  if length(amplitudeErrorPositivo)==1
    amplitudeErrorPositivostd=NaN;
  else
    amplitudeErrorPositivostd=std(amplitudeErrorPositivo);
  end 
end
    result = [result amplitudeErrorPositivomax];    %13
    result = [result amplitudeErrorPositivomin];    %14
    result = [result amplitudeErrorPositivomean];   %15
    result = [result amplitudeErrorPositivomedian]; %16
    result = [result amplitudeErrorPositivostd];    %17

%%AMPLITUDE ERROR NEGATIVO IDA
if amplitudeErrorNegativo==-1 && length(amplitudeErrorNegativo)==1
  amplitudeErrorNegativomax=NaN;
  amplitudeErrorNegativomin=NaN;
  amplitudeErrorNegativomean=NaN;
  amplitudeErrorNegativomedian=NaN;
  amplitudeErrorNegativostd=NaN;
else
  amplitudeErrorNegativomax=max(amplitudeErrorNegativo);
  amplitudeErrorNegativomin=min(amplitudeErrorNegativo);
  amplitudeErrorNegativomean=mean(amplitudeErrorNegativo);
  amplitudeErrorNegativomedian=median(amplitudeErrorNegativo);
  amplitudeErrorNegativostd=std(amplitudeErrorNegativo);
  if length(amplitudeErrorNegativo)==1
    amplitudeErrorNegativostd=NaN;
  else
    amplitudeErrorNegativostd=std(amplitudeErrorNegativo);
  end 
end
    result = [result amplitudeErrorNegativomax];    %18
    result = [result amplitudeErrorNegativomin];    %19
    result = [result amplitudeErrorNegativomean];   %20
    result = [result amplitudeErrorNegativomedian]; %21
    result = [result amplitudeErrorNegativostd];    %22

%%PEAKMAX STIMULO MAXIMO IDA
if peakmaxstimmax==-1 && length(peakmaxstimmax)==1
  peakmaxstimmaxMax=NaN;
  peakmaxstimmaxMin=NaN;
  peakmaxstimmaxMean=NaN;
  peakmaxstimmaxMedian=NaN;
else
  peakmaxstimmaxMax=max(peakmaxstimmax);
  peakmaxstimmaxMin=min(peakmaxstimmax);
  peakmaxstimmaxMean=mean(peakmaxstimmax);
  peakmaxstimmaxMedian=median(peakmaxstimmax); 
end
    result = [result peakmaxstimmaxMax];    %23
    result = [result peakmaxstimmaxMin];    %24
    result = [result peakmaxstimmaxMean];   %25
    result = [result peakmaxstimmaxMedian]; %26

%%PEAKMAX STIMULO MEDIO IDA
if peakmaxstimmed==-1 && length(peakmaxstimmed)==1
  peakmaxstimmedMax=NaN;
  peakmaxstimmedMin=NaN;
  peakmaxstimmedMean=NaN;
  peakmaxstimmedMedian=NaN;
else
  peakmaxstimmedMax=max(peakmaxstimmed);
  peakmaxstimmedMin=min(peakmaxstimmed);
  peakmaxstimmedMean=mean(peakmaxstimmed);
  peakmaxstimmedMedian=median(peakmaxstimmed);  
end
    result = [result peakmaxstimmedMax];    %27
    result = [result peakmaxstimmedMin];    %28
    result = [result peakmaxstimmedMean];   %29
    result = [result peakmaxstimmedMedian]; %30

%%PEAKMAX STIMULO MINIMO IDA
if peakmaxstimmin==-1 && length(peakmaxstimmin)==1
  peakmaxstimminMax=NaN;
  peakmaxstimminMin=NaN;
  peakmaxstimminMean=NaN;
  peakmaxstimminMedian=NaN; 
else
  peakmaxstimminMax=max(peakmaxstimmin);
  peakmaxstimminMin=min(peakmaxstimmin);
  peakmaxstimminMean=mean(peakmaxstimmin);
  peakmaxstimminMedian=median(peakmaxstimmin);  
end
    result = [result peakmaxstimminMax];    %31
    result = [result peakmaxstimminMin];    %32
    result = [result peakmaxstimminMean];   %33
    result = [result peakmaxstimminMedian]; %34

%%GAIN IDA
if gain==-1 && length(gain)==1
  gainmax=NaN;
  gainmin=NaN;
  gainmean=NaN;
  gainmedian=NaN;
  gainstd=NaN;   
else
  gainmax=max(gain);
  gainmin=min(gain);
  gainmean=mean(gain);
  gainmedian=median(gain);
  if length(gain)==1
    gainstd=NaN; 
  else
    gainstd=std(gain);      
  end  
end

    result = [result gainmax];      %35
    result = [result gainmin];      %36
    result = [result gainmean];     %37
    result = [result gainmedian];   %38
    result = [result gainstd];      %39
    
    
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
    result = [result latencymaxv];   %40
    result = [result latencyminv];   %41
    result = [result latencymeanv];  %42
    result = [result latencymedianv];%43
    result = [result latencystdv];   %44


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
    result = [result velocitypeakmaxv];     %45
    result = [result velocitypeakminv];     %46
    result = [result velocitypeakmeanv];    %47
    result = [result velocitypeakmedianv];  %48
    result = [result velocitypeakstdv];     %49

%%AMPLITUDE ERROR POSITIVO vuelta
if amplitudeErrorPositivo_v==-1 && length(amplitudeErrorPositivo_v)==1
  amplitudeErrorPositivomaxv=NaN;
  amplitudeErrorPositivominv=NaN;
  amplitudeErrorPositivomeanv=NaN;
  amplitudeErrorPositivomedianv=NaN;
  amplitudeErrorPositivostdv=NaN;  
else
  amplitudeErrorPositivomaxv=max(amplitudeErrorPositivo_v);
  amplitudeErrorPositivominv=min(amplitudeErrorPositivo_v);
  amplitudeErrorPositivomeanv=mean(amplitudeErrorPositivo_v);
  amplitudeErrorPositivomedianv=median(amplitudeErrorPositivo_v);
  if length(amplitudeErrorPositivo_v)==1
    amplitudeErrorPositivostdv=NaN;
  else
    amplitudeErrorPositivostdv=std(amplitudeErrorPositivo_v);
  end 
end
    result = [result amplitudeErrorPositivomaxv];    %50
    result = [result amplitudeErrorPositivominv];    %51
    result = [result amplitudeErrorPositivomeanv];   %52
    result = [result amplitudeErrorPositivomedianv]; %53
    result = [result amplitudeErrorPositivostdv];    %54

%%AMPLITUDE ERROR NEGATIVO vuelta
if amplitudeErrorNegativo_v==-1 && length(amplitudeErrorNegativo_v)==1
  amplitudeErrorNegativomaxv=NaN;
  amplitudeErrorNegativominv=NaN;
  amplitudeErrorNegativomeanv=NaN;
  amplitudeErrorNegativomedianv=NaN;
  amplitudeErrorNegativostdv=NaN;
else
  amplitudeErrorNegativomaxv=max(amplitudeErrorNegativo_v);
  amplitudeErrorNegativominv=min(amplitudeErrorNegativo_v);
  amplitudeErrorNegativomeanv=mean(amplitudeErrorNegativo_v);
  amplitudeErrorNegativomedianv=median(amplitudeErrorNegativo_v);
  amplitudeErrorNegativostdv=std(amplitudeErrorNegativo_v);
  if length(amplitudeErrorNegativo_v)==1
    amplitudeErrorNegativostdv=NaN;
  else
    amplitudeErrorNegativostdv=std(amplitudeErrorNegativo_v);
  end 
end
    result = [result amplitudeErrorNegativomaxv];    %55
    result = [result amplitudeErrorNegativominv];    %56
    result = [result amplitudeErrorNegativomeanv];   %57
    result = [result amplitudeErrorNegativomedianv]; %58
    result = [result amplitudeErrorNegativostdv];    %59
    
%%GAIN vuelta
if gain_v==-1 && length(gain_v)==1
  gainmaxv=NaN;
  gainminv=NaN;
  gainmeanv=NaN;
  gainmedianv=NaN;
  gainstdv=NaN;   
else
  gainmaxv=max(gain_v);
  gainminv=min(gain_v);
  gainmeanv=mean(gain_v);
  gainmedianv=median(gain_v);
  if length(gain_v)==1
    gainstdv=NaN; 
  else
    gainstdv=std(gain_v);      
  end  
end

    result = [result gainmaxv];      %60
    result = [result gainminv];      %61
    result = [result gainmeanv];     %62
    result = [result gainmedianv];   %63
    result = [result gainstdv];      %64   
    
endfunction

