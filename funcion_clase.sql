CREATE OR REPLACE FUNCTION prueba_descarga_amauri(p_uri IN VARCHAR2, p_file_with_path IN VARCHAR2) return number 
AS LANGUAGE JAVA
NAME 'xxcmx_test_down.downloadUsingNIO(java.lang.String, java.lang.String) return integer';
/