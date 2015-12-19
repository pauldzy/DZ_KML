
--*************************--
PROMPT sqlplus_header.sql;

WHENEVER SQLERROR EXIT -99;
WHENEVER OSERROR  EXIT -98;
SET DEFINE OFF;



--*************************--
PROMPT DZ_KML_UTIL.pks;

CREATE OR REPLACE PACKAGE dz_kml_util
AUTHID CURRENT_USER
AS

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION c_schema(
       p_call_stack    IN  VARCHAR2 DEFAULT NULL
      ,p_type          IN  VARCHAR2 DEFAULT 'SCHEMA'
      ,p_depth         IN  NUMBER   DEFAULT 1
   ) RETURN VARCHAR2 DETERMINISTIC;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION gz_split(
       p_str           IN  VARCHAR2
      ,p_regex         IN  VARCHAR2
      ,p_match         IN  VARCHAR2 DEFAULT NULL
      ,p_end           IN  NUMBER   DEFAULT 0
      ,p_trim          IN  VARCHAR2 DEFAULT 'FALSE'
   ) RETURN MDSYS.SDO_STRING2_ARRAY DETERMINISTIC;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION prune_number(
       p_input         IN  NUMBER
      ,p_trunc         IN  NUMBER DEFAULT NULL
   ) RETURN NUMBER;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION prune_number_varchar2(
       p_input         IN  NUMBER
      ,p_trunc         IN  NUMBER DEFAULT NULL
   ) RETURN VARCHAR2;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION prune_number_clob(
       p_input         IN  NUMBER
      ,p_trunc         IN  NUMBER DEFAULT NULL
   ) RETURN CLOB;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION pretty(
       p_input         IN  CLOB
      ,p_level         IN  NUMBER
      ,p_amount        IN  VARCHAR2 DEFAULT '   '
      ,p_linefeed      IN  VARCHAR2 DEFAULT CHR(10)
   ) RETURN CLOB;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION value2xml (
       p_name          IN  VARCHAR2
      ,p_input         IN  VARCHAR2
      ,p_pretty_print  IN  NUMBER   DEFAULT 0
      ,p_null_handling IN  VARCHAR2 DEFAULT 'FALSE'
   ) RETURN CLOB;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION value2xml (
       p_name          IN  VARCHAR2
      ,p_input         IN  DATE
      ,p_pretty_print  IN  NUMBER   DEFAULT 0
      ,p_null_handling IN  VARCHAR2 DEFAULT 'FALSE'
   ) RETURN CLOB;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION value2xml (
       p_name          IN  VARCHAR2
      ,p_input         IN  NUMBER
      ,p_pretty_print  IN  NUMBER   DEFAULT 0
      ,p_null_handling IN  VARCHAR2 DEFAULT 'FALSE'
   ) RETURN CLOB;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION value2xmlcdata (
       p_name          IN  VARCHAR2
      ,p_input         IN  CLOB
      ,p_pretty_print  IN  NUMBER   DEFAULT 0
      ,p_null_handling IN  VARCHAR2 DEFAULT 'FALSE'
   ) RETURN CLOB;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION value2xmlcdata (
       p_name          IN  VARCHAR2
      ,p_input         IN  VARCHAR2
      ,p_pretty_print  IN  NUMBER   DEFAULT 0
      ,p_null_handling IN  VARCHAR2 DEFAULT 'FALSE'
   ) RETURN CLOB;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION value2xmlcdata (
       p_name          IN  VARCHAR2
      ,p_input         IN  NUMBER
      ,p_pretty_print  IN  NUMBER   DEFAULT 0
      ,p_null_handling IN  VARCHAR2 DEFAULT 'FALSE'
   ) RETURN CLOB;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION smart_transform(
       p_input         IN  MDSYS.SDO_GEOMETRY
      ,p_srid          IN  NUMBER
   ) RETURN MDSYS.SDO_GEOMETRY;

END dz_kml_util;
/

GRANT EXECUTE ON dz_kml_util TO public;


--*************************--
PROMPT DZ_KML_UTIL.pkb;

CREATE OR REPLACE PACKAGE BODY dz_kml_util
AS

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION c_schema(
       p_call_stack IN  VARCHAR2 DEFAULT NULL
      ,p_type       IN  VARCHAR2 DEFAULT 'SCHEMA'
      ,p_depth      IN  NUMBER   DEFAULT 1
   ) RETURN VARCHAR2 DETERMINISTIC
   AS
      str_call_stack VARCHAR2(4000 Char) := p_call_stack;
      ary_lines      MDSYS.SDO_STRING2_ARRAY;
      ary_words      MDSYS.SDO_STRING2_ARRAY;
      int_handle     PLS_INTEGER := 0;
      int_n          PLS_INTEGER;
      str_name       VARCHAR2(30 Char);
      str_owner      VARCHAR2(30 Char);
      str_type       VARCHAR2(30 Char);
      
   BEGIN
   
      IF str_call_stack IS NULL
      THEN
         str_call_stack := DBMS_UTILITY.FORMAT_CALL_STACK;
         
      END IF;

      ary_lines := gz_split(
          p_str   => str_call_stack
         ,p_regex => CHR(10)
      );

      FOR i IN 1 .. ary_lines.COUNT
      LOOP
         IF ary_lines(i) LIKE '%handle%number%name%'
         THEN
            int_handle := i + p_depth;
            
         END IF;

      END LOOP;

      IF int_handle = 0
      OR NOT ary_lines.EXISTS(int_handle)
      THEN
         RAISE_APPLICATION_ERROR(
             -20001
            ,'error in parsing stack, no stack call found at ' || p_depth || ' depth'
         );
         
      END IF;

      ary_words := gz_split(
          p_str   => ary_lines(int_handle)
         ,p_regex => '\s+'
         ,p_end   => 3
      );

      IF NOT ary_words.EXISTS(3)
      THEN
         RAISE_APPLICATION_ERROR(
             -20001
            ,'error in parsing call stack line for info' || chr(10) || ary_lines(int_handle)
         );
         
      END IF;

      IF ary_words(3) LIKE 'pr%'
      THEN
        int_n := LENGTH('procedure ');
      
      ELSIF ary_words(3) LIKE 'fun%'
      THEN
         int_n := LENGTH('function ');
         
      ELSIF ary_words(3) LIKE 'package body%'
      THEN
         int_n := LENGTH('package body ');
      
      ELSIF ary_words(3) LIKE 'pack%'
      THEN
         int_n := LENGTH('package ');
      
      ELSIF ary_words(3) LIKE 'anonymous%'
      THEN
         int_n := LENGTH('anonymous block ');
      
      ELSE
         int_n := null;
      
      END IF;

      IF int_n IS NOT NULL
      THEN
         str_type := TRIM(
            UPPER(SUBSTR( ary_words(3), 1, int_n - 1 ))
         );
         
      ELSE
         str_type := 'TRIGGER';
      
      END IF;

      str_owner := TRIM(
         SUBSTR(ary_words(3),int_n + 1,INSTR(ary_words(3),'.') - (int_n + 1))
      );
      str_name := TRIM(
         SUBSTR(ary_words(3),INSTR(ary_words(3),'.') + 1)
      );

      IF UPPER(p_type) = 'NAME'
      THEN
         RETURN str_name;
         
      ELSIF UPPER(p_type) = 'SCHEMA.NAME'
      OR    UPPER(p_type) = 'OWNER.NAME'
      THEN
         RETURN str_owner || '.' || str_name;
         
      ELSIF UPPER(p_type) = 'TYPE'
      THEN
         RETURN str_type;
         
      ELSE
         RETURN str_owner;
         
      END IF;

   END c_schema;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION gz_split(
       p_str              IN VARCHAR2
      ,p_regex            IN VARCHAR2
      ,p_match            IN VARCHAR2 DEFAULT NULL
      ,p_end              IN NUMBER   DEFAULT 0
      ,p_trim             IN VARCHAR2 DEFAULT 'FALSE'
   ) RETURN MDSYS.SDO_STRING2_ARRAY DETERMINISTIC 
   AS
      int_delim      PLS_INTEGER;
      int_position   PLS_INTEGER := 1;
      int_counter    PLS_INTEGER := 1;
      ary_output     MDSYS.SDO_STRING2_ARRAY;
      num_end        NUMBER      := p_end;
      str_trim       VARCHAR2(5 Char) := UPPER(p_trim);
      
      FUNCTION trim_varray(
         p_input            IN MDSYS.SDO_STRING2_ARRAY
      ) RETURN MDSYS.SDO_STRING2_ARRAY
      AS
         ary_output MDSYS.SDO_STRING2_ARRAY := MDSYS.SDO_STRING2_ARRAY();
         int_index  PLS_INTEGER := 1;
         str_check  VARCHAR2(4000 Char);
         
      BEGIN

         --------------------------------------------------------------------------
         -- Step 10
         -- Exit if input is empty
         --------------------------------------------------------------------------
         IF p_input IS NULL
         OR p_input.COUNT = 0
         THEN
            RETURN ary_output;
            
         END IF;

         --------------------------------------------------------------------------
         -- Step 20
         -- Trim the strings removing anything utterly trimmed away
         --------------------------------------------------------------------------
         FOR i IN 1 .. p_input.COUNT
         LOOP
            str_check := TRIM(p_input(i));
            
            IF str_check IS NULL
            OR str_check = ''
            THEN
               NULL;
               
            ELSE
               ary_output.EXTEND(1);
               ary_output(int_index) := str_check;
               int_index := int_index + 1;
               
            END IF;

         END LOOP;

         --------------------------------------------------------------------------
         -- Step 10
         -- Return the results
         --------------------------------------------------------------------------
         RETURN ary_output;

      END trim_varray;

   BEGIN

      --------------------------------------------------------------------------
      -- Step 10
      -- Create the output array and check parameters
      --------------------------------------------------------------------------
      ary_output := MDSYS.SDO_STRING2_ARRAY();

      IF str_trim IS NULL
      THEN
         str_trim := 'FALSE';
         
      ELSIF str_trim NOT IN ('TRUE','FALSE')
      THEN
         RAISE_APPLICATION_ERROR(-20001,'boolean error');
         
      END IF;

      IF num_end IS NULL
      THEN
         num_end := 0;
         
      END IF;

      --------------------------------------------------------------------------
      -- Step 20
      -- Exit early if input is empty
      --------------------------------------------------------------------------
      IF p_str IS NULL
      OR p_str = ''
      THEN
         RETURN ary_output;
         
      END IF;

      --------------------------------------------------------------------------
      -- Step 30
      -- Account for weird instance of pure character breaking
      --------------------------------------------------------------------------
      IF p_regex IS NULL
      OR p_regex = ''
      THEN
         FOR i IN 1 .. LENGTH(p_str)
         LOOP
            ary_output.EXTEND(1);
            ary_output(i) := SUBSTR(p_str,i,1);
            
         END LOOP;
         
         RETURN ary_output;
         
      END IF;

      --------------------------------------------------------------------------
      -- Step 40
      -- Break string using the usual REGEXP functions
      --------------------------------------------------------------------------
      LOOP
         EXIT WHEN int_position = 0;
         int_delim  := REGEXP_INSTR(
             p_str
            ,p_regex
            ,int_position
            ,1
            ,0
            ,p_match
         );
         
         IF  int_delim = 0
         THEN
            -- no more matches found
            ary_output.EXTEND(1);
            ary_output(int_counter) := SUBSTR(p_str,int_position);
            int_position  := 0;
            
         ELSE
            IF int_counter = num_end
            THEN
               -- take the rest as is
               ary_output.EXTEND(1);
               ary_output(int_counter) := SUBSTR(p_str,int_position);
               int_position  := 0;
               
            ELSE
               --dbms_output.put_line(ary_output.COUNT);
               ary_output.EXTEND(1);
               ary_output(int_counter) := SUBSTR(p_str,int_position,int_delim-int_position);
               int_counter := int_counter + 1;
               int_position := REGEXP_INSTR(p_str,p_regex,int_position,1,1,p_match);
               
            END IF;
            
         END IF;
         
      END LOOP;

      --------------------------------------------------------------------------
      -- Step 50
      -- Trim results if so desired
      --------------------------------------------------------------------------
      IF str_trim = 'TRUE'
      THEN
         RETURN trim_varray(
            p_input => ary_output
         );
         
      END IF;

      --------------------------------------------------------------------------
      -- Step 60
      -- Cough out the results
      --------------------------------------------------------------------------
      RETURN ary_output;
      
   END gz_split;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION prune_number(
       p_input       IN  NUMBER
      ,p_trunc       IN  NUMBER DEFAULT NULL
   ) RETURN NUMBER
   AS
      
   BEGIN
      
      IF p_trunc IS NULL
      THEN
         RETURN p_input;
         
      END IF;
      
      IF p_input IS NULL
      THEN
         RETURN NULL;
         
      END IF;
      
      RETURN TRUNC(p_input,p_trunc);
      
   END prune_number;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION prune_number_varchar2(
       p_input       IN  NUMBER
      ,p_trunc       IN  NUMBER DEFAULT NULL
   ) RETURN VARCHAR2
   AS
   BEGIN
      RETURN TO_CHAR(
         prune_number(
             p_input => p_input
            ,p_trunc => p_trunc
         )
      );
      
   END prune_number_varchar2;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION prune_number_clob(
       p_input       IN  NUMBER
      ,p_trunc       IN  NUMBER DEFAULT NULL
   ) RETURN CLOB
   AS
   BEGIN
      RETURN TO_CLOB(
         prune_number(
             p_input => p_input
            ,p_trunc => p_trunc
         )
      );
      
   END prune_number_clob;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION indent(
       p_level      IN  NUMBER
      ,p_amount     IN  VARCHAR2 DEFAULT '   '
   ) RETURN VARCHAR2
   AS
      str_output VARCHAR2(4000 Char) := '';
      
   BEGIN
   
      IF  p_level IS NOT NULL
      AND p_level > 0
      THEN
         FOR i IN 1 .. p_level
         LOOP
            str_output := str_output || p_amount;
            
         END LOOP;
         
         RETURN str_output;
         
      ELSE
         RETURN '';
         
      END IF;
      
   END indent;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION pretty(
       p_input      IN CLOB
      ,p_level      IN NUMBER
      ,p_amount     IN VARCHAR2 DEFAULT '   '
      ,p_linefeed   IN VARCHAR2 DEFAULT CHR(10)
   ) RETURN CLOB
   AS
      str_amount   VARCHAR2(4000 Char) := p_amount;
      str_linefeed VARCHAR2(2 Char)    := p_linefeed;
      
   BEGIN

      --------------------------------------------------------------------------
      -- Step 10
      -- Process Incoming Parameters
      --------------------------------------------------------------------------
      IF p_amount IS NULL
      THEN
         str_amount := '   ';
         
      END IF;

      --------------------------------------------------------------------------
      -- Step 20
      -- If input is NULL, then do nothing
      --------------------------------------------------------------------------
      IF p_input IS NULL
      THEN
         RETURN NULL;
         
      END IF;

      --------------------------------------------------------------------------
      -- Step 30
      -- Return indented and line fed results
      --------------------------------------------------------------------------
      IF p_level IS NULL
      THEN
         RETURN p_input;
         
      ELSIF p_level = -1
      THEN
         RETURN p_input || TO_CLOB(str_linefeed);
         
      ELSE
         RETURN TO_CLOB(
            indent(p_level,str_amount)
         ) || p_input || TO_CLOB(str_linefeed);
         
      END IF;

   END pretty;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION value2xml (
       p_name             IN  VARCHAR2
      ,p_input            IN  VARCHAR2
      ,p_pretty_print     IN  NUMBER   DEFAULT 0
      ,p_null_handling    IN  VARCHAR2 DEFAULT 'FALSE'
   ) RETURN CLOB
   AS
      str_null_handling VARCHAR2(4000 Char) := NULL; --UPPER(p_null_handling);
      
   BEGIN
   
      --------------------------------------------------------------------------
      -- Step 10
      -- Check over incoming parameters
      --------------------------------------------------------------------------
      IF str_null_handling IS NULL
      THEN
         str_null_handling := 'FALSE';
         
      ELSIF str_null_handling NOT IN ('TRUE','FALSE','NILLABLE')
      THEN
         RAISE_APPLICATION_ERROR(-20001,'boolean error');
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 20
      -- Process NULL input
      --------------------------------------------------------------------------
      IF p_input IS NULL
      THEN
         IF str_null_handling = 'TRUE'
         THEN
            RETURN NULL;
            
         ELSIF str_null_handling = 'NILLABLE'
         THEN
            RETURN TO_CLOB('<' || p_name || ' xsi:nil="true"/>');
            
         ELSE
            RETURN TO_CLOB('<' || p_name || '/>');
            
         END IF;
         
      END IF;
         
      --------------------------------------------------------------------------
      -- Step 30
      -- Process input
      --------------------------------------------------------------------------
      RETURN TO_CLOB('<' || p_name || '>')
      || DBMS_XMLGEN.CONVERT(p_input)
      || TO_CLOB('</' || p_name || '>');  
      
   END value2xml;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION value2xml (
       p_name          IN  VARCHAR2
      ,p_input         IN  NUMBER
      ,p_pretty_print  IN  NUMBER   DEFAULT 0
      ,p_null_handling IN  VARCHAR2 DEFAULT 'FALSE'
   ) RETURN CLOB
   AS
      str_null_handling VARCHAR2(4000 Char) := UPPER(p_null_handling);
      
   BEGIN
   
      --------------------------------------------------------------------------
      -- Step 10
      -- Check over incoming parameters
      --------------------------------------------------------------------------
      IF str_null_handling IS NULL
      THEN
         str_null_handling := 'FALSE';
         
      ELSIF str_null_handling NOT IN ('TRUE','FALSE','NILLABLE')
      THEN
         RAISE_APPLICATION_ERROR(-20001,'boolean error');
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 20
      -- Process NULL input
      --------------------------------------------------------------------------
      IF p_input IS NULL
      THEN
         IF str_null_handling = 'TRUE'
         THEN
            RETURN NULL;
            
         ELSIF str_null_handling = 'NILLABLE'
         THEN
            RETURN TO_CLOB('<' || p_name || ' xsi:nil="true"/>');
            
         ELSE
            RETURN TO_CLOB('<' || p_name || '/>');
            
         END IF;
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 30
      -- Process input
      --------------------------------------------------------------------------
      RETURN TO_CLOB('<' || p_name || '>')
      || DBMS_XMLGEN.CONVERT(p_input)
      || TO_CLOB('</' || p_name || '>');
      
   END value2xml;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION value2xml (
       p_name          IN  VARCHAR2
      ,p_input         IN  DATE
      ,p_pretty_print  IN  NUMBER   DEFAULT 0
      ,p_null_handling IN  VARCHAR2 DEFAULT 'FALSE'
   ) RETURN CLOB
   AS
      str_null_handling VARCHAR2(4000 Char) := UPPER(p_null_handling);
      
   BEGIN
   
      --------------------------------------------------------------------------
      -- Step 10
      -- Check over incoming parameters
      --------------------------------------------------------------------------
      IF str_null_handling IS NULL
      THEN
         str_null_handling := 'FALSE';
         
      ELSIF str_null_handling NOT IN ('TRUE','FALSE','NILLABLE')
      THEN
         RAISE_APPLICATION_ERROR(-20001,'boolean error');
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 20
      -- Process NULL input
      --------------------------------------------------------------------------
      IF p_input IS NULL
      THEN
         IF str_null_handling = 'TRUE'
         THEN
            RETURN NULL;
            
         ELSIF str_null_handling = 'NILLABLE'
         THEN
            RETURN TO_CLOB('<' || p_name || ' xsi:nil="true"/>');
            
         ELSE
            RETURN TO_CLOB('<' || p_name || '/>');
            
         END IF;
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 30
      -- Process input
      --------------------------------------------------------------------------
      RETURN TO_CLOB('<' || p_name || '>')
      || DBMS_XMLGEN.CONVERT(TO_CHAR(p_input,'YYYY-MM-DD'))
      || TO_CLOB('</' || p_name || '>');
      
   END value2xml;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION value2xmlcdata (
       p_name          IN  VARCHAR2
      ,p_input         IN  CLOB
      ,p_pretty_print  IN  NUMBER   DEFAULT 0
      ,p_null_handling IN  VARCHAR2 DEFAULT 'FALSE'
   ) RETURN CLOB
   AS
      str_null_handling VARCHAR2(5 Char) := UPPER(p_null_handling);
      
   BEGIN
   
      IF p_input IS NULL
      THEN
         IF str_null_handling = 'TRUE'
         THEN
            RETURN TO_CLOB('<' || p_name || '/>');
            
         ELSE
            RETURN NULL;
            
         END IF;
         
      ELSE
         RETURN TO_CLOB('<' || p_name || '><![CDATA[') 
            || p_input 
            || TO_CLOB(']]></' || p_name || '>');
            
      END IF;
      
   END value2xmlcdata;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION value2xmlcdata (
       p_name          IN  VARCHAR2
      ,p_input         IN  VARCHAR2
      ,p_pretty_print  IN  NUMBER   DEFAULT 0
      ,p_null_handling IN  VARCHAR2 DEFAULT 'FALSE'
   ) RETURN CLOB
   AS
   BEGIN
      RETURN value2xmlcdata(
          p_name
         ,TO_CLOB(p_input)
         ,p_pretty_print
         ,p_null_handling
      );
      
   END value2xmlcdata;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION value2xmlcdata (
       p_name          IN  VARCHAR2
      ,p_input         IN  NUMBER
      ,p_pretty_print  IN  NUMBER   DEFAULT 0
      ,p_null_handling IN  VARCHAR2 DEFAULT 'FALSE'
   ) RETURN CLOB
   AS
   BEGIN
      RETURN value2xmlcdata(
          p_name
         ,TO_CLOB(p_input)
         ,p_pretty_print
         ,p_null_handling
      );
      
   END value2xmlcdata;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION smart_transform(
       p_input     IN  MDSYS.SDO_GEOMETRY
      ,p_srid      IN  NUMBER
   ) RETURN MDSYS.SDO_GEOMETRY
   AS
      sdo_output     MDSYS.SDO_GEOMETRY;
      
      -- preferred SRIDs
      num_wgs84_pref NUMBER := 4326;
      num_nad83_pref NUMBER := 8265;
      
   BEGIN

      --------------------------------------------------------------------------
      -- Step 10
      -- Check incoming parameters
      --------------------------------------------------------------------------
      IF p_input IS NULL
      THEN
         RETURN p_input;
         
      END IF;

      IF p_srid IS NULL
      THEN
         RAISE_APPLICATION_ERROR(
             -20001
            ,'function requires srid in parameter 2'
         );
         
      END IF;

      --------------------------------------------------------------------------
      -- Step 20
      -- Check if SRID values match
      --------------------------------------------------------------------------
      IF p_srid = p_input.SDO_SRID
      THEN
         RETURN p_input;
         
      END IF;

      --------------------------------------------------------------------------
      -- Step 30
      -- Check for equivalents and adjust geometry SRID if required
      --------------------------------------------------------------------------
      IF  p_srid IN (4269,8265)
      AND p_input.SDO_SRID IN (4269,8265)
      THEN
         sdo_output := p_input;
         sdo_output.SDO_SRID := num_nad83_pref;
         RETURN sdo_output;
         
      ELSIF p_srid IN (4326,8307)
      AND   p_input.SDO_SRID IN (4326,8307)
      THEN
         sdo_output := p_input;
         sdo_output.SDO_SRID := num_wgs84_pref;
         RETURN sdo_output;
         
      END IF;

      --------------------------------------------------------------------------
      -- Step 40
      -- Run the transformation then
      --------------------------------------------------------------------------
      IF p_srid = 3785
      THEN
         sdo_output := MDSYS.SDO_CS.TRANSFORM(
             geom     => p_input
            ,use_case => 'USE_SPHERICAL'
            ,to_srid  => p_srid
         );
         
      ELSE
         sdo_output := MDSYS.SDO_CS.TRANSFORM(
             geom     => p_input
            ,to_srid  => p_srid
         );
      
      END IF;
      
      RETURN sdo_output;

   END smart_transform;
   
END dz_kml_util;
/


--*************************--
PROMPT DZ_KML_DATA.tps;

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


--*************************--
PROMPT DZ_KML_DATA.tpb;

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


--*************************--
PROMPT DZ_KML_DATA_LIST.tps;

CREATE OR REPLACE TYPE dz_kml_data_list FORCE
AS 
TABLE OF dz_kml_data;
/

GRANT EXECUTE ON dz_kml_data_list TO PUBLIC;


--*************************--
PROMPT DZ_KML_FOLDER.tps;

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


--*************************--
PROMPT DZ_KML_FOLDER.tpb;

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


--*************************--
PROMPT DZ_KML_MAIN.pks;

CREATE OR REPLACE PACKAGE dz_kml_main
AUTHID CURRENT_USER
AS

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   /*
   header: DZ_KML
     
   - Build ID: 4
   - TFS Change Set: 8320
   
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


--*************************--
PROMPT DZ_KML_MAIN.pkb;

CREATE OR REPLACE PACKAGE BODY dz_kml_main
AS

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION point2coords(
       p_input            IN  MDSYS.SDO_POINT_TYPE
      ,p_2d_flag          IN  VARCHAR2 DEFAULT 'TRUE'
      ,p_elevation        IN  NUMBER   DEFAULT 0
      ,p_prune_number     IN  NUMBER   DEFAULT NULL
   ) RETURN CLOB
   AS
      str_output VARCHAR2(4000 Char);
      
   BEGIN
   
      str_output := str_output || '<coordinates>' || 
         dz_kml_util.prune_number_varchar2(
             p_input => p_input.x
            ,p_trunc => p_prune_number
         ) || ',' || 
         dz_kml_util.prune_number_varchar2(
             p_input => p_input.y
            ,p_trunc => p_prune_number
         ) || ',';
                 
      IF p_input.z IS NOT NULL
      AND p_2d_flag = 'FALSE'
      THEN
         str_output := str_output || dz_kml_util.prune_number_varchar2(
             p_input => p_input.z
            ,p_trunc => p_prune_number
         );
         
      ELSE
         str_output := str_output || p_elevation;
      
      END IF;
      
      str_output := str_output || '</coordinates>';
      
      RETURN TO_CLOB(str_output);   
      
   END point2coords;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION point2coords(
       p_input            IN  MDSYS.SDO_GEOMETRY
      ,p_2d_flag          IN  VARCHAR2 DEFAULT 'TRUE'
      ,p_elevation        IN  NUMBER   DEFAULT 0
      ,p_prune_number     IN  NUMBER   DEFAULT NULL
   ) RETURN CLOB
   AS
      int_dims   PLS_INTEGER;
      int_gtyp   PLS_INTEGER;
      int_lrs    PLS_INTEGER;
      str_output VARCHAR2(4000 Char);
      
   BEGIN
   
      int_dims := p_input.get_dims();
      int_gtyp := p_input.get_gtype();
      int_lrs  := p_input.get_lrs_dim();
      
      IF int_gtyp <> 1
      THEN
         RAISE_APPLICATION_ERROR(
             -20001
            ,'input sdo must be point'
         );
         
      END IF;
      
      IF p_input.SDO_POINT IS NOT NULL
      THEN
         RETURN point2coords(
             p_input        => p_input.SDO_POINT
            ,p_2d_flag      => p_2d_flag
            ,p_elevation    => p_elevation
            ,p_prune_number => p_prune_number
         );
         
      END IF;
      
      str_output := str_output || '<coordinates>' || 
         dz_kml_util.prune_number_varchar2(
             p_input => p_input.SDO_ORDINATES(1)
            ,p_trunc => p_prune_number
         ) || ',' || 
         dz_kml_util.prune_number_varchar2(
             p_input => p_input.SDO_ORDINATES(2)
            ,p_trunc => p_prune_number
         );
      
      IF p_2d_flag = 'TRUE'
      OR int_dims = 2
      THEN
         str_output := str_output || ',' || p_elevation;
         
      ELSE
         IF  int_dims = 3
         AND int_lrs = 3
         THEN
            str_output := str_output || ',' || p_elevation;
            
         ELSIF int_dims = 3
         AND   int_lrs = 0
         THEN
            str_output := str_output || ',' || dz_kml_util.prune_number_varchar2(
                p_input => p_input.SDO_ORDINATES(3)
               ,p_trunc => p_prune_number
            );
            
         ELSIF int_dims = 4
         AND   int_lrs = 3
         THEN
            str_output := str_output || ',' || dz_kml_util.prune_number_varchar2(
                p_input => p_input.SDO_ORDINATES(4)
               ,p_trunc => p_prune_number
            );
            
         ELSE
            str_output := str_output || ',' || dz_kml_util.prune_number_varchar2(
                p_input => p_input.SDO_ORDINATES(3)
               ,p_trunc => p_prune_number
            );
            
         END IF;            
         
      END IF;
      
      str_output := str_output || '</coordinates>';
      
      RETURN TO_CLOB(str_output);
      
   END point2coords;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION sdoords2coords(
       p_input            IN  MDSYS.SDO_GEOMETRY
      ,p_start            IN  NUMBER   DEFAULT 1
      ,p_stop             IN  NUMBER   DEFAULT NULL
      ,p_inter            IN  NUMBER   DEFAULT 1
      ,p_2d_flag          IN  VARCHAR2 DEFAULT 'TRUE'
      ,p_elevation        IN  NUMBER   DEFAULT 0
      ,p_prune_number     IN  NUMBER   DEFAULT NULL
   ) RETURN CLOB
   AS
      clb_output  CLOB;
      int_start   PLS_INTEGER;
      int_stop    PLS_INTEGER;
      int_counter PLS_INTEGER;
      int_dims    PLS_INTEGER;
      int_lrs     PLS_INTEGER;
      
   BEGIN
   
      int_dims := p_input.get_dims();
      int_lrs  := p_input.get_lrs_dim();
      
      int_start := p_start;
      
      IF p_stop IS NULL
      THEN
         int_stop := p_input.SDO_ORDINATES.COUNT;
         
      ELSE
         int_stop := p_stop;
         
      END IF;
      
      clb_output  := TO_CLOB('<coordinates>');
      
      IF p_inter = 1
      THEN
         int_counter := int_start;
         
         WHILE int_counter <= int_stop
         LOOP 
            clb_output  := clb_output || dz_kml_util.prune_number_clob(
                p_input => p_input.SDO_ORDINATES(int_counter)
               ,p_trunc => p_prune_number
            );
            
            int_counter := int_counter + 1;
            
            clb_output  := clb_output || TO_CLOB(',') || 
            dz_kml_util.prune_number_clob(
                p_input => p_input.SDO_ORDINATES(int_counter)
               ,p_trunc => p_prune_number
            );
            int_counter := int_counter + 1;

            IF int_dims = 2
            THEN
               clb_output  := clb_output || 
               TO_CLOB(',') || TO_CLOB(p_elevation);
               
            ELSIF int_dims = 3
            THEN
               IF p_2d_flag = 'TRUE'
               THEN
                  clb_output  := clb_output || TO_CLOB(',' || p_elevation);
                  int_counter := int_counter + 1;
                  
               ELSE
                  IF int_lrs = 3
                  THEN
                     clb_output  := clb_output || TO_CLOB(',' || p_elevation);
                     int_counter := int_counter + 1;
                  ELSE
                     clb_output  := clb_output || TO_CLOB(',') || 
                     dz_kml_util.prune_number_clob(
                         p_input => p_input.SDO_ORDINATES(int_counter)
                        ,p_trunc => p_prune_number
                     );
                     int_counter := int_counter + 1;
                     
                  END IF;
                  
               END IF;
               
            ELSIF int_dims = 4
            THEN
               IF p_2d_flag = 'TRUE'
               THEN
                  clb_output  := clb_output || TO_CLOB(',' || p_elevation);
                  int_counter := int_counter + 2;
                  
               ELSE
                  IF int_lrs = 3
                  THEN
                     int_counter := int_counter + 1;
                     clb_output  := clb_output || TO_CLOB(',') || 
                     dz_kml_util.prune_number_clob(
                         p_input => p_input.SDO_ORDINATES(int_counter)
                        ,p_trunc => p_prune_number
                     );
                     int_counter := int_counter + 1;
                     
                  ELSE
                     clb_output  := clb_output || TO_CLOB(',') || 
                     dz_kml_util.prune_number_clob(
                         p_input => p_input.SDO_ORDINATES(int_counter)
                        ,p_trunc => p_prune_number
                     );
                     int_counter := int_counter + 2;
                     
                  END IF;
                  
               END IF;
               
            END IF;
            
            IF int_counter < int_stop
            THEN
               clb_output := clb_output || TO_CLOB(' ');
               
            END IF;
         
         END LOOP;
         
      ELSIF p_inter = 3
      THEN
         IF int_dims != (p_stop - p_start + 1)/2
         THEN
            RAISE_APPLICATION_ERROR(
                -20001
               ,'extract etype 3 from geometry'
            );
            
         END IF;
         
         IF int_dims = 2
         THEN
            clb_output  := clb_output || TO_CLOB(
               dz_kml_util.prune_number(
                   p_input => p_input.SDO_ORDINATES(1)
                  ,p_trunc => p_prune_number
               ) || ',' || 
               dz_kml_util.prune_number(
                   p_input => p_input.SDO_ORDINATES(2)
                  ,p_trunc => p_prune_number
               ) || ',' || p_elevation || ' ' || 
               dz_kml_util.prune_number(
                   p_input => p_input.SDO_ORDINATES(3)
                  ,p_trunc => p_prune_number
               ) || ',' || 
               dz_kml_util.prune_number(
                   p_input => p_input.SDO_ORDINATES(2)
                  ,p_trunc => p_prune_number
               ) || ',' || p_elevation || ' ' || 
               dz_kml_util.prune_number(
                   p_input => p_input.SDO_ORDINATES(3)
                  ,p_trunc => p_prune_number
               ) || ','|| 
               dz_kml_util.prune_number(
                   p_input => p_input.SDO_ORDINATES(4)
                  ,p_trunc => p_prune_number
               ) || ',' || p_elevation || ' ' || 
               dz_kml_util.prune_number(
                   p_input => p_input.SDO_ORDINATES(1)
                  ,p_trunc => p_prune_number
               ) || ',' || 
               dz_kml_util.prune_number(
                   p_input => p_input.SDO_ORDINATES(4)
                  ,p_trunc => p_prune_number
               ) || ',' || p_elevation || ' ' || 
               dz_kml_util.prune_number(
                   p_input => p_input.SDO_ORDINATES(1)
                  ,p_trunc => p_prune_number
               ) || ',' || 
               dz_kml_util.prune_number(
                   p_input => p_input.SDO_ORDINATES(2)
                  ,p_trunc => p_prune_number
               ) || ',' || p_elevation
            );
  
         ELSIF int_dims = 3
         THEN
            IF int_lrs = 3
            OR p_2d_flag = 'TRUE'
            THEN
               clb_output := clb_output || TO_CLOB(
                  dz_kml_util.prune_number(
                      p_input => p_input.SDO_ORDINATES(1)
                     ,p_trunc => p_prune_number
                  ) || ',' || 
                  dz_kml_util.prune_number(
                      p_input => p_input.SDO_ORDINATES(2)
                     ,p_trunc => p_prune_number
                  ) || ',' || p_elevation || ' ' || 
                  dz_kml_util.prune_number(
                      p_input => p_input.SDO_ORDINATES(4)
                     ,p_trunc => p_prune_number
                  ) || ',' || 
                  dz_kml_util.prune_number(
                      p_input => p_input.SDO_ORDINATES(2)
                     ,p_trunc => p_prune_number
                  ) || ',' || p_elevation || ' ' || 
                  dz_kml_util.prune_number(
                      p_input => p_input.SDO_ORDINATES(4)
                     ,p_trunc => p_prune_number
                  ) || ',' || 
                  dz_kml_util.prune_number(
                      p_input => p_input.SDO_ORDINATES(5)
                     ,p_trunc => p_prune_number
                  ) || ',' || p_elevation || ' ' || 
                  dz_kml_util.prune_number(
                      p_input => p_input.SDO_ORDINATES(1)
                     ,p_trunc => p_prune_number
                  ) || ',' || 
                  dz_kml_util.prune_number(
                      p_input => p_input.SDO_ORDINATES(5)
                     ,p_trunc => p_prune_number
                  ) || ',' || p_elevation || ' ' || 
                  dz_kml_util.prune_number(
                      p_input => p_input.SDO_ORDINATES(1)
                     ,p_trunc => p_prune_number
                  ) || ',' || 
                  dz_kml_util.prune_number(
                      p_input => p_input.SDO_ORDINATES(2)
                     ,p_trunc => p_prune_number
                  ) || ',' || p_elevation
               );
               
            ELSE
               clb_output := clb_output || TO_CLOB(
                  dz_kml_util.prune_number(
                      p_input => p_input.SDO_ORDINATES(1)
                     ,p_trunc => p_prune_number
                  ) || ',' || 
                  dz_kml_util.prune_number(
                      p_input => p_input.SDO_ORDINATES(2)
                     ,p_trunc => p_prune_number
                  ) || ',' || 
                  dz_kml_util.prune_number(
                      p_input => p_input.SDO_ORDINATES(3)
                     ,p_trunc => p_prune_number
                  ) || ' ' || 
                  dz_kml_util.prune_number(
                      p_input => p_input.SDO_ORDINATES(4)
                     ,p_trunc => p_prune_number
                  ) || ',' || 
                  dz_kml_util.prune_number(
                      p_input => p_input.SDO_ORDINATES(2)
                     ,p_trunc => p_prune_number
                  ) || ',' || 
                  dz_kml_util.prune_number(
                      p_input => p_input.SDO_ORDINATES(3)
                     ,p_trunc => p_prune_number
                  ) || ' ' || 
                  dz_kml_util.prune_number(
                      p_input => p_input.SDO_ORDINATES(4)
                     ,p_trunc => p_prune_number
                  ) || ',' || 
                  dz_kml_util.prune_number(
                      p_input => p_input.SDO_ORDINATES(5)
                     ,p_trunc => p_prune_number
                  ) || ',' || 
                  dz_kml_util.prune_number(
                      p_input => p_input.SDO_ORDINATES(6)
                     ,p_trunc => p_prune_number
                  ) || ' ' || 
                  dz_kml_util.prune_number(
                      p_input => p_input.SDO_ORDINATES(1)
                     ,p_trunc => p_prune_number
                  ) || ',' || 
                  dz_kml_util.prune_number(
                      p_input => p_input.SDO_ORDINATES(5)
                     ,p_trunc => p_prune_number
                  ) || ',' || 
                  dz_kml_util.prune_number(
                      p_input => p_input.SDO_ORDINATES(6)
                     ,p_trunc => p_prune_number
                  ) || ' ' || 
                  dz_kml_util.prune_number(
                      p_input => p_input.SDO_ORDINATES(1)
                     ,p_trunc => p_prune_number
                  ) || ',' || 
                  dz_kml_util.prune_number(
                      p_input => p_input.SDO_ORDINATES(2)
                     ,p_trunc => p_prune_number
                  ) || ',' || 
                  dz_kml_util.prune_number(
                      p_input => p_input.SDO_ORDINATES(3)
                     ,p_trunc => p_prune_number
                  )
               );
            
            END IF;
            
         ELSIF int_dims = 4
         THEN
            IF p_2d_flag = 'TRUE'
            THEN
               clb_output  := clb_output || TO_CLOB(
                  dz_kml_util.prune_number(
                      p_input => p_input.SDO_ORDINATES(1)
                     ,p_trunc => p_prune_number
                  ) || ',' || 
                  dz_kml_util.prune_number(
                      p_input => p_input.SDO_ORDINATES(2)
                     ,p_trunc => p_prune_number
                  ) || ',' || p_elevation || ' ' || 
                  dz_kml_util.prune_number(
                      p_input => p_input.SDO_ORDINATES(5)
                     ,p_trunc => p_prune_number
                  ) || ',' || 
                  dz_kml_util.prune_number(
                      p_input => p_input.SDO_ORDINATES(2)
                     ,p_trunc => p_prune_number
                  ) || ',' || p_elevation || ' ' || 
                  dz_kml_util.prune_number(
                      p_input => p_input.SDO_ORDINATES(5)
                     ,p_trunc => p_prune_number
                  ) || ',' || 
                  dz_kml_util.prune_number(
                      p_input => p_input.SDO_ORDINATES(6)
                     ,p_trunc => p_prune_number
                  ) || ',' || p_elevation || ' ' || 
                  dz_kml_util.prune_number(
                      p_input => p_input.SDO_ORDINATES(1)
                     ,p_trunc => p_prune_number
                  ) || ',' || 
                  dz_kml_util.prune_number(
                      p_input => p_input.SDO_ORDINATES(6)
                     ,p_trunc => p_prune_number
                  ) || ',' || p_elevation || ' ' || 
                  dz_kml_util.prune_number(
                      p_input => p_input.SDO_ORDINATES(1)
                     ,p_trunc => p_prune_number
                  ) || ',' || 
                  dz_kml_util.prune_number(
                      p_input => p_input.SDO_ORDINATES(2)
                     ,p_trunc => p_prune_number
                  ) || ',' || p_elevation
               );
            
            ELSE
               clb_output  := clb_output || TO_CLOB(
                  dz_kml_util.prune_number(
                      p_input => p_input.SDO_ORDINATES(1)
                     ,p_trunc => p_prune_number
                  ) || ',' || 
                  dz_kml_util.prune_number(
                      p_input => p_input.SDO_ORDINATES(2)
                     ,p_trunc => p_prune_number
                  ) || ',' || 
                  dz_kml_util.prune_number(
                      p_input => p_input.SDO_ORDINATES(3)
                     ,p_trunc => p_prune_number
                  ) || ' ' || 
                  dz_kml_util.prune_number(
                      p_input => p_input.SDO_ORDINATES(5)
                     ,p_trunc => p_prune_number
                  ) || ',' || 
                  dz_kml_util.prune_number(
                      p_input => p_input.SDO_ORDINATES(2)
                     ,p_trunc => p_prune_number
                  ) || ',' || 
                  dz_kml_util.prune_number(
                      p_input => p_input.SDO_ORDINATES(3)
                     ,p_trunc => p_prune_number
                  ) || ' ' || 
                  dz_kml_util.prune_number(
                      p_input => p_input.SDO_ORDINATES(5)
                     ,p_trunc => p_prune_number
                  ) || ',' || 
                  dz_kml_util.prune_number(
                      p_input => p_input.SDO_ORDINATES(6)
                     ,p_trunc => p_prune_number
                  ) || ',' || 
                  dz_kml_util.prune_number(
                      p_input => p_input.SDO_ORDINATES(7)
                     ,p_trunc => p_prune_number
                  ) || ' ' || 
                  dz_kml_util.prune_number(
                      p_input => p_input.SDO_ORDINATES(1)
                     ,p_trunc => p_prune_number
                  ) || ',' || 
                  dz_kml_util.prune_number(
                      p_input => p_input.SDO_ORDINATES(6)
                     ,p_trunc => p_prune_number
                  ) || ',' || 
                  dz_kml_util.prune_number(
                      p_input => p_input.SDO_ORDINATES(7)
                     ,p_trunc => p_prune_number
                  ) || ' ' || 
                  dz_kml_util.prune_number(
                      p_input => p_input.SDO_ORDINATES(1)
                     ,p_trunc => p_prune_number
                  ) || ',' || 
                  dz_kml_util.prune_number(
                      p_input => p_input.SDO_ORDINATES(2)
                     ,p_trunc => p_prune_number
                  ) || ',' || 
                  dz_kml_util.prune_number(
                      p_input => p_input.SDO_ORDINATES(3)
                     ,p_trunc => p_prune_number
                  )
               );
               
            END IF;
            
         END IF;
         
      ELSE
         RAISE_APPLICATION_ERROR(
             -20001
            ,'no code for interpretation ' || p_inter
         );
         
      END IF;
      
      RETURN clb_output || TO_CLOB('</coordinates>');
      
   END sdoords2coords;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION polygon2coords(
       p_input            IN  MDSYS.SDO_GEOMETRY
      ,p_2d_flag          IN  VARCHAR2 DEFAULT 'TRUE'
      ,p_elevation        IN  NUMBER   DEFAULT 0
      ,p_prune_number     IN  NUMBER   DEFAULT NULL
   ) RETURN CLOB
   AS
      int_dims    PLS_INTEGER;
      int_gtyp    PLS_INTEGER;
      int_counter PLS_INTEGER;
      clb_output  CLOB := '';
      int_offset  PLS_INTEGER;
      int_etype   PLS_INTEGER;
      int_inter   PLS_INTEGER;
      int_start   PLS_INTEGER;
      int_stop    PLS_INTEGER;
      
   BEGIN
   
      int_dims := p_input.get_dims();
      int_gtyp := p_input.get_gtype();
      
      IF int_gtyp <> 3
      THEN
         RAISE_APPLICATION_ERROR(
             -20001
            ,'input sdo must be polygon'
         );
         
      END IF;
      
      int_counter := 1;
      WHILE int_counter <= p_input.SDO_ELEM_INFO.COUNT
      LOOP
         int_offset  := p_input.SDO_ELEM_INFO(int_counter);
         int_counter := int_counter + 1;
         int_etype   := p_input.SDO_ELEM_INFO(int_counter);
         int_counter := int_counter + 1;
         int_inter   := p_input.SDO_ELEM_INFO(int_counter);
         int_counter := int_counter + 1;
         
         int_start   := int_offset;
         IF int_counter > p_input.SDO_ELEM_INFO.COUNT
         THEN
            int_stop := NULL;
            
         ELSE
            int_stop := p_input.SDO_ELEM_INFO(int_counter) - 1;
            
         END IF;
         
         IF int_etype = 1003
         THEN
            clb_output := clb_output || TO_CLOB(
               '<outerBoundaryIs><LinearRing>') || 
               sdoords2coords(
                   p_input        => p_input
                  ,p_start        => int_start
                  ,p_stop         => int_stop
                  ,p_inter        => int_inter
                  ,p_2d_flag      => p_2d_flag
                  ,p_elevation    => p_elevation
                  ,p_prune_number => p_prune_number
               ) || TO_CLOB('</LinearRing></outerBoundaryIs>');
               
         ELSIF int_etype = 2003
         THEN 
            clb_output := clb_output || TO_CLOB(
               '<innerBoundaryIs><LinearRing>') || 
               sdoords2coords(
                   p_input        => p_input
                  ,p_start        => int_start
                  ,p_stop         => int_stop
                  ,p_inter        => int_inter
                  ,p_2d_flag      => p_2d_flag
                  ,p_elevation    => p_elevation
                  ,p_prune_number => p_prune_number
               ) || TO_CLOB('</LinearRing></innerBoundaryIs>');
               
         ELSE
            RAISE_APPLICATION_ERROR(
                -20001
               ,'no code for etype ' || int_etype
            );
            
         END IF;   
         
      END LOOP;

      RETURN clb_output;
      
   END polygon2coords;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION point2kml(
       p_input            IN  MDSYS.SDO_GEOMETRY
      ,p_2d_flag          IN  VARCHAR2 DEFAULT 'TRUE'
      ,p_elevation        IN  NUMBER   DEFAULT 0
      ,p_prune_number     IN  NUMBER   DEFAULT NULL
      ,p_extrude          IN  VARCHAR2 DEFAULT 'false'
      ,p_tessellate       IN  VARCHAR2 DEFAULT 'true'
      ,p_altitudemode     IN  VARCHAR2 DEFAULT 'clampToGround'
   ) RETURN CLOB
   AS
      int_dims         PLS_INTEGER;
      int_gtyp         PLS_INTEGER;
      str_output       VARCHAR2(4000 Char) := '';
      str_extrude      VARCHAR2(4000 Char) := p_extrude;
      str_tessellate   VARCHAR2(4000 Char) := p_tessellate;
      str_altitudemode VARCHAR2(4000 Char) := p_altitudemode;
      
   BEGIN
   
      IF str_extrude IS NULL
      THEN
         str_extrude := 'false';
         
      END IF;
      
      IF str_tessellate IS NULL
      THEN
         str_tessellate := 'true';
         
      END IF;
      
      IF str_altitudemode IS NULL
      THEN
         str_altitudemode := 'clampToGround';
         
      END IF;
   
      int_dims := p_input.get_dims();
      int_gtyp := p_input.get_gtype();
      
      IF int_gtyp <> 1
      THEN
         RAISE_APPLICATION_ERROR(
             -20001
            ,'input sdo must be point'
         );
         
      END IF;
      
      str_output := str_output || '<Point>'
         || '<extrude>' || str_extrude || '</extrude>'
         || '<tessellate>' || str_tessellate || '</tessellate>'
         || '<altitudeMode>' || str_altitudemode || '</altitudeMode>' 
         || point2coords(
             p_input        => p_input
            ,p_2d_flag      => p_2d_flag
            ,p_elevation    => p_elevation
            ,p_prune_number => p_prune_number
         ) || '</Point>';

      RETURN TO_CLOB(str_output);
      
   END point2kml;  
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION cloud2kml(
       p_input            IN  MDSYS.SDO_GEOMETRY
      ,p_2d_flag          IN  VARCHAR2 DEFAULT 'TRUE'
      ,p_elevation        IN  NUMBER   DEFAULT 0
      ,p_prune_number     IN  NUMBER   DEFAULT NULL
      ,p_extrude          IN  VARCHAR2 DEFAULT 'false'
      ,p_tessellate       IN  VARCHAR2 DEFAULT 'true'
      ,p_altitudemode     IN  VARCHAR2 DEFAULT 'clampToGround'
   ) RETURN CLOB
   AS
      int_dims         PLS_INTEGER;
      int_gtyp         PLS_INTEGER;
      int_lrs          PLS_INTEGER;
      int_stop         PLS_INTEGER;
      int_counter      PLS_INTEGER;
      clb_output       CLOB;
      str_extrude      VARCHAR2(4000 Char) := p_extrude;
      str_tessellate   VARCHAR2(4000 Char) := p_tessellate;
      str_altitudemode VARCHAR2(4000 Char) := p_altitudemode;
      
   BEGIN
   
      IF str_extrude IS NULL
      THEN
         str_extrude := 'false';
         
      END IF;
      
      IF str_tessellate IS NULL
      THEN
         str_tessellate := 'true';
         
      END IF;
      
      IF str_altitudemode IS NULL
      THEN
         str_altitudemode := 'clampToGround';
         
      END IF;
   
      int_dims := p_input.get_dims();
      int_gtyp := p_input.get_gtype();
      int_lrs  := p_input.get_lrs_dim();
      
      int_stop := p_input.SDO_ORDINATES.COUNT;
      int_counter := 1;
      
      clb_output := TO_CLOB('');
      
      WHILE int_counter <= int_stop
      LOOP
         clb_output  := clb_output || TO_CLOB(
            '<Point>'  
            || '<extrude>' || str_extrude || '</extrude>'
            || '<tessellate>' || str_tessellate || '</tessellate>'
            || '<altitudeMode>' || str_altitudemode || '</altitudeMode>' 
            || '<coordinates>'
         );
            
         clb_output  := clb_output || dz_kml_util.prune_number_clob(
            p_input => p_input.SDO_ORDINATES(int_counter),
            p_trunc => p_prune_number
         );
         int_counter := int_counter + 1;
            
         clb_output  := clb_output || ',';
         clb_output  := clb_output || dz_kml_util.prune_number(
            p_input => p_input.SDO_ORDINATES(int_counter),
            p_trunc => p_prune_number
         );
         int_counter := int_counter + 1;

         IF int_dims = 2
         THEN
            clb_output  := clb_output || TO_CLOB(',' || p_elevation);
         
         ELSIF int_dims = 3
         THEN
            IF p_2d_flag = 'TRUE'
            THEN
               clb_output  := clb_output || TO_CLOB(',' || p_elevation);
               int_counter := int_counter + 1;
               
            ELSE
               IF int_lrs = 3
               THEN
                  clb_output  := clb_output || TO_CLOB(',' || p_elevation);
                  int_counter := int_counter + 1;
                  
               ELSE
                  clb_output  := clb_output || TO_CLOB(',') || 
                  dz_kml_util.prune_number_clob(
                      p_input => p_input.SDO_ORDINATES(int_counter)
                     ,p_trunc => p_prune_number
                  );
                  int_counter := int_counter + 1;
                  
               END IF;
                  
            END IF;
               
         ELSIF int_dims = 4
         THEN
            IF p_2d_flag = 'TRUE'
            THEN
               clb_output  := clb_output || TO_CLOB(',' || p_elevation);
               int_counter := int_counter + 2;
               
            ELSE
               IF int_lrs = 3
               THEN
                  int_counter := int_counter + 1;
                  clb_output  := clb_output || TO_CLOB( ',') || 
                  dz_kml_util.prune_number_clob(
                      p_input => p_input.SDO_ORDINATES(int_counter)
                     ,p_trunc => p_prune_number
                  );
                  int_counter := int_counter + 1;
                  
               ELSE
                  clb_output  := clb_output || TO_CLOB(',') || 
                  dz_kml_util.prune_number_clob(
                      p_input => p_input.SDO_ORDINATES(int_counter)
                     ,p_trunc => p_prune_number
                  );
                  int_counter := int_counter + 2;
                  
               END IF;
                  
            END IF;
            
         END IF;
            
         clb_output := clb_output || TO_CLOB('</coordinates></Point>');
         
      END LOOP;

      RETURN clb_output;
      
   END cloud2kml;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION line2kml(
       p_input            IN  MDSYS.SDO_GEOMETRY
      ,p_2d_flag          IN  VARCHAR2 DEFAULT 'TRUE'
      ,p_elevation        IN  NUMBER   DEFAULT 0
      ,p_prune_number     IN  NUMBER   DEFAULT NULL
      ,p_extrude          IN  VARCHAR2 DEFAULT 'false'
      ,p_tessellate       IN  VARCHAR2 DEFAULT 'true'
      ,p_altitudemode     IN  VARCHAR2 DEFAULT 'clampToGround'
   ) RETURN CLOB
   AS
      int_dims         PLS_INTEGER;
      int_gtyp         PLS_INTEGER;
      int_lrs          PLS_INTEGER;
      clb_output       CLOB := TO_CLOB('');
      str_extrude      VARCHAR2(4000 Char) := p_extrude;
      str_tessellate   VARCHAR2(4000 Char) := p_tessellate;
      str_altitudemode VARCHAR2(4000 Char) := p_altitudemode;
      
   BEGIN
   
      IF str_extrude IS NULL
      THEN
         str_extrude := 'false';
         
      END IF;
      
      IF str_tessellate IS NULL
      THEN
         str_tessellate := 'true';
         
      END IF;
      
      IF str_altitudemode IS NULL
      THEN
         str_altitudemode := 'clampToGround';
         
      END IF;
   
      int_dims := p_input.get_dims();
      int_gtyp := p_input.get_gtype();
      int_lrs  := p_input.get_lrs_dim();
      
      IF int_gtyp != 2
      THEN
         RAISE_APPLICATION_ERROR(
             -20001
            ,'input sdo must be line'
         );
         
      END IF;
      
      clb_output := clb_output || TO_CLOB(
         '<LineString>'
         || '<extrude>' || str_extrude || '</extrude>'
         || '<tessellate>' || str_tessellate || '</tessellate>'
         || '<altitudeMode>' || str_altitudemode || '</altitudeMode>'
      ) || sdoords2coords(
          p_input        => p_input
         ,p_start        => 1
         ,p_stop         => NULL
         ,p_inter        => 1
         ,p_2d_flag      => p_2d_flag
         ,p_elevation    => p_elevation
         ,p_prune_number => p_prune_number
      ) || TO_CLOB('</LineString>');

      RETURN clb_output;
      
   END line2kml;  
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION polygon2kml(
       p_input            IN  MDSYS.SDO_GEOMETRY
      ,p_2d_flag          IN  VARCHAR2 DEFAULT 'TRUE'
      ,p_elevation        IN  NUMBER   DEFAULT 0
      ,p_prune_number     IN  NUMBER   DEFAULT NULL
      ,p_extrude          IN  VARCHAR2 DEFAULT 'false'
      ,p_tessellate       IN  VARCHAR2 DEFAULT 'true'
      ,p_altitudemode     IN  VARCHAR2 DEFAULT 'clampToGround'
   ) RETURN CLOB
   AS
      int_dims         PLS_INTEGER;
      int_gtyp         PLS_INTEGER;
      clb_output       CLOB := '';
      str_extrude      VARCHAR2(4000 Char) := p_extrude;
      str_tessellate   VARCHAR2(4000 Char) := p_tessellate;
      str_altitudemode VARCHAR2(4000 Char) := p_altitudemode;
      
   BEGIN
   
      IF str_extrude IS NULL
      THEN
         str_extrude := 'false';
         
      END IF;
      
      IF str_tessellate IS NULL
      THEN
         str_tessellate := 'true';
         
      END IF;
      
      IF str_altitudemode IS NULL
      THEN
         str_altitudemode := 'clampToGround';
         
      END IF;
   
      int_dims := p_input.get_dims();
      int_gtyp := p_input.get_gtype();
      
      IF int_gtyp != 3
      THEN
         RAISE_APPLICATION_ERROR(
             -20001
            ,'input sdo must be polygon'
         );
         
      END IF;
      
      clb_output := clb_output || TO_CLOB(
         '<Polygon>'
         || '<extrude>' || str_extrude || '</extrude>'
         || '<tessellate>' || str_tessellate || '</tessellate>'
         || '<altitudeMode>' || str_altitudemode || '</altitudeMode>'
      ) || polygon2coords(
          p_input        => p_input
         ,p_2d_flag      => p_2d_flag
         ,p_elevation    => p_elevation
         ,p_prune_number => p_prune_number
      ) || TO_CLOB('</Polygon>');
                  
      RETURN clb_output;
      
   END polygon2kml;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION multigeometry2kml(
       p_input            IN  MDSYS.SDO_GEOMETRY
      ,p_2d_flag          IN  VARCHAR2 DEFAULT 'TRUE'
      ,p_elevation        IN  NUMBER   DEFAULT 0
      ,p_prune_number     IN  NUMBER   DEFAULT NULL
      ,p_extrude          IN  VARCHAR2 DEFAULT 'false'
      ,p_tessellate       IN  VARCHAR2 DEFAULT 'true'
      ,p_altitudemode     IN  VARCHAR2 DEFAULT 'clampToGround'
   ) RETURN CLOB
   AS
      int_gtype        PLS_INTEGER;
      int_inner        PLS_INTEGER;
      sdo_inner        MDSYS.SDO_GEOMETRY;
      int_dims         PLS_INTEGER;
      int_index        PLS_INTEGER;
      clb_output       CLOB := TO_CLOB('');
      str_extrude      VARCHAR2(4000 Char) := p_extrude;
      str_tessellate   VARCHAR2(4000 Char) := p_tessellate;
      str_altitudemode VARCHAR2(4000 Char) := p_altitudemode;
      
   BEGIN
   
      IF str_extrude IS NULL
      THEN
         str_extrude := 'false';
         
      END IF;
      
      IF str_tessellate IS NULL
      THEN
         str_tessellate := 'true';
         
      END IF;
      
      IF str_altitudemode IS NULL
      THEN
         str_altitudemode := 'clampToGround';
         
      END IF;
   
      int_dims  := p_input.get_dims();
      int_gtype := p_input.get_gtype();
      
      IF int_gtype NOT IN (4,5,6,7)
      THEN
         RAISE_APPLICATION_ERROR(
             -20001
            ,'input sdo must be multigeometry'
         );
         
      END IF;
      
      int_index := MDSYS.SDO_UTIL.GETNUMELEM(p_input);
      
      clb_output := clb_output || TO_CLOB('<MultiGeometry>');
      
      FOR i IN 1 .. int_index
      LOOP
         sdo_inner := MDSYS.SDO_UTIL.EXTRACT(p_input,i);
         int_inner := sdo_inner.get_gtype();
         
         IF int_inner = 1
         THEN
            clb_output := clb_output || point2kml(
                p_input        => sdo_inner
               ,p_2d_flag      => p_2d_flag
               ,p_elevation    => p_elevation
               ,p_prune_number => p_prune_number
               ,p_extrude      => str_extrude
               ,p_tessellate   => str_tessellate
               ,p_altitudemode => str_altitudemode
            );
            
         ELSIF int_inner = 2
         THEN
            clb_output := clb_output || line2kml(
                p_input        => sdo_inner
               ,p_2d_flag      => p_2d_flag
               ,p_elevation    => p_elevation
               ,p_prune_number => p_prune_number
               ,p_extrude      => str_extrude
               ,p_tessellate   => str_tessellate
               ,p_altitudemode => str_altitudemode
            );
            
         ELSIF int_inner = 3
         THEN
            clb_output := clb_output || polygon2kml(
                p_input        => sdo_inner
               ,p_2d_flag      => p_2d_flag
               ,p_elevation    => p_elevation
               ,p_prune_number => p_prune_number
               ,p_extrude      => str_extrude
               ,p_tessellate   => str_tessellate
               ,p_altitudemode => str_altitudemode
            );
            
         ELSIF int_inner = 5
         THEN
            clb_output := clb_output || cloud2kml(
                p_input        => sdo_inner
               ,p_2d_flag      => p_2d_flag
               ,p_elevation    => p_elevation
               ,p_prune_number => p_prune_number
               ,p_extrude      => str_extrude
               ,p_tessellate   => str_tessellate
               ,p_altitudemode => str_altitudemode
            );
            
         ELSE
            RAISE_APPLICATION_ERROR(
                -20001
               ,'weird gtype ' || int_inner
            );
            
         END IF;
         
      END LOOP;
      
      clb_output  := clb_output || TO_CLOB('</MultiGeometry>');
      
      RETURN clb_output;
      
   END multigeometry2kml;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION geokml2sdo(
      p_input            IN  CLOB
   ) RETURN MDSYS.SDO_GEOMETRY
   AS
   BEGIN
      -- Stub for future expansion
      RETURN MDSYS.SDO_UTIL.FROM_KMLGEOMETRY(p_input);
   
   END geokml2sdo;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION sdo2geokml(
       p_input            IN  MDSYS.SDO_GEOMETRY
      ,p_pretty_print     IN  NUMBER   DEFAULT NULL
      ,p_2d_flag          IN  VARCHAR2 DEFAULT 'TRUE'
      ,p_prune_number     IN  NUMBER   DEFAULT NULL
      ,p_extrude          IN  VARCHAR2 DEFAULT 'false'
      ,p_tessellate       IN  VARCHAR2 DEFAULT 'true'
      ,p_altitudemode     IN  VARCHAR2 DEFAULT 'clampToGround'
   ) RETURN CLOB
   AS
      sdo_input        MDSYS.SDO_GEOMETRY := p_input;
      str_2d_flag      VARCHAR2(4000 Char) := UPPER(p_2d_flag);
      int_gtype        PLS_INTEGER;
      int_dims         PLS_INTEGER;
      int_lrs          PLS_INTEGER;
      num_elevation    NUMBER := 0;
      str_extrude      VARCHAR2(4000 Char) := p_extrude;
      str_tessellate   VARCHAR2(4000 Char) := p_tessellate;
      str_altitudemode VARCHAR2(4000 Char) := p_altitudemode;
      
   BEGIN
   
      --------------------------------------------------------------------------
      -- Step 10
      -- Check incoming parameters
      --------------------------------------------------------------------------
      IF p_input IS NULL
      THEN
         RETURN NULL;
         
      END IF;
      
      IF str_2d_flag IS NULL
      THEN
         str_2d_flag := 'TRUE';
         
      ELSIF str_2d_flag NOT IN ('TRUE','FALSE')
      THEN
         RAISE_APPLICATION_ERROR(
             -20001
            ,'boolean error'
         );
         
      END IF;
      
      IF str_extrude IS NULL
      THEN
         str_extrude := 'false';
         
      END IF;
      
      IF str_tessellate IS NULL
      THEN
         str_tessellate := 'true';
         
      END IF;
      
      IF str_altitudemode IS NULL
      THEN
         str_altitudemode := 'clampToGround';
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 20
      -- Transform geometry if required
      --------------------------------------------------------------------------
      sdo_input := dz_kml_util.smart_transform(
          p_input => sdo_input
         ,p_srid  => 8307
      );
      
      --------------------------------------------------------------------------
      -- Step 30
      -- Generate the KML
      --------------------------------------------------------------------------
      int_gtype := sdo_input.get_gtype();
      int_dims  := sdo_input.get_dims();
      int_lrs   := sdo_input.get_lrs_dim();
      
      IF int_gtype = 1
      THEN
         RETURN point2kml(
             p_input        => sdo_input
            ,p_2d_flag      => str_2d_flag
            ,p_elevation    => num_elevation
            ,p_prune_number => p_prune_number
            ,p_extrude      => str_extrude
            ,p_tessellate   => str_tessellate
            ,p_altitudemode => str_altitudemode
         );
         
      ELSIF int_gtype = 2
      THEN
         RETURN line2kml(
             p_input        => sdo_input
            ,p_2d_flag      => str_2d_flag
            ,p_elevation    => num_elevation
            ,p_prune_number => p_prune_number
            ,p_extrude      => str_extrude
            ,p_tessellate   => str_tessellate
            ,p_altitudemode => str_altitudemode
         );
            
      ELSIF int_gtype = 3
      THEN
         RETURN polygon2kml(
             p_input        => sdo_input
            ,p_2d_flag      => str_2d_flag
            ,p_elevation    => num_elevation
            ,p_prune_number => p_prune_number
            ,p_extrude      => str_extrude
            ,p_tessellate   => str_tessellate
            ,p_altitudemode => str_altitudemode
         );
         
      ELSIF int_gtype IN (4,5,6,7)
      THEN
         RETURN multigeometry2kml(
             p_input        => sdo_input
            ,p_2d_flag      => str_2d_flag
            ,p_elevation    => num_elevation
            ,p_prune_number => p_prune_number
            ,p_extrude      => str_extrude
            ,p_tessellate   => str_tessellate
            ,p_altitudemode => str_altitudemode
         );
         
      ELSE
         RAISE_APPLICATION_ERROR(
             -20001
            ,'unknown gtype of ' || int_gtype
         );
         
      END IF;
      
   END sdo2geokml;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION fast_header(
      p_kml_name     IN  VARCHAR,
      p_pretty_print IN  NUMBER DEFAULT NULL
   ) RETURN CLOB
   AS
   BEGIN
   
      RETURN dz_kml_util.pretty(
          '<?xml version="1.0" encoding="UTF-8"?>'
         ,p_pretty_print
      ) || dz_kml_util.pretty(
          '<kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2" >'
         ,p_pretty_print
      ) || dz_kml_util.pretty(
          '<Document>'
         ,p_pretty_print
      ) || dz_kml_util.pretty(
          '<name><![CDATA[' || p_kml_name || ']]>' || '</name>'
         ,p_pretty_print
      ) || dz_kml_util.pretty(
          '<visibility>true</visibility>'
         ,p_pretty_print
      ) || dz_kml_util.pretty(
          '<open>true</open>'
         ,p_pretty_print
      );
      
   END fast_header;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION fast_footer(
      p_pretty_print IN  NUMBER DEFAULT NULL
   ) RETURN CLOB
   AS 
   BEGIN
      RETURN dz_kml_util.pretty(
          '</Document>'
         ,p_pretty_print
      ) || dz_kml_util.pretty(
          '</kml>'
         ,p_pretty_print
      );
      
   END fast_footer;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION value2kmldata (
       p_name          IN  VARCHAR2
      ,p_input         IN  VARCHAR2
      ,p_pretty_print  IN  NUMBER   DEFAULT 0
      ,p_null_handling IN  VARCHAR2 DEFAULT 'FALSE'
   ) RETURN CLOB
   AS
      str_null_handling VARCHAR2(5 Char) := UPPER(p_null_handling);
      
   BEGIN
   
      IF p_input IS NULL
      THEN
         IF str_null_handling = 'TRUE'
         THEN
            RETURN TO_CLOB('<Data name="' || p_name || '"/>');
            
         ELSE
            RETURN NULL;
            
         END IF;
         
      ELSE
         RETURN TO_CLOB(
            '<Data name="' || p_name || '"><value>' || 
            DBMS_XMLGEN.CONVERT(p_input) || 
            '</value></Data>'
         );
         
      END IF;
      
   END value2kmldata;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION value2kmldata (
       p_name          IN  VARCHAR2
      ,p_input         IN  NUMBER
      ,p_pretty_print  IN  NUMBER   DEFAULT 0
      ,p_null_handling IN  VARCHAR2 DEFAULT 'FALSE'
   ) RETURN CLOB
   AS
   BEGIN
   
      RETURN value2kmldata(
          p_name          => p_name
         ,p_input         => TO_CHAR(p_input)
         ,p_pretty_print  => p_pretty_print
         ,p_null_handling => p_null_handling
      );
      
   END value2kmldata;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION value2kmldata (
       p_name          IN  VARCHAR2
      ,p_input         IN  DATE
      ,p_pretty_print  IN  NUMBER   DEFAULT 0
      ,p_null_handling IN  VARCHAR2 DEFAULT 'FALSE'
   ) RETURN CLOB
   AS
   BEGIN
   
      RETURN value2kmldata(
          p_name          => p_name
         ,p_input         => TO_CHAR(p_input,'YYYY-MM-DD"T"HH24:MI:SS')
         ,p_pretty_print  => p_pretty_print
         ,p_null_handling => p_null_handling
      );
      
   END value2kmldata;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
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
   ) RETURN CLOB
   AS
      clb_output       CLOB;
      str_extrude      VARCHAR2(4000 Char) := p_extrude;
      str_tessellate   VARCHAR2(4000 Char) := p_tessellate;
      str_altitudemode VARCHAR2(4000 Char) := p_altitudemode;
      
   BEGIN
   
      --------------------------------------------------------------------------
      -- Step 10
      -- Check over incoming parameters
      --------------------------------------------------------------------------
      IF p_input IS NULL
      THEN
         RETURN NULL;
         
      END IF;
      
      IF str_extrude IS NULL
      THEN
         str_extrude := 'false';
         
      END IF;
      
      IF str_tessellate IS NULL
      THEN
         str_tessellate := 'true';
         
      END IF;
      
      IF str_altitudemode IS NULL
      THEN
         str_altitudemode := 'clampToGround';
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 20
      -- Create the placemark, style and name 
      --------------------------------------------------------------------------
      clb_output := TO_CLOB(
         dz_kml_util.pretty('<Placemark>',p_pretty_print) || 
         dz_kml_util.pretty('<name>' || DBMS_XMLGEN.CONVERT(p_name) || '</name>',p_pretty_print + 1)
      );
      
      IF p_visibility IS NOT NULL
      THEN
         clb_output := clb_output || TO_CLOB(
            dz_kml_util.pretty('<visibility>' || DBMS_XMLGEN.CONVERT(p_visibility) || '</visibility>',p_pretty_print + 1)
         );
         
      END IF;
      
      IF p_open IS NOT NULL
      THEN
         clb_output := clb_output || TO_CLOB(
            dz_kml_util.pretty('<open>' || DBMS_XMLGEN.CONVERT(p_open) || '</open>',p_pretty_print + 1)
         );
         
      END IF;
      
      IF p_address IS NOT NULL
      THEN
         clb_output := clb_output || TO_CLOB(
            dz_kml_util.pretty('<address>' || DBMS_XMLGEN.CONVERT(p_address) || '</address>',p_pretty_print + 1)
         );
         
      END IF;
            
      IF p_description IS NOT NULL
      THEN
         clb_output := clb_output || TO_CLOB(
            dz_kml_util.pretty('<description>' || DBMS_XMLGEN.CONVERT(p_description) || '</description>',p_pretty_print + 1)
         );
         
      END IF;
      
      IF p_styleurl IS NOT NULL
      THEN
         clb_output := clb_output || TO_CLOB(
            dz_kml_util.pretty('<styleUrl>' || DBMS_XMLGEN.CONVERT(p_styleurl) || '</styleUrl>',p_pretty_print + 1)
         );
      
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 30
      -- Handle a NULL input, return nothing if so
      --------------------------------------------------------------------------
      IF p_input IS NOT NULL
      THEN
         clb_output := clb_output || sdo2geokml(
             p_input        => p_input
            ,p_pretty_print => p_pretty_print + 1
            ,p_2d_flag      => p_2d_flag
            ,p_prune_number => p_prune_number
            ,p_extrude      => str_extrude
            ,p_tessellate   => str_tessellate
            ,p_altitudemode => str_altitudemode
         );
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 40
      -- Finish the placemark
      --------------------------------------------------------------------------
      clb_output := clb_output || TO_CLOB(
         dz_kml_util.pretty('</Placemark>',p_pretty_print)
      );
                 
      --------------------------------------------------------------------------
      -- Step 50
      -- Cough out the results
      --------------------------------------------------------------------------
      RETURN clb_output;
      
   END sdo2placemark;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION error2kml(
       p_return_code      IN NUMBER
      ,p_status_message   IN VARCHAR2
      ,p_error_source     IN VARCHAR2     DEFAULT NULL
      ,p_tid              IN NUMBER       DEFAULT 0
      ,p_error_sdo        IN MDSYS.SDO_GEOMETRY DEFAULT NULL
   ) RETURN CLOB
   AS
      clb_kml  CLOB;
      str_name VARCHAR2(4000 Char) := p_error_source;

   BEGIN

      --------------------------------------------------------------------------
      -- Step 10
      -- Check over incoming parameters
      --------------------------------------------------------------------------
      IF str_name IS NULL
      THEN
         str_name := 'Error Condition';
         
      END IF;

      --------------------------------------------------------------------------
      -- Step 20
      -- Construct the KML output
      --------------------------------------------------------------------------
      clb_kml := '<Placemark>' || CHR (10)
              || dz_kml_util.value2xml('name',str_name,2) || CHR(10)
              || dz_kml_util.value2xml(
                 'description',
                 'Status Code: ' || TO_CHAR(p_return_code) || CHR(10) || 'Status Message: ' || p_status_message,
                 2
              ) || CHR(10)
              || '   <gx:balloonVisibility>1</gx:balloonVisibility>' || CHR(10)
              || '   <ExtendedData>' || CHR(10)
              || dz_kml_main.value2kmldata('objtype','ow_error',2) || CHR(10)
              || dz_kml_main.value2kmldata('error_code',TO_CHAR(p_return_code),2) || CHR(10)
              || dz_kml_main.value2kmldata('error_message',p_status_message,2) || CHR(10)
              || dz_kml_main.value2kmldata('tid',TO_CHAR(p_tid),2) || CHR(10)
              || '   </ExtendedData>' || CHR(10);

      IF p_error_sdo IS NOT NULL
      THEN
         clb_kml := clb_kml || dz_kml_main.sdo2geokml(p_error_sdo) || CHR(10);
         
      END IF;

      clb_kml := clb_kml || '</Placemark>' || CHR(10);

      --------------------------------------------------------------------------
      -- Step 30
      -- Cough out the results
      --------------------------------------------------------------------------
      RETURN clb_kml;

   END error2kml;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION table2kml(
       p_table_name       IN VARCHAR2
      ,p_geom_column      IN VARCHAR2
      ,p_name_column      IN VARCHAR2
      ,p_attr_columns     IN VARCHAR2
      ,p_where_clause     IN VARCHAR2
      ,p_style_name       IN VARCHAR2
   ) RETURN CLOB
   AS
      str_sql     VARCHAR2(4000 Char);
      TYPE array_of_string IS TABLE OF VARCHAR2(4000 Char);
      TYPE array_of_clob   IS TABLE OF CLOB;
      ary_columns MDSYS.SDO_STRING2_ARRAY;
      ary_values  array_of_clob;
      ary_kml     array_of_clob;
      ary_names   array_of_string;
      ary_extdata MDSYS.SDO_STRING2_ARRAY;
      clb_output  CLOB;
      
   BEGIN
      
      ary_columns := dz_kml_util.gz_split(p_attr_columns,',');
      
      str_sql := 'SELECT ';
      
      FOR i IN 1 .. ary_columns.COUNT
      LOOP
         str_sql := str_sql || 'a.' || LOWER(ary_columns(i)) || ' ';
         
         IF i < ary_columns.COUNT
         THEN
            str_sql := str_sql || '|| ''||'' || ';
            
         ELSE
            str_sql := str_sql || ',';
            
         END IF;
         
      END LOOP;
      
      str_sql := str_sql 
              || '' || p_name_column || ', '
              || dz_kml_util.c_schema() || '.dz_kml_main.sdo2geokml(a.' || p_geom_column || ',0,''TRUE'',4326,12) '
              || 'FROM '
              || p_table_name || ' a ';
              
      IF p_where_clause IS NOT NULL
      THEN
         str_sql := str_sql
                 || 'WHERE ' || p_where_clause;
      END IF;
      
      EXECUTE IMMEDIATE str_sql 
      BULK COLLECT INTO ary_values,ary_names,ary_kml;
      
      clb_output := '';
      FOR i IN 1 ..ary_values.COUNT
      LOOP
         clb_output := clb_output
                 || '<Placemark>' || CHR(10)
                 || '   <name><![CDATA[' || ary_names(i) || ']]></name>' || CHR(10)
                 || '   <description><![CDATA[]]></description>' || CHR(10)
                 || '   <styleUrl>#' || p_style_name || '</styleUrl>' || CHR(10)
                 || '   <ExtendedData>' || CHR(10);
                 
         ary_extdata := dz_kml_util.gz_split(ary_values(i),'\|\|');      
         FOR j IN 1 .. ary_extdata.COUNT
         LOOP
              clb_output := clb_output
                         || '      <Data name="' || LOWER(ary_columns(j)) || '">'
                         || '<value>' || ary_extdata(j) || '</value>'
                         || '</Data>' || CHR(10);
         END LOOP;
         clb_output := clb_output
                    || '   </ExtendedData>' || CHR(10)
                    || ary_kml(i) || CHR(10)
                    || '</Placemark>' || CHR(10);
      END LOOP;
      
      RETURN clb_output;
      
   END;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
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
   )
   AS
      clb_output    CLOB;
      str_directory VARCHAR2(30 Char)  := p_directory;
      str_filename  VARCHAR2(255 Char) := p_filename;
      
   BEGIN
      
      --------------------------------------------------------------------------
      -- Step 10
      -- Check over incoming parameters
      --------------------------------------------------------------------------
      IF p_directory IS NULL
      THEN
         str_directory := 'LOADING_DOCK';
         
      END IF;
      
      IF p_filename IS NULL
      THEN
         str_filename := 'kmldump.kml';
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 20
      -- Get the kml
      --------------------------------------------------------------------------
      clb_output := table2kml(
          p_table_name       => p_table_name
         ,p_geom_column      => p_geom_column
         ,p_name_column      => p_name_column
         ,p_attr_columns     => p_attr_columns
         ,p_where_clause     => p_where_clause
         ,p_style_name       => p_style_name
      );
             
      --------------------------------------------------------------------------
      -- Step 30
      -- Dump to file
      --------------------------------------------------------------------------       
      DBMS_XSLPROCESSOR.CLOB2FILE(
          clb_output
         ,str_directory
         ,str_filename
      );
   
   END table2kml2file;
   
END dz_kml_main;
/


--*************************--
PROMPT DZ_KML_TEST.pks;

CREATE OR REPLACE PACKAGE dz_kml_test
AUTHID DEFINER
AS

   C_TFS_CHANGESET CONSTANT NUMBER := 8320;
   C_JENKINS_JOBNM CONSTANT VARCHAR2(255 Char) := 'NULL';
   C_JENKINS_BUILD CONSTANT NUMBER := 4;
   C_JENKINS_BLDID CONSTANT VARCHAR2(255 Char) := 'NULL';
   
   C_PREREQUISITES CONSTANT MDSYS.SDO_STRING2_ARRAY := MDSYS.SDO_STRING2_ARRAY(
   );
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION prerequisites
   RETURN NUMBER;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION version
   RETURN VARCHAR2;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION inmemory_test
   RETURN NUMBER;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION scratch_test
   RETURN NUMBER;
   
END dz_kml_test;
/

GRANT EXECUTE ON dz_kml_test TO public;


--*************************--
PROMPT DZ_KML_TEST.pkb;

CREATE OR REPLACE PACKAGE BODY dz_kml_test
AS

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION prerequisites
   RETURN NUMBER
   AS
      num_check NUMBER;
      
   BEGIN
      
      FOR i IN 1 .. C_PREREQUISITES.COUNT
      LOOP
         SELECT 
         COUNT(*)
         INTO num_check
         FROM 
         user_objects a
         WHERE 
             a.object_name = C_PREREQUISITES(i) || '_TEST'
         AND a.object_type = 'PACKAGE';
         
         IF num_check <> 1
         THEN
            RETURN 1;
         
         END IF;
      
      END LOOP;
      
      RETURN 0;
   
   END prerequisites;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION version
   RETURN VARCHAR2
   AS
   BEGIN
      RETURN '{"TFS":' || C_TFS_CHANGESET || ','
      || '"JOBN":"' || C_JENKINS_JOBNM || '",'   
      || '"BUILD":' || C_JENKINS_BUILD || ','
      || '"BUILDID":"' || C_JENKINS_BLDID || '"}';
      
   END version;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION inmemory_test
   RETURN NUMBER
   AS
   BEGIN
      RETURN 0;
      
   END inmemory_test;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION scratch_test
   RETURN NUMBER
   AS
   BEGIN
      RETURN 0;
      
   END scratch_test;

END dz_kml_test;
/


--*************************--
PROMPT sqlplus_footer.sql;


SHOW ERROR;

DECLARE
   l_num_errors PLS_INTEGER;

BEGIN

   SELECT
   COUNT(*)
   INTO l_num_errors
   FROM
   user_errors a
   WHERE
   a.name LIKE 'DZ_KML%';

   IF l_num_errors <> 0
   THEN
      RAISE_APPLICATION_ERROR(-20001,'COMPILE ERROR');

   END IF;

   l_num_errors := DZ_KML_TEST.inmemory_test();

   IF l_num_errors <> 0
   THEN
      RAISE_APPLICATION_ERROR(-20001,'INMEMORY TEST ERROR');

   END IF;

END;
/

EXIT;

