CREATE OR REPLACE TYPE BODY dz_kml_folder 
AS

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   CONSTRUCTOR FUNCTION dz_kml_folder
   RETURN SELF AS RESULT
   AS
   BEGIN
      RETURN;
      
   END dz_kml_folder;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   CONSTRUCTOR FUNCTION dz_kml_folder(
      p_folder_name   IN VARCHAR2
   ) RETURN SELF AS RESULT
   AS
   BEGIN
      self.folder_name := p_folder_name;
      RETURN;
      
   END dz_kml_folder;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   MEMBER FUNCTION toKML(
       p_payload           IN  CLOB     DEFAULT NULL
      ,p_inline_style      IN  VARCHAR2 DEFAULT 'FALSE'
      ,p_pretty_print      IN  NUMBER   DEFAULT NULL
   ) RETURN CLOB
   AS
      clb_output       CLOB;
      str_inline_style VARCHAR2(4000 Char) := UPPER(p_inline_style);
      
   BEGIN
   
      --------------------------------------------------------------------------
      -- Step 10
      -- Check over incoming parameters
      --------------------------------------------------------------------------
      IF str_inline_style IS NULL
      THEN
         str_inline_style := 'FALSE';
         
      ELSIF str_inline_style NOT IN ('TRUE','FALSE')
      THEN
         RAISE_APPLICATION_ERROR(-20001,'boolean error');
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 20
      -- Open the folder 
      --------------------------------------------------------------------------
      IF self.folder_id IS NULL
      THEN
         clb_output := dz_kml_util.pretty(
             '<Folder>'
            ,p_pretty_print
         );
         
      ELSE
         clb_output := dz_kml_util.pretty(
             '<Folder id="' || self.folder_id || '">'
            ,p_pretty_print
         );
      
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 30
      -- Add in the Folder name 
      --------------------------------------------------------------------------
      IF self.folder_name IS NOT NULL
      THEN
         clb_output := clb_output || dz_kml_util.pretty(
             dz_kml_util.value2xmlcdata(
                 'name'
                ,self.folder_name
                ,p_pretty_print + 1
             )
            ,p_pretty_print + 1
         );
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 40
      -- Add in the Folder visibility
      --------------------------------------------------------------------------
      IF self.folder_visibility IS NOT NULL
      THEN
         clb_output := clb_output || dz_kml_util.pretty(
             '<visibility>' || TO_CHAR(self.folder_visibility) || '</visibility>'
            ,p_pretty_print + 1
         );
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 50
      -- Add in the Folder open
      --------------------------------------------------------------------------
      IF self.folder_open IS NOT NULL
      THEN
         clb_output := clb_output || dz_kml_util.pretty(
             '<open>' || TO_CHAR(self.folder_open) || '</open>'
            ,p_pretty_print + 1
         );
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 60
      -- Add in the Folder description 
      --------------------------------------------------------------------------
      IF self.folder_description IS NOT NULL
      THEN
         clb_output := clb_output || dz_kml_util.pretty(
             dz_kml_util.value2xmlcdata(
                 'description'
                ,self.folder_description
                ,p_pretty_print + 1
             )
            ,p_pretty_print + 1
         );
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 70
      -- Add in the Folder styleid
      --------------------------------------------------------------------------
      IF self.folder_style IS NOT NULL
      THEN
         clb_output := clb_output || dz_kml_util.pretty(
             self.folder_style
            ,p_pretty_print + 1
         );
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 80
      -- Add in the Folder Data
      --------------------------------------------------------------------------
      IF self.folder_data IS NOT NULL
      AND self.folder_data.COUNT > 0
      THEN
         FOR i IN 1 .. self.folder_data.COUNT
         LOOP
            clb_output := clb_output || self.folder_data(i).toKML(p_pretty_print + 1);
         
         END LOOP;
      
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 90
      -- Add in the payload
      --------------------------------------------------------------------------
      IF p_payload IS NOT NULL
      THEN
         clb_output := clb_output || p_payload;
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 100
      -- Close the folder
      --------------------------------------------------------------------------
      clb_output := clb_output || dz_kml_util.pretty(
          '</Folder>'
         ,p_pretty_print
      );
      
      --------------------------------------------------------------------------
      -- Step 110
      -- Return the results
      --------------------------------------------------------------------------
      RETURN clb_output;
      
   END toKML;
   
END;
/

