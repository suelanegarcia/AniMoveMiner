        
/*###################################################################################################################
### AUTOR: SUELANE GARCIA FONTES   DATA: 29/11/2019
### FINALIDADE: CRIA A ESTRUTURA E ROTINAS DO BANCO DE DADOS QUE APOIAM A EXECUÇÃO DO ALGORITMO ANIMOMOVEMINER
### DEVE SER EXECUTADO UMA UNICA VEZ - ANTES DO USO DO ANIMOVEMINER - PREPARADO PARA O MYSQL
#####################################################################################################################

****  VIEW WITH ANIMAL MOVEMENT DATA ****
	CREATE OR REPLACE VIEW tb_mov_animal AS
	SELECT cast(location_lat as double) as lat , cast(location_long as double) as lon, 
    individual, timestamp as date FROM  tb_jaguar where year(timestamp) = 2015  order by timestamp;

**** VIEW WITH FACTORS DATA  ****
	CREATE OR REPLACE VIEW tb_data_factor (id, lat, lon, datetime, factor , yearF, monF) AS
	select id, null, null, datetime, status, year(datetime), month(datetime) 
	From monk_panama_rain where ra <> 0 and year(datetime) = 2004;			
*/

/*###################################################################################################################
### 
### *******************************************  PREPARE THE DATABASE  ********************************************
### 
#####################################################################################################################*/

DELIMITER $$
DROP PROCEDURE if exists PrepareDB$$
CREATE PROCEDURE PrepareDB()
BEGIN 
--  *****************************  DELETE AUXILIAR TABLES  ******************************
	  DROP TABLE IF EXISTS TB_RST_MovAnimal_Estado;
      DROP TABLE IF EXISTS TBPeriodState;
      DROP TABLE IF EXISTS TB_Periodo_Freq; 
      DROP TABLE IF EXISTS TB_Rule_Animal_Neighbor_Animal;
      DROP TABLE IF EXISTS tb_fator_ambiente;
      DROP TABLE IF EXISTS tb_animal_movement;
      DROP TABLE IF EXISTS tb_rule_animal_neighbor_animal_anual;
      
	       
--  *********************  CREATE TABLE TO STORE THE DISTANCE VALUE BETWEEN THE ANIMALS  ******************************        
       create table if NOT EXISTS  TB_Distancia_Animal (
						seq int primary key auto_increment, 
						ind1 varchar(20), 
						lat1 double, 
						lon1 double, 
						date1 datetime, 
						vstate1 varchar(30),
						ind2 varchar (20), 
						lat2 double, 
						lon2 double,	
						date2 datetime, 
						vstate2 varchar(30),              
						dist double);  
                     
--  *********************  CREATE TABLE TO STORE THE DISTANCE VALUE BETWEEN THE ANIMALS AND FACTORS********************             
        CREATE TABLE IF NOT EXISTS TB_Distance_Animal_Factor (
				seq int primary key auto_increment, 
				id varchar(20), 
				lat double, 
				lon double, 
				date datetime, 
                monF int, 
                yearF int, 
                state varchar(30),
               	factor varchar (20), 
				dist double
	  );                 

  DELETE FROM TB_Distancia_Animal;
  DELETE FROM TB_Distance_Animal_Factor;
        
END$$
DELIMITER ;
 

/*#####################################################################################################################
### 
### *****************************  IDENTIFY THE DISTANCE BETWEEN ANIMALS ********************************************
### 
#####################################################################################################################*/

DELIMITER $$
DROP PROCEDURE if exists calculaDistancia$$
CREATE PROCEDURE `calculaDistancia`(min_before integer, min_after integer)
BEGIN
	DECLARE done INT DEFAULT 0;
	DECLARE done2 INT DEFAULT 0;
	DECLARE vdate1 datetime;
	DECLARE vdate2 datetime;
	DECLARE vlat1 double;
	DECLARE vlat2 double;
	DECLARE vind1 varchar(30);
	DECLARE vind2  varchar(30);
	DECLARE vlong1 double;
	DECLARE vlong2 double;
    DECLARE vestado1 varchar(30);
    DECLARE vestado2 varchar(30); 
	DECLARE count double DEFAULT 1;

	BEGIN 
				DECLARE curs CURSOR FOR (SELECT distinct  lat as x, lon as y, individual as id, timestamp as date, estado 
                                         FROM TB_RST_MovAnimal_Estado);
				DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

				DELETE FROM TB_Distancia_Animal; 

				OPEN curs;

				first_cur:REPEAT
					FETCH curs INTO  vlat1, vlong1, vind1, vdate1, vestado1;
						IF NOT done THEN	
							BEGIN 
								-- <calc the distance> --      
								DECLARE curs2 CURSOR FOR (
								SELECT   A.lat as x, A.lon as y, A.individual as id, A.timestamp as date, A.estado from TB_RST_MovAnimal_Estado A						                             
								where  DATE_FORMAT( A.timestamp, '%Y%m%d') = DATE_FORMAT( vdate1, '%Y%m%d') and 
								A.timestamp between DATE_SUB(vdate1, INTERVAL min_before MINUTE) and DATE_ADD(vdate1, INTERVAL min_after MINUTE)
                                and not exists (select ind1 from TB_Distancia_Animal where ind2 = vind1 and date2 = vdate1));	
                                
								DECLARE CONTINUE HANDLER FOR NOT FOUND SET done2 = 1;					
								OPEN curs2;
								second_cur:REPEAT
								FETCH curs2 INTO vlat2, vlong2, vind2, vdate2, vestado2;
									IF NOT done2 THEN
												INSERT INTO TB_Distancia_Animal (ind1, lat1, lon1, date1, vstate1, ind2, lat2, lon2,  date2, vstate2,  dist) 
												SELECT vind1, vlat1, vlong1, vdate1, vestado1, vind2, vlat2, vlong2, vdate2, vestado2,  
												VINCENTY(vlat1, vlong1, vlat2, vlong2) AS dist;
									END IF;                 
								SET count = count + 1; 
								UNTIL done2 
								END REPEAT second_cur;               
								CLOSE curs2;
								set done2 = 0;
								 
							END;
						END IF;
				UNTIL done
				END REPEAT first_cur;	
				CLOSE curs;
		end;
 
end
$$

/*###################################################################################################################
### 
### ***************************** IDENTIFY THE DISTANCE BETWEEN ANIMALS AND FACTORS**********************************
### 
#####################################################################################################################*/

DELIMITER $$
DROP PROCEDURE IF EXISTS  Animal_Neighbor_Factor$$
CREATE PROCEDURE Animal_Neighbor_Factor(IN pmin_before int, IN pmin_after int, IN pdist int) 
BEGIN 
    DECLARE vid VARCHAR(30);
	DECLARE vlat decimal(14,4);
    DECLARE vlon decimal(14,4);
	DECLARE vdatetime datetime;
    DECLARE vyearF int;
    DECLARE vmonF int;    
    
    -- verify which columns need consider
	select id, lat, lon, datetime, yearF, monF into vid, vlat, vlon, vdatetime, vyearF, vmonF
	from tb_data_factor order by lat desc, lon desc, datetime desc limit 1; 
    
    delete from tb_distance_Animal_Factor;
     
     -- TEST SITUATIONS:
    -- ####  Situation 1: distance (lat/lon) and time (datetime) ####
	IF (vlat is not null and vlon is not null and vdatetime is not null) THEN 
		 INSERT INTO tb_distance_Animal_Factor (id, lat, lon, date, monF, yearF, state, factor, dist)
		 SELECT  A.individual id, A.lat, A.lon, A.timestamp, month(A.timestamp) monF, 
				 year(A.timestamp) yearF, A.estado, B.factor, VINCENTY(A.lat, A.lon, B.lat, B.lon) dist
		 FROM TB_rst_movanimal_estado A, tb_data_factor B
         where date(A.timestamp) = date( B.datetime) and 
                B.datetime between DATE_SUB(A.timestamp, INTERVAL pmin_before MINUTE) and 
								   DATE_ADD(A.timestamp, INTERVAL pmin_after MINUTE) and 
                                   VINCENTY(A.lat, A.lon, B.lat, B.lon) < pdist 				
		group by A.individual, A.lat, A.lon   order by A.timestamp desc  limit 1;         
        
	-- ####    Situation 2: no distance and time (datetime)   ####    
    ELSEIF (vlat is null and  vlon is null and vdatetime is not null) THEN 
		 call recoveryFactorAroundAnimal(pmin_before, pmin_after);
    END IF;
    
END$$

call Animal_Neighbor_Factor (15, 15, 0.400)
/*###################################################################################################################
### 
### *****************************   VERIFY FACTORS AROUND ANIMAL MOVEMENT POINTS                  *******************
### 
#####################################################################################################################*/
DELIMITER $$
DROP PROCEDURE if exists recoveryFactorAroundAnimal$$
CREATE PROCEDURE `recoveryFactorAroundAnimal`(min_before integer, min_after integer)
BEGIN
	DECLARE done INT DEFAULT 0;
	DECLARE vdate1 datetime;
	DECLARE vlat1 double;
	DECLARE vind1 varchar(30);
	DECLARE vlong1 double;
	DECLARE vestado1 varchar(30);
    DECLARE vstatus varchar(30); 
	DECLARE count double DEFAULT 1;

	BEGIN 
			DECLARE curs CURSOR FOR (SELECT distinct lat as x, lon as y, individual as id, timestamp as date, estado 
                                     FROM TB_RST_MovAnimal_Estado);                                         
			DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
			OPEN curs;

			first_cur:REPEAT
				FETCH curs INTO  vlat1, vlong1, vind1, vdate1, vestado1;
					IF NOT done THEN	
						BEGIN 
							SET vstatus = (select factor from tb_data_factor  
											where   date(datetime) = date(vdate1) and   
													datetime between DATE_SUB(vdate1, INTERVAL min_before MINUTE) and
													DATE_ADD(vdate1, INTERVAL min_after MINUTE)
                                                    order by datetime desc limit 1);
                                                         
							INSERT INTO tb_distance_Animal_Factor (id, lat, lon, date, monF, yearF, state, factor, dist) 
							SELECT vind1, vlat1, vlong1, vdate1, month(vdate1), year(vdate1), vestado1, vstatus, null AS dist;						               
							SET count = count + 1; 		
						END;
					END IF;
				UNTIL done
				END REPEAT first_cur;	
				CLOSE curs;
		end;
end
$$

/*###################################################################################################################
### 
### *****************************   VINCENTY FORMULA - CALCULATE THE DISTANCE BETWEEN TWO POINTS  *******************
### 
#####################################################################################################################*/

DELIMITER $$
DROP FUNCTION IF EXISTS vincenty$$
CREATE FUNCTION vincenty(
        lat1 FLOAT, lon1 FLOAT,
        lat2 FLOAT, lon2 FLOAT
     ) RETURNS FLOAT
    NO SQL
    DETERMINISTIC
    COMMENT 'Returns the distance in degrees on the Earth between two known points
             of latitude and longitude using the Vincenty formula. Multiply by 111.045 to convert to KM 
             from http://en.wikipedia.org/wiki/Great-circle_distance 
             http://www.plumislandmedia.net/mysql/vicenty-great-circle-distance-formula/'
BEGIN
    RETURN 111.045 * 
    DEGREES(
		ATAN2(
			SQRT(
				POW(COS(RADIANS(lat2))*SIN(RADIANS(lon2-lon1)),2) +  
				POW(
					COS(RADIANS(lat1))*SIN(RADIANS(lat2)) - 
					(SIN(RADIANS(lat1))*COS(RADIANS(lat2)) * COS(RADIANS(lon2-lon1))),
				2) 
			), 
				SIN(RADIANS(lat1))*SIN(RADIANS(lat2)) + COS(RADIANS(lat1))*COS(RADIANS(lat2))*COS(RADIANS(lon2-lon1))
			) 
	); 
END$$
DELIMITER ;

/*###################################################################################################################
### 
### *********************************      IDENTIFY THE PERIOD OF DAY 			   **********************************
### 
#####################################################################################################################*/
	              
DELIMITER $$
DROP PROCEDURE if exists calcTotalStatePeriod$$
CREATE PROCEDURE `calcTotalStatePeriod`()
BEGIN
								
alter table TBPeriodState add periodo char(2);
						
update TBPeriodState set periodo =  
(CASE WHEN Time(minSeq) >= '06:00:00' and  Time(maxSeq) <= '17:59:59' THEN 'D'
			            WHEN Time(minSeq) >= '18:00:00' and  Time(maxSeq) <= '23:59:59' THEN 'N' 
                        WHEN Time(minSeq) >= '00:00:00' and  Time(maxSeq) <= '05:59:59' THEN 'N'  ELSE 'DN' END);
    
select  yearmonidest, periodo,  count(periodo) total, ((count(periodo)/(select count(A.mon) 
                                                 From TBPeriodState  A 
                                                 where A.yearid =   TBPeriodState.yearid and 
													   A.mon = TBPeriodState.mon
                                                  group by yearid, mon)) * 100) total_perc
From  TBPeriodState group by yearmonidest, periodo
order by yearmonidest, total desc;

END$$




/*###################################################################################################################
### 
### *********************************      IDENTIFY THE SEASON BY PERIOD OF DAY   **********************************
### 
#####################################################################################################################*/
	              
DELIMITER $$
DROP PROCEDURE if exists calcTotalStateBySeasonPeriod$$
CREATE PROCEDURE `calcTotalStateBySeasonPeriod`()
BEGIN
	
-- alter table TBPeriodState add season varchar(10);

update TBPeriodState set season =  (CASE WHEN mon BETWEEN 1 AND 3 THEN 'Cheia' 
WHEN mon BETWEEN 4  AND 5  THEN 'Baixa'
WHEN mon BETWEEN 6  AND 9  THEN 'Seca'
WHEN mon BETWEEN 10 AND 12 THEN 'Enchente' END);

select  yearId,estado, season, 
(CASE WHEN periodo = 'D' THEN 'Dia' WHEN periodo = 'N' THEN 'Noite' WHEN periodo = 'DN' THEN 'Dia/Noite' END) periodo, 
 count(periodo) total, ((count(periodo)/(select count(A.season) 
                                                 From TBPeriodState  A 
                                                 where A.yearid =   TBPeriodState.yearid and 
													   A.season = TBPeriodState.season
                                                  group by yearid, season)) * 100) total_perc
From  TBPeriodState group by yearId, season, periodo
order by yearId, season, periodo, total desc;

END$$

call calcTotalStateBySeasonPeriod();