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

