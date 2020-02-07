function result = memory(fileName)   
% Cargar datos prueba

result = [];

structIn=loadOscannCSV(strcat(fileName,'.csv'));

if numfields(structIn) == 0
    %search result = [result
    result = ones(1,51)*-99;
    return
endif




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

%TODO plot
%figure(1);
%hold on;
%plot(time,gaze,time,stimulus);
%plot(time(blinks~=0),gaze(blinks~=0),'r.','linewidth',2);


% Separar por cambio de estimulo
indexStimChange=find(diff(stimulus)~=0);
indexStimChange(end+1)=length(stimulus);
#####################################################################PROCESADO

% Detectar fijaciones
[indexFixations, fixType, fixDuration] = fixationDetection(time, gaze, blinks, velocidad);

% Extraer puntos iniciales
[indexInitialPoints] = extractInitialPoints(time,gaze,stimulus,indexStimChange,indexFixations,fixType,false);


%plot 
%for i=1:length(indexInitialPoints)
%  figure(1);
%  hold on;
%  plot(time(indexInitialPoints(i)),gaze(indexInitialPoints(i)),'mx','linewidth',2);
%endfor
%print(1,strcat(dirname,sesion,".pdf"))

[finalFixations] = memory_finalFixation (indexInitialPoints, indexFixations, time, gaze,indexStimChange, stimulus);


[latency,velocitypeak,amplitudeErrorPositivo,amplitudeErrorNegativo,peakmaxstimmax,peakmaxstimmed,peakmaxstimmin,gain,memorySuccess, memory, anticipatedPoints, nAnticipated, latency_v, velocitypeak_v] = memory_calculateResults (indexInitialPoints, indexStimChange, stimulus, time, velocidad, finalFixations, gaze, indexFixations);




%%MEMORY SUCCESS
rateMemorySuccess= (memorySuccess/(length(indexStimChange)/4))*100;


result = [result nBlinks];                              %1
if (memorySuccess==0) 
  nAnticipated = NaN;
end
result = [result nAnticipated];                         %2

result = [result memorySuccess];                        %3
result = [result rateMemorySuccess];                    %4


%%LATENCY
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

result = [result latencymax];       %5
result = [result latencymin];       %6
result = [result latencymean];      %7
result = [result latencymedian];    %8
result = [result latencystd];       %9
  

%%VELOCITY PEAK
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

result = [result velocitypeakmax];      %10
result = [result velocitypeakmin];      %11
result = [result velocitypeakmean];     %12
result = [result velocitypeakmedian];   %13
result = [result velocitypeakstd];      %14

%%AMPLITUDE ERROR POSITIVO
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

result = [result amplitudeErrorPositivomax];    %15
result = [result amplitudeErrorPositivomin];    %16
result = [result amplitudeErrorPositivomean];   %17
result = [result amplitudeErrorPositivomedian]; %18
result = [result amplitudeErrorPositivostd];    %19

%%AMPLITUDE ERROR NEGATIVO
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

result = [result amplitudeErrorNegativomax];    %20
result = [result amplitudeErrorNegativomin];    %21
result = [result amplitudeErrorNegativomean];   %22
result = [result amplitudeErrorNegativomedian]; %23
result = [result amplitudeErrorNegativostd];    %24

%%PEAKMAX STIMULO MAXIMO
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

result = [result peakmaxstimmaxMax];            %25
result = [result peakmaxstimmaxMin];            %26
result = [result peakmaxstimmaxMean];           %27
result = [result peakmaxstimmaxMedian];         %28

%%PEAKMAX STIMULO MEDIO

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

result = [result peakmaxstimmedMax];            %29
result = [result peakmaxstimmedMin];            %30
result = [result peakmaxstimmedMean];           %31
result = [result peakmaxstimmedMedian];         %32


%%PEAKMAX STIMULO MINIMO
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

result = [result peakmaxstimminMax];            %33
result = [result peakmaxstimminMin];            %34
result = [result peakmaxstimminMean];           %35
result = [result peakmaxstimminMedian];         %36

%%GAIN
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

result = [result gainmax];                      %37
result = [result gainmin];                      %38
result = [result gainmean];                     %39
result = [result gainmedian];                   %40
result = [result gainstd];                      %41

%%LATENCY  VUELTA
ltnc=0;
latencypos_v=-1;
for p=1:length(latency_v)
  if latency_v(p)>80
    ltnc++;
    latencypos_v(ltnc)=latency_v(p);
  endif
endfor

if latencypos_v==-1 && length(latencypos_v)==1  
  latencymaxv=NaN;
  latencyminv=NaN;
  latencymeanv=NaN;
  latencymedianv=NaN;
  latencystdv=NaN;  
else
  latencymaxv=max(latencypos_v);
  latencyminv=min(latencypos_v);
  latencymeanv=mean(latencypos_v);
  latencymedianv=median(latencypos_v);
  if (ltnc==1)
    latencystdv=NaN;
  else
    latencystdv=std(latencypos_v);
  end
endif

result = [result latencymaxv];       %42
result = [result latencyminv];       %43
result = [result latencymeanv];      %44
result = [result latencymedianv];    %45
result = [result latencystdv];       %46
  

%%VELOCITY PEAK  VUELTA
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

result = [result velocitypeakmaxv];      %47
result = [result velocitypeakminv];      %48
result = [result velocitypeakmeanv];     %49
result = [result velocitypeakmedianv];   %50
result = [result velocitypeakstdv];      %51

endfunction

%fclose(myfile);

