CREATE OR REPLACE TYPE BODY dz_kml_data 
AS

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   CONSTRUCTOR FUNCTION dz_kml_data
   RETURN SELF AS RESULT
   AS
   BEGIN
      RETURN;
      
   END dz_kml_data;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   CONSTRUCTOR FUNCTION dz_kml_data(
       p_data_name    IN  VARCHAR2
      ,p_data_value   IN  VARCHAR2
   ) RETURN SELF AS RESULT
   AS
   BEGIN
      self.data_name := p_data_name;
      self.data_value_string := p_data_value;
      
   END dz_kml_data;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   CONSTRUCTOR FUNCTION dz_kml_data(
       p_data_name    IN  VARCHAR2
      ,p_data_value   IN  NUMBER
   ) RETURN SELF AS RESULT
   AS
   BEGIN
      self.data_name := p_data_name;
      self.data_value_number := p_data_value;
      
   END dz_kml_data;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   CONSTRUCTOR FUNCTION dz_kml_data(
       p_data_name    IN  VARCHAR2
      ,p_data_value   IN  DATE
   ) RETURN SELF AS RESULT
   AS
   BEGIN
      self.data_name := p_data_name;
      self.data_value_date := p_data_value;
      
   END dz_kml_data;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   MEMBER FUNCTION toKML(
      p_pretty_print      IN NUMBER   DEFAULT NULL
   ) RETURN CLOB
   AS
      clb_output CLOB;
   
   BEGIN
   
      --------------------------------------------------------------------------
      -- Step 10
      -- Open the ExtendedData
      --------------------------------------------------------------------------
      clb_output := dz_kml_util.pretty('<ExtendedData>',p_pretty_print);
      
      --------------------------------------------------------------------------
      -- Step 20
      -- Open the Data
      --------------------------------------------------------------------------
      clb_output := clb_output || dz_kml_util.pretty(
          '<Data name="' || self.data_name || '">'
         ,p_pretty_print + 1
      );
                 
      --------------------------------------------------------------------------
      -- Step 30
      -- Add the display name
      --------------------------------------------------------------------------
      IF self.data_display_name IS NOT NULL
      THEN
         clb_output := clb_output || dz_kml_util.pretty(
             dz_kml_util.value2xml('displayName',self.data_display_name,p_pretty_print + 2)
            ,p_pretty_print + 2
         );
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 30
      -- Add the data value
      --------------------------------------------------------------------------
      IF self.data_value_string IS NOT NULL
      THEN
         clb_output := clb_output || dz_kml_util.pretty(
             dz_kml_util.value2xml('value',self.data_value_string,p_pretty_print + 2)
            ,p_pretty_print + 2
         );
                    
      ELSIF self.data_value_number IS NOT NULL
      THEN
         clb_output := clb_output || dz_kml_util.pretty(
             dz_kml_util.value2xml('value',self.data_value_number,p_pretty_print + 2)
            ,p_pretty_print + 2
         );
                    
      ELSIF self.data_value_date IS NOT NULL
      THEN
         clb_output := clb_output || dz_kml_util.pretty(
             dz_kml_util.value2xml('value',self.data_value_date,p_pretty_print + 2)
            ,p_pretty_print + 2
         );
                    
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 10
      -- Close the data
      --------------------------------------------------------------------------
      clb_output := clb_output || dz_kml_util.pretty(
          '</Data>'
         ,p_pretty_print + 1
      );
      
      --------------------------------------------------------------------------
      -- Step 10
      -- Close the ExtendedData
      --------------------------------------------------------------------------
      clb_output := clb_output || dz_kml_util.pretty(
          '</ExtendedData>'
         ,p_pretty_print
      );
      
   END toKML;
   
END;
/

