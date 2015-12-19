CREATE OR REPLACE TYPE dz_kml_data_list FORCE
AS 
TABLE OF dz_kml_data;
/

GRANT EXECUTE ON dz_kml_data_list TO PUBLIC;

