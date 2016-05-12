/* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  Vybere budovy v Praze ze všech v ČR (z OSM)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

create table praha_building_osm(
		gid int primary key,
		geom geometry,
		building text,
		"building:height" text,
        "building:part" text) ;
		
		
Insert into praha_building_osm

select  B.gid, 
        B.geom,
        B.building, 
        B.height,
        B.part

from(	select gid,geom,building, height 
			from osm.czech_polygon
			where building is not null
		) as B

join( 	select gid,geom,name 
			from osm.czech_polygon 
			where name like 'Hlavní město Praha' ) as P

on ST_Within(B.geom, P.geom);

/* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  Vybere budovy z OSM pro danou oblast ze všech budov v Praze
    ..ale jen ty co nejsou building:part a nemají definovanou building:height
     a vytvoří okolo každé z nich bufeer 5m           
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
/*         toto -- čislo se bude měnit podle čísla datasetu bd3_prah--  */              
create table bud73_OSM(
                gid int primary key,
                geom geometry,
                building text	);

insert into bud73_OSM
select  budovy.gid, 
        ST_Buffer(budovy.geom,3) as geom, /* hodnota 3 m se může volit od 0 do těch 5m */
        budovy.building
from(   select	ST_MakeEnvelope(
                        max(ST_XMax(geom))+100 ,    max(ST_YMax(geom))+100 , 
                        min(ST_XMin(geom))-100 ,    min(ST_YMin(geom))-100 , /* to je zvětšení hranice o 100m */
                        5514 ) as geom 
        from ipr.bd3_prah73   /* hranice  okolo IPR budov */ 
    ) as hranice
join(   select  gid, 
                ST_Transform(geom,5514) as geom,
                building
        from jakl.praha_building_osm
        where  "building:part" is null              /* vybere jen ty co nejsou součastí (part) relace a nemaji definovanou vyšku */
          and  "building:height" is null
    ) as budovy
on ST_Within(budovy.geom , hranice.geom);

/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        Vytvoří jeden polygon pro každou jednu budovu  (IPR)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

create table bud73_IPR(
             id_bud int,
             geom geometry);

insert into bud73_IPR
select  id_bud,
        ST_Union(                                       /* spojí polygony */
            ST_Buffer(                           
                ST_Force_2D(                            /* vybere jen X,Y souřadnice */   
                    ST_MakeValid(geom)),0.1)) as geom   /* bylo potřeba opravit*/
from   ipr.bd3_prah73
where  typ like '%stresni%'
group by id_bud;

/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Vytvoří tabulku která již spojít [gid] budov z OSM		
                        s [id_bud] budov z IPR, které jsou uvnitř	

... pro jednu budovu z OSM může být více budov z IPR	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

create table gid_id(
		    gid int,
		    id_bud int);

insert into gid_id
select	AAA.gid,
			BBB.id_bud
from  jakl.bud73_osm 	as AAA
join  jakl.bud73_ipr			as BBB
on ST_Within(BBB.geom , AAA.geom);

/* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	    Vytvoří tabulku kde jsou [gid] budov z OSM  a vysky prevzdaté z IPR 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 	*/

create table osm_height(	
			gid int primary key,
			building_height 	real	);

Insert into osm_height
select	budovy.gid,
			vysky.height
from(	select *
			from  gid_id
			where gid in (	select gid      /* vybere jen ty OSM budovy co mají v sobě jednu budovu z IPR */
										from gid_id
										group by gid
										having count(gid)=1	)       
		) as budovy
join(	select	id_bud,	
						max(maxZ) - min(minZ) as Height
			from(	select	id_bud,
									ST_ZMax(geom) as maxZ,
									ST_ZMin(geom) as minZ
						from   ipr.bd3_prah73
					) as max_min
			group by id_bud
		) as vysky			
on budovy.id_bud = vysky.id_bud;

/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		nakonec Získaná data přidá do původní tabulky budov z OSM 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

update praha_building_osm
SET "building:height" = building_height
from osm_height
where osm_height.gid = praha_building_osm.gid;

/*=========================================================
    nakonec odstraní všechny dočasné tabulky
======================================================*/
drop table bud73_osm;
drop table bud73_ipr;
drop table gid_id;
drop table osm_height;

/* 
skript lze spustit vícekrát zasebou .. a postpně zvětšovat buffer kolem OSM budov,
 aby to nalezlo budovy z IPR
*/




