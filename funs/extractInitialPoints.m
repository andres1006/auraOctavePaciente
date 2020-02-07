function [indexInitialPoints] = extractInitialPoints(time,gaze,stimulus,indexStimChange,indexFixations,fixType,isAntisaccade, sigPeaks)
  ## Resumen
  % Esta funcion extrae los puntos iniciales a partir de fijaciones usando un sistema de puntuacion
  % Se valoran distintos parametros, quedando como comienzo del movimiento el que tenga mas puntos
  % Los puntos iniciales de sacadas se corresponden a puntos finales de fijacion.
  % Se puede utilizar para pruebas de sacadas y de antisacadas
  % Se valora:
  %   - Si comienza cerca del estimulo inicial
  %   - Si acaba cerca del estimulo final (o antiestimulo para antisacadas)
  %   - La amplitud de la sacada realizada
  %   - La cercania al tiempo esperable de 100 ms despues del cambio del estimulo
  %   - La duracion de la fijacion
  
  ## Outputs
  % indexInitialPoints : vector con indices que indican el punto de comienzo. Mismo numero de elementos que indexStimChange
  
  ## Inputs
  % time : vector con las marcas de tiempo
  % gaze : vector con los datos de mirada en el eje a analizar
  % stimulus : vector con los datos del estimulo en el eje a analizar
  % indexStimChange : vector con los indices donde se produce un cambio de estimulo
  % indexFixations : vector (bidimensional) con los puntos de comienzo y final de fijacion
  % fixType : vector que indica que fijaciones son SWJ (Se podria evitar este si en indexFixations no se introducen o se filtran)
  % isAntisaccade : se debe introducir un 1 si se cumple eso. Mejora el resultado en ese tipo de pruebas
  
  ## Defines ############################
  % Posicion de la fijacion respecto al estimulo inicial (Recta pendiente negativa)
  amplToStim_MaxPoints=5; %Maximo de puntos cuando la amplitud al estimulo es 0
  amplToStim_CutPoints=6; %Amplitud donde la recta de puntos corta el eje. A partir de aqui el resto tendra 0 puntos
  
  % Amplitud (Recta pendiente positiva)
  amplNextSaccade_MaxPoints=4;  %Maximo de puntos
  
  % Posicion de la fijacion siguiente respecto al estimulo final (Recta pendiente negativa)
  amplToStimPost_MaxPoints=1.5; %Maximo de puntos cuando la amplitud al estimulo es 0
  amplToStimPost_CutPoints=6; %Amplitud donde la recta de puntos corta el eje. A partir de aqui el resto tendra 0 puntos
  
  % Tiempo del inicio frente a tiempo esperado (100ms tras cambio de estimulo) (Rectas pendiente negativa)
  timeToStimChange_MaxPoints=1; %Maximo de puntos
  timeToStimChange_CutPoints=500; %Amplitud donde la recta de puntos corta el eje. A partir de aqui el resto tendra 0 puntos
 
  % Duracion de la fijacion (Recta pendiente positiva) 
  fixDuration_MaxPoints=0.5; %Maximo de puntos
  fixDuration_CutPoints=150; %A partir de que valor se da el maximo 

  % Si una sacada alcanza este puntaje, se deja de buscar. (Max points = 12)
  enoughPoints=999;

  ## %%%%%%% ############################
  
  
  ## Inicializacion de variables
  indexInitialPoints=-1;
  rangoInicio=0;
  if indexFixations!=-1 && length(fixType)>1
    % Por cada cambio del estimulo
    for i=1:length(indexStimChange)-1
      %% Extraer una region de la prueba
      % Se analiza entre el cambio del estimulo anterior hasta el siguiente
      if(i==1)
        rangoInicio=1;
      elseif (indexInitialPoints(i-1)!=1) %Si se ha sacado punto inicial en el anterior punto que la region empiece a partir de ese punto mas 5 frames para evitar superposiciones de puntos.
        rangoInicio=indexInitialPoints(i-1)+5;
      else
        rangoInicio=indexStimChange(i-1)+5; %Si no ha sacado punto inicial la region empieza en el cambio de estimulo anterior, por si suceden adelantamientos.
      endif
      rangoFin=indexStimChange(i+1)-50; %Hasta el siguiente cambio de estimulo

      stimulusInicio=stimulus(indexStimChange(i)-1);
      stimulusFin=stimulus(indexStimChange(i)+1);
      
      %%% Busqueda por puntuacion
      
      best_Points=-99999; % Variables para buscar un maximo
      bestIndex_Points=0;
      counter=0; %Para contar cuantas fijaciones valoramos en una sacada.
      amplwin=0;
   
      % Para cada fijacion en el vector
      for j=1:length(indexFixations(:,1))
        if(time(indexFixations(j,2))>=time(rangoFin) || best_Points>enoughPoints)
          break;       
        endif
        % Solo puntuar las que cuyo final de fijacion este dentro del rango y no sean SWJ   
        if(time(indexFixations(j,2))>time(rangoInicio) && fixType(j)<2)
          counter++;
          %El punto de inicio es el final de fijacion 
          
          if isAntisaccade~=0 && sigPeaks!=-1
            amplitudeToStimulusInicio=abs(sigPeaks(i)-gaze(indexFixations(j,2)));
            amplToStim_MaxPoints_mod=amplToStim_MaxPoints/2;
          else
            amplitudeToStimulusInicio=abs(stimulusInicio-gaze(indexFixations(j,2)));
            amplToStim_MaxPoints_mod=amplToStim_MaxPoints;
          endif
          
          ## Valorar cercania del punto inicial al estimulo inicial
          % La amplitud al estimulo es la diferencia entre el final de fijacion y el estimulo antes de cambiar
    
          

          
          %Se da mas puntos cuanto mas cerca este (Amplitud relativa == 0)
          %Se usa una recta de pendiente negativa.
          amplToStim_Points=amplitudeToStimulusInicio*(-amplToStim_MaxPoints_mod/amplToStim_CutPoints)+amplToStim_MaxPoints_mod;
          if(amplToStim_Points<0)
            amplToStim_Points=0;
          endif
          
          ## Buscar la siguiente fijacion (Esto se simplifica si se filtran los SWJ antes)
          k=j+1; %Buscar por indice la siguiente
          if(k<=length(indexFixations))
            while(fixType(k)>=2) %Que no sea SWj
              k=k+1;
              if(k>length(indexFixations))
                k=j;
                break;
              endif
            endwhile  
          else
            k=j;
          endif

          ## Valorar la amplitud de la sacada
          % Se da mas puntuacion a sacadas mas grandes  
          amplitudSacadaSiguiente=abs(gaze(indexFixations(k,1))-gaze(indexFixations(j,2)));
%          if amplitudSacadaSiguiente<1
%            %Es necesario que la amplitud de la sacada sea mayor que 1 grado de amplitud
%            continue;
%          endif
          
          % Pendiente positiva, mas amplitud mas puntos. Se limita a un maximo
          amplNextSaccade_Points=amplitudSacadaSiguiente;
          if(amplNextSaccade_Points>amplNextSaccade_MaxPoints)
            amplNextSaccade_Points=amplNextSaccade_MaxPoints;
          endif
          ## Valorar que el punto que se alcanza esta cerca del estimulo final
          % Amplitud relativa del comienzo de la siguiente fijacion respecto del estimulo siguiente  
          if(isAntisaccade==0) 
            amplitudeToStimulusFinal=abs(stimulusFin-gaze(indexFixations(k,1)));
          else
            % Si son antisacadas hay que valorar igualmente que pueda estar mirando al punto opuesto
            % Se puntua usando la amplitud relativa minima
            amplitudeToStimulusFinal=min(abs(stimulusFin-gaze(indexFixations(k,1))),abs(-stimulusFin-gaze(indexFixations(k,1))));
          endif
          
          %Se da mas puntos cuanto mas cerca este (Amplitud relativa == 0)
          %Se usa una recta de pendiente negativa.
          amplToStimPost_Points=amplitudeToStimulusFinal*(-amplToStimPost_MaxPoints/amplToStimPost_CutPoints)+amplToStimPost_MaxPoints;
          if(amplToStimPost_Points<0)
            amplToStimPost_Points=0;
          endif
          
          ## Valorar la duracion de la fijacion
          % Se dan unos pocos mas puntos a las sacadas que vienen de fijaciones mayores a 150ms
          fixDuration=time(indexFixations(j,2))-time(indexFixations(j,1));
          fixDuration_Points=fixDuration*(fixDuration_MaxPoints/fixDuration_CutPoints);
          if(fixDuration_Points>fixDuration_MaxPoints)
            fixDuration_Points=fixDuration_MaxPoints;
          endif
          
          ## Valorar que el punto inicial se produzca cuando se espera
          % Los inicios se esperan que se den un poco despues del cambio del estimulo
          % Al usar abs se valora igual que el punto este por detras o por delante de este punto
          timeToStimChange=abs(time(indexStimChange(i))+100-time(indexFixations(j,2)));
          
          %Se da mas puntos cuanto mas cerca este (tiempo relativa == 0)
          %Se usa una recta de pendiente negativa  
          timeToStimChange_Points=timeToStimChange*(-timeToStimChange_MaxPoints/timeToStimChange_CutPoints)+timeToStimChange_MaxPoints;
          if(timeToStimChange_Points<0)
            timeToStimChange_Points=0;
          endif
          
          ### SUMA DE PUNTOS
          this_Points=amplToStim_Points+amplNextSaccade_Points+amplToStimPost_Points+timeToStimChange_Points+fixDuration_Points;
          
  %         if(i==3 || i== 8 || i==18)
  %           j
  %           this_Points
  %           amplToStim_Points
  %           amplNextSaccade_Points
  %           amplToStimPost_Points
  %           timeToStimChange_Points
  %           fixDuration_Points
  %    
  %         end
          
          ## Si obtenemos mas puntos que lo mejor, quedarnos con esta sacada
          if(this_Points>best_Points)
            best_Points=this_Points;
            bestIndex_Points=j;
            amplwin = amplitudSacadaSiguiente;
          endif
        endif
        
        
        %Si el final de la fijacion en la siguiente iteracion se sale del rango, parar de buscar
        %Tambien se para si se ha alcanzado una puntuacion destacable (Asi se da mas peso a sacadas al comienzo del rango)
        
       endfor
      % Guardar como punto inicial el correspondiente al final de fijacion con mas puntos
       if(bestIndex_Points!=0 && best_Points>5)
        if amplwin<1 && counter==1
          indexInitialPoints(i)=1; 
        else
          indexInitialPoints(i)=indexFixations(bestIndex_Points,2);  
        endif   
       else
         indexInitialPoints(i)=1;
       end
      
      
  %      if i>1 && indexInitialPoints(i-1)==indexInitialPoints(i)
  %        indexInitialPoints(i)=-1;
  %        disp("Punto de inicio no encontrado")
  %      endif
      endfor
  endif % indexFixations!=-1
endfunction