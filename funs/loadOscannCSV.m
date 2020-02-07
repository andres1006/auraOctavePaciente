function [ dataStructOut ] = loadOscannCSV( filePath )
%Cargar los datos de un csv en una estructura cuya organizacion es conocida
%Inicializar
dataStructOut=struct;

% [a,b]=uigetfile('*.csv');
% filePath=strcat(b,a);

%Abrir el archivo
fileOpen=importdata(strcat(filePath),',',2);

%Guardar lo general
dataStructOut.data=fileOpen.data;
dataStructOut.textdata=fileOpen.textdata{2};

%Guardar datos separados
dataStructOut.time=fileOpen.data(:,1);

%Grados (Directo del fichero)
dataStructOut.gaze=fileOpen.data(:,2:3);
dataStructOut.estimulus=fileOpen.data(:,4:5);
dataStructOut.gazeVel=fileOpen.data(:,6:7);
dataStructOut.gazeError=fileOpen.data(:,8:9);
dataStructOut.pupilArea=fileOpen.data(:,10);
dataStructOut.gazeRaw=fileOpen.data(:,11:12);
dataStructOut.detectionFail=fileOpen.data(:,13);

%Guardar info de la primera linea
datosPrimeraLinea=strsplit(fileOpen.textdata{1},',');
%dataStructOut.px2deg=str2double(datosPrimeraLinea{2});
dataStructOut.screenResolution=[str2double(datosPrimeraLinea{2}),str2double(datosPrimeraLinea{3})];
dataStructOut.screenDist=str2double(datosPrimeraLinea{5});
dataStructOut.screenWidth=str2double(datosPrimeraLinea{7});
dataStructOut.sesion=datosPrimeraLinea{9};
dataStructOut.filename=datosPrimeraLinea{11};
dataStructOut.calibration=datosPrimeraLinea{13};

%Pixeles
%dataStructOut.gazePx=dataStructOut.gaze*dataStructOut.px2deg;
%dataStructOut.estimulusPx=dataStructOut.estimulus*dataStructOut.px2deg;
%dataStructOut.gazeVelPx=dataStructOut.gazeVel*dataStructOut.px2deg;
%dataStructOut.gazeErrorPx=dataStructOut.gazeError*dataStructOut.px2deg;
%
%dataStructOut.gazeRawPx=dataStructOut.gazeRaw*dataStructOut.px2deg;
end



% function [ dataStructOut ] = loadOscannCSV( filePath )
% %Cargar los datos de un csv en una estructura cuya organizacion es conocida
% %Inicializar
% dataStructOut=struct;
% 
% % [a,b]=uigetfile('*.csv');
% % filePath=strcat(b,a);
% 
% %Abrir el archivo
% fileOpen=importdata(strcat(filePath),',',2);
% 
% %Guardar lo general
% dataStructOut.data=fileOpen.data;
% dataStructOut.textdata=fileOpen.textdata{2};
% 
% %Guardar datos separados
% dataStructOut.time=fileOpen.data(:,1);
% 
% %Grados (Directo del fichero)
% dataStructOut.gaze=fileOpen.data(:,2:3);
% dataStructOut.estimulus=fileOpen.data(:,4:5);
% dataStructOut.gazeVel=fileOpen.data(:,6:7);
% dataStructOut.gazeError=fileOpen.data(:,8:9);
% dataStructOut.pupilArea=fileOpen.data(:,10);
% dataStructOut.gazeRaw=fileOpen.data(:,11:12);
% 
% %Guardar info de la primera linea
% datosPrimeraLinea=strsplit(fileOpen.textdata{1},',');
% dataStructOut.px2deg=str2double(datosPrimeraLinea{2});
% 
% %Pixeles
% dataStructOut.gazePx=dataStructOut.gaze*dataStructOut.px2deg;
% dataStructOut.estimulusPx=dataStructOut.estimulus*dataStructOut.px2deg;
% dataStructOut.gazeVelPx=dataStructOut.gazeVel*dataStructOut.px2deg;
% dataStructOut.gazeErrorPx=dataStructOut.gazeError*dataStructOut.px2deg;
% 
% dataStructOut.gazeRawPx=dataStructOut.gazeRaw*dataStructOut.px2deg;
% 
% 
% end

