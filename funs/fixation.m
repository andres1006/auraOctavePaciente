
function result=fixation(filename)

%[filename,dirname] = uigetfile ("../*.csv"); 
result=[];
   
% Cargar datos prueba
structIn=loadOscannCSV(strcat(filename,'.csv'));
if numfields(structIn) == 0
    result = ones(1,29)*-99;
    return
endif

time=structIn.time;
gazex=structIn.gaze(:,1);
gazey=structIn.gaze(:,2);
gazeVelx=structIn.gazeVel(:,1);
gazeVely=structIn.gazeVel(:,2);
stimulus=structIn.estimulus;
blinks=structIn.detectionFail;
sesion=structIn.sesion;
pupilArea=structIn.pupilArea;


%isNan or isinf
i=1;
while i<=length(gazeVelx)
  if isnan(gazeVelx(i))==1 || isnan(gazex(i))==1 || isinf(gazeVelx(i))==1 || isinf(gazex(i))==1 || isnan(gazeVely(i))==1 || isnan(gazey(i))==1 || isinf(gazeVely(i))==1 || isinf(gazey(i))==1
    gazex(i) = [];
    time(i) = [];
    gazey(i) = [];
    stimulus(i) = [];
    blinks(i) = [];
    gazeVelx(i) = [];
    gazeVely(i) = [];
  else
    i++;
  end
endwhile

if (length(gazex)==0)
  result = NaN(1,29);
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
NumberofBlinks=nBlinks;

%remove blinks from the data
i=1;
timewb=-1;
wb=0;
while i<length(time)
  if blinks(i)==0
    wb++;
    timewb(wb)=time(i);
    gazexwb(wb)=gazex(i);
    gazeywb(wb)=gazey(i);
    stimuluswb(wb)=stimulus(i);   
  endif
  i++;
endwhile

if timewb != -1 

  type=zeros(length(time),1);

  %--------------------------------------------------------------------------------MICROSACCADES

  ###ITERATIVE THRESHOLD x############
  %smooth pursuit velocity less than 30-40º/s

  for i=1:length(gazeVelx)
    GazeVelocity(i)=sqrt(gazeVelx(i)^2 +gazeVely(i)^2);
  end

  threshold=abs(mean(GazeVelocity)+7*std(GazeVelocity));
  if threshold>max(abs(GazeVelocity)) threshold=mean(abs(GazeVelocity)); endif
  for i=1:100 %iteraciones para encontrar el umbral
    n=0;
    for m=1:length(GazeVelocity)
      if abs(GazeVelocity(m))<=threshold && blinks(m)==0
        n=n+1;
        gazeVelIn(n)=abs(GazeVelocity(m));
      endif
    endfor
    if n==0 break; endif
    thold=mean(gazeVelIn)+6*std(gazeVelIn);
    clear gazeVelIn;
    if abs(thold-threshold)<5
      threshold=thold;
      break;
    else
      threshold=thold;
    endif;
  endfor
  threshold1=threshold;
  %Minimo threshold de velocidad en y
  if(threshold < 6)
    threshold=6; 
  endif 


  %Maximo threshold de velocidad, sacado de la literatura y experimentalmente.
  if(threshold >20) %%20
    
    threshold=20;
  endif

  %{


  thresholdx=abs(mean(gazeVelx)+7*std(gazeVelx));
  if thresholdx>max(abs(gazeVelx)) thresholdx=mean(abs(gazeVelx)); endif
  for i=1:100 %iteraciones para encontrar el umbral
    n=0;
    for m=1:length(gazeVelx)
      if abs(gazeVelx(m))<=thresholdx && blinks(m)==0
        n=n+1;
        gazeVelIn(n)=abs(gazeVelx(m));
      endif
    endfor
    if n==0 break; endif
    tholdx=mean(gazeVelIn)+6*std(gazeVelIn);
    clear gazeVelIn;
    if abs(tholdx-thresholdx)<5
      thresholdx=tholdx;
      break;
    else
      thresholdx=tholdx;
    endif;
  endfor

  %Mínimo de threshold de velocidad en x
  if(thresholdx < 6)
    thresholdx=6; 
  endif


  thresholdy=abs(mean(gazeVely)+7*std(gazeVely));
  if thresholdy>max(abs(gazeVely)) thresholdy=mean(abs(gazeVely)); endif
  for i=1:100 %iteraciones para encontrar el umbral
    n=0;
    for m=1:length(gazeVely)
      if abs(gazeVely(m))<=thresholdy && blinks(m)==0
        n=n+1;
        gazeVelIn(n)=abs(gazeVely(m));
      endif
    endfor
    if n==0 break; endif
    tholdy=mean(gazeVelIn)+6*std(gazeVelIn);
    clear gazeVelIn;
    if abs(tholdy-thresholdy)<5
      thresholdy=tholdy;
      break;
    else
      thresholdy=tholdy;
    endif;
  endfor

  %Minimo threshold de velocidad en y
  if(thresholdy < 6)
    thresholdy=6; 
  endif 


  %Maximo threshold de velocidad, sacado de la literatura y experimentalmente.
  if(thresholdx >18) %%20
    thresholdx=18;
  endif
  thresholdx;
  if(thresholdy > 50)
    thresholdy=50;
  endif
  thresholdy;



  %Clasificar microsacadas, se necesita un filtro para que no pille las sacadas despues y antes de los parpadeos like SP, ejemplo de eso Santi y Silvia
  for j=1:length(gazeVelx)
    if (abs(gazeVelx(j))>thresholdx || abs(gazeVely(j))>thresholdy) && blinks(j)==0
      if j>1 type(j-1)=1; endif %it's identificated only the peak, it's added the two adjacent point because these point also are saccade.
      type(j)=1; %-----------------------------------type=1 there's saccade
      if j<length(gazeVelx)
       type(j+1)=1;
      endif
      %plot(time(j),gaze(j),'m');
    else 
      if type(j)!=1 %Por si se ha establecido como 1 en el punto anterior a causa de abarcar todo el pico de velocidad que coge el umbral.
        type(j)=0;  %-----------------------------------type=0 there's smooth pursuit
      endif
      %    SPEM++;
      %plot(time(j),gaze(j),'g');
    endif
    
  endfor
  %}

  %Clasificar microsacadas, se necesita un filtro para que no pille las sacadas despues y antes de los parpadeos like SP, ejemplo de eso Santi y Silvia
  for j=1:length(GazeVelocity)
    if (abs(GazeVelocity(j))>=threshold) %&& blinks(j)==0 NO SE TIENEN EN CUENTA EN ESTA CLASIFICACION LOS PARPADEOS PARA EL CONTEO DE LAS DISTRACCIONES
      if j>1 type(j-1)=1; endif %it's identificated only the peak, it's added the two adjacent point because these point also are saccade.
      type(j)=1; %-----------------------------------type=1 there's saccade
      if j<length(GazeVelocity)
       type(j+1)=1;
      endif
      %plot(time(j),gaze(j),'m');
    else 
      if type(j)!=1 %Por si se ha establecido como 1 en el punto anterior a causa de abarcar todo el pico de velocidad que coge el umbral.
        type(j)=0;  %-----------------------------------type=0 there's smooth pursuit
      endif
      %    SPEM++;
      %plot(time(j),gaze(j),'g');
    endif
    
  endfor
  
  ####################################MODIFICADO POR SILVIA 06/09/18 PARA LAS DISTRACCIONES
  %descartar los sacadas mayores a 10º (indeoendientemente del parpadeos o no)
  
  inicios=0;
  finales=0;
  estado=0;
  ini=0;
  fin=0;

  for i=1:length(type)-1
  if estado==0 && type(i)==0 && type(i+1)==1 %se ha encontrado una sacada
    ini++;
    inicios(ini)=i;
    estado=1;
  elseif estado ==1 && type(i)==1 && type(i+1)==0 %se ha terminado la sacada
    fin++;
    finales(fin)=i;
    estado=0;
    sentidoy(fin) = (gazey(finales(fin))-gazey(inicios(fin)));
    sentidox(fin) = (gazex(finales(fin))-gazex(inicios(fin)));
  elseif i==length(type)-1 && ini!=fin
    fin++;
    finales(fin)=length(type);
    sentidoy(fin) = (gazey(finales(fin))-gazey(inicios(ini)));
    sentidox(fin) = (gazex(finales(fin))-gazex(inicios(ini))); 
  elseif i == 1 && type(i) == 1  
    ini++;
    inicios(ini)=i;
    estado=1;   
  endif
endfor
  

for i=1:ini
  if (abs(gazex(inicios(i)))>10  || abs(gazex(finales(i)))>10) %grafica x
    inicio = inicios(i);
    final = finales(i);
    %COMPROBAR SI HAY ESCALONES POR DETRAS
    for j=1:i-1
      if (abs(gazex(inicios(i-j)))>10 || abs(gazex(finales(i-j)))>10)
        break;
      endif 
      if (sentidox(i)*sentidox(i-j)>0) && (time(inicios(i-j+1))-time(finales(i-j))<500) && abs(sentidox(i-j))>0.4
        if sentidox(i)>0 %pendiente positiva
          if gazex(inicios(i-j+1)) > gazex(inicios(i-j))
            inicio = inicios(i-j);
          else
            break;  
          endif
        elseif sentidox(i)<0
          if gazex(inicios(i-j+1)) < gazex(inicios(i-j))
            inicio = inicios(i-j);
          else
            break;  
          endif
        endif
      else
        break;  
      endif
    endfor
    
    %COMPROBAR SI HAY ESCALONES POR DELANTE
    for j=i+1:ini
      
      if (abs(gazex(inicios(j)))>10 || abs(gazex(finales(j)))>10)
        break;
      endif
      
      if (sentidox(i)*sentidox(j)>0) && (time(finales(j))-time(inicios(j-1))<500) && abs(sentidox(j))>0.4
        if sentidox(i)>0 %pendiente positiva
          if gazex(finales(j-1)) < gazex(inicios(j))
            final = finales(j);
          else
            break;  
          endif
        elseif sentidox(i)<0
          if gazex(finales(j-1)) > gazex(inicios(j))
            final = finales(j);
          else
            break;  
          endif
        endif
      else
        break;  
      endif  
    endfor
    for k=inicio:final
      type(k) = -99;
    endfor 
  endif
  
  if (abs(gazey(inicios(i)))>10  || abs(gazey(finales(i)))>10) %grafica y
    
    inicio = inicios(i);
    final = finales(i);
    
    %COMPROBAR SI HAY ESCALONES POR DETRAS
    for j=1:i-1
      
      if (abs(gazey(inicios(i-j)))>10 || abs(gazey(finales(i-j)))>10)
        break;
      endif 
      
      if (sentidoy(i)*sentidoy(i-j)>0) && (time(inicios(i-j+1))-time(finales(i-j))<500) && abs(sentidoy(i-j))>0.4
        if (abs(gazey(inicios(i)))>10 || abs(gazey(finales(i)))>10) %grafica y
          if sentidoy(i)>0 %pendiente positiva
            if gazey(inicios(i-j+1)) > gazey(inicios(i-j))
              inicio = inicios(i-j);
            else
              break;  
            endif
          elseif sentidoy(i)<0
            if gazey(inicios(i-j+1)) < gazey(inicios(i-j))
              inicio = inicios(i-j);
            else
              break;  
            endif
          endif
        endif
      else
        break;  
      endif  
    endfor  
    
    %COMPROBAR SI HAY ESCALONES POR DELANTE
    for j=i+1:ini
      
      if (abs(gazey(inicios(j)))>10 || abs(gazey(finales(j)))>10)
        break;
      endif
      if (sentidoy(i)*sentidoy(j)>0) && (time(finales(j))-time(inicios(j-1))<500) && abs(sentidoy(j))>0.4
        if (abs(gazey(inicios(i)))>10 || abs(gazey(finales(i)))>10) %grafica y
          if sentidoy(i)>0 %pendiente positiva
            if gazey(inicios(j-1)) < gazey(inicios(j))
              final = finales(j);
            else
              break;  
            endif
          elseif sentidoy(i)<0
            if gazey(inicios(j-1)) > gazey(inicios(j))
              final = finales(j);
            else
              break;  
            endif
          endif
        endif
      else
        break;
      endif
    endfor 
    for k=inicio:final
      type(k) = -99;
    endfor 
  endif
endfor  


%Por si ha iniciado la prueba mirando a otro sitio
for i=1:length(type)
  if (type(i)==-99 && (abs(gazex(i))>10 || abs(gazey(i))>10))
    for j=1:i
      if (abs(gazex(j))<10 && abs(gazey(j))<10) break; endif
      type(j)=-99;
    endfor
    break;
  endif
endfor

i=2;
dis=0;
while(i<=length(type)-1)
  if (((type(i-1)==-99 && type(i)!=-99) || (blinks(i-1)!=0 && blinks(i)==0)) && (abs(gazex(i))>10 || abs(gazey(i))>10) && dis==0)
    dis=1;
    type(i) = -99;
  elseif dis==1
    type(i) = -99;
    if (type(i+1) == -99 || blinks(i)!=0)
      dis=0;
    endif  
  endif
  i++;
endwhile


estado=0;
distracciones=0;
for i=1:length(type)-1
  if (abs(gazex(i)) > 10 || abs(gazey(i)) > 10) && estado == 0
    distracciones++;
    estado=1;
  elseif abs(gazex(i))<5 && abs(gazey(i))<5
    estado=0;  
  endif  
endfor
  
  
  ##################################################################################################
  ########################################    BCEA    ##############################################
  ##################################################################################################
  ox=NaN;
  oy=NaN;
  centroide=[NaN,NaN];
  BCEA=NaN;
  ind=0;
  for(i=1:length(type))
    if(type(i)!=-99 && blinks(i)==0)
      ind++;
      X(ind,1)=gazex(i);
      X(ind,2)=gazey(i);
    endif
  endfor
  if(ind!=0)
  
    ox=std(X(:,1));
    oy=std(X(:,2));
    p=corr(X(:,1),X(:,2));% default pearson's linear correlation coefficient.

    BCEA=pi*2.291*ox*oy*(sqrt(1-(p^2)));% Probabilidad=68.2% chi2inv(0.682,2) %1.3288

    %Center of elipse
    centroide=[mean(X(:,1)), mean(X(:,2))];
  endif

  ##################################################################################################
  ##################################################################################################

  %Para que no cuente las sacadas en las cuales haya un parpadeo 5 frames antes o 5 frames despues
  for i=1:length(gazex)-1
    if(blinks(i)!=0)
      type(i)=0;
    endif
    
    if type(i)==1
      inicio_prov=i;
      j=0;
      
      while type(i+j)==1
        j++;
        if (i+j)>length(gazex) break; endif
      endwhile
      j=j-1;
      fin_prov=j+i;
      if i <= 5
        nuevo_ini=1;
      else
        nuevo_ini=i-5;
      endif
      
      if (i+j) >= (length(gazex)-5)
        nuevo_fin=length(gazex);
      else
        nuevo_fin=i+j+5;
      endif
      
      if find(blinks(nuevo_ini:nuevo_fin),1)
        type(inicio_prov:fin_prov)=0;
      endif
      i=i+j;
    endif
  endfor

  %Existian puntos sueltos de slow motion, con este algortimo nos los quitamos
  for i=1:length(gazex)
    if i==1
      if type(i)==0 && type(i+1)==1 
        type(i)=1;
      endif 
    elseif i==length(gazex) 
      if type(i)==0 && type(i-1)==1
        type(i)=1;
      endif
    elseif type(i)==0 && type(i-1)==1 && type(i+1)==1
      type(i)=1;
    endif
  endfor



  %% Calculo de la amplitud
  onset=[];
  finish=[];
  amplitud=[];
  i=1;
  while i<length(gazex)-1
    j=1;
    while (i+j)<length(gazex) && type(i+j)==type(i) %%Determinar cuantos frames son de un mismo tipo y calcular su amplitud
      j++;
      if ((i+j)==length(gazex)) break; endif
    endwhile
    j=j-1;
    beginx=gazex(i);
    beginy=gazey(i);
    maxx=gazex(i+j);
    maxy=gazey(i+j);
    for k=i:i+j
      if((maxx-beginx)<0)
        if(gazex(k)<maxx) maxx=gazex(k); endif;
      else
        if(gazex(k)>maxx) maxx=gazex(k); endif;
      endif
      if((maxy-beginy)<0)
        if(gazey(k)<maxy) maxy=gazey(k); endif;
      else
        if(gazey(k)>maxy) maxy=gazey(k); endif;
      endif
    endfor
    onset=vertcat(onset,i);
    finish=vertcat(finish,i+j);  
    ampli=sqrt((maxx-beginx)^2 + (maxy-beginy)^2);
    amplitud=vertcat(amplitud,ampli);
    
    i=i+j+1;
  endwhile

  %%Calculo de SWJ
  [ampl_swj,time_swj,num_swjmono, num_swjbi,plotonset]=SqWaveJ(gazex,gazey,type,onset,finish,amplitud,time);


  gaze=zeros(length(gazex),2);
  gazeVel=zeros(length(gazeVelx),2);
  gaze(:,1)=gazex;
  gaze(:,2)=gazey;
  gazeVel(:,1)=gazeVelx;
  gazeVel(:,2)=gazeVely;

  %Función para sacar las microsacadas
  [onset_mic , finish_mic , vpeak_mic , ampl_mic, type, v_mean_mic]=micsaccdeg(time,gazeVel,type,onset,finish,amplitud);

  %Funcion para sacar los drift
  [onset_drift , finish_drift , vpeak_drift , ampl_drift, type, v_mean_drift]=driftdeg(gaze,time,gazeVel,type,pupilArea,onset,finish,amplitud);

  %Calculo del numero de microsacadas, sacadas y drift
  num_microsacadas=length(onset_mic);
  num_drift=length(onset_drift);

  num_sacadas=0;
  for i=2:length(gazex)
    if(type(i)==1 && type(i-1)==0)
      num_sacadas++;
    endif
  endfor

  %{
  i=1;
  figure; 
  hold on;
  %plot(time,stimulus);
  plot(time(type==1), gazex(type==1),"b."); %Sacada
  plot(time(type==0), gazex(type==0),"g."); %Fijacion
  plot(time(type==2), gazex(type==2),"m."); %Microsacada
  plot(time(type==3), gazex(type==3),"c."); %Drift
  plot(time(blinks~=0), gazex(blinks~=0),"r."); %Parpadeo
  while i<=(length(plotonset)-3)
    plot(time(plotonset(i:(i+3))),gaze(plotonset(i:(i+3))),"k -",'LineWidth',3 );
    i=i+4;
  endwhile
  axis([0 max(time) -5 10])
  legend('Sacada','Fijación','Microsacada','Drift','Parpaeo', 'SWJ' ,'Location','northwestoutside')
  xlabel('time(ms)')
  ylabel('gazex(deg)')
  title(filename);

  i=1;
  figure;
  hold on;
  %plot(time,stimulus);
  plot(time(type==1), gazey(type==1),"b .");
  plot(time(type==0), gazey(type==0),"g .");
  plot(time(type==2), gazey(type==2),"m .");
  plot(time(type==3), gazey(type==3),"c .");
  plot(time(blinks~=0), gazey(blinks~=0),"r.");
  while i<=(length(plotonset)-3)
    plot(time(plotonset(i:(i+3))),gazey(plotonset(i:(i+3))),"k -",'LineWidth',3 );
    i=i+4;
  endwhile
  axis([0 max(time) -5 10])
  legend('Sacada','Fijación','Microsacada','Drift','Parpaeo','SWJ','Location','northwestoutside')
  xlabel('time(ms)')
  ylabel('gazey(deg)')
  title(filename)
  %}

  %{
  gaze=sqrt(gazex.^2+gazey.^2);
  figure;
  hold on;
  plot(time(type==1), gaze(type==1),"b."); %Sacada
  plot(time(type==0), gaze(type==0),"g."); %Fijacion
  plot(time(type==2), gaze(type==2),"m."); %Microsacada
  plot(time(type==3), gaze(type==3),"c."); %Drift
  plot(time(blinks~=0), gaze(blinks~=0),"r."); %Parpadeo
  i=1
  while i<=(length(plotonset)-3)
    plot(time(plotonset(i:(i+3))),gaze(plotonset(i:(i+3))),"k -",'LineWidth',3 );
    i=i+4;
  endwhile
  axis([0 max(time) -10 10])
  legend('Sacada','Fijación','Microsacada','Drift','Parpadeo','SWJ','Location','northwestoutside')
  xlabel('time(ms)')
  ylabel('gaze(deg)')
  %}
  %{
  figure; 
  hold on;
  %plot(time,stimulus);
  plot(gazex(type==1), gazey(type==1),"b.");
  plot(gazex(type==0), gazey(type==0),"g.");
  plot(gazex(type==2), gazey(type==2),"m.");
  plot(gazex(type==3), gazey(type==3),"k.");
  plot(gazex(blinks~=0), gazey(blinks~=0),"r.");
  plot(gazex(plotonset),gazey(plotonset),"k - ");

  if(num_microsacadas!=0)
  for i=1:length(onset_drift)
    text(gazex(onset_drift(i):finish_drift(i)), gazey(onset_drift(i):finish_drift(i)),num2str(i),'FontWeight','bold');
  endfor
  endif
  %}


  %Cosas a imprimir: BCEA, CENTRO BCEA, FRECUENCIA DE MICROSACADAS, AMPLITUD MICROSACADAS, VELOCIDAD MICROSACADAS,VELOCIDAD MAXIMA MICROSACADAS,
  %AMPLITUD DRIFT, VELOCIDAD DRIFT,VELOCIDAD MAXIMA DRIFT, NUMERO DE SACADAS, 
  %NUMERO DE MICROSACADAS, NUMERO DE DRIFT, NUMERO DE BLINKS

  if(num_microsacadas!=0)

    ampl_mic_final=mean(ampl_mic);
    if length(ampl_mic)!=1
      ampl_mic_std=std(ampl_mic);
    else
      ampl_mic_std=NaN;
    end
    
    v_mean_mic_final=mean(v_mean_mic);
    if length(v_mean_mic)!=1
      v_mean_mic_std=std(v_mean_mic);
    else
      v_mean_mic_std=NaN;
    end
    
    vpeak_mic_final=mean(vpeak_mic);
    if length(vpeak_mic)!=1
      vpeak_mic_final_std=std(vpeak_mic);
    else
      vpeak_mic_final_std=NaN;
    end
    
    frec_microsacadas=num_microsacadas/[max(time)/1000];
  else
    ampl_mic_final=NaN;
    ampl_mic_std=NaN;
    v_mean_mic_final=NaN;
    v_mean_mic_std=NaN;
    vpeak_mic_final=NaN;
    vpeak_mic_final_std=NaN;
    frec_microsacadas=NaN;
  endif

  if(num_drift!=0)

    ampl_drift_final=mean(ampl_drift);
    if length(ampl_drift)!=1
      ampl_drift_std=std(ampl_drift);
    else
      ampl_drift_std=NaN;
    end
    
    v_mean_drift_final=mean(v_mean_drift);
    if length(v_mean_drift)!=1
      v_mean_drift_std=std(v_mean_drift);
    else
      v_mean_drift_std=NaN;
    end
    
    vpeak_drift_final=mean(vpeak_drift);
    if length(vpeak_drift)!=1
      vpeak_drift_final_std=std(vpeak_drift);
    else
      vpeak_drift_final_std=NaN;
    end
    
  else
    ampl_drift_final=NaN;
    ampl_drift_std=NaN;
    v_mean_drift_final=NaN;
    v_mean_drift_std=NaN;
    vpeak_drift_final=NaN;
    vpeak_drift_final_std=NaN;
  endif

  if((num_swjmono+num_swjbi)!=0)

    amplitud_swj=mean(ampl_swj);
    if length(ampl_swj)!=1
      amplitud_swj_std=std(ampl_swj);
    else
      amplitud_swj_std=NaN;
    end
    
    tiempo_swj=mean(time_swj);
    if length(time_swj)!=1
      tiempo_swj_std=std(time_swj);
    else
      tiempo_swj_std=NaN;
    end
    
  else
    amplitud_swj=NaN;
    amplitud_swj_std=NaN;
    tiempo_swj=NaN;
    tiempo_swj_std=NaN;
  endif

  num_sacadas;
  num_microsacadas;
  num_drift;
  num_swjmono;
  num_swjbi;

  filename;
  result=[result NumberofBlinks]; %1
  result=[result num_sacadas]; %2
  result=[result num_microsacadas]; %3
  result=[result num_drift]; %4
  result=[result num_swjmono]; %5
  result=[result num_swjbi]; %6

  result=[result BCEA]; %7
  result=[result centroide]; %8 %9

  result=[result ampl_mic_final]; %10
  result=[result ampl_mic_std]; %11
  result=[result v_mean_mic_final]; %12
  result=[result v_mean_mic_std]; %13
  result=[result vpeak_mic_final]; %14
  result=[result vpeak_mic_final_std]; %15
  result=[result frec_microsacadas]; %16

  result=[result ampl_drift_final]; %17
  result=[result ampl_drift_std]; %18
  result=[result v_mean_drift_final]; %19
  result=[result v_mean_drift_std]; %20
  result=[result vpeak_drift_final]; %21
  result=[result vpeak_drift_final_std]; %22


  result=[result amplitud_swj]; %23
  result=[result amplitud_swj_std]; %24
  result=[result tiempo_swj]; %25
  result=[result tiempo_swj_std]; %26


  result=[result ox]; %27
  result=[result oy]; %28
  result=[result distracciones]; %29

else
  result = NaN(1,29);  
endif

endfunction

