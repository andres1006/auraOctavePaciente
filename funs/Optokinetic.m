function result = Optokinetic(filename)

%Carga del archivo
result = [];

data=loadOscannCSV(strcat(filename,'.csv'));

if numfields(data) == 0
    result = ones(1,18)*-99; %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    return
endif

test_pre = strsplit(filename,'-'){1,1};
test=strsplit(test_pre,'/'){1,end};
blinks= data.detectionFail;


%Calculo de las velocidades sin filtrar para el procesamiento
for(i = 2 : length(data.gazeRaw(:,1)))
  gazeVelRaw(i,1) = 1000*(data.gazeRaw(i,1)-data.gazeRaw(i-1,1))/(data.time(i)-data.time(i-1));
  gazeVelRaw(i,2) = 1000*(data.gazeRaw(i,2)-data.gazeRaw(i-1,2))/(data.time(i)-data.time(i-1));
end
gazeVelRaw(1,:) = gazeVelRaw(2,:);

%Se modifican los vecores para algunos casos, asi el codigo es reutilizable para todos los tipos de pruebas
if(test == "TOPTHL")
  gaze = data.gaze(:,1).';
  gazeRaw = data.gazeRaw(:,1).';
  gazeVel = data.gazeVel(:,1).';
  gazeVelRaw = gazeVelRaw(:,1).';
elseif(test == "TOPTHR")
  gaze = -data.gaze(:,1).';
  gazeRaw = -data.gazeRaw(:,1).';
  gazeVel = -data.gazeVel(:,1).';
  gazeVelRaw = -gazeVelRaw(:,1).';
elseif(test == "TOPTVD")
  gaze = data.gaze(:,2).';
  gazeRaw = data.gazeRaw(:,2).';
  gazeVel = data.gazeVel(:,2).';
  gazeVelRaw = gazeVelRaw(:,2).';
elseif(test == "TOPTVU")
  gaze = -data.gaze(:,2).';
  gazeRaw = -data.gazeRaw(:,2).';
  gazeVel = -data.gazeVel(:,2).';
  gazeVelRaw = -gazeVelRaw(:,2).';
end

%isNan
nan=isnan(gazeVel);
for i=1:length(gazeVel)
  if nan(i)==1
    gaze(i) = [];
    gazeVel(i) = [];
    gazeRaw(i) = [];
    gazeVelRaw(i) = [];
    blinks(i) = [];
  end
endfor

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


positiveVel = abs(gazeVel);
%%Creacion de un vector con las velocidades negativas nulas
%for(i = 1 : length(positiveVel))
%    if(positiveVel(i) < 10)
%      positiveVel(i) = 0;
%    end
%end

positiveVelRaw = abs(gazeVelRaw);
%%Creacion de un vector con las velocidades raw negativas nulas
%for(i = 1 : length(positiveVelRaw))
%    if(positiveVelRaw(i) < 20)
%      positiveVelRaw(i) = 0;
%    end
%end

%Funcion de deteccion de los picos de velocidad
%Variable indice para conocer la longitud del vector de valores pico
velPks=-1;
ind = 1;
%Variable para almacenar el valor provisional maximo en caso de haber "falsos" valores
tmpPeak = 1;
for(i = 2 : length(positiveVel)-1)
    %Comparacion con el valor anterior y siguiente para determinar un posible maximo
    if(positiveVel(i-1) < positiveVel(i) && 
       positiveVel(i) > positiveVel(i+1) && 
       positiveVel(i) > positiveVel(tmpPeak) && 
       positiveVel(i) >= 20)
      %Almacenamiento del posible valor maximo temporal
      tmpPeak = i;
    end
    
    %Cuando la velocidad pasa por 10 se almacena el valor temporal maximo como definitivo (revisar)
    if(tmpPeak != 1 && positiveVel(i) < 10)
      velPks(ind) = tmpPeak;
      tmpPeak = 1;
      ind += 1;
    end
end

%figure;
%hold on;
%plot(data.time,positiveVel,'b','LineWidth',1.5);
%scatter(data.time(velPks),positiveVel(velPks),'r','filled');
#################################################################################
#######################INICIALIZAR VARIABLES######################################
##################################################################################
rCoef=NaN;
rCoefTotal=NaN;
gazeNystagmusAngle=NaN;
gazePursuitAngle=NaN;
amplitudeNY=NaN;
amplitudeSP=NaN;
meanSlowVel=NaN;
meanFastVel=NaN;
gazeRawMax=-99;
gazeRawMin=-99;

if velPks!=-1 ############SI NO SE DETECTA NINGUN PICO NO HAY RESULTADOS TODO NaN
  %Funcion de deteccion de maximos en la mirada
  %Se recorre el vector de la mirada desde cada velocidad pico hasta encontrar un maximo local
  ind = 1;
  for(i = 1 : length(velPks))
    j = 0;
    tmpPeak = 1;
    while(true)
      %Comprobacion de que no se excede la longitud del vector de velocidades maximas
      if(i+1 < length(velPks))
        %Se finaliza la deteccion de un maximo si se alcanza el siguiente pico de velocidad
        if(velPks(i)+j >= velPks(i+1))
          if(tmpPeak != 1)
            pksMax(ind) = tmpPeak;
            ind += 1;
          end
          break;
        end
      %Se finaliza la deteccion de un maximo si se alcanza el final del vector de la mirada
      elseif(velPks(i)+j >= length(gaze))
        if(tmpPeak != 1)
          pksMax(ind) = tmpPeak;
          ind += 1;
        end
        break;
      end
    
      %Comparacion de los valores anterior y siguiente con el actual para determinar un posible maximo
      if(gaze(velPks(i)+j-1) < gaze(velPks(i)+j) && 
         gaze(velPks(i)+j) > gaze(velPks(i)+j+1))
         %Almacenamiento temporal del posible maximo en la mirada
        if(tmpPeak != 1)
          if(gaze(velPks(i)) > gaze(tmpPeak))
            tmpPeak = velPks(i)+j;
          end
        else
          tmpPeak = velPks(i)+j;
        end
      end
      
      j += 1;
    end
  end

  %Funcion de deteccion de minimos en la mirada
  %Se recorre el vector de la mirada desde cada velocidad pico hasta encontrar un minimo local
  ind = 1;
  %Vector temporal que contiene los valores maximos de la mirada y el final del vector de la mirada
  pksMaxTmp=[pksMax length(gaze)];
  for(i = 1 : length(pksMaxTmp))
    j = 0;
    tmpPeak = 1;
    while(true)
      %Comprobacion de que el valor de velocidad pico mas uno no excede la longitud del vector de la mirada
      if(pksMaxTmp(i) >= length(gaze)-1)
        break;
      end
      %Comprobacion de que no se alcanza el inicio del vector de la mirada
      if(i != 1)
        %Se finaliza la deteccion de un minimo si se alcanza el anterior pico de la mirada
        if(pksMaxTmp(i)-j <= pksMaxTmp(i-1)+1)
          if(tmpPeak != 1)
            pksMin(ind) = tmpPeak;
            ind += 1;
          end
          break;
        end
      %Se finaliza la deteccion de un minimo si se alcanza el inicio del vector de la mirada
      elseif(pksMaxTmp(i)-j <= 1)
        if(tmpPeak != 1)
          pksMin(ind) = tmpPeak;
          ind += 1;
        end
        break;
      end
      
      %Comparacion de los valores anterior y siguiente con el actual para determinar un posible minimo
      if(gaze(pksMaxTmp(i)-j-1) > gaze(pksMaxTmp(i)-j) && 
         gaze(pksMaxTmp(i)-j) < gaze(pksMaxTmp(i)-j+1))
        %Almacenamiento temporal del posible minimo en la mirada
        if(tmpPeak != 1)
          if(gaze(pksMaxTmp(i)) < gaze(tmpPeak))
            tmpPeak = pksMaxTmp(i)-j;
          end
        else
          tmpPeak = pksMaxTmp(i)-j;
        end
      end
      
      j += 1;
    end
  end

  %Funcion para unir los pares de movimiento de alta velocidad
  ind = 1;
  numNystagmus = 0;
  for(i = 1 : length(velPks))
    j = 0;
    %Valores temporales para almacenar los posibles pares maximo y minimo
    tmpMax = 0;
    tmpMin = 0;
    
    %Apartado de comparacion para obtener el pico maximo del par
    while(true)
      %Comprobacion de que no se exceda la longitud del vector de velocidades pico
      if(i+1 <= length(velPks))
        %En caso de llegar al siguiente pico de velocidad se sale del bucle
        if(velPks(i)+j >= velPks(i+1))
          break;
        end
      %En caso de llegar al final de la prueba se sale del bucle
      elseif(velPks(i)+j >= length(gaze))
        break;
      end
      
      %Comparacion del valor actual con el vector de picos maximos en la mirada
      for(k = 1 : length(pksMax))
        if(velPks(i)+j == pksMax(k))
          tmpMax = pksMax(k);
          break;
        end
      end
      %Se sale del bucle si se ha encontrado un pico maximo identico
      if(tmpMax != 0)
        break;
      end
      j += 1;
    end
      
    %Apartado de comparacion para obtener el pico minimo del par
    if(tmpMax)
      j = 0;
      while(true)
      %Comprobacion de que no es la primera iteracion para comparar con 0
        if(i != 1)
          %En caso de llegar al anterior pico de velocidad se sale del bucle
          if(velPks(i)-j <= velPks(i-1))
            break;
          end
        %En caso de llegar al inicio del vector de velocidades pico se sale del bucle
        elseif(velPks(i)-j <= 0)
          break;
        end
        
        %Comparacion del valor actual con el vector de picos minimo en la mirada
        for(k = 1 : length(pksMin))
          if(velPks(i)-j == pksMin(k))
            tmpMin = pksMin(k);
            break;
          end
        end
        %Se sale del bucle si se ha encontrado un pico minimo identico
        if(tmpMin != 0)
          break;
        end
        j += 1;
      end
    end
    
    %En caso de haber encontrado ambos picos se añade al vector de pares final
    if(tmpMax != 0 && tmpMin != 0)
      nystagmus(ind,:) = [tmpMin tmpMax];
      numNystagmus += 1;
      ind += 1;
    end
  end

  %Valor para recortar los extremos de las regresiones para obtener un coeficiente de regresion optimo
  regMargin = 8;

  %Funcion para unir los pares de movimiento de baja velocidad
  ind = 1;
  numPursuits = 0;
  for(i = 1 : length(pksMax))
    j = 0;
    %Valor temporal para almacenar los posibles minimos
    tmpMin = 0;
    
    %Apartado de comparacion para obtener el pico minimo del par
    while(true)
      %Comprobacion de que no se exceda la longitud del vector de picos maximos
      if(i+1 < length(pksMax))
        %En caso de llegar al siguiente pico maximo se sale del bucle
        if(pksMax(i)+j >= pksMax(i+1))
          break;
        end
      %En caso de llegar al final de la prueba se sale del bucle
      elseif(pksMax(i)+j >= length(gaze))
        break;
      end
      
      %Comparacion del valor actual con el vector de picos minimos en la mirada
      for(k = 1 : length(pksMin))
        if(pksMax(i)+j == pksMin(k))
          tmpMin = pksMin(k);
          break;
        end
      end
      %Se sale del bucle si se ha encontrado un pico minimo identico
      if(tmpMin != 0)
        break;
      end
      j += 1;
    end
    
    %En caso de haber encontrado un pico minimo se añade al vector de pares final
    if(tmpMin != 0)
      if(tmpMin < pksMax(i))
        pursuit(ind,:) = [tmpMin pksMax(i)];
        ind += 1;
      else
        pursuit(ind,:) = [pksMax(i) tmpMin];
        ind += 1;
      end    
      numPursuits += 1;
    end
  end

  %Plot de los multiples seguimientos y velocidades de los mismos
  %figure;
  %hold on;
  %cmap = rand(length(pursuit(:,1)),3);
  %subplot(1,2,1);
  %for(i = 1 : length(pursuit(:,1)))
  %  plot(gazeVel(pursuit(i,1):pursuit(i,2)),'color',cmap(i,:),'LineWidth',1.5);
  %  hold on;
  %end
  %title("Gaze Speed");
  %subplot(1,2,2);
  %for(i = 1 : length(pursuit(:,1)))
  %  plot(gaze(pursuit(i,1):pursuit(i,2)),'color',cmap(i,:),'LineWidth',1.5);
  %  hold on;
  %end
  %title("Gaze");

  %Funcion para comprobar si dentro de cada seguimiento se han realizado sacadas en la direccion del estimulo
  i = 1;
  while(i < length(pursuit(:,1)))
    ind = 0;
    firstValue = true;
    continueVal = false;
    posibleEndVal = false;
    valueIni = pursuit(i,1);
    prevPursuit = pursuit(i,2);
    for(j = pursuit(i,1) : pursuit(i,2))
      if(gazeVel(j) < -25)
        valueEnd = j;
        continueVal = true;
      end
      if(continueVal && gazeVel(j) >= -25 && j != prevPursuit)
        if(firstValue && valueEnd-2 > valueIni+2)
          pursuit(i,:) = [valueIni+2 valueEnd-2];
        elseif(valueEnd-2 > valueIni+2)
          pursuit = [pursuit(1:i+ind,:) ; [valueIni+2 valueEnd-2] ; pursuit(i+ind+1:end,:)];
        end
        posibleEndVal = true;
        firstValue = false;
        continueVal = false;
        valueIni = j;
        ind += 1;
      elseif(posibleEndVal && j == prevPursuit && valueIni+2 < j)
        pursuit = [pursuit(1:i+ind,:) ; [valueIni+2 j] ; pursuit(i+ind+1:end,:)];
      end
    end
    i += ind+1;
  end

  %Volver a poner los valores como son originalmente
  if(test == "TOPTHR" || test == "TOPTVU")
      gaze = -gaze;
      gazeRaw = -gazeRaw;
      gazeVel = -gazeVel;
      gazeVelRaw = -gazeVelRaw;
  end

  %Calculo de regresiones para cada correccion
  for(i = 1 : length(pursuit(:,1)))
    if(pursuit(i,2)-pursuit(i,1) > regMargin+1)
      valueIni = pursuit(i,1)+regMargin/2;
      valueEnd = pursuit(i,2)-regMargin/2;
    else
      valueIni = pursuit(i,1);
      valueEnd = pursuit(i,2);
    end
    numerator = 0;
    denominator = 0;
    for(j = valueIni : valueEnd)
      numerator += (data.time(j)-mean(data.time(valueIni:valueEnd)))*(gaze(j)-mean(gaze(valueIni:valueEnd)));
      denominator += (data.time(j)-mean(data.time(valueIni:valueEnd)))*(data.time(j)-mean(data.time(valueIni:valueEnd)));
    end
    %Almacenamiento de las pendientes y los origenes para cada regresion
    pursuitSlope(i) = numerator/denominator;
    pursuitOrigin(i) = mean(gaze(valueIni:valueEnd))-pursuitSlope(i)*mean(data.time(valueIni:valueEnd));
    
    %Calculo del coeficiente de regresion
    ssTotal = 0;
    ssResidual = 0;
    for(j = valueIni : valueEnd)
      %Calculo de la suma de los cuadrados
      ssTotal += (gaze(j)-mean(gaze(valueIni:valueEnd)))*(gaze(j)-mean(gaze(valueIni:valueEnd)));
      %Calculo del cuadrado de los residuos
      ssResidual += (gaze(j)-pursuitSlope(i)*data.time(j)-pursuitOrigin(i))*(gaze(j)-pursuitSlope(i)*data.time(j)-pursuitOrigin(i));
    end
    %Almacenamiento del coeficiente de regresion para cada par
    rCoef(i) = 1-ssResidual/ssTotal;
  end

  %Funcion para calcular los maximos de velocidades raw "reales" para las estadisticas
  for(i = 1 : length(nystagmus(:,1)))
    max = 0;
    maxVelRawInd(i) = nystagmus(i,1);
    for(j = nystagmus(i,1) : nystagmus(i,2))
      if(positiveVelRaw(j) > max)
        max = positiveVelRaw(j);
        maxVelRawInd(i) = j;
      end
    end
  end

  %Funcion para obtener los intervalos de velocidad pico para calcular las velocidades medias de los nistagmos
  ind = 1;
  for(i = 1 : length(maxVelRawInd))
    %En caso de inicio se toma como intervalo desde 1 hasta el segundo valor de velocidad pico
    if(i == 1)
      valueIni = 1;
      valueEnd = maxVelRawInd(i+1);
    %En caso de final se toma como intervalo desde el penultimo valor de velocidad pico hasta el final
    elseif(i == length(maxVelRawInd))
      valueIni = maxVelRawInd(i-1);
      valueEnd = length(positiveVelRaw);
    %En el caso por defecto se coge el intervalo desde el pico anterior hasta el siguiente
    else
      valueIni = maxVelRawInd(i-1);
      valueEnd = maxVelRawInd(i+1);
    end
    
    valTmp = [0 0];
    j = maxVelRawInd(i);
    while(j > valueIni)
      %Si la velocidad raw pasa por 0 se toma como valor de inicio del intervalo y se pasa a  obtener el valor final
      if(positiveVelRaw(j) < 20)
        valTmp(1) = j;
        break;
      end
      j -= 1;
    end
    
    j = maxVelRawInd(i);
    while(j < valueEnd)
      %Si la velocidad pasa por 0 se toma como valor final del intervalo
      if(positiveVelRaw(j) < 20)
        valTmp(2) = j;
        break;
      end
      j += 1;
    end
    
    %Si ambos valores se han obtenido satisfactoriamente se almacenan en un vector de intervalos para su uso mas adelante
    if(valTmp(1) != 0 && valTmp(2) != 0)
      meanVelWindow(ind,:) = valTmp;
      ind += 1;
    end
  end

  %Valor temporal del numerador para la regresion
  numerator = 0;
  %Valor temporal del denominador para la regresion
  denominator = 0;
  for(i = 1 : length(gaze))
    numerator += (data.time(i)-mean(data.time))*(gaze(i)-mean(gaze));
    denominator += (data.time(i)-mean(data.time))*(data.time(i)-mean(data.time));
  end

  %Valores de la regresion lineal de primer orden de toda la prueba para medir la "desviacion"
  gdSlope = numerator/denominator;
  gdOrigin = mean(gaze)-gdSlope*mean(data.time);

  %Calculo del coeficiente de regresion
    Total = 0;
    Residual = 0;
    for(j = 1 : length(gaze))
      %Calculo de la suma de los cuadrados
      Total += (gaze(j)-mean(gaze))*(gaze(j)-mean(gaze));
      %Calculo del cuadrado de los residuos
      Residual += (gaze(j)-gdSlope*data.time(j)-gdOrigin)*(gaze(j)-gdSlope*data.time(j)-gdOrigin);
    end
    %Almacenamiento del coeficiente de regresion para cada par
    rCoefTotal = 1-Residual/Total;
    
  %figure;
  %hold on;
  %if(test == "TOPTHL" || test == "TOPTHR")
  %  title("X Gaze");
  %  ylabel("X Gaze / deg");
  %elseif(test == "TOPTVD" || test == "TOPTVU")
  %  title("Y Gaze");
  %  ylabel("Y Gaze / deg");
  %end
  %xlabel("Time / ms");
  %%Plot de la mirada
  %plot(data.time,gazeRaw,'r');
  %plot(data.time,gaze,'b','LineWidth',1.5);
  %%Plot de la recta de "desviacion"
  %plot(data.time,gdSlope*data.time+gdOrigin,'color',[1 0.5 0],'LineWidth',1.5);
  %%Creacion del mapa de colores aleatorio para diferenciar los pares
  %cmap = rand(length(pursuit(:,1)),3);
  %for(i = 1 : length(pursuit(:,1)))
  %%  scatter(data.time(pursuit(i,:)),gaze(pursuit(i,:)),[],cmap(i,:),"filled");
  %%  regColor = (rCoef(i)-min(rCoef))/(max(rCoef)-min(rCoef));
  %%  plot(data.time(pursuit(i,1):pursuit(i,2)),pursuitSlope(i)*data.time(pursuit(i,1):pursuit(i,2))+pursuitOrigin(i),'color',[(1-regColor) regColor 0],'LineWidth',1.5);
  %  if(rCoef(i) >= 0.90)
  %    plot(data.time(pursuit(i,1):pursuit(i,2)),pursuitSlope(i)*data.time(pursuit(i,1):pursuit(i,2))+pursuitOrigin(i),'g','LineWidth',1.5);
  %  else
  %    plot(data.time(pursuit(i,1):pursuit(i,2)),pursuitSlope(i)*data.time(pursuit(i,1):pursuit(i,2))+pursuitOrigin(i),'r','LineWidth',1.5);
  %  end
  %end

  %Calculo de regresiones para cada correccion
  for(i = 1 : length(pursuit(:,1)))
    numerator = 0;
    denominator = 0;
    for(j = pursuit(i,1) : pursuit(i,2))
      numerator += (data.gaze(j,1)-mean(data.gaze(pursuit(i,1):pursuit(i,2),1)))*(data.gaze(j,2)-mean(data.gaze(pursuit(i,1):pursuit(i,2),2)));
      denominator += (data.gaze(j,1)-mean(data.gaze(pursuit(i,1):pursuit(i,2),1)))*(data.gaze(j,1)-mean(data.gaze(pursuit(i,1):pursuit(i,2),1)));
    end
    %Almacenamiento de las pendientes y los origenes para cada regresion
    gazeSlope(i) = numerator/denominator;
    gazeOrigin(i) = mean(data.gaze(pursuit(i,1):pursuit(i,2),2))-gazeSlope(i)*mean(data.gaze(pursuit(i,1):pursuit(i,2),1));
  end

  %Calculo de los angulos de la mirada en XY
  for(i = 1 : length(pursuit(:,1)))
    gazePursuitAngle(i) = atan2(data.gaze(pursuit(i,2),2)-data.gaze(pursuit(i,1),2),data.gaze(pursuit(i,2),1)-data.gaze(pursuit(i,1),1));
  end
  for(i = 1 : length(nystagmus(:,1)))
    gazeNystagmusAngle(i) = atan2(data.gaze(nystagmus(i,2),2)-data.gaze(nystagmus(i,1),2),data.gaze(nystagmus(i,2),1)-data.gaze(nystagmus(i,1),1));
  end


  %Funcion para obtener los valores reales de maximos y minimos en la mirada raw
  gazeRawMin(1)=meanVelWindow(1,1);
  for(i = 1 : length(pursuit(:,1)))
    tmpMax = gazeRaw(pursuit(i,1));
    tmpMin = gazeRaw(pursuit(i,2));
    gazeRawMax(i) = pursuit(i,1);
    gazeRawMin(i+1) = pursuit(i,2);
    if(pursuit(i,1)-5 > 0 && pursuit(i,1)+5 < length(gazeRaw))
      for(j = pursuit(i,1)-5 : pursuit(i,1)+5)
        if(gazeRaw(j) > tmpMax)
          gazeRawMax(i) = j;
          tmpMax = gazeRaw(j);      
        end
      end
    end
    if(pursuit(i,2)-5 > 0 && pursuit(i,2)+5 < length(gazeRaw))
      for(j = pursuit(i,2)-5 : pursuit(i,2)+5)
        if(gazeRaw(j) < tmpMin)
          gazeRawMin(i+1) = j;
          tmpMin = gazeRaw(j);      
        end
      end
    end
  end
  gazeRawMax(i+1)=meanVelWindow(end,2);


  %figure;
  %hold on;
  %plot(data.time,gazeRaw,'b','LineWidth',1.5);
  %scatter(data.time(gazeRawMax),gazeRaw(gazeRawMax),'r','filled');
  %scatter(data.time(gazeRawMin),gazeRaw(gazeRawMin),'g','filled');
  %scatter(data.time(pursuit),gazeRaw(pursuit),'b','filled');
  %legend("Gaze Raw","Maxs","Mins");
  %title("Gaze Raw Mins and Maxs");
  %xlabel("Time / ms");
  %ylabel("Gaze / deg");

  %Calculo de parametros relevantes
  ind = 1;
  for(i = 1 : length(pursuit(:,1)))
    if(rCoef(i) >= 0.90)
      %Amplitud del smooth pursuit
      if sign(gazeRaw(pursuit(i,2))*gazeRaw(pursuit(i,1)))<0
        amplitudeSP(ind) = abs(gazeRaw(pursuit(i,2))-gazeRaw(pursuit(i,1)));
      else
        amplitudeSP(ind) = abs(gazeRaw(pursuit(i,2)))+abs(gazeRaw(pursuit(i,1)));
      end
      
      %Velocidad media de los seguimientos de las barras
      meanSlowVel(ind) = mean(gazeVel(pursuit(i,1):pursuit(i,2)));
      
      ind += 1;
    end
  end

  maxVelRaw = gazeVelRaw(maxVelRawInd);
  for(i = 1 : length(meanVelWindow(:,1)))
    %Velocidad media de los nistagmos optocineticos
    meanFastVel(i) = mean(gazeVelRaw(meanVelWindow(i,1):meanVelWindow(i,2)));
    %Amplitud del nistagmo optocinetico
    if sign(gazeRaw(gazeRawMax(i))*gazeRaw(gazeRawMin(i)))<0
      amplitudeNY(i) = abs(gazeRaw(gazeRawMax(i))-gazeRaw(gazeRawMin(i)));
    else
      amplitudeNY(i) = abs(gazeRaw(gazeRawMax(i)))+abs(gazeRaw(gazeRawMin(i)));
    end
    %amplitudeNY(i) = gazeRaw(gazeRawMax(i)) - gazeRaw(gazeRawMin(i));
  end

  %figure;
  %hold on;
  %title("XY Gaze");
  %xlabel("X Gaze /deg");
  %ylabel("Y Gaze / deg");
  %%Plot de la mirada en XY
  %scatter(data.gaze(:,1),data.gaze(:,2));
  %for(i = 1 : length(pursuit(:,1)))
  %  %Scatter con los puntos inicio y fin de cada nistagmo
  %  scatter(data.gaze(pursuit(i,:),1),data.gaze(pursuit(i,:),2),[],cmap(i,:),"filled");
  %  %Plot de las lineas de regresion de cada nistagmo
  %  plot(data.gaze(pursuit(i,1):pursuit(i,2),1),gazeSlope(i)*data.gaze(pursuit(i,1):pursuit(i,2),1)+gazeOrigin(i),'r','LineWidth',1.5);
  %  %Plot de las lineas que unen el inicio y el final de cada nistagmo
  %  plot(data.gaze(pursuit(i,:),1),data.gaze(pursuit(i,:),2),'g','LineWidth',1.5);
  %end

  %figure;
  %hold on;
  %subplot(1,2,1);
  %%Histograma de las velocidades medias de los seguimiento
  %hist(meanSlowVel);
  %title("Pursuit Speeds");
  %xlabel("Speed / deg*s^-1");
  %subplot(1,2,2);
  %%Histograma de las velocidades medias de los nistagmos
  %hist(meanFastVel);
  %title("Nystagmus Speeds");
  %xlabel("Speed / deg*s^-1");

  %Sistema para imprimir en polares la direccion de los angulos de la mirada durante los seguimientos
  ind = 1;
  tmpMin = -180;
  for(i = -179 : 180)
    numAngles = 0;
    tmpMax = i;
    for(j = 1 : length(gazePursuitAngle))
      if(gazePursuitAngle(j) >= tmpMin*pi/180 && gazePursuitAngle(j) <= tmpMax*pi/180)
        numAngles += 1;
      end
    end
    if(numAngles > 0)
      pursuitAngle(ind,:) = [(tmpMax+tmpMin)*pi/360 numAngles];
      ind += 1;
    end
    tmpMin = i;
  end

  %En caso de realizar el cambio de -180 a 180 grados se coloca el vector para imprimirlo correctamente
  for(i = 2 : length(pursuitAngle))
    if((pursuitAngle(i) > pi/2 || pursuitAngle(i) < -pi/2) && (pursuitAngle(i-1) > pi/2 || pursuitAngle(i-1) < -pi/2) && pursuitAngle(i)*pursuitAngle(i-1) < 0)
      pursuitAngle(1:i-1,:) = flipud(pursuitAngle(1:i-1,:));
      pursuitAngle(i:end,:) = flipud(pursuitAngle(i:end,:));
      pursuitAngle = flipud(pursuitAngle);
      break;
    end
  end

  %Sistema para imprimir en polares la direccion de los angulos de la mirada durante los nistagmos
  ind = 1;
  tmpMin = -180;
  tmpMax = -170;
  for(i = -170 : 1 : 180)
    numAngles = 0;
    tmpMax = i;
    for(j = 1 : length(gazeNystagmusAngle))
      if(gazeNystagmusAngle(j) >= tmpMin*pi/180 && gazeNystagmusAngle(j) <= tmpMax*pi/180)
        numAngles += 1;
      end
    end
    if(numAngles > 0)
      nystagmusAngle(ind,:) = [(tmpMax+tmpMin)*pi/360 numAngles];
      ind += 1;
    end
    tmpMin = i;
  end

  %En caso de realizar el cambio de -180 a 180 grados se coloca el vector para imprimirlo correctamente
  for(i = 2 : length(nystagmusAngle))
    if((nystagmusAngle(i) > pi/2 || nystagmusAngle(i) < -pi/2) && (nystagmusAngle(i-1) > pi/2 || nystagmusAngle(i-1) < -pi/2) && nystagmusAngle(i)*nystagmusAngle(i-1) < 0)
      nystagmusAngle(1:i-1,:) = flipud(nystagmusAngle(1:i-1,:));
      nystagmusAngle(i:end,:) = flipud(nystagmusAngle(i:end,:));
      nystagmusAngle = flipud(nystagmusAngle);
      break;
    end
  end

  %figure;
  %title("Angle Density");
  %%Plot en polares de las direcciones de la mirada en los seguimientos
  %polar(pursuitAngle(:,1),pursuitAngle(:,2),'b');
  %hold on;
  %%Plot en polares de las direcciones de la mirada en los nistagmos
  %polar(nystagmusAngle(:,1),nystagmusAngle(:,2),'r');
  %legend("Pursuit Angles","Nystagmus Angles");
  %
  %figure;
  %hold on;
  %title("Raw Gaze Speed");
  %xlabel("Time / ms");
  %ylabel("Speed / deg*s^-1");
  %%Plot de la velocidad raw positiva
  %plot(data.time,positiveVelRaw,'b','LineWidth',1.5);
  %cmap = rand(length(nystagmus(:,1)),3);
  %%Dos scatter: uno con las velocidades raw pico y otro con los intervalos de velocidades en los nistagmos
  %for(i = 1 : length(meanVelWindow(:,1)))
  %  scatter(data.time(meanVelWindow(i,:)),positiveVelRaw(meanVelWindow(i,:)),[],cmap(i,:),'filled');
  %  scatter(data.time(maxVelRawInd),positiveVelRaw(maxVelRawInd),'r','filled');
  %end
endif %if velPks!=-1 ############SI NO SE DETECTA NINGUN PICO NO HAY RESULTADOS TODO NaN
%% Result

%Coeficiente de regresion de cada seguimiento lento

rCoefMean=mean(rCoef);
if length(rCoef)!=1
  rCoefSD=std(rCoef);
else
  rCoefSD=NaN;
endif


result = [result rCoefMean]; %2
result = [result rCoefSD]; %3

%Coeficiente de regresión total de la prueba
result = [result rCoefTotal]; %4

%Ángulos de cada nystagmos
NystagAngleMean=mean(gazeNystagmusAngle);
if length(gazeNystagmusAngle)!=1
  NystagAngleSD=std(gazeNystagmusAngle);
else
  NystagAngleSD=NaN;
endif

result = [result NystagAngleMean]; %5
result = [result NystagAngleSD]; %6

%Angulo de cada seguimiento lento
SPAngleMean=mean(gazePursuitAngle);
if length(gazePursuitAngle)!=1
  SPAngleSD=std(gazePursuitAngle);
else
  SPAngleSD=NaN;
endif

result = [result SPAngleMean]; %7
result = [result SPAngleSD]; %8

%Amplitud de los nystagmos
NystagAmplitudeMean=mean(amplitudeNY);
if length(amplitudeNY)!=1
  NystagAmplitudeSD=std(amplitudeNY);
else
  NystagAmplitudeSD=NaN;
endif

result = [result NystagAmplitudeMean]; %9
result = [result NystagAmplitudeSD]; %10

%Amplitud de los seguimientos lentos
SPAmplitudeMean=mean(amplitudeSP);
if length(amplitudeSP)!=1
  SPAmplitudeSD=std(amplitudeSP);
else
  SPAmplitudeSD=NaN;
endif

result = [result SPAmplitudeMean]; %11
result = [result SPAmplitudeSD]; %12

%Velocidad media de cada smooth pursuit
meanSPVelMean=mean(meanSlowVel);
if length(meanSlowVel)!=1
  meanSPVelSD=std(meanSlowVel);
else
  meanSPVelSD=NaN;
endif

result = [result meanSPVelMean]; %13
result = [result meanSPVelSD]; %14

%Velocidad media de cada nystagmos
meanFastVelMean=mean(meanFastVel);
if length(meanFastVel)!=1
  meanFastVelSD=std(meanFastVel);
else
  meanFastVelSD=NaN;
endif

result = [result meanFastVelMean]; %15
result = [result meanFastVelSD]; %16

%Picos maximos en la mirada
if gazeRawMax == -99
  gazeRawMaxMean = NaN;
else
  gazeRawMaxMean=mean(gazeRaw(gazeRawMax));
endif
if length(gazeRawMax)!=1
  gazeRawMaxSD = std(gazeRaw(gazeRawMax));
else
  gazeRawMaxSD = NaN;
endif

result = [result gazeRawMaxMean]; %17
result = [result gazeRawMaxSD]; %18

%Picos minimos en la mirada
if gazeRawMin == -99
  gazeRawMinMean = NaN;
else
  gazeRawMinMean=mean(gazeRaw(gazeRawMin));
endif
if length(gazeRawMin)!=1
  gazeRawMinSD=std(gazeRaw(gazeRawMin));
else
  gazeRawMinSD=NaN;
endif

result = [result gazeRawMinMean]; %19
result = [result gazeRawMinSD]; %20

endfunction