CREATE OR REPLACE TYPE dz_kml_data FORCE
AUTHID CURRENT_USER
AS OBJECT (
    data_name                VARCHAR2(4000 Char)
   ,data_display_name        VARCHAR2(4000 Char)
   ,data_value_number        NUMBER
   ,data_value_string        VARCHAR2(4000 Char)
   ,data_value_date          DATE
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   ,CONSTRUCTOR FUNCTION dz_kml_data
    RETURN SELF AS RESULT
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   ,CONSTRUCTOR FUNCTION dz_kml_data(
        p_data_name    IN  VARCHAR2
       ,p_data_value   IN  VARCHAR2
    ) RETURN SELF AS RESULT
    
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   ,CONSTRUCTOR FUNCTION dz_kml_data(
        p_data_name    IN  VARCHAR2
       ,p_data_value   IN  NUMBER
    ) RETURN SELF AS RESULT
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   ,CONSTRUCTOR FUNCTION dz_kml_data(
        p_data_name    IN  VARCHAR2
       ,p_data_value   IN  DATE
    ) RETURN SELF AS RESULT
    
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   ,MEMBER FUNCTION toKML(
       p_pretty_print  IN NUMBER DEFAULT NULL
    ) RETURN CLOB

);
/

GRANT EXECUTE ON dz_kml_data TO PUBLIC;

