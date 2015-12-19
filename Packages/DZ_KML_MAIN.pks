CREATE OR REPLACE PACKAGE dz_kml_main
AUTHID CURRENT_USER
AS

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   /*
   header: DZ_KML
     
   - Build ID: DZBUILDIDDZ
   - TFS Change Set: DZTFSCHANGESETDZ
   
   Utility for the exchange of geometries between Oracle Spatial and OGC
   Keyhole Markup Language.  Originally written for 10g to produce KML from SDO
   and the reverse never implemented beyond a stub to 
   SDO_UTIL.FROM_KMLGEOMETRY added with 11g.
   
   */
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   /*
   Function: dz_kml_main.geokml2sdo

   Wrapper around SDO_UTIL.FROM_KMLGEOMETRY intended for future expansion.

   Parameters:

      p_input - KML geometry text submitted as CLOB
      
   Returns:

      MDSYS.SDO_GEOMETRY
      
   */
   FUNCTION geokml2sdo(
      p_input            IN  CLOB
   ) RETURN MDSYS.SDO_GEOMETRY;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   /*
   Function: dz_kml_main.sdo2geokml

   Pure PLSQL utility for generating KML geometries from SDO_GEOMETRY.  This 
   was written before the addition of SDO_UTIL.TO_KMLGEOMETRY in 11gR2.
   This version provides more flexibility overall in managing precision and 3D
   options with KML.

   Parameters:

      p_input - input SDO_GEOMETRY to convert to KML
      p_pretty_print - optional flag to produce XML in pretty printed format
      p_2d_flag - optional flag to remove 3D information from input
      p_prune_number - optional value to prune all vertice precision too
      p_extrude - value to set for extrude in KML, default is 'false'
      p_tessellate - value to set for tesselate in KML, default is 'true'
      p_altitudemode - value to set for altitudemode, default is 'clampToGround'
      
   Returns:

      CLOB value of KML geometry
      
   */
   FUNCTION sdo2geokml(
       p_input            IN  MDSYS.SDO_GEOMETRY
      ,p_pretty_print     IN  NUMBER   DEFAULT NULL
      ,p_2d_flag          IN  VARCHAR2 DEFAULT 'TRUE'
      ,p_prune_number     IN  NUMBER   DEFAULT NULL
      ,p_extrude          IN  VARCHAR2 DEFAULT 'false'
      ,p_tessellate       IN  VARCHAR2 DEFAULT 'true'
      ,p_altitudemode     IN  VARCHAR2 DEFAULT 'clampToGround'
   ) RETURN CLOB;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   /*
   Function: dz_kml_main.value2kmldata

   Pure PLSQL utility for generating KML data element.

   Parameters:

      p_name - name to apply to the KML data element
      p_input - value to apply to KML data element, may be VARCHAR2, NUMBER
      or DATE. 
      p_pretty_print - optional flag to produce XML in pretty printed format
      p_null_handling - optional TRUE/FALSE flag to produce a null XML Data
      tag or simply skip XML tag generation altogether.
      
   Returns:

      CLOB value of KML data element
      
   */
   FUNCTION value2kmldata(
       p_name             IN  VARCHAR2
      ,p_input            IN  VARCHAR2
      ,p_pretty_print     IN  NUMBER   DEFAULT 0
      ,p_null_handling    IN  VARCHAR2 DEFAULT 'FALSE'
   ) RETURN CLOB;
   
   FUNCTION value2kmldata(
       p_name             IN  VARCHAR2
      ,p_input            IN  NUMBER
      ,p_pretty_print     IN  NUMBER   DEFAULT 0
      ,p_null_handling    IN  VARCHAR2 DEFAULT 'FALSE'
   ) RETURN CLOB;
   
   FUNCTION value2kmldata(
       p_name             IN  VARCHAR2
      ,p_input            IN  DATE
      ,p_pretty_print     IN  NUMBER   DEFAULT 0
      ,p_null_handling    IN  VARCHAR2 DEFAULT 'FALSE'
   ) RETURN CLOB;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   /*
   Function: dz_kml_main.sdo2placemark

   Pure PLSQL utility for generating KML placemark element.

   Parameters:

      p_input - geometry to insert as KML into placemark element.
      p_name - name to apply to the KML placemark element.
      p_visibility - optional value for placemark visibility property
      p_open - optional value for placemark open property
      p_address - optional value for placemark address property
      p_description - optional value for placemark descripton property
      p_styleurl - optional value for placemark styleurl property
      p_pretty_print - optional flag to produce XML in pretty printed format
      p_2d_flag - optional flag to remove 3D information from input geometry
      p_prune_number - optional value to prune all geometry vertice precision
      p_extrude - value to set for extrude in geometry, default is 'false'
      p_tessellate - value to set for tesselate in geometry, default is 'true'
      p_altitudemode - value to set for altitudemode in geometry, default is 
      'clampToGround'
      
   Returns:

      CLOB value of KML data element
      
   */
   FUNCTION sdo2placemark(
       p_input            IN  MDSYS.SDO_GEOMETRY
      ,p_name             IN  VARCHAR2
      ,p_visibility       IN  VARCHAR2 DEFAULT NULL
      ,p_open             IN  VARCHAR2 DEFAULT NULL
      ,p_address          IN  VARCHAR2 DEFAULT NULL
      ,p_description      IN  VARCHAR2 DEFAULT NULL
      ,p_styleurl         IN  VARCHAR2 DEFAULT NULL
      ,p_pretty_print     IN  NUMBER   DEFAULT NULL
      ,p_2d_flag          IN  VARCHAR2 DEFAULT 'TRUE'
      ,p_prune_number     IN  NUMBER   DEFAULT NULL
      ,p_extrude          IN  VARCHAR2 DEFAULT 'false'
      ,p_tessellate       IN  VARCHAR2 DEFAULT 'true'
      ,p_altitudemode     IN  VARCHAR2 DEFAULT 'clampToGround'
   ) RETURN CLOB;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   /*
   Function: dz_kml_main.error2kml

   Function for generating an empty (or optionally not empty) KML placemark suitable 
   for showing error feedback in Google Earth and other KML viewers.

   Parameters:

      p_return_code - return code to show in error message
      p_status_message - status message to show in error message
      p_error_source - name of the placemark KML element
      p_tid - placemark tid value, default is zero
      p_error_sdo - optional geometry to pass in the placemark that in some way  
      would be informational to the receiver.
      
   Returns:

      CLOB value of KML placemark element
      
   */
   FUNCTION error2kml(
       p_return_code      IN  NUMBER
      ,p_status_message   IN  VARCHAR2
      ,p_error_source     IN  VARCHAR2     DEFAULT NULL
      ,p_tid              IN  NUMBER       DEFAULT 0
      ,p_error_sdo        IN  MDSYS.SDO_GEOMETRY DEFAULT NULL
   ) RETURN CLOB;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   /*
   Function: dz_kml_main.table2kml

   Function for generating a series of KML placemarks for each record in an
   Oracle table.

   Parameters:

      p_table_name - name of table to convert into KML placemarks.
      p_geom_column - column containing the SDO_GEOMETRT to convert into KML
      p_name_column - string column containing the value to use for the placemark
      name attribute
      p_attr_columns - comma-delimited list of columns to include in placemark
      data elements
      p_where_clause - where clause to limit selection against the table
      p_style_name - styleurl attribute to add to KML placemarks
      
   Returns:

      CLOB value of KML placemark element
      
   */
   FUNCTION table2kml(
       p_table_name       IN  VARCHAR2
      ,p_geom_column      IN  VARCHAR2
      ,p_name_column      IN  VARCHAR2
      ,p_attr_columns     IN  VARCHAR2
      ,p_where_clause     IN  VARCHAR2
      ,p_style_name       IN  VARCHAR2
   ) RETURN CLOB;
      
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   /*
   Procedure: dz_kml_main.table2kml2file

   Procedure for generating a series of KML placemarks for each record in an
   Oracle table and writing the resulting KML to a file in an Oracle directory.

   Parameters:

      p_table_name - name of table to convert into KML placemarks.
      p_geom_column - column containing the SDO_GEOMETRT to convert into KML
      p_name_column - string column containing the value to use for the placemark
      name attribute
      p_attr_columns - comma-delimited list of columns to include in placemark
      data elements
      p_where_clause - where clause to limit selection against the table
      p_style_name - styleurl attribute to add to KML placemarks
      p_kml_header - KML header to add before the series of placemarks
      p_kml_footer - KML footer to add after the series of placemarks
      p_directory - directory to write resulting file, default is LOADING_DOCK
      p_filename - filename of resulting KML file, default is kmldump.kml
      
   Returns:

      Nothing
      
   */
   PROCEDURE table2kml2file(
       p_table_name       IN VARCHAR2
      ,p_geom_column      IN VARCHAR2
      ,p_name_column      IN VARCHAR2
      ,p_attr_columns     IN VARCHAR2
      ,p_where_clause     IN VARCHAR2
      ,p_style_name       IN VARCHAR2
      ,p_kml_header       IN VARCHAR2 DEFAULT NULL
      ,p_kml_footer       IN VARCHAR2 DEFAULT NULL
      ,p_directory        IN VARCHAR2 DEFAULT 'LOADING_DOCK'
      ,p_filename         IN VARCHAR2 DEFAULT 'kmldump.kml'
   );
    
END dz_kml_main;
/

GRANT EXECUTE ON dz_kml_main TO public;

