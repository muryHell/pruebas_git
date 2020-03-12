SET SERVEROUTPUT ON;
DECLARE
    l_res VARCHAR2(255);
    l_path VARCHAR2(266);
    l_file VARCHAR2(255);
    l_res_clase NUMBER;
   lines dbms_output.chararr; 
   num_lines number := 117; 
BEGIN
DBMS_OUTPUT.ENABLE (1000000);
DBMS_JAVA.set_output (1000000);
l_file := 'EIRG951009J53_88061415_FA.pdf';
l_path := '/oebsdev/inbound/facturas/pruebas_amauri';
l_res := XXCMX_AR_GET_URL_FACTURA_PKG.get_pdf(
                                                                    p_rfcCliente => 'EIRG951009J53',
                                                                    p_folioFactura => '88061415',
                                                                    p_idDocumento => 33,
                                                                    p_getFactura => 'FA'
                                                                 );

DBMS_OUTPUT.PUT_LINE('Respuesta Web Service '  || l_res);

DBMS_OUTPUT.PUT_LINE('=============================================================');
DBMS_OUTPUT.PUT_LINE('Llamado a la clase Java XXCMX_TEST_DOWN');
DBMS_OUTPUT.PUT_LINE('=============================================================');
BEGIN
    l_res_clase := apps.prueba_descarga_amauri(l_res,l_path||'/'||l_file);
    DBMS_OUTPUT.PUT_LINE('Finalizo correctamente ' || to_char(sysdate,'DD/MM/YY HH:MM:SS'));
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error al llamar a la clase ' || sqlerrm);
END;


END;
/
ALTER SESSION SET NLS_LANGUAGE = 'AMERICAN';