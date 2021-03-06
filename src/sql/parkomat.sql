/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Parkomaty
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

CREATE TABLE export_parkomat (
    geom geometry,
    amenity text DEFAULT 'vending_machine',
    vending text DEFAULT 'parking_tickets',
    source text DEFAULT 'IPR',
    "source:loc" text DEFAULT 'IPR'
    )

/*===================================================================*/

INSERT INTO export_parkomat(geom)
SELECT geom 
FROM ipr.dop_zps_automaty_b
