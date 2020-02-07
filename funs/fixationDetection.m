function [indexFixationsFinal, fixTypeFinal, fixDurationFinal]=fixationDetection(time, gaze, blinks, velocidad)

######## INPUTS ######
% time: vector de marcas de tiempo en ms
% gaze: vector de puntos de mirada en grados
% blinks: vector que indica si hay o no parpadeo

######## OUTPUTS #####
% indexFixationsFinal: vector con los puntos de inicio y final de las fijaciones detectadas
% fixTypeFinal: vector que indica de que tipo es cada fijacion detectada
%  - 0 equivale a una fijacion larga (duracion >300ms)
%  - 1 equivale a una fijacion corta (duracion <300ms)
%  - 2 equivale a un SWJ (square wave jerk), donde la mirada sale de una fijacion y vuelve a la misma.

######################
## Calcular umbral de "velocidad"
######################
%Calculamos un umbral con el desplazamiento (Sin dividir por la velocidad)
%Se calcula la diff limitando el desplazamiento maximo, para que las sacadas no afecten mucho a la media (Su diff sera muy grande)
indexFixationsFinal=-1;
fixTypeFinal=-1;
fixDurationFinal=-1;

maxVel=0.4;
gazeVelAbs=abs(diff(gaze));#abs(gazeVel);

meanV1=mean(gazeVelAbs(gazeVelAbs<maxVel));
stdV1=std(gazeVelAbs(gazeVelAbs<maxVel));
%thresV1=meanV1+6*stdV1
thresV1=meanV1+3*stdV1;

%Indicar un nivel de umbral minimo, da mejores resultados
minThres=0.20;
if(thresV1<minThres)
  thresV1=minThres;
end
thresV2=thresV1*0.75;

######################
## Separar regiones por umbral de diff extendida
######################

## Calcular Diff A3
% En lugar de separar por un umbral usando el incremento de posicion en un frame
% Se calcula la diff a 3 frames, para capturar mejor las diferencias de posicion
% Se usa el valor absoluto

diffA3=0;
n2=2; %%% OJO, probando con solo a 2 frames
for i=n2+1:length(gaze)
  diffA3(i-1)=abs(gaze(i)-gaze(i-n2));
end

%diffA3=abs([diffA3']);
%figure;
%plot(diffA3);

## Separar correciones
% Se separa cada region de fijacion guardando donde empieza y acaba cada region
% Se emplea una maquina de estados

indexFixations=[0,0];
nFix=1;
saving=0; %Para la maquina de estados

for i=1:length(diffA3)-1 
  if(saving==0)
    % Caso de no estamos guardando = buscar comienzo de fijacion
    if(diffA3(i)<=thresV1 && blinks(i)==0) %thres v1 o v2?
      % Guardar como comienzo el primer punto que entra por el umbral y no es parpadeo
      saving=1;
      indexFixations(nFix,1)=i;
    end
  end
  if(saving==1)
    % Caso de estamos guardando = buscar final de fijacion
    if(diffA3(i+1)>thresV2 || i+1==length(gaze)-1 || blinks(i+1)!=0)
      %Dejar de guardar cuando el siguiente esta fuera del umbral
      %O se llega al final
      %O se alcanza un parpadeo
      saving=0;    
      indexFixations(nFix,2)=i;
      if(indexFixations(nFix,2)-indexFixations(nFix,1)>2)
      %Solo guardar la fijacion si ha durado > que el min (Al no incrementar se sobreescribira)
        nFix=nFix+1;
      end 
    end
  end
endfor
% Corregir numero de fijaciones, ya que con el metodo anterior nos indica 1 de mas
nFix=nFix-1;



if nFix!=0 % no hay fijaciones en toda la prueba
  ######################
  ## Filtrado y union de regiones
  ######################
  % Se analizan las regiones para ver si de verdad son fijaciones
  % O si se deben unir entre si por ser la misma fijacion 

  % Se aplican varias condiciones en una pasadas por el vector de fijaciones

  #Guardar dfMedians y finales corregidos 
  #Usar los df medians para ir extrapolando las fijaciones y ver la amplitud entre muestras
  #Si al extrapolar alguna es menor que un umbral se unen ambas

  indexFixationsF=indexFixations(1,:); %F de filtrado
  nFixF=1;
  fixationDfMedian=0;

  for i=1:nFix
    ## Calcular la mediana de los incrementos de posicion en la fijacion 
    # sirve tanto como indicador del nivel de ruido
    # como para saber la tendencia (pendiente aprox) de la fijacion
    diffGazeFix=diff(gaze(indexFixations(i,1):indexFixations(i,2)));
    fixationDfMedian(i)=median(diffGazeFix);
    dfMeanAbs=mean(abs(diffGazeFix));

    ## Usar la diff y la media para corregir el final
    # se suelen colar algunas muestras con incrementos elevados ya que usamos la diffA3 para separar, no la diff
    for j=0:length(diffGazeFix)-1
    jInv=length(diffGazeFix)-j;
      if(abs(diffGazeFix(jInv))<dfMeanAbs*3)
        break;
      end
      indexFixations(i,2)=indexFixations(i,2)-1;
    endfor

    ## A partir de la segunda se puede empezar a filtrar
    if(i>1) 
      distanciaEntreFix=indexFixations(i,1)-indexFixations(i-1,2); %Distancia de comienzo de fijacion a la ultima introducida
      hayParpadeo=0;
      amplitudMinima=9999;
      
      # Se comprueban las muestras que hay entre 2 fijaciones
      for j=0:distanciaEntreFix
        # Se buscan parpadeos
        if (blinks(j+indexFixations(i-1,2))~=0)
          hayParpadeo=1;
          break; %Si hay se sale
        endif
      
      # Y se analiza la distancia con la tendencia
      % Es decir, se usa la diff mediana para extrapolar la fijacion en estas muestras
      % Si convergen ambas extrapolaciones y alcanzan un valor X suficientemente pequeño
      % Se pueden considerar que son parte de la misma fijacion
        amplitudIzq=gaze(indexFixations(i-1,2))+fixationDfMedian(i-1)*j;
        amplitudDer=gaze(indexFixations(i,1))-fixationDfMedian(i)*(distanciaEntreFix-j);

        
        if(abs(amplitudDer-amplitudIzq)<amplitudMinima)
          amplitudMinima=abs(amplitudDer-amplitudIzq);
        else
          break;
        end
    
      endfor

      % Combinacion, si procede, de las fijaciones
      if(hayParpadeo>0)
        % En el caso de parpadeo, se unen si las medias estan cerca
        if(abs(mean(gaze(indexFixations(i,1):indexFixations(i,2)))-mean(gaze(indexFixations(i-1,1):indexFixations(i-1,2))))>thresV1)
          nFixF=nFixF+1;
          indexFixationsF(nFixF,:)=indexFixations(i,:);
        else
          indexFixationsF(nFixF,2)=indexFixations(i,2); 
          endif
      else
       % Si no hay parpadeo
        if(amplitudMinima<thresV1)
          %Si la separacion minima de las extrapolaciones es menor que el umbral alto
          if(amplitudMinima<thresV2)
            %Si incluso es menor que el umbral bajo, se unen
            indexFixationsF(nFixF,2)=indexFixations(i,2);
          else
            %Si no, se intentan unir con las medias (Pero con el umbral V2)
            mediaAnterior=mean(gaze(indexFixations(i-1,1):indexFixations(i-1,2)));
            mediaActual=mean(gaze(indexFixations(i,1):indexFixations(i,2)));
            if(abs(mediaAnterior-mediaActual)>thresV2)
              nFixF=nFixF+1;
              indexFixationsF(nFixF,:)=indexFixations(i,:);
            else
              indexFixationsF(nFixF,2)=indexFixations(i,2);
            end
          end
         else
           %Si la separacion es mucha, directamente se consideran fijaciones distintas
            nFixF=nFixF+1;
            indexFixationsF(nFixF,:)=indexFixations(i,:);
         end  
       endif
    end

  endfor

  ######################
  ## Clasificar fijaciones
  ######################

  fixType=0;
  fixDuration=0;
  for i=1:nFixF
    fixType(i)=1;
    
    fixDuration(i)=time(indexFixationsF(i,2))-time(indexFixationsF(i,1));
     
    
    if(fixDuration(i)>300)
      fixType(i)=0;
      else
        if(i!=1 && i!=nFixF)
        %SWJ: square wave jerks. Hasta 5º (patologicos) y 200ms aprox
        %http://journals.plos.org/plosone/article?id=10.1371/journal.pone.0058535
           amplitudIzq=gaze(indexFixationsF(i,1))-gaze(indexFixationsF(i-1,2)); 
           amplitudDer=gaze(indexFixationsF(i+1,1))-gaze(indexFixationsF(i,2)); 
           if(abs(amplitudDer)<3 && abs(amplitudIzq)<3) 
            if(abs(amplitudDer+amplitudIzq)<0.75) %SANTI: He puesto un 2 aqui thresV1*2ginput
            %Si la suma es inferior a X significa que ambas sacadas son complementarias, una amplitud + y otra con amplitud -
            %La condicion de menor a 0.75 es para indicar que han de volver practicamente al mismo punto
            
            %relacionAmplitudes=amplitudDer/amplitudIzq;
  %          if(relacionAmplitudes>-1-0.33 && relacionAmplitudes<-1+0.33)

              amplMaxAbs=max(abs(amplitudDer),abs(amplitudIzq));
              amplMinAbs=min(abs(amplitudDer),abs(amplitudIzq));
              if(amplMaxAbs/amplMinAbs < 2.5)
              %Otra condicion es que las sacadas sean practicamente iguales en amplitud
              %Si una es mas que el doble se descarta como SWJ. (Se deja el margen por si el ojo se esta moviendo y un lado queda mas corto)
                fixType(i)=2;
              end
             end 
           end
        end
      end
      
  endfor

  ######################
  ## Gestion SWJ
  ######################
  % Unir las fijaciones entre SWJ detectados segun corresponda

  %for i=2:nFixF %Se empieza en la segunda (La 1 nunca podra ser SWJ)
  i=2;
  while i<nFixF

      if(fixType(i)==2) %Si es SWJ
        %Obtener el numero de SWJ adyacentes, por si se detectan mas de 1 seguido
        nSWJ=1;
        for j=i+1:nFixF %Se comprueba si hay mas SWJ 
          if(fixType(j)!=2) %Hasta alcanzar una fijacion que no sea square jerk
            break
          endif
          if(mod(j,1)==0)
            nSWJ=nSWJ+1; %Se va actualizando el contador
          endif
        endfor
              
        
        %Hay dos casos en funcion del numero de SWJ seguidos 
        % Impar: El sencillo, --_--_--, al final las fijaciones entre todos los SWJ acaban en la misma amplitud. Se unen desde la primera fijacion, uno si uno no
        % Par: Hay que decidir, --_--__, se distinguen dos fijaciones. Se escoge para unir, uno si uno no, la fijacion del extremo de mayor duracion
        indexBump=0; %Var que indica si se empieza en una fix mas adelante     
        if(mod(nSWJ,2)==0) %Si hay un numero par de SWJ
          if(fixDuration(i-1)<fixDuration(i+nSWJ))
            indexBump=1; %Se empieza por la segunda si la fijacion mas corta es la primera
          end 
         else
          nSWJ=nSWJ+1; %Se modifica el numero total de fijaciones para que sea par
         end
         
        nSWJ=nSWJ/2; %El numero de sacadas a eliminar es la mitad de las sacadas pares
        %Ejmplo:
        % 1 SWJ: --_-- , se elimina 1 
        % 2 SWJ: --_--_ , se elimina 1 tambien (dependera de donde se empiece, pero solo se elimina 1)
        % 3 SWJ: --_--_-- , se eliminan 2
        % 5 SWJ: --_--_--_--, se eliminan 3
        
        % Aplicar el ajuste de SWJ
        % Extender la fijacion inicial hasta el final de la siguiente despues de el ultimo SWJ
        % Nota: los SWJ quedaran dentro de esta fijacion
        indexFixationsF(i-1+indexBump,2)=indexFixationsF(i-1+2*nSWJ+indexBump,2);
        % Se calcula la nueva duracion y se modifica el tipo de fijacion
        fixDuration(i-1+indexBump)=time(indexFixationsF(i-1+indexBump,2))-time(indexFixationsF(i-1+indexBump,1));
        if(fixDuration(i-1+indexBump)>300)
          fixType(i-1+indexBump)=0;
        else
          fixType(i-1+indexBump)=1;
        end
        
        %Se marcan como invalidas (para eliminarlas) las fijaciones que quedan entre SWJ.
        % Efectivamente esto elimina las fijaciones impares, empezando por la segunda impar.
        % Asi solo nos quedamos con los SWJ de la fijacion unida
        for j=1:nSWJ;
          fixType(i-1+2*j+indexBump)=-1;
        end
        
        i=i+2*nSWJ+indexBump; %Saltarse las que ya se han tocado
      else
      
        i=i+1;
      end

  endwhile


  %%Eliminar las sacadas marcadas como -1
  indexFixationsFinal=[0,0];
  nFixFinal=0;
  fixTypeFinal=0;
  fixDurationFinal=0;

  for i=1:nFixF
    if(fixType(i)!=-1)
      nFixFinal=nFixFinal+1;
      indexFixationsFinal(nFixFinal,:)=indexFixationsF(i,:); 
      fixTypeFinal(nFixFinal)=fixType(i);
      fixDurationFinal(nFixFinal)=fixDuration(i);
    end
  end

for j=1:length(indexFixationsFinal(:,1))
    fin=0;
    ini=0;
    if j==1
      finalprin=1;
    else
      finalprin=indexFixationsFinal(j-1,2);
    end
    if j==length(indexFixationsFinal(:,1))
      finalfin=length(velocidad);
    else
      finalfin=indexFixationsFinal(j+1,1);
    end
    for k=1:200
      if fin==0 
        if indexFixationsFinal(j,2)+k-1>=finalfin
          fin=finalfin;
        elseif abs(velocidad(indexFixationsFinal(j,2)+k-1))>10
          fin=indexFixationsFinal(j,2)+k-2;
          indexFixationsFinal(j,2)=fin;
        endif
      endif
      if ini==0
        if indexFixationsFinal(j,1)-k<=finalprin
          ini=finalprin;
        elseif abs(velocidad(indexFixationsFinal(j,1)-k))>10
          ini=indexFixationsFinal(j,1)-k-1;
          indexFixationsFinal(j,1)=ini;
        endif
      endif
      if fin~=0 && ini~=0
        break;
      endif 
    endfor  
  endfor

  %for i=1:length(indexFixationsFinal)
  %  printf("%d,%d,%d , %d\n",i-1,fixTypeFinal(i),indexFixationsFinal(i,1)-1,indexFixationsFinal(i,2)-1);
  %end
endif %  if nFix!=0
endfunction
