CREATE OR REPLACE TYPE dz_kml_folder FORCE
AUTHID CURRENT_USER
AS OBJECT (
    folder_id                VARCHAR2(4000 Char)
   ,folder_name              VARCHAR2(4000 Char)
   ,folder_style_url         VARCHAR2(4000 Char)
   ,folder_visibility        NUMBER
   ,folder_open              NUMBER
   ,folder_description       VARCHAR2(4000 Char)
   ,folder_style             VARCHAR2(4000 Char)
   ,folder_data              dz_kml_data_list
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   ,CONSTRUCTOR FUNCTION dz_kml_folder
    RETURN SELF AS RESULT
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   ,CONSTRUCTOR FUNCTION dz_kml_folder(
       p_folder_name        IN  VARCHAR2
    ) RETURN SELF AS RESULT

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   ,MEMBER FUNCTION toKML(
        p_payload           IN  CLOB     DEFAULT NULL
       ,p_inline_style      IN  VARCHAR2 DEFAULT 'FALSE'
       ,p_pretty_print      IN  NUMBER   DEFAULT NULL
    ) RETURN CLOB

);
/

GRANT EXECUTE ON dz_kml_folder TO PUBLIC;

