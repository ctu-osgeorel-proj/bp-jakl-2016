/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%% TOILETS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

CREATE TABLE export_toilets (
    geom geometry,
    amenity text DEFAULT 'toilets',
    "access" text DEFAULT 'yes',
    fee text DEFAULT null,
    "fee:price" text DEFAULT null,
    wheelchair text DEFAULT 'no',
    opening_hours text,
    operator text,
    description text,
    source text DEFAULT 'IPR',
    "source:loc" text DEFAULT 'IPR'
    )

/*===================================================================*/

INSER INTO jakl.export_toilets(
    "geom",
    "amenity",
    "access",
    "fee",
    "fee:price",
    "wheelchair",
    "opening_hours",
    "operator",
    "description",
    "source",
    "source:loc"
)


SELECT  "geom",

        CASE WHEN true THEN 'toilets' END AS amenity,

        CASE WHEN poskyt LIKE '%HMP%' THEN 'yes' ELSE 'permisive' END AS access ,

        CASE WHEN cena LIKE '%Kè%' THEN 'yes' ELSE 'no' END AS fee,

        CASE	WHEN cena LIKE '%20%'   THEN '20 Kč'  
		        WHEN cena LIKE '%15%' 	THEN '15 Kč' 
		        WHEN cena LIKE '%10%' 	THEN '10 Kč'
		        WHEN cena LIKE '%8%'	THEN '8 Kč'
		        WHEN cena LIKE '%5%'	THEN '5 Kč'
		        WHEN cena LIKE '%3%'	THEN '3 Kč'
		                                ELSE null
	        END AS charge,

        CASE WHEN (vozickari=1) THEN 'yes' ELSE 'no' END AS wheelchair ,

        CASE WHEN ((otevreno = 'nonstop') 
                OR (otevreno LIKE '%:%') 
                OR (otevreno LIKE '% h%') ) THEN (
                    REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
                    REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
                    REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
                    REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(otevreno,	
                        ': ',' '),
                        ' (nejisté)',''),
                        'nonstop','0:00-24:00'), 
	                    'leden','Jan '),
                     	'únor','Feb '), 
                        'březen','Mar '), 
                        'duben','Apr '), 
                        'květen','May '), 
                        'červen','Jun '),
	                    'červenec','Jul '), 
                        'srpen','Aug '), 
                        'září','Sep '), 
                        'říjen','Oct '),  
                        'listopad','Nov '), 
                        'prosinec','Dec '),
	                    'po','Mo '),
                        'út','Tu '),
                        'st','We '),
                        'čt','Th '),
                        'pá','Fr '),
                        'so','Sa '),
                        'ne','Su '),
                        'denně', 'Mo-Sa'),
	                    '+dušičky',''),
                        ',', ' ; '),
                        '(zima)','Dec-Mar'),
                        '(léto)','Jun-Oct'),
                        '(orientačně)',''),
                        ' -','-')               ) 
			                                ELSE null END AS opening_hours,
 
        CASE WHEN poskyt LIKE '%HMP%' THEN 'Hlavní Město Praha' ELSE null END AS operator,

        ACE(REPLACE(adresa, '', '"') ) AS description,

        CASE WHEN true THEN 'IPR' END AS source, 

        CASE WHEN true THEN 'IPR' END AS "source:loc" 

FROM ipr.fsv_verejnawc_b
