To reproduce the study carried out on the jaguars of Taiamã, follow these steps:

1. Prepare the database in MySQL:
    a) execute the backup script of the land cover tables. In the 'dataset' folder,
select the 'dump_table_soil_cover_Taiama.sql' script and run on MySQL.
    b) execute the data preparation and manipulation script. In the 'dataset' folder,
select the script 'script_proc_AnimalMoveMiner_english.sql' and run on MySQL.

2. Prepare the environment for RStudio: the files for executing the algorithm are in the 'algorithm' folder.

3. When executing the algorithm 'Algoritmo_AniMoveMineR_English_v.1.0.Rmd' with the 'Knit with parameters' select
the jaguar movement data file, contained in the 'Animal_Move_Data_Prepared.csv' file in the 'dataset' folder.


*** The animal movement data set was extracted from DOI: 10.1002/ecy.2379 and also at Dryad Digital Repository (https://doi.org/10.5061/dryad.2dh0223)
*** The land cover data set from Taiamã was obtained from the map extracted from the "MapBiomas Project - Collection 4.1 of the Annual Series of Coverage and 
*** Land Use Maps in Brazil, accessed on 06/07/20 through the link: https://mapbiomas.org/”. This project is a multi-institutional initiative 
*** to generate annual maps of land cover and use from automatic classification processes applied to images of satellite. 
*** The shapefile was used to extract the classification soil cover data using the R routine. The data set was stored in tables: classif_cobertura_solo and 
*** TB_RST_MovAnimal_Estado_CopiA

