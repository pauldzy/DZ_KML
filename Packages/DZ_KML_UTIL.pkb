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

