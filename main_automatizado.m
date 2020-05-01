function [] = main_automatizado(Dir)
   warning('off','all')
###############################################################################################################
%%%dataProcess
%%% Analiza los test de Sacadas, Antisacadas, Sacadas de memoria, Seguimiento Lento y Fijaciones de pacientes con
%%% una estructura de carpetas de Hospital/Patologias/Paciente/test o Patologia/Paciente/test y genera un csv de 
%%% test en el cual cada fila es un Paciente de la estructura de carpetas y cada fila un Parametro del test.
%%% En este caso para los test sacadicos (sacadas, anti y memoria) se generan parametros relativos solo a la ida
%%% de las sacadas.

%%% Autor principal: Silvia Gomez Martin
%%% Empresa: Aura Innovative Robotics
%%% Version 2.1.3
%%% Autor ultima modificacion: Silvia Gomez Martin 
%%% Fecha ultima modificacion: 25 de Octubre de 2018

%%% Se ha integrado los parametros de vuelta en las sacadas
###############################################################################################################


#! /usr/bin/octave -qf
%includes
version = "2.1.3";
pkg load statistics;

%%%%%%%%%%%%%%%%%%%%%%PARAMETRO PARA LA DES/ACTIVACION DE LOS PARAMETROS DE VUELTA
vuelta=1;   %vuelta = 0 -> Excel sin parametros de vuelta
            %vuelta = 1 -> Excel con parametros de vuelta

%Dir=uigetdir('/*');
addpath('funs'); 
patologia=0;
infoDir=dir(Dir);
%EVALUAR COMO ESTAN DISPUESTAS LAS CARPETAS
for i=3:length(infoDir)
  if isdir(strcat(Dir,"/",infoDir(i).name))   
    infoPat=dir(strcat(Dir,"/",infoDir(i).name));
    for j=3:length(infoPat)
      if exist(strcat(Dir,"/",infoDir(i).name,"/",infoPat(j).name,"/",infoPat(j).name,".csv"),"file")
        %EN LA ESTRUCTURA DE CARPETAS SOLO EXISTE UNA PATOLOGIA SIN CARPETA PARA DEFINIRLA
        patologia=1;
        break;
      else
        %LA ESTRUCTURA SE DIVIDE EN CARPETAS POR PATOLOGIA
        patologia=2;
      endif
    endfor
  if patologia==1
    break;
  endif
  endif
endfor

if patologia==1
  %Si existen los archivos los reescribe.
  fdTSV = fopen (strcat(Dir,"/TSV_v-",version,".csv"), "w"); 
  fdTSM = fopen (strcat(Dir,"/TSM_v-",version,".csv"), "w"); 
  fdTAS = fopen (strcat(Dir,"/TAS_v-",version,".csv"), "w"); 
  fdTSL = fopen (strcat(Dir,"/TSL_v-",version,".csv"), "w"); 
  fdTFIX = fopen (strcat(Dir,"/TFIX_v-",version,".csv"), "w"); 
  
  %Headers
  if fdTSV!=-1 
    %Cabeceros horizontales de TSV
    fprintf(fdTSV, 'ID,tsv_lat_h, tsv_lat_sd_h,tsv_gain_h,tsv_gain_sd_h,tsv_vpeak_h,tsv_vpeak_sd_h,tsv_err_pos_h,tsv_err_pos_sd_h,tsv_err_neg_h,tsv_err_neg_sd_h,tsv_blinks_h,tsv_fast_h,'); 
    if vuelta == 1 
      fprintf(fdTSV,'tsv_lat_r_h,tsv_lat_sd_r_h,tsv_vpeak_r_h,tsv_vpeak_std_r_h,');
    endif 
    
    %Cabeceros verticales de TSV
    fprintf(fdTSV, 'tsv_lat_v,tsv_lat_sd_v,tsv_gain_v,tsv_gain_sd_v,tsv_vpeak_v,tsv_vpeak_sd_v,tsv_err_pos_v,tsv_err_pos_sd_v,tsv_err_neg_v,tsv_err_neg_sd_v,tsv_blinks_v,tsv_fast_v');    
    if vuelta == 1 
      fprintf(fdTSV, ',tsv_lat_r_v,tsv_lat_sd_r_v,tsv_vpeak_r_v,tsv_vpeak_std_r_v\n');
    else
      fprintf(fdTSV, '\n');      
    endif
  endif  
  
  
  if fdTSM!=-1
    %Cabeceros horizontales de TSM 
    fprintf(fdTSM, 'ID,tsm_lat_h, tsm_lat_sd_h, tsm_gain_h, tsm_gain_sd_h, tsm_vpeak_h, tsm_vpeak_sd_h, tsm_err_pos_h, tsm_err_pos_sd_h, tsm_err_neg_h, tsm_err_neg_sd_h, tsm_blinks_h, tsm_fast_h, tsm_corr_h, tsm_corr_rate_h,');
    if vuelta == 1 
      fprintf(fdTSM,'tsm_lat_r_h,tsm_lat_sd_r_h,tsm_vpeak_r_h,tsm_vpeak_std_r_h,');
    endif
    
    %Cabeceros verticales de TSM
    fprintf(fdTSM, 'tsm_lat_v, tsm_lat_sd_v, tsm_gain_v, tsm_gain_sd_v, tsm_vpeak_v, tsm_vpeak_sd_v, tsm_err_pos_v, tsm_err_pos_sd_v, tsm_err_neg_v, tsm_err_neg_sd_v, tsm_blinks_v, tsm_fast_v, tsm_corr_v, tsm_corr_rate_v'); 
    if vuelta == 1 
      fprintf(fdTSM, ',tsm_lat_r_v,tsm_lat_sd_r_v,tsm_vpeak_r_v,tsm_vpeak_std_r_v\n');
    else
      fprintf(fdTSM, '\n');
    endif
  endif  
  
  if fdTAS!=-1
    %Cabeceros horizontales de TAS
    fprintf(fdTAS, 'ID,tas_lat_h, tas_lat_sd_h, tas_lat_ref_h, tas_lat_ref_sd_h, tas_Tref_h, tas_Tref_sd_h, tas_err_pos_h, tas_err_pos_sd_h, tas_err_neg_h,tas_err_neg_sd_h, tas_blinks_h, tas_corr_h, tas_ref_h, tas_err_h, tas_sor_h, tas_fast_h, tas_corr_rate_h, tas_ref_rate_h, tas_errs_rate_h, tas_sor_rate_h, tas_fast_rate_h,');
    if vuelta == 1 
      fprintf(fdTAS,'tas_lat_r_h,tas_lat_sd_r_h,tas_vpeak_r_h,tas_vpeak_std_r_h,');
    endif
    
    %Cabeceros verticales de TAS
    fprintf(fdTAS, 'tas_lat_v, tas_lat_sd_v, tas_lat_ref_v, tas_lat_ref_sd_v, tas_Tref_v, tas_Tref_sd_v, tas_err_pos_v, tas_err_pos_sd_v, tas_err_neg_v,tas_err_neg_sd_v, tas_blinks_v, tas_corr_v, tas_ref_v, tas_err_v, tas_sor_v, tas_fast_v, tas_corr_rate_v, tas_ref_rate_v, tas_errs_rate_v, tas_sor_rate_v, tas_fast_rate_v');
    if vuelta == 1 
      fprintf(fdTAS, ',tas_lat_r_v,tas_lat_sd_r_v,tas_vpeak_r_v,tas_vpeak_std_r_v\n');
    else
      fprintf(fdTAS, '\n');
    endif
  endif  
  if fdTSL!=-1
    %Cabeceros horizontales de TSL
    fprintf(fdTSL, 'ID,tsls_blinks_h, tsls_catchup_h, tsls_backup_h, tsls_swj_h, tsls_pursuitTime_h,  tsls_lat_h, tsls_erroPursuitAndSaccades_h, tsls_errorPursuitOnly_h, tsls_gain_h, tsls_velocityError_h, tsls_blinks_v, tsls_catchup_v, tsls_backup_v, tsls_swj_v, tsls_pursuitTime_v, tsls_lat_v, tsls_erroPursuitAndSaccades_v, tsls_errorPursuitOnly_v, tsls_gain_v, tsls_velocityError_v');
    
    %Cabeceros verticales de TSL
    fprintf(fdTSL, ',tsll_blinks_h, tsll_catchup_h, tsll_backup_h, tsll_swj_h, tsll_pursuitTime_h,  tsll_lat_h, tsll_erroPursuitAndSaccades_h, tsll_errorPursuitOnly_h, tsll_gain_h, tsll_velocityError_h, tsll_blinks_v, tsll_catchup_v, tsll_backup_v, tsll_swj_v, tsll_pursuitTime_v, tsll_lat_v, tsll_erroPursuitAndSaccades_v, tsll_errorPursuitOnly_v, tsll_gain_v, tsll_velocityError_v, tsll_blinks_s, tsll_catchup_s, tsll_backup_s, tsll_swj_s, tsll_pursuitTime_s, tsll_lat_s, tsll_erroPursuitAndSaccades_s, tsll_errorPursuitOnly_s, tsll_gain_s, tsll_velocityError_s\n');
  endif
  
  if fdTFIX!=-1
    fprintf(fdTFIX, 'ID, tfix_blinks, tfix_sacadas, tfix_microsacadas, tfix_drift, tfix_swjmono, tfix_swjbi, tfix_distraccion, tfix_bcea, tfix_ox, tfix_oy, tfix_centr_x, tfix_centr_y, tfix_ampl_m, tfix_ampl_m_sd, tfix_vel_m, tfix_vel_m_sd, tfix_vpeak_m, tfix_vpeak_m_sd, tfix_frecuency_m, tfix_ampl_d, tfix_ampl_d_sd, tfix_vel_d, tfix_vel_d_sd, tfix_vpeak_d, tfix_vpeak_d_sd, tfix_ampl_swj, tfix_ampl_swj_sd, tfix_time_swj, tfix_time_swj_sd\n');
  endif
%    fprintf(fdTOP, 'ID, top_blinks_hl, top_rcoef_hl, top_rcoef_sd_hl, top_rcoeftotal_hl, top_nyangle_hl, top_nyangle_sd_hl, top_spangle_hl, top_spangle_sd_hl, top_nyampl_hl, top_nyampl_sd_hl, top_spampl_hl, top_spampl_sd_hl, top_meanspvel_hl, top_meanspvel_sd_hl, top_meannyvel_hl, top_meannyvel_sd_hl, top_peakmaxrel_hl, top_peakmaxrel_sd_hl, top_peakminrel_hl, top_peakminrel_sd_hl ,');
%    fprintf(fdTOP, 'top_blinks_hr, top_rcoef_hr, top_rcoef_sd_hr, top_rcoeftotal_hr, top_nyangle_hr, top_nyangle_sd_hr, top_spangle_hr, top_spangle_sd_hr, top_nyampl_hr, top_nyampl_sd_hr, top_spampl_hr, top_spampl_sd_hr, top_meanspvel_hr, top_meanspvel_sd_hr, top_meannyvel_hr, top_meannyvel_sd_hr, top_peakmaxrel_hr, top_peakmaxrel_sd_hr, top_peakminrel_hr, top_peakminrel_sd_hr ,');
%    fprintf(fdTOP, 'top_blinks_vu, top_rcoef_vu, top_rcoef_sd_vu, top_rcoeftotal_vu, top_nyangle_vu, top_nyangle_sd_vu, top_spangle_vu, top_spangle_sd_vu, top_nyampl_vu, top_nyampl_sd_vu, top_spampl_vu, top_spampl_sd_vu, top_meanspvel_vu, top_meanspvel_sd_vu, top_meannyvel_vu, top_meannyvel_sd_vu, top_peakmaxrel_vu, top_peakmaxrel_sd_vu, top_peakminrel_vu, top_peakminrel_sd_vu,');
%    fprintf(fdTOP, 'top_blinks_vd, top_rcoef_vd, top_rcoef_sd_vd, top_rcoeftotal_vd, top_nyangle_vd, top_nyangle_sd_vd, top_spangle_vd, top_spangle_sd_vd, top_nyampl_vd, top_nyampl_sd_vd, top_spampl_hr, top_spampl_sd_hr, top_meanspvel_vd, top_meanspvel_sd_vd, top_meannyvel_vd, top_meannyvel_sd_vd, top_peakmaxrel_vd, top_peakmaxrel_sd_vd, top_peakminrel_vd, top_peakminrel_sd_vd\n');
 
  for i=3:length(infoDir)    
    if isdir(strcat(Dir,"/",infoDir(i).name))
      patientName=infoDir(i).name
      if strcmp(patientName,"..") || strcmp(patientName,".")
        continue;
      end
      testsDirInfo=dir(strcat(Dir,"/",infoDir(i).name));
      %TSVH = ones(1,12)*-99;
      TSVH = NaN(1,12);
      TSVH_V = NaN(1,4);
      TSVHName=NaN;
      %TSVV = ones(1,12)*-99;
      TSVV = NaN(1,12);
      TSVV_V = NaN(1,4);
      TSVVName=NaN;
      %TSMH = ones(1,14)*-99;
      TSMH = NaN(1,14);
      TSMH_V = NaN(1,4);
      TSMHName=NaN;
      %TSMV = ones(1,14)*-99;
      TSMV = NaN(1,14);
      TSMV_V = NaN(1,4);
      TSMVName=NaN;
      %TASVH = ones(1,21)*-99;
      TASVH = NaN(1,21);
      TASVH_V = NaN(1,4);
      TASVHName=NaN;
      %TASVV = ones(1,21)*-99;
      TASVV = NaN(1,21);
      TASVV_V = NaN(1,4);
      TASVVName=NaN;
      %TSLLH = ones(1,10)*-99;
      TSLLH = NaN(1,10);
      TSLLHName=NaN;
      %TSLLV = ones(1,10)*-99;
      TSLLV = NaN(1,10);
      TSLLVName=NaN;
      %TSLLS = ones(1,10)*-99;
      TSLLS = NaN(1,10);
      TSLLSName=NaN;
      %TSLSH = ones(1,10)*-99;
      TSLSH = NaN(1,10);
      TSLSHName=NaN;
      %TSLSV = ones(1,10)*-99;
      TSLSV = NaN(1,10);
      TSLSVName=NaN;
      %TFIX = ones(1,28)*-99;
      TFIX = NaN(1,29);
      TFIXName=NaN;
      for j=1:length(testsDirInfo)
        if length(testsDirInfo(j).name) >= 4 && length(strfind(testsDirInfo(j).name, 'SACCADES')) == 0 && length(strfind(testsDirInfo(j).name, 'STATISTICAL')) == 0 
          if strcmp(testsDirInfo(j).name(1:4),"TSVH")
            if exist(strcat(Dir,'/',patientName, '/', testsDirInfo(j).name, '/', testsDirInfo(j).name, '.csv'),'file')
              TSVHName = testsDirInfo(j).name
              r = saccades(strcat(Dir,'/',patientName, '/', testsDirInfo(j).name, '/', testsDirInfo(j).name));
                %     Lat_x  SD           gain    SD     VPeak, SD   ,Error+, SD     Error- SD    Blinks, fastResponse 
              TSVH = [r(5),  r(7),        r(37) , r(39), r(10), r(12), r(15), r(17), r(20), r(22), r(1),   r(2)];
              if vuelta == 1
                TSVH_V = [r(42),r(44),r(47),r(49)];
              endif  
            end
          elseif strcmp(testsDirInfo(j).name(1:4),"TSVV")
          if exist(strcat(Dir,'/',patientName, '/', testsDirInfo(j).name, '/', testsDirInfo(j).name, '.csv'),'file')
            TSVVName = testsDirInfo(j).name
            r = saccades(strcat(Dir,"/",patientName, '/', testsDirInfo(j).name, '/', testsDirInfo(j).name));
            TSVV = [r(5),  r(7),        r(37) , r(39), r(10), r(12), r(15), r(17), r(20), r(22), r(1),   r(2)];
            if vuelta == 1
              TSVV_V = [r(42),r(44),r(47),r(49)];
            endif
          endif
          elseif strcmp(testsDirInfo(j).name(1:4),"TSMH")
          if exist(strcat(Dir,'/',patientName, '/', testsDirInfo(j).name, '/', testsDirInfo(j).name, '.csv'),'file')
            TSMHName = testsDirInfo(j).name
            r = memory(strcat(Dir,'/',patientName, '/', testsDirInfo(j).name, '/', testsDirInfo(j).name));        
            TSMH = [r(7), r(9), r(39), r(41), r(12), r(14), r(17), r(19), r(22), r(24), r(1), r(2), r(3), r(4)];
            if vuelta == 1
              TSMH_V = [r(44),r(46),r(49),r(51)];
            endif
          endif
          elseif strcmp(testsDirInfo(j).name(1:4),"TSMV")
          if exist(strcat(Dir,'/',patientName, '/', testsDirInfo(j).name, '/', testsDirInfo(j).name, '.csv'),'file')
            TSMVName = testsDirInfo(j).name
            r = memory(strcat(Dir,'/',patientName, '/', testsDirInfo(j).name, '/', testsDirInfo(j).name));
            TSMV = [r(7), r(9), r(39), r(41), r(12), r(14), r(17), r(19), r(22), r(24), r(1), r(2), r(3), r(4)];
            if vuelta == 1
              TSMV_V = [r(44),r(46),r(49),r(51)];
            endif
          endif
          elseif strcmp(testsDirInfo(j).name(1:5),"TASVH")
          if exist(strcat(Dir,'/',patientName, '/', testsDirInfo(j).name, '/', testsDirInfo(j).name, '.csv'),'file')
            TASVHName = testsDirInfo(j).name
            r = antisaccades(strcat(Dir,'/',patientName, '/', testsDirInfo(j).name, '/', testsDirInfo(j).name));
            %        Blicks, Correct, Reflexive, Wrong, SoR , Adel, Seccess, corrected,Error,SORa  , anticipat,Lat_x,y(meanAntisaccadeLatency), SD   , Lat_ref, SD   , Δref, SD    , Error+,    SD,   num, Error-, SD  , num   
            TASVH = [r(1)  , r(2)   , r(3)     , r(4) , r(5), r(6), r(7)   , r(8)     ,r(9) , r(10), r(11)    ,r(22)                          , r(26), r(31)  , r(35), r(40), r(44), r(19) , r(21), r(14), r(16)];
            if vuelta == 1
              TASVH_V = [r(47),r(49),r(52),r(54)];
            endif
          endif
          elseif strcmp(testsDirInfo(j).name(1:5),"TASVV")
          if exist(strcat(Dir,'/',patientName, '/', testsDirInfo(j).name, '/', testsDirInfo(j).name, '.csv'),'file')
            TASVVName = testsDirInfo(j).name
            r = antisaccades(strcat(Dir,'/',patientName, '/', testsDirInfo(j).name, '/', testsDirInfo(j).name));
            TASVV = [r(1)  , r(2)   , r(3)     , r(4) , r(5), r(6), r(7), r(8)     ,r(9) , r(10), r(11)    ,r(22)                          , r(26), r(31)  , r(35), r(40), r(44), r(19) , r(21), r(14), r(16)];
            if vuelta == 1
              TASVV_V = [r(47),r(49),r(52),r(54)];
            endif
          endif
          elseif strcmp(testsDirInfo(j).name(1:5),"TSLLH")
          if exist(strcat(Dir,'/',patientName, '/', testsDirInfo(j).name, '/', testsDirInfo(j).name, '.csv'),'file')
            TSLLHName = testsDirInfo(j).name
            r = tsl(strcat(Dir,'/',patientName, '/', testsDirInfo(j).name, '/', testsDirInfo(j).name));
            TSLLH = [r(1), r(3), r(4), r(5), r(6), r(2), r(7), r(8), r(9), r(10)];
          endif
          elseif strcmp(testsDirInfo(j).name(1:5),"TSLLV")
          if exist(strcat(Dir,'/',patientName, '/', testsDirInfo(j).name, '/', testsDirInfo(j).name, '.csv'),'file')  
            TSLLVName = testsDirInfo(j).name
            r = tsl(strcat(Dir,'/',patientName, '/', testsDirInfo(j).name, '/', testsDirInfo(j).name));
            TSLLV = [r(1), r(3), r(4), r(5), r(6), r(2), r(7), r(8), r(9), r(10)];
          endif
          elseif strcmp(testsDirInfo(j).name(1:5),"TSLLS")
          if exist(strcat(Dir,'/',patientName, '/', testsDirInfo(j).name, '/', testsDirInfo(j).name, '.csv'),'file') 
            TSLLSName = testsDirInfo(j).name
            r = tsl(strcat(Dir,'/',patientName, '/', testsDirInfo(j).name, '/', testsDirInfo(j).name));
            TSLLS = [r(1), r(3), r(4), r(5), r(6), r(2), r(7), r(8), r(9), r(10)];
          endif
          elseif strcmp(testsDirInfo(j).name(1:5),"TSLSH")
          if exist(strcat(Dir,'/',patientName, '/', testsDirInfo(j).name, '/', testsDirInfo(j).name, '.csv'),'file')
            TSLSHName = testsDirInfo(j).name
            r = tsl(strcat(Dir,'/',patientName, '/', testsDirInfo(j).name, '/', testsDirInfo(j).name));
            TSLSH = [r(1), r(3), r(4), r(5), r(6), r(2), r(7), r(8), r(9), r(10)];
          endif
          elseif strcmp(testsDirInfo(j).name(1:5),"TSLSV")
           if exist(strcat(Dir,'/',patientName, '/', testsDirInfo(j).name, '/', testsDirInfo(j).name, '.csv'),'file') 
            TSLSVName = testsDirInfo(j).name
            r = tsl(strcat(Dir,'/',patientName, '/', testsDirInfo(j).name, '/', testsDirInfo(j).name));
            TSLSV = [r(1), r(3), r(4), r(5), r(6), r(2), r(7), r(8), r(9), r(10)];
          endif
          elseif strcmp(testsDirInfo(j).name(1:4),"TFIX")
           if exist(strcat(Dir,'/',patientName, '/', testsDirInfo(j).name, '/', testsDirInfo(j).name, '.csv'),'file')
            TFIXName =testsDirInfo(j).name
            r = fixation(strcat(Dir,'/',patientName, '/', testsDirInfo(j).name, '/', testsDirInfo(j).name));
             %    Blinks sacadas  microsacadas  drift  SWJmono SWJbi,  distraccion,  BCEA     ox     oy       centroide,    ampl_m  SD   vmean_m  SD    Vpeak_m         SD  frecuency, ampl_m_d      SD  vmean_d   SD     Vpeak_d, SD  ampl_m_swj    SD  time_SWJ  SD   
            TFIX = [r(1),  r(2),   r(3),          r(4), r(5),   r(6),      r(29),    r(7) ,  r(27) ,r(28),    r(8), r(9),  r(10), r(11), r(12), r(13),     r(14),      r(15),  r(16),    r(17),   r(18), r(19),  r(20)     r(21), r(22), r(23),     r(24), r(25) ,r(26)];
          endif
          %          elseif strcmp(testsDirInfo(j).name(1:6),"TOPTHL")
          %              TOPTHLName=testsDirInfo(j).name;
          %              r = Optokinetic(strcat(directory, '/', mainDirInfo(i).name, '/', testsDirInfo(j).name, '/', testsDirInfo(j).name));
          %              TOPTHL = [r(1), r(2), r(3), r(4), r(5), r(6), r(7), r(8), r(9), r(10), r(11), r(12), r(13), r(14), r(15), r(16), r(17), r(18), r(19), r(20)];
          %          elseif strcmp(testsDirInfo(j).name(1:6),"TOPTHR")
          %              TOPTHRName=testsDirInfo(j).name;
          %              r = Optokinetic(strcat(directory, '/', mainDirInfo(i).name, '/', testsDirInfo(j).name, '/', testsDirInfo(j).name));
          %              TOPTHR = [r(1), r(2), r(3), r(4), r(5), r(6), r(7), r(8), r(9), r(10), r(11), r(12), r(13), r(14), r(15), r(16), r(17), r(18), r(19), r(20)];
          %          elseif strcmp(testsDirInfo(j).name(1:6),"TOPTVD")
          %              TOPTVDName=testsDirInfo(j).name;
          %              r = Optokinetic(strcat(directory, '/', mainDirInfo(i).name, '/', testsDirInfo(j).name, '/', testsDirInfo(j).name));
          %              TOPTVD = [r(1), r(2), r(3), r(4), r(5), r(6), r(7), r(8), r(9), r(10), r(11), r(12), r(13), r(14), r(15), r(16), r(17), r(18), r(19), r(20)];
          %          elseif strcmp(testsDirInfo(j).name(1:6),"TOPTVU")
          %              TOPTVUName=testsDirInfo(j).name;
          %              r = Optokinetic(strcat(directory, '/', mainDirInfo(i).name, '/', testsDirInfo(j).name, '/', testsDirInfo(j).name));
          %              TOPTVU = [r(1), r(2), r(3), r(4), r(5), r(6), r(7), r(8), r(9), r(10), r(11), r(12), r(13), r(14), r(15), r(16), r(17), r(18), r(19), r(20)];
          endif
        endif
      endfor

      
    %fprintf Pablo 
      if fdTSV!=-1 
        %Datos horizontales TSV
        fprintf(fdTSV, '%s,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%d,%d,',patientName,TSVH(1),TSVH(2),TSVH(3),TSVH(4),TSVH(5),TSVH(6),TSVH(7),TSVH(8),TSVH(9),TSVH(10),TSVH(11),TSVH(12));  
        if vuelta == 1 
          fprintf(fdTSV, '%f,%f,%f,%f,',TSVH_V(1),TSVH_V(2),TSVH_V(3),TSVH_V(4));
        endif 
        
        %Datos verticales TSV
        fprintf(fdTSV, '%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%d,%d',TSVV(1),TSVV(2),TSVV(3),TSVV(4),TSVV(5),TSVV(6),TSVV(7),TSVV(8),TSVV(9),TSVV(10),TSVV(11),TSVV(12));     
        if vuelta == 1 
          fprintf(fdTSV, ',%f,%f,%f,%f\n',TSVV_V(1),TSVV_V(2),TSVV_V(3),TSVV_V(4));
        else
          fprintf(fdTSV, '\n');
        endif
      endif  
      
      if fdTSM!=-1
        %Datos horizontales TSM
        fprintf(fdTSM, '%s,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%d,%d,%d,%f,',patientName,TSMH(1),TSMH(2),TSMH(3),TSMH(4),TSMH(5),TSMH(6),TSMH(7),TSMH(8),TSMH(9),TSMH(10),TSMH(11),TSMH(12),TSMH(13),TSMH(14));
        if vuelta == 1 
          fprintf(fdTSM, '%f,%f,%f,%f,',TSMH_V(1),TSMH_V(2),TSMH_V(3),TSMH_V(4));
        endif 
        
        %Datos verticales TSM
        fprintf(fdTSM, '%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%d,%d,%d,%f',TSMV(1),TSMV(2),TSMV(3),TSMV(4),TSMV(5),TSMV(6),TSMV(7),TSMV(8),TSMV(9),TSMV(10),TSMV(11),TSMV(12),TSMV(13),TSMV(14));
        if vuelta == 1 
          fprintf(fdTSM, ',%f,%f,%f,%f\n',TSMV_V(1),TSMV_V(2),TSMV_V(3),TSMV_V(4));
        else
          fprintf(fdTSM, '\n');
        endif
      endif
      
      if fdTAS!=-1
        %Datos horizontales TAS
        fprintf(fdTAS, '%s,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%d,%d,%d,%d,%d,%d,%f,%f,%f,%f,%f,',patientName,TASVH(12),TASVH(13),TASVH(14),TASVH(15),TASVH(16),TASVH(17),TASVH(18),TASVH(19),TASVH(20),TASVH(21),TASVH(1),TASVH(2),TASVH(3),TASVH(4),TASVH(5),TASVH(6),TASVH(7),TASVH(8),TASVH(9),TASVH(10),TASVH(11));
        if vuelta == 1 
          fprintf(fdTAS, '%f,%f,%f,%f,',TASVH_V(1),TASVH_V(2),TASVH_V(3),TASVH_V(4));
        endif
        
        %Datos verticales TAS
        fprintf(fdTAS, '%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%d,%d,%d,%d,%d,%d,%f,%f,%f,%f,%f',TASVV(12),TASVV(13),TASVV(14),TASVV(15),TASVV(16),TASVV(17),TASVV(18),TASVV(19),TASVV(20),TASVV(21),TASVV(1),TASVV(2),TASVV(3),TASVV(4),TASVV(5),TASVV(6),TASVV(7),TASVV(8),TASVV(9),TASVV(10),TASVV(11));
        if vuelta == 1 
          fprintf(fdTAS, ',%f,%f,%f,%f\n',TASVV_V(1),TASVV_V(2),TASVV_V(3),TASVV_V(4));
        else
          fprintf(fdTAS, '\n');
        endif
      endif
      
      if fdTSL!=-1
        %Datos horizontales TSLS
        fprintf(fdTSL, '%s,%d,%f,%d,%d,%d,%f,%f,%f,%f,%f,',patientName,TSLSH(1), TSLSH(2), TSLSH(3), TSLSH(4), TSLSH(5), TSLSH(6), TSLSH(7), TSLSH(8), TSLSH(9), TSLSH(10));
        
        %Datos verticales TSLS
        fprintf(fdTSL, '%d,%f,%d,%d,%d,%f,%f,%f,%f,%f,', TSLSV(1), TSLSV(2), TSLSV(3), TSLSV(4), TSLSV(5), TSLSV(6), TSLSV(7), TSLSV(8), TSLSV(9), TSLSV(10));
        
        %Datos horizontales TSLL
        fprintf(fdTSL, '%d,%f,%d,%d,%d,%f,%f,%f,%f,%f,',TSLLH(1), TSLLH(2), TSLLH(3), TSLLH(4), TSLLH(5), TSLLH(6), TSLLH(7), TSLLH(8), TSLLH(9), TSLLH(10));
        
        %Datos verticales TSLL
        fprintf(fdTSL, '%d,%f,%d,%d,%d,%f,%f,%f,%f,%f,', TSLLV(1), TSLLV(2), TSLLV(3), TSLLV(4), TSLLV(5), TSLLV(6), TSLLV(7), TSLLV(8), TSLLV(9), TSLLV(10));
        
        %Cabeceros TSLLS
        fprintf(fdTSL, '%d,%f,%d,%d,%d,%f,%f,%f,%f,%f\n',TSLLS(1), TSLLS(2), TSLLS(3), TSLLS(4), TSLLS(5), TSLLS(6), TSLLS(7), TSLLS(8), TSLLS(9), TSLLS(10));                                        
      endif
      
      if fdTFIX!=-1
      
        fprintf(fdTFIX, '%s,%d,%d,%d,%d,%d,%d,%d,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f\n',patientName,TFIX(1),TFIX(2),TFIX(3),TFIX(4),TFIX(5),TFIX(6),TFIX(7),TFIX(8),TFIX(9),TFIX(10),TFIX(11),TFIX(12),TFIX(13),TFIX(14),TFIX(15),TFIX(16),TFIX(17),TFIX(18),TFIX(19),TFIX(20),TFIX(21),TFIX(22),TFIX(23),TFIX(24),TFIX(25),TFIX(26),TFIX(27),TFIX(28),TFIX(29));
      endif  
 %        fprintf(fdTOP, '%s,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,',patientName,TOPTHL(1), TOPTHL(2), TOPTHL(3), TOPTHL(4), TOPTHL(5), TOPTHL(6), TOPTHL(7), TOPTHL(8), TOPTHL(9), TOPTHL(10), TOPTHL(11), TOPTHL(12), TOPTHL(13), TOPTHL(14), TOPTHL(15), TOPTHL(16), TOPTHL(17), TOPTHL(18), TOPTHL(19), TOPTHL(20));
 %        fprintf(fdTOP, '%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,',TOPTHR(1), TOPTHR(2), TOPTHR(3), TOPTHR(4), TOPTHR(5), TOPTHR(6), TOPTHR(7), TOPTHR(8), TOPTHR(9), TOPTHR(10), TOPTHR(11), TOPTHR(12), TOPTHR(13), TOPTHR(14), TOPTHR(15), TOPTHR(16), TOPTHR(17), TOPTHR(18), TOPTHR(19), TOPTHR(20));
 %        fprintf(fdTOP, '%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,',TOPTVD(1), TOPTVD(2), TOPTVD(3), TOPTVD(4), TOPTVD(5), TOPTVD(6), TOPTVD(7), TOPTVD(8), TOPTVD(9), TOPTVD(10), TOPTVD(11), TOPTVD(12), TOPTVD(13), TOPTVD(14), TOPTVD(15), TOPTVD(16), TOPTVD(17), TOPTVD(18), TOPTVD(19), TOPTVD(20));
 %        fprintf(fdTOP, '%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f\n',TOPTVU(1), TOPTVU(2), TOPTVU(3), TOPTVU(4), TOPTVU(5), TOPTVU(6), TOPTVU(7), TOPTVU(8), TOPTVU(9), TOPTVU(10), TOPTVU(11), TOPTVU(12), TOPTVU(13), TOPTVU(14), TOPTVU(15), TOPTVU(16), TOPTVU(17), TOPTVU(18), TOPTVU(19), TOPTVU(20));           
    endif
  endfor
   if fdTSV!=-1
      fclose(fdTSV);
    endif
    if fdTSM!=-1
      fclose(fdTSM);
    endif
    if fdTAS!=-1
      fclose(fdTAS);
    endif
    if fdTSL!=-1
      fclose(fdTSL);
    endif
    if fdTFIX!=-1
      fclose(fdTFIX);
    endif
  %    fclose(fdTOP);
else

  ##############################################################################
  ##################TIENE ESTRUCTURA DIVIDIDA EN PATOLOGIAS#####################
  ##############################################################################
  
  for i=3:length(infoDir)
    if isdir(strcat(Dir,"/",infoDir(i).name))   
      Patologia=infoDir(i).name
      infoPat=dir(strcat(Dir,"/",infoDir(i).name)); 
      %Si existen los archivos los reescribe.
      fdTSV = fopen (strcat(Dir,'/',infoDir(i).name,"/TSV_v-",version,".csv"), "w"); 
      fdTSM = fopen (strcat(Dir,'/',infoDir(i).name,"/TSM_v-",version,".csv"), "w"); 
      fdTAS = fopen (strcat(Dir,'/',infoDir(i).name,"/TAS_v-",version,".csv"), "w"); 
      fdTSL = fopen (strcat(Dir,'/',infoDir(i).name,"/TSL_v-",version,".csv"), "w"); 
      fdTFIX = fopen (strcat(Dir,'/',infoDir(i).name,"/TFIX_v-",version,".csv"), "w"); 
      %fdTOP = fopen (strcat(directory,"/TOP.csv"), "a");
      
      %Headers
      if fdTSV!=-1       
        %Cabeceros horizontales de TSV
        fprintf(fdTSV, 'ID,tsv_lat_h, tsv_lat_sd_h,tsv_gain_h,tsv_gain_sd_h,tsv_vpeak_h,tsv_vpeak_sd_h,tsv_err_pos_h,tsv_err_pos_sd_h,tsv_err_neg_h,tsv_err_neg_sd_h,tsv_blinks_h,tsv_fast_h,'); 
        if vuelta == 1 
          fprintf(fdTSV,'tsv_lat_r_h,tsv_lat_sd_r_h,tsv_vpeak_r_h,tsv_vpeak_std_r_h,');
        endif 
        
        %Cabeceros verticales de TSV
        fprintf(fdTSV, 'tsv_lat_v,tsv_lat_sd_v,tsv_gain_v,tsv_gain_sd_v,tsv_vpeak_v,tsv_vpeak_sd_v,tsv_err_pos_v,tsv_err_pos_sd_v,tsv_err_neg_v,tsv_err_neg_sd_v,tsv_blinks_v,tsv_fast_v');    
        if vuelta == 1 
          fprintf(fdTSV, ',tsv_lat_r_v,tsv_lat_sd_r_v,tsv_vpeak_r_v,tsv_vpeak_std_r_v\n');
        else
          fprintf(fdTSV, '\n');
        endif
      endif
      
      if fdTSM!=-1
        %Cabeceros horizontales de TSM 
        fprintf(fdTSM, 'ID,tsm_lat_h, tsm_lat_sd_h, tsm_gain_h, tsm_gain_sd_h, tsm_vpeak_h, tsm_vpeak_sd_h, tsm_err_pos_h, tsm_err_pos_sd_h, tsm_err_neg_h, tsm_err_neg_sd_h, tsm_blinks_h, tsm_fast_h, tsm_corr_h, tsm_corr_rate_h,');
        if vuelta == 1 
          fprintf(fdTSM,'tsm_lat_r_h,tsm_lat_sd_r_h,tsm_vpeak_r_h,tsm_vpeak_std_r_h,');
        endif
        
        %Cabeceros verticales de TSM 
        fprintf(fdTSM, 'tsm_lat_v, tsm_lat_sd_v, tsm_gain_v, tsm_gain_sd_v, tsm_vpeak_v, tsm_vpeak_sd_v, tsm_err_pos_v, tsm_err_pos_sd_v, tsm_err_neg_v, tsm_err_neg_sd_v, tsm_blinks_v, tsm_fast_v, tsm_corr_v, tsm_corr_rate_v'); 
        if vuelta == 1 
          fprintf(fdTSM, ',tsm_lat_r_v,tsm_lat_sd_r_v,tsm_vpeak_r_v,tsm_vpeak_std_r_v\n');
        else
          fprintf(fdTSM, '\n');
        endif
      endif  
      
      if fdTAS!=-1
        %Cabeceros horizontales de TAS
        fprintf(fdTAS, 'ID,tas_lat_h, tas_lat_sd_h, tas_lat_ref_h, tas_lat_ref_sd_h, tas_Tref_h, tas_Tref_sd_h, tas_err_pos_h, tas_err_pos_sd_h, tas_err_neg_h,tas_err_neg_sd_h, tas_blinks_h, tas_corr_h, tas_ref_h, tas_err_h, tas_sor_h, tas_fast_h, tas_corr_rate_h, tas_ref_rate_h, tas_errs_rate_h, tas_sor_rate_h, tas_fast_rate_h,');
        if vuelta == 1 
          fprintf(fdTAS,'tas_lat_r_h,tas_lat_sd_r_h,tas_vpeak_r_h,tas_vpeak_std_r_h,');
        endif
        
        %Cabeceros verticales de TAS
        fprintf(fdTAS, 'tas_lat_v, tas_lat_sd_v, tas_lat_ref_v, tas_lat_ref_sd_v, tas_Tref_v, tas_Tref_sd_v, tas_err_pos_v, tas_err_pos_sd_v, tas_err_neg_v,tas_err_neg_sd_v, tas_blinks_v, tas_corr_v, tas_ref_v, tas_err_v, tas_sor_v, tas_fast_v, tas_corr_rate_v, tas_ref_rate_v, tas_errs_rate_v, tas_sor_rate_v, tas_fast_rate_v');
        if vuelta == 1 
          fprintf(fdTAS, ',tas_lat_r_v,tas_lat_sd_r_v,tas_vpeak_r_v,tas_vpeak_std_r_v\n');
        else
          fprintf(fdTAS, '\n');
        endif
      endif 
      
      if fdTSL!=-1
        %Cabeceros horizontales de TSL
        fprintf(fdTSL, 'ID, tsls_blinks_h, tsls_catchup_h, tsls_backup_h, tsls_swj_h, tsls_pursuitTime_h,  tsls_lat_h, tsls_erroPursuitAndSaccades_h, tsls_errorPursuitOnly_h, tsls_gain_h, tsls_velocityError_h, tsls_blinks_v, tsls_catchup_v, tsls_backup_v, tsls_swj_v, tsls_pursuitTime_v, tsls_lat_v, tsls_erroPursuitAndSaccades_v, tsls_errorPursuitOnly_v, tsls_gain_v, tsls_velocityError_v');
        
        %Cabeceros verticales de TSL
        fprintf(fdTSL, ',tsll_blinks_h, tsll_catchup_h, tsll_backup_h, tsll_swj_h, tsll_pursuitTime_h,  tsll_lat_h, tsll_erroPursuitAndSaccades_h, tsll_errorPursuitOnly_h, tsll_gain_h, tsll_velocityError_h, tsll_blinks_v, tsll_catchup_v, tsll_backup_v, tsll_swj_v, tsll_pursuitTime_v, tsll_lat_v, tsll_erroPursuitAndSaccades_v, tsll_errorPursuitOnly_v, tsll_gain_v, tsll_velocityError_v, tsll_blinks_s, tsll_catchup_s, tsll_backup_s, tsll_swj_s, tsll_pursuitTime_s, tsll_lat_s, tsll_erroPursuitAndSaccades_s, tsll_errorPursuitOnly_s, tsll_gain_s, tsll_velocityError_s\n');
      endif
      
      if fdTFIX!=-1
        fprintf(fdTFIX, 'ID, tfix_blinks, tfix_sacadas, tfix_microsacadas, tfix_drift, tfix_swjmono, tfix_swjbi, tfix_distraccion, tfix_bcea, tfix_ox, tfix_oy, tfix_centr_x, tfix_centr_y, tfix_ampl_m, tfix_ampl_m_sd, tfix_vel_m, tfix_vel_m_sd, tfix_vpeak_m, tfix_vpeak_m_sd, tfix_frecuency_m, tfix_ampl_d, tfix_ampl_d_sd, tfix_vel_d, tfix_vel_d_sd, tfix_vpeak_d, tfix_vpeak_d_sd, tfix_ampl_swj, tfix_ampl_swj_sd, tfix_time_swj, tfix_time_swj_sd\n');
      endif
      %    fprintf(fdTOP, 'ID, top_blinks_hl, top_rcoef_hl, top_rcoef_sd_hl, top_rcoeftotal_hl, top_nyangle_hl, top_nyangle_sd_hl, top_spangle_hl, top_spangle_sd_hl, top_nyampl_hl, top_nyampl_sd_hl, top_spampl_hl, top_spampl_sd_hl, top_meanspvel_hl, top_meanspvel_sd_hl, top_meannyvel_hl, top_meannyvel_sd_hl, top_peakmaxrel_hl, top_peakmaxrel_sd_hl, top_peakminrel_hl, top_peakminrel_sd_hl ,');
      %    fprintf(fdTOP, 'top_blinks_hr, top_rcoef_hr, top_rcoef_sd_hr, top_rcoeftotal_hr, top_nyangle_hr, top_nyangle_sd_hr, top_spangle_hr, top_spangle_sd_hr, top_nyampl_hr, top_nyampl_sd_hr, top_spampl_hr, top_spampl_sd_hr, top_meanspvel_hr, top_meanspvel_sd_hr, top_meannyvel_hr, top_meannyvel_sd_hr, top_peakmaxrel_hr, top_peakmaxrel_sd_hr, top_peakminrel_hr, top_peakminrel_sd_hr ,');
      %    fprintf(fdTOP, 'top_blinks_vu, top_rcoef_vu, top_rcoef_sd_vu, top_rcoeftotal_vu, top_nyangle_vu, top_nyangle_sd_vu, top_spangle_vu, top_spangle_sd_vu, top_nyampl_vu, top_nyampl_sd_vu, top_spampl_vu, top_spampl_sd_vu, top_meanspvel_vu, top_meanspvel_sd_vu, top_meannyvel_vu, top_meannyvel_sd_vu, top_peakmaxrel_vu, top_peakmaxrel_sd_vu, top_peakminrel_vu, top_peakminrel_sd_vu,');
      %    fprintf(fdTOP, 'top_blinks_vd, top_rcoef_vd, top_rcoef_sd_vd, top_rcoeftotal_vd, top_nyangle_vd, top_nyangle_sd_vd, top_spangle_vd, top_spangle_sd_vd, top_nyampl_vd, top_nyampl_sd_vd, top_spampl_hr, top_spampl_sd_hr, top_meanspvel_vd, top_meanspvel_sd_vd, top_meannyvel_vd, top_meannyvel_sd_vd, top_peakmaxrel_vd, top_peakmaxrel_sd_vd, top_peakminrel_vd, top_peakminrel_sd_vd\n');
      
      for j=3:length(infoPat) %-5 por los 5 archivos .csv para almacenar los datos de las 5 pruebas a analizar
        if isdir(strcat(Dir,"/",infoDir(i).name,"/",infoPat(j).name))
          patientName=infoPat(j).name
          testsDirInfo=dir(strcat(Dir,"/",infoDir(i).name,'/',patientName));
          %TSVH = ones(1,12)*-99;
          TSVH = NaN(1,12);
          TSVH_V = NaN(1,4);
          TSVHName=NaN;
          %TSVV = ones(1,12)*-99;
          TSVV = NaN(1,12);
          TSVV_V = NaN(1,4);
          TSVVName=NaN;
          %TSMH = ones(1,14)*-99;
          TSMH = NaN(1,14);          
          TSMH_V = NaN(1,4);
          TSMHName=NaN;
          %TSMV = ones(1,14)*-99;
          TSMV = NaN(1,14);
          TSMV_V = NaN(1,4);
          TSMVName=NaN;
          %TASVH = ones(1,21)*-99;
          TASVH = NaN(1,21);
          TASVH_V = NaN(1,4);
          TASVHName=NaN;
          %TASVV = ones(1,21)*-99;
          TASVV = NaN(1,21);
          TASVV_V = NaN(1,4);
          TASVVName=NaN;
          %TSLLH = ones(1,10)*-99;
          TSLLH = NaN(1,10);
          TSLLHName=NaN;
          %TSLLV = ones(1,10)*-99;
          TSLLV = NaN(1,10);
          TSLLVName=NaN;
          %TSLLS = ones(1,10)*-99;
          TSLLS = NaN(1,10);
          TSLLSName=NaN;
          %TSLSH = ones(1,10)*-99;
          TSLSH = NaN(1,10);
          TSLSHName=NaN;
          %TSLSV = ones(1,10)*-99;
          TSLSV = NaN(1,10);
          TSLSVName=NaN;
          %TFIX = ones(1,28)*-99;
          TFIX = NaN(1,29);
          TFIXName=NaN;
          for j=1:length(testsDirInfo)
            if length(testsDirInfo(j).name) >= 4 && length(strfind(testsDirInfo(j).name, 'SACCADES')) == 0 && length(strfind(testsDirInfo(j).name, 'STATISTICAL')) == 0
                if strcmp(testsDirInfo(j).name(1:4),"TSVH")
                    if exist(strcat(Dir,"/",infoDir(i).name,'/',patientName, '/', testsDirInfo(j).name, '/', testsDirInfo(j).name, '.csv'),'file')
                      TSVHName = testsDirInfo(j).name
                      r = saccades(strcat(Dir,"/",infoDir(i).name,'/',patientName, '/', testsDirInfo(j).name, '/', testsDirInfo(j).name));
                        %     Lat_x  SD           gain    SD     VPeak, SD   ,Error+, SD     Error- SD    Blinks, fastResponse 
                      TSVH = [r(5),  r(7),        r(37) , r(39), r(10), r(12), r(15), r(17), r(20), r(22), r(1),   r(2)];
                      if vuelta == 1
                        TSVH_V = [r(42),r(44),r(47),r(49)];
                      endif 
                    end
                elseif strcmp(testsDirInfo(j).name(1:4),"TSVV")
                  if exist(strcat(Dir,"/",infoDir(i).name,'/',patientName, '/', testsDirInfo(j).name, '/', testsDirInfo(j).name, '.csv'),'file')
                    TSVVName = testsDirInfo(j).name
                    r = saccades(strcat(Dir,"/",infoDir(i).name,'/',patientName, '/', testsDirInfo(j).name, '/', testsDirInfo(j).name));
                    TSVV = [r(5),  r(7),        r(37) , r(39), r(10), r(12), r(15), r(17), r(20), r(22), r(1),   r(2)];
                    if vuelta == 1
                      TSVV_V = [r(42),r(44),r(47),r(49)];
                    endif
                  endif
                elseif strcmp(testsDirInfo(j).name(1:4),"TSMH")
                  if exist(strcat(Dir,"/",infoDir(i).name,'/',patientName, '/', testsDirInfo(j).name, '/', testsDirInfo(j).name, '.csv'),'file')
                    TSMHName = testsDirInfo(j).name
                    r = memory(strcat(Dir,"/",infoDir(i).name,'/',patientName, '/', testsDirInfo(j).name, '/', testsDirInfo(j).name));
                    TSMH = [r(7), r(9), r(39), r(41), r(12), r(14), r(17), r(19), r(22), r(24), r(1), r(2), r(3), r(4)];
                    if vuelta == 1
                      TSMH_V = [r(44),r(46),r(49),r(51)];
                    endif
                  endif
                elseif strcmp(testsDirInfo(j).name(1:4),"TSMV")
                  if exist(strcat(Dir,"/",infoDir(i).name,'/',patientName, '/', testsDirInfo(j).name, '/', testsDirInfo(j).name, '.csv'),'file')
                    TSMVName = testsDirInfo(j).name
                    r = memory(strcat(Dir,"/",infoDir(i).name,'/',patientName, '/', testsDirInfo(j).name, '/', testsDirInfo(j).name));
                    TSMV = [r(7), r(9), r(39), r(41), r(12), r(14), r(17), r(19), r(22), r(24), r(1), r(2), r(3), r(4)];
                    if vuelta == 1
                      TSMV_V = [r(44),r(46),r(49),r(51)];
                    endif
                  endif
                elseif strcmp(testsDirInfo(j).name(1:5),"TASVH")
                  if exist(strcat(Dir,"/",infoDir(i).name,'/',patientName, '/', testsDirInfo(j).name, '/', testsDirInfo(j).name, '.csv'),'file')
                    TASVHName = testsDirInfo(j).name
                    r = antisaccades(strcat(Dir,"/",infoDir(i).name,'/',patientName, '/', testsDirInfo(j).name, '/', testsDirInfo(j).name));
                    %        Blicks, Correct, Reflexive, Wrong, SoR , Adel, Seccess, corrected,Error,SORa  , anticipat,Lat_x,y(meanAntisaccadeLatency), SD   , Lat_ref, SD   , Δref, SD    , Error+,    SD,   num, Error-, SD  , num   
                    TASVH = [r(1)  , r(2)   , r(3)     , r(4) , r(5), r(6), r(7)   , r(8)     ,r(9) , r(10), r(11)    ,r(22)                          , r(26), r(31)  , r(35), r(40), r(44), r(19) , r(21), r(14), r(16)];
                    if vuelta == 1
                      TASVH_V = [r(47),r(49),r(52),r(54)];
                    endif
                  endif
               elseif strcmp(testsDirInfo(j).name(1:5),"TASVV")
                  if exist(strcat(Dir,"/",infoDir(i).name,'/',patientName, '/', testsDirInfo(j).name, '/', testsDirInfo(j).name, '.csv'),'file')
                    TASVVName = testsDirInfo(j).name
                    r = antisaccades(strcat(Dir,"/",infoDir(i).name,'/',patientName, '/', testsDirInfo(j).name, '/', testsDirInfo(j).name));
                    TASVV = [r(1)  , r(2)   , r(3)     , r(4) , r(5), r(6), r(7), r(8)     ,r(9) , r(10), r(11)    ,r(22)                          , r(26), r(31)  , r(35), r(40), r(44), r(19) , r(21), r(14), r(16)];
                    if vuelta == 1
                      TASVV_V = [r(47),r(49),r(52),r(54)];
                    endif
                  endif
                elseif strcmp(testsDirInfo(j).name(1:5),"TSLLH")
                  if exist(strcat(Dir,"/",infoDir(i).name,'/',patientName, '/', testsDirInfo(j).name, '/', testsDirInfo(j).name, '.csv'),'file')
                    TSLLHName = testsDirInfo(j).name
                    r = tsl(strcat(Dir,"/",infoDir(i).name,'/',patientName, '/', testsDirInfo(j).name, '/', testsDirInfo(j).name));
                    TSLLH = [r(1), r(3), r(4), r(5), r(6), r(2), r(7), r(8), r(9), r(10)];
                  endif
                elseif strcmp(testsDirInfo(j).name(1:5),"TSLLV")
                  if exist(strcat(Dir,"/",infoDir(i).name,'/',patientName, '/', testsDirInfo(j).name, '/', testsDirInfo(j).name, '.csv'),'file')  
                    TSLLVName = testsDirInfo(j).name
                    r = tsl(strcat(Dir,"/",infoDir(i).name,'/',patientName, '/', testsDirInfo(j).name, '/', testsDirInfo(j).name));
                    TSLLV = [r(1), r(3), r(4), r(5), r(6), r(2), r(7), r(8), r(9), r(10)];
                  endif
               elseif strcmp(testsDirInfo(j).name(1:5),"TSLLS")
                 if exist(strcat(Dir,"/",infoDir(i).name,'/',patientName, '/', testsDirInfo(j).name, '/', testsDirInfo(j).name, '.csv'),'file') 
                    TSLLSName = testsDirInfo(j).name
                    r = tsl(strcat(Dir,"/",infoDir(i).name,'/',patientName, '/', testsDirInfo(j).name, '/', testsDirInfo(j).name));
                    TSLLS = [r(1), r(3), r(4), r(5), r(6), r(2), r(7), r(8), r(9), r(10)];
                  endif
               elseif strcmp(testsDirInfo(j).name(1:5),"TSLSH")
                  if exist(strcat(Dir,"/",infoDir(i).name,'/',patientName, '/', testsDirInfo(j).name, '/', testsDirInfo(j).name, '.csv'),'file')
                    TSLSHName = testsDirInfo(j).name
                    r = tsl(strcat(Dir,"/",infoDir(i).name,'/',patientName, '/', testsDirInfo(j).name, '/', testsDirInfo(j).name));
                    TSLSH = [r(1), r(3), r(4), r(5), r(6), r(2), r(7), r(8), r(9), r(10)];
                endif
                elseif strcmp(testsDirInfo(j).name(1:5),"TSLSV")
                   if exist(strcat(Dir,"/",infoDir(i).name,'/',patientName, '/', testsDirInfo(j).name, '/', testsDirInfo(j).name, '.csv'),'file') 
                    TSLSVName = testsDirInfo(j).name
                    r = tsl(strcat(Dir,"/",infoDir(i).name,'/',patientName, '/', testsDirInfo(j).name, '/', testsDirInfo(j).name));
                    TSLSV = [r(1), r(3), r(4), r(5), r(6), r(2), r(7), r(8), r(9), r(10)];
                  endif
                elseif strcmp(testsDirInfo(j).name(1:4),"TFIX")
                  if exist(strcat(Dir,"/",infoDir(i).name,'/',patientName, '/', testsDirInfo(j).name, '/', testsDirInfo(j).name, '.csv'),'file') 
                    TFIXName =testsDirInfo(j).name
                    r = fixation(strcat(Dir,"/",infoDir(i).name,'/',patientName, '/', testsDirInfo(j).name, '/', testsDirInfo(j).name));
                    %    Blinks sacadas  microsacadas  drift  SWJmono SWJbi,  distraccion,  BCEA     ox     oy       centroide,    ampl_m  SD   vmean_m  SD    Vpeak_m         SD  frecuency, ampl_m_d      SD  vmean_d   SD     Vpeak_d, SD  ampl_m_swj    SD  time_SWJ  SD   
                    TFIX = [r(1),  r(2),   r(3),          r(4), r(5),   r(6),      r(29),     r(7) ,  r(27) ,r(28),    r(8), r(9),  r(10), r(11), r(12), r(13),     r(14),      r(15),  r(16),    r(17),   r(18), r(19),  r(20),     r(21), r(22), r(23),     r(24), r(25) ,r(26)];
                  endif
      %          elseif strcmp(testsDirInfo(j).name(1:6),"TOPTHL")
      %              TOPTHLName=testsDirInfo(j).name;
      %              r = Optokinetic(strcat(directory, '/', mainDirInfo(i).name, '/', testsDirInfo(j).name, '/', testsDirInfo(j).name));
      %              TOPTHL = [r(1), r(2), r(3), r(4), r(5), r(6), r(7), r(8), r(9), r(10), r(11), r(12), r(13), r(14), r(15), r(16), r(17), r(18), r(19), r(20)];
      %          elseif strcmp(testsDirInfo(j).name(1:6),"TOPTHR")
      %              TOPTHRName=testsDirInfo(j).name;
      %              r = Optokinetic(strcat(directory, '/', mainDirInfo(i).name, '/', testsDirInfo(j).name, '/', testsDirInfo(j).name));
      %              TOPTHR = [r(1), r(2), r(3), r(4), r(5), r(6), r(7), r(8), r(9), r(10), r(11), r(12), r(13), r(14), r(15), r(16), r(17), r(18), r(19), r(20)];
      %          elseif strcmp(testsDirInfo(j).name(1:6),"TOPTVD")
      %              TOPTVDName=testsDirInfo(j).name;
      %              r = Optokinetic(strcat(directory, '/', mainDirInfo(i).name, '/', testsDirInfo(j).name, '/', testsDirInfo(j).name));
      %              TOPTVD = [r(1), r(2), r(3), r(4), r(5), r(6), r(7), r(8), r(9), r(10), r(11), r(12), r(13), r(14), r(15), r(16), r(17), r(18), r(19), r(20)];
      %          elseif strcmp(testsDirInfo(j).name(1:6),"TOPTVU")
      %              TOPTVUName=testsDirInfo(j).name;
      %              r = Optokinetic(strcat(directory, '/', mainDirInfo(i).name, '/', testsDirInfo(j).name, '/', testsDirInfo(j).name));
      %              TOPTVU = [r(1), r(2), r(3), r(4), r(5), r(6), r(7), r(8), r(9), r(10), r(11), r(12), r(13), r(14), r(15), r(16), r(17), r(18), r(19), r(20)];
                endif
            endif
          endfor
          
        ########################################################fprintf Pablo 
        %fprintf Pablo 
        if fdTSV!=-1 
          %Datos horizontales TSV
          fprintf(fdTSV, '%s,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%d,%d,',patientName,TSVH(1),TSVH(2),TSVH(3),TSVH(4),TSVH(5),TSVH(6),TSVH(7),TSVH(8),TSVH(9),TSVH(10),TSVH(11),TSVH(12));  
          if vuelta == 1 
            fprintf(fdTSV, '%f,%f,%f,%f,',TSVH_V(1),TSVH_V(2),TSVH_V(3),TSVH_V(4));
          endif 
          
          %Datos verticales TSV
          fprintf(fdTSV, '%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%d,%d',TSVV(1),TSVV(2),TSVV(3),TSVV(4),TSVV(5),TSVV(6),TSVV(7),TSVV(8),TSVV(9),TSVV(10),TSVV(11),TSVV(12));     
          if vuelta == 1 
            fprintf(fdTSV, ',%f,%f,%f,%f\n',TSVV_V(1),TSVV_V(2),TSVV_V(3),TSVV_V(4));
          else
            fprintf(fdTSV, '\n');
          endif
        endif
        
        if fdTSM!=-1
          %Datos horizontales TSM
          fprintf(fdTSM, '%s,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%d,%d,%d,%f,',patientName,TSMH(1),TSMH(2),TSMH(3),TSMH(4),TSMH(5),TSMH(6),TSMH(7),TSMH(8),TSMH(9),TSMH(10),TSMH(11),TSMH(12),TSMH(13),TSMH(14));
          if vuelta == 1 
            fprintf(fdTSM, '%f,%f,%f,%f,',TSMH_V(1),TSMH_V(2),TSMH_V(3),TSMH_V(4));
          endif 
          
          %Datos verticales TSM
          fprintf(fdTSM, '%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%d,%d,%d,%f',TSMV(1),TSMV(2),TSMV(3),TSMV(4),TSMV(5),TSMV(6),TSMV(7),TSMV(8),TSMV(9),TSMV(10),TSMV(11),TSMV(12),TSMV(13),TSMV(14));
          if vuelta == 1 
            fprintf(fdTSM, ',%f,%f,%f,%f\n',TSMV_V(1),TSMV_V(2),TSMV_V(3),TSMV_V(4));
          else
            fprintf(fdTSM, '\n');
          endif
        endif
        
        if fdTAS!=-1
          %Datos horizontales TAS
          fprintf(fdTAS, '%s,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%d,%d,%d,%d,%d,%d,%f,%f,%f,%f,%f,',patientName,TASVH(12),TASVH(13),TASVH(14),TASVH(15),TASVH(16),TASVH(17),TASVH(18),TASVH(19),TASVH(20),TASVH(21),TASVH(1),TASVH(2),TASVH(3),TASVH(4),TASVH(5),TASVH(6),TASVH(7),TASVH(8),TASVH(9),TASVH(10),TASVH(11));
          if vuelta == 1 
            fprintf(fdTAS, '%f,%f,%f,%f,',TASVH_V(1),TASVH_V(2),TASVH_V(3),TASVH_V(4));
          endif
          
          %Datos verticales TAS
          fprintf(fdTAS, '%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%d,%d,%d,%d,%d,%d,%f,%f,%f,%f,%f',TASVV(12),TASVV(13),TASVV(14),TASVV(15),TASVV(16),TASVV(17),TASVV(18),TASVV(19),TASVV(20),TASVV(21),TASVV(1),TASVV(2),TASVV(3),TASVV(4),TASVV(5),TASVV(6),TASVV(7),TASVV(8),TASVV(9),TASVV(10),TASVV(11));
          if vuelta == 1 
            fprintf(fdTAS, ',%f,%f,%f,%f\n',TASVV_V(1),TASVV_V(2),TASVV_V(3),TASVV_V(4));
          else
            fprintf(fdTAS, '\n');
          endif
        endif
        
        if fdTSL!=-1
          %Datos horizontales TSLS
          fprintf(fdTSL, '%s,%d,%f,%d,%d,%d,%f,%f,%f,%f,%f,',patientName,TSLSH(1), TSLSH(2), TSLSH(3), TSLSH(4), TSLSH(5), TSLSH(6), TSLSH(7), TSLSH(8), TSLSH(9), TSLSH(10));
          
          %Datos verticales TSLS
          fprintf(fdTSL, '%d,%f,%d,%d,%d,%f,%f,%f,%f,%f,', TSLSV(1), TSLSV(2), TSLSV(3), TSLSV(4), TSLSV(5), TSLSV(6), TSLSV(7), TSLSV(8), TSLSV(9), TSLSV(10));
          
          %Datos horizontales TSLL
          fprintf(fdTSL, '%d,%f,%d,%d,%d,%f,%f,%f,%f,%f,',TSLLH(1), TSLLH(2), TSLLH(3), TSLLH(4), TSLLH(5), TSLLH(6), TSLLH(7), TSLLH(8), TSLLH(9), TSLLH(10));
          
          %Datos verticales TSLL
          fprintf(fdTSL, '%d,%f,%d,%d,%d,%f,%f,%f,%f,%f,', TSLLV(1), TSLLV(2), TSLLV(3), TSLLV(4), TSLLV(5), TSLLV(6), TSLLV(7), TSLLV(8), TSLLV(9), TSLLV(10));
          
          %Datos TSLLS
          fprintf(fdTSL, '%d,%f,%d,%d,%d,%f,%f,%f,%f,%f\n',TSLLS(1), TSLLS(2), TSLLS(3), TSLLS(4), TSLLS(5), TSLLS(6), TSLLS(7), TSLLS(8), TSLLS(9), TSLLS(10));                                       
        endif
        
        if fdTFIX!=-1
          fprintf(fdTFIX, '%s,%d,%d,%d,%d,%d,%d,%d,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f\n',patientName,TFIX(1),TFIX(2),TFIX(3),TFIX(4),TFIX(5),TFIX(6),TFIX(7),TFIX(8),TFIX(9),TFIX(10),TFIX(11),TFIX(12),TFIX(13),TFIX(14),TFIX(15),TFIX(16),TFIX(17),TFIX(18),TFIX(19),TFIX(20),TFIX(21),TFIX(22),TFIX(23),TFIX(24),TFIX(25),TFIX(26),TFIX(27),TFIX(28),TFIX(29));
        endif
        
%            fprintf(fdTOP, '%s,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,',patientName,TOPTHL(1), TOPTHL(2), TOPTHL(3), TOPTHL(4), TOPTHL(5), TOPTHL(6), TOPTHL(7), TOPTHL(8), TOPTHL(9), TOPTHL(10), TOPTHL(11), TOPTHL(12), TOPTHL(13), TOPTHL(14), TOPTHL(15), TOPTHL(16), TOPTHL(17), TOPTHL(18), TOPTHL(19), TOPTHL(20));
%            fprintf(fdTOP, '%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,',TOPTHR(1), TOPTHR(2), TOPTHR(3), TOPTHR(4), TOPTHR(5), TOPTHR(6), TOPTHR(7), TOPTHR(8), TOPTHR(9), TOPTHR(10), TOPTHR(11), TOPTHR(12), TOPTHR(13), TOPTHR(14), TOPTHR(15), TOPTHR(16), TOPTHR(17), TOPTHR(18), TOPTHR(19), TOPTHR(20));
%            fprintf(fdTOP, '%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,',TOPTVD(1), TOPTVD(2), TOPTVD(3), TOPTVD(4), TOPTVD(5), TOPTVD(6), TOPTVD(7), TOPTVD(8), TOPTVD(9), TOPTVD(10), TOPTVD(11), TOPTVD(12), TOPTVD(13), TOPTVD(14), TOPTVD(15), TOPTVD(16), TOPTVD(17), TOPTVD(18), TOPTVD(19), TOPTVD(20));
%            fprintf(fdTOP, '%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f\n',TOPTVU(1), TOPTVU(2), TOPTVU(3), TOPTVU(4), TOPTVU(5), TOPTVU(6), TOPTVU(7), TOPTVU(8), TOPTVU(9), TOPTVU(10), TOPTVU(11), TOPTVU(12), TOPTVU(13), TOPTVU(14), TOPTVU(15), TOPTVU(16), TOPTVU(17), TOPTVU(18), TOPTVU(19), TOPTVU(20));        
          
        endif  
      endfor
      if fdTSV!=-1
        fclose(fdTSV);
      endif
      if fdTSM!=-1
        fclose(fdTSM);
      endif
      if fdTAS!=-1
        fclose(fdTAS);
      endif
      if fdTSL!=-1
        fclose(fdTSL);
      endif
      if fdTFIX!=-1
        fclose(fdTFIX);
      endif
    %    fclose(fdTOP);
    endif
  endfor
  
endif