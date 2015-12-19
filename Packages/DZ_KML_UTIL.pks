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

