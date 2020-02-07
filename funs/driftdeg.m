
% Function for detecting drift from a time series of eye movements.
%
% Inputs:
%    gaze   - Time series of eye movements
%    time - The sampling rate of the time series of eye movements.
%    gazeVel - Velocity of the eye movement.
%    type - Type of the frame, saccade, microsaccade or fixation.
%    pupilArea - The area of the Pupil during the test

%
% Outputs:
%    microsaccades - Column one: Time of onset of drift
%                    Column two: Time at which the drift terminate
%                    Column three: Peak velocity of drift
%                    Column four: amplitude of drift
%                    Column five: return type, if it's a drift or not.
%                    Column six: the mean velocity of the drift.

function [onset_drift , finish_drift , vpeak , ampl , tipo, v_mean] = driftdeg(gaze, time, gazeVel, type,pupilArea, onset, finish, amplitud)


N = length(onset);
v = zeros(N,2);
for i=1:length(time)
  vel(i) = sqrt(gazeVel(:,1)(i)^2 + gazeVel(:,2)(i)^2);
end



gazex=gaze(:,1);
gazey=gaze(:,2);

ptoinix=gazex(1);
ptoiniy=gazey(1);

%Donde comienza a dibujarse la primera caja, ptos iniciales
if (rem(ptoinix,0.01)!=0)
  ptoinix=floor(ptoinix*100)/100;
endif

if(rem(ptoiniy,0.01)!=0)
  ptoiniy=floor(ptoiniy*100)/100;
endif

%Crear la primera caja en 'x' y en 'y'

indice=1;

vectorcajasx(indice)=ptoinix;
vectorcajasx(indice+1)=ptoinix+0.01;
vectorcajasx(indice+2)=ptoinix+0.01;
vectorcajasx(indice+3)=ptoinix;
vectorcajasx(indice+4)=ptoinix;

vectorcajasy(indice)=ptoiniy;
vectorcajasy(indice+1)=ptoiniy;
vectorcajasy(indice+2)=ptoiniy+0.01;
vectorcajasy(indice+3)=ptoiniy+0.01;
vectorcajasy(indice+4)=ptoiniy;

numptos(indice)=1;

%indice=indice+4;
indice=indice+5;
haycaja=zeros(length(gazex));
haycaja(1)=1;
diffx(1)=gazex(1)-ptoinix;
diffy(1)=gazey(1)-ptoiniy;
sigptox=vectorcajasx(indice-3);%-2
sigptoy=vectorcajasy(indice-2);%-1

%Calculo de la localizacion de las cajas
for i=2:length(gazex)
 
  diffx(i)=gazex(i)-ptoinix;
  diffy(i)=gazey(i)-ptoiniy; 
  
    if(abs(ptoinix)<0.00001)
      ptoinix=0; %%Cuando el punto se acercaba a cero, al ser float la resta nunca era cero, por lo que se lo asignamos aqui el 0
    endif
  %Comprobacion de si se encuentra en x
  
   if(diffx(i)>0.01) %Si la diferencia es positiva, el siguiente punto estara en el primer o cuarto cuadrante, suponiendo el pto anterior el origen
    ptoinix=vectorcajasx(indice-3);%-2
    sigptox=ptoinix+0.01;
    while(gazex(i)>sigptox) %Mientras la caja aun no contenga al punto
      ptoinix=sigptox;
      sigptox=sigptox+0.01;
    endwhile;
  elseif(diffx(i)<0)%Diferencia negativa, segundo o tercer cuadrante
    sigptox=ptoinix;
    ptoinix=sigptox-0.01;
    while(gazex(i)<ptoinix) %Mientras la caja aun no contenga al punto
      sigptox=ptoinix;
      ptoinix=ptoinix-0.01;
    endwhile;
  endif
  
  %Comprobacion si se encuentra en y
  if(diffy(i)>0.01) %Si la diferencia es positiva, primer o segundo cuadrante, pto anterior como origen de coordenadas
    ptoiniy=vectorcajasy(indice-2);%-1
    sigptoy=ptoiniy+0.01;
    while(gazey(i)>sigptoy) %Mientras la caja aun no contenga al punto
      ptoiniy=sigptoy;
      sigptoy=sigptoy+0.01;
    endwhile;
  elseif(diffy(i)<0)
   sigptoy=ptoiniy; %si la diferencia es negativa, tercer o cuarto cuadrante
   ptoiniy=sigptoy-0.01;
   while(gazey(i)<ptoiniy) %Mientras la caja aun no contenga al punto
    sigptoy=ptoiniy;
    ptoiniy=ptoiniy-0.01;
   endwhile;  
  endif
  
  %Comprobar que la caja no esta repetida
  flagy=(diffy(i)>0.01 || diffy(i)<0); 
  flagx=(diffx(i)>0.01 || diffx(i)<0);
  
  %Tienen que ser las dos flag 0 para que la caja este repetida
  if(flagy||flagx)
  
    vectorcajasx(indice)=ptoinix;
    vectorcajasx(indice+1)=sigptox;
    vectorcajasx(indice+2)=sigptox;
    vectorcajasx(indice+3)=ptoinix;
    vectorcajasx(indice+4)=ptoinix;
    
    vectorcajasy(indice)=ptoiniy;
    vectorcajasy(indice+1)=ptoiniy;
    vectorcajasy(indice+2)=sigptoy;
    vectorcajasy(indice+3)=sigptoy;
    vectorcajasy(indice+4)=ptoiniy;
    
    indice=indice+5;
    %indice=indice+4;
    haycaja(i)=1;
  endif
  
endfor


onset_drift = [];
finish_drift = [];
vpeak = [];
ampl = [];
v_mean=[];
tipo=type;
numeroguardado=[];

clear numcajas_drift;
clear diff;


%Calculo del drift
for i=2:N-1
  
  if(type(onset(i))==0 && type(onset(i-1))==2) %El drift solo se da entre microsacadas
    j=1;
    numcajas_drift=1;
    %Calcular el numero de cajas que hay en el drift
    while (j+onset(i))<=finish(i) && type(onset(i)+j)==0
      if(haycaja(j+i)) numcajas_drift=numcajas_drift+1;
      endif
      j++;
      if(j+onset(i))>finish(i)  j=j-1; break; endif  %Condicion de seguridad    
    endwhile
    
    if(amplitud(i)<1)
      %Condicion para que sea drift
      if(numcajas_drift<56 && type(onset(i+1))==2 && std(pupilArea(onset(i):finish(i)))<100) % Que acabe con una microsacada, y el menor numero de cajas

        if (time(finish(i))-time(onset(i)))<800
          numcajas_drift;
          onset_drift=vertcat(onset_drift,onset(i));
          finish_drift=vertcat(finish_drift,finish(i));
          tipo(onset(i):finish(i))=3;
          numeroguardado=vertcat(numeroguardado,numcajas_drift);
          vpeak = vertcat(vpeak, max(vel(onset(i): finish(i))));
          v_mean=vertcat(v_mean,mean(vel(onset(i): finish(i))));
          ampl = vertcat(ampl,amplitud(i));
        endif
      endif
    endif  
    %i=j+i;
    %if(i>length(gazex)) break; endif %Condicion de salida
  endif  
endfor

n=1;
for i=1:length(tipo)
  if haycaja(i)==1  
    if tipo(i)==3 
      tipo_cajas(n:(n+4))=1; %+3
    else
      tipo_cajas(n:(n+4))=0; %+3
    endif
    n=n+5; %+4
  endif
endfor
%{
cajasplotx=vectorcajasx(tipo_cajas==1);
cajasploty=vectorcajasy(tipo_cajas==1);


figure;
hold on;
plot(gazex(tipo==1),gazey(tipo==1),'b.');
plot(gazex(tipo==0),gazey(tipo==0),'g.');
plot(gazex(tipo==2),gazey(tipo==2),'m.');
plot(gazex(tipo==3),gazey(tipo==3),'c.','MarkerSize',10);
j=1;
while j<=length(cajasplotx)
  plot(cajasplotx(j:(j+4)),cajasploty(j:(j+4)),'k-','LineWidth',2);
  j=j+5;
endwhile
i=1;
while i<=length(onset_drift)
  plot(gazex(onset_drift(i):finish_drift(i)),gazey(onset_drift(i):finish_drift(i)),"c -",'LineWidth',1);
  i=i+1;
endwhile
if (length(numeroguardado)!=0)
  for i=1:length(numeroguardado)
    %text(gazex(onset_drift(i)+1:finish_drift(i)),gazey(onset_drift(i)+1:finish_drift(i)),num2str(i),'FontWeight','bold');
    
    text(gazex(onset_drift(i)),gazey(onset_drift(i))-0.05,strcat('N= ',num2str(numeroguardado(i))),'FontWeight','bold');
  endfor
endif
legend('Sacada','Fijación','Microsacada','Drift','Location','northwestoutside')
xlabel('gazex(deg)')
ylabel('gazey(deg)')
title('box-counting')
%}
end