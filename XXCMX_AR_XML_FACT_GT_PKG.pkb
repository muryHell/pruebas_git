CREATE OR REPLACE PACKAGE BODY APPS.XXCMX_AR_XML_FACT_GT_PKG
AS
/* $Header: XXCMX_AR_XML_FACT_GT_PKG.pkb 1.0 2019/10/09 22:44:51 acuahutle ship OEB-4320 $ */
     /*========================================================================================+
  |PROCEDURE
  |         agrega_texto_nodo
  |DESCRIPTION                                                                           
  |                         Procedimiento que agrega texto a los nodos
  |                                                                                      |
  |ARGUMENTS  
  |                         IN:
                                 p_dato : testo a gregar
  |                              p_element_node: nodo al cual se va a agregar el texto
  |
  |                         OUT:
  |
  |
  |HISTORY                                                                               |
  | Date         Author                 Version     Change Reference                     |
  |------------------------------------------------------------------------------------- |
  |2019/09/10   Amauri Cuahutle      1.0         Creación de Proceso                       |
  +======================================================================================*/
  PROCEDURE agrega_texto_nodo(p_dato IN VARCHAR2, p_element_node IN dbms_xmldom.domnode)
  AS
  
  BEGIN
  
    /*Se agrega el texto*/
        g_nameText := dbms_xmldom.createtextnode( 
                doc => g_xmlDoc, 
                data => HTF.ESCAPE_SC ( p_dato) 
            ); 
             
            --convert it to a node 
            g_nameTextNode := dbms_xmldom.makenode( 
                t => g_nameText 
            );
             
            --add the name text to the name element 
            g_childNode := dbms_xmldom.appendchild( 
                n => p_element_node, 
                newchild => g_nameTextNode 
            ); 
     /*fin agrega el texto*/
  
  EXCEPTION
    WHEN OTHERS THEN
        fnd_file.put_line(fnd_file.LOG,'Error en el procedimiento agrega_texto_nodo ' || sqlerrm);
  END agrega_texto_nodo;
   /*========================================================================================+
  |PROCEDURE
  |         add_attribute
  |DESCRIPTION                                                                           
  |                         Procedimiento que agrega un atributo a un elemento al xml
  |                                                                                      |
  |ARGUMENTS  
  |                         IN:
  |                P_ELEMENTO         Elemento en donde se agrega el
  |                                  atributo
  |                P_ETIQUETA         Nombre de la etiqueta
  |               P_VALOR            Texto que se agrega al atributo
  |                         OUT:
  |                                                                                      |
  |RETURNS :
  |                 BOOLEAN
  |
  |HISTORY                                                                               |
  | Date         Author                 Version     Change Reference                     |
  |------------------------------------------------------------------------------------- |
  |2019/10/09   Amauri Cuahutle      1.0         CreaciÃ³n de Proceso                       |
  +======================================================================================*/
   PROCEDURE add_attribute (p_elemento IN dbms_xmldom.DOMElement
                              ,p_etiqueta IN VARCHAR2
                              ,p_valor    IN VARCHAR2) IS
   
   BEGIN
      --Se agrega el elemento solo si existe un valor (texto)
      IF p_valor IS NOT NULL THEN         
         dbms_xmldom.setAttribute(p_elemento, p_etiqueta, p_valor);
      END IF;
   EXCEPTION
      WHEN OTHERS THEN
         fnd_file.put_line(fnd_file.LOG,'Error al generar attributo  ' || sqlerrm);
   END add_attribute;
   
    /*========================================================================================+
  |FUNCTION
  |         get_exp
  |DESCRIPTION                                                                           
  |                         Función que valida si es exportación o no para calcular el campo 3
  |                                                                                      |
  |ARGUMENTS  
  |                         IN:
  |                                  p_bill_site_id:  ID del site del cliente
  |                         OUT:
  |
  |RETURNS
  |                         VARCHAR2:  Regresa si el tipo de documento es exportación
  |HISTORY                                                                               |
  | Date         Author                 Version     Change Reference                     |
  |------------------------------------------------------------------------------------- |
  |2019/09/10   Amauri Cuahutle      1.0         Creación de Proceso                       |
  +======================================================================================*/
  FUNCTION get_exp(p_bill_site_id IN NUMBER)RETURN VARCHAR2
   AS
   
    l_exp VARCHAR2(15);
    l_country_code VARCHAR2(15);
    
   BEGIN
   
    SELECT
         hl.country
         INTO l_country_code
    FROM   hz_parties hp
         , hz_party_sites hps
         , hz_locations hl
         , hz_cust_accounts_all hca
         , hz_cust_acct_sites_all hcsa
         , hz_cust_site_uses_all hcsu
    WHERE  hp.party_id = hps.party_id
    AND    hps.location_id = hl.location_id
    AND    hp.party_id = hca.party_id
    AND    hcsa.party_site_id = hps.party_site_id
    AND    hcsu.cust_acct_site_id = hcsa.cust_acct_site_id
    AND    hca.cust_account_id = hcsa.cust_account_id
    AND    hcsu.site_use_id = p_bill_site_id
    AND hl.country = 'GT'
    ;
    
    l_exp := null;
    RETURN l_exp;
    
   EXCEPTION
    WHEN NO_DATA_FOUND THEN
        l_exp := 'SI';
        RETURN l_exp;
    WHEN OTHERS THEN
        l_exp := null;
        fnd_file.put_line(fnd_file.LOG,'Error al obtener el tipo Exportacion ' || sqlerrm);
        RETURN l_exp;
   END get_exp;
 /*========================================================================================+
  |FUNCTION
  |         get_tipo
  |DESCRIPTION                                                                           
  |                         Función que obtiene el tipo para el campo 2
  |                                                                                      |
  |ARGUMENTS  
  |                         IN:
  |                                  p_trx_num:  Numero de la factura
  |                         OUT:
  |
  |RETURNS
  |                         VARCHAR2:  Regresa el tipo de acuerdo a las reglas de validación
  |HISTORY                                                                               |
  | Date         Author                 Version     Change Reference                     |
  |------------------------------------------------------------------------------------- |
  |2019/09/10   Amauri Cuahutle      1.0         Creación de Proceso                       |
  +======================================================================================*/
  FUNCTION get_tipo(p_trx_num IN VARCHAR2) RETURN VARCHAR2
  AS
  
    l_tipo VARCHAR2(190);
    l_num NUMBER;
    l_type VARCHAR2(190);
  
  BEGIN
  
    SELECT COUNT(ooh.order_number),
                  rctt.type
         INTO l_num,l_type
      FROM oe_order_headers_all ooh,
           oe_order_lines_all ool,
           ra_customer_trx_all rcta,
           ra_cust_trx_types_all rctt,
           ra_customer_trx_lines_all rctl
     WHERE ooh.header_id = ool.header_id
       AND rcta.interface_header_context = 'ORDER ENTRY'
       AND rctl.interface_line_context = 'ORDER ENTRY'
       AND rctl.interface_line_attribute1 = TO_CHAR (ooh.order_number)
       AND rctl.interface_line_attribute6 = TO_CHAR (ool.line_id)
       AND rctl.customer_trx_id = rcta.customer_trx_id
        AND rcta.trx_number = p_trx_num
        AND rcta.cust_trx_type_id = rctt.cust_trx_type_id
        AND rctt.org_id = rcta.org_id
       --AND ooh.order_number = NVL (:p_order_number, ooh.order_number)
    GROUP BY rctt.type
       ;
    
    IF(l_type = 'CM')THEN
        l_tipo := 'NCRE';
        l_num := 0;
    ELSIF(l_type = 'INV')THEN
        l_tipo := 'FCAM';
        l_num := 0;
    END IF;
    
    RETURN l_tipo;
    
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
        IF(l_type = 'CM')THEN
            l_tipo := 'NCRE';
        ELSE
            l_tipo := 'FACT';
        END IF;
        RETURN l_tipo;
    WHEN OTHERS THEN
        fnd_file.put_line(fnd_file.LOG,'Error al obtener el tipo  ' || sqlerrm);
        RETURN null;
  END get_tipo;
 /*========================================================================================+
  |FUNCTION
  |         get_data_emisor
  |DESCRIPTION                                                                           
  |                         Función que obtiene los campos CodigoEstablecimiento, NombreComercial,CorreoEmisor y AfiliacionIVA
  |                                                                                      |
  |ARGUMENTS  
  |                         IN:
  |                                  p_lookup_code:  Code a consultar en el lookup
  |                         OUT:
  |
  |RETURNS
  |                         VARCHAR2:  Regresa los datos almacenados en el lookup de acuerdo al code
  |HISTORY                                                                               |
  | Date         Author                 Version     Change Reference                     |
  |------------------------------------------------------------------------------------- |
  |2019/09/10   Amauri Cuahutle      1.0         Creación de Proceso                       |
  +======================================================================================*/
  FUNCTION get_data_emisor(p_lookup_code IN VARCHAR2)RETURN VARCHAR2
  AS
  
    l_dato VARCHAR2(250);
  
  BEGIN
  
    SELECT description
    INTO l_dato
    FROM fnd_lookup_values_vl
    WHERE lookup_type = 'XXCMX_AR_VALUES_FEL_GTM'
    AND lookup_code = p_lookup_code;
    
    RETURN l_dato;
  
  EXCEPTION
    WHEN OTHERS THEN
        fnd_file.put_line(fnd_file.LOG,'Error al get_data_emisor ' || sqlerrm);
        RETURN null;
  END;
  
   /*========================================================================================+
  |FUNCTION
  |         get_correoreceptor
  |DESCRIPTION                                                                           
  |                         Función que obtiene el correo del receptor, solo se tomara el correo tipo MAIL FE
  |                                                                                      |
  |ARGUMENTS  
  |                         IN:
  |                                  p_site_use_id:  Id del site del cliente a tomar el correo
  |                         OUT:
  |
  |RETURNS
  |                         VARCHAR2:  Regresa el correo del site del receptor
  |HISTORY                                                                               |
  | Date         Author                 Version     Change Reference                     |
  |------------------------------------------------------------------------------------- |
  |2019/09/10   Amauri Cuahutle      1.0         Creación de Proceso                       |
  +======================================================================================*/
  FUNCTION get_correoreceptor(p_site_use_id IN NUMBER) RETURN VARCHAR2
  AS
  
    l_correo VARCHAR2(250);
  
  BEGIN
  
    SELECT hcp.email_address
    INTO l_correo
    FROM   hz_parties hp
         , hz_party_sites hps
         , hz_contact_points hcp
         , hz_locations hl
         , hz_cust_accounts_all hca
         , hz_cust_acct_sites_all hcsa
         , hz_cust_site_uses_all hcsu
    WHERE  hp.party_id = hps.party_id
    AND    hps.location_id = hl.location_id
    AND    hp.party_id = hca.party_id
    AND    hcsa.party_site_id = hps.party_site_id
    AND    hcsu.cust_acct_site_id = hcsa.cust_acct_site_id
    AND    hca.cust_account_id = hcsa.cust_account_id
    AND    hcsu.site_use_id = p_site_use_id
    AND hcp.owner_table_name ='HZ_PARTY_SITES'
    AND hcp.contact_point_type = 'EMAIL'
    AND hcp.contact_point_purpose = 'MAIL FE'
    AND hps.party_site_id = hcp.owner_table_id
    ;
    
    RETURN l_correo;
  
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN null;
    WHEN OTHERS THEN
        fnd_file.put_line(fnd_file.LOG,'Error al get_correoreceptor ' || sqlerrm);
        RETURN null;
  END get_correoreceptor;
  
   /*========================================================================================+
  |FUNCTION
  |         get_correoreceptor
  |DESCRIPTION                                                                           
  |                         Función que obtiene el correo del receptor, solo se tomara el correo tipo MAIL FE
  |                                                                                      |
  |ARGUMENTS  
  |                         IN:
  |                                  p_site_use_id:  Id del site del cliente a tomar el correo
  |                         OUT:
  |
  |RETURNS
  |                         VARCHAR2:  Regresa el correo del site del receptor
  |HISTORY                                                                               |
  | Date         Author                 Version     Change Reference                     |
  |------------------------------------------------------------------------------------- |
  |2019/09/10   Amauri Cuahutle      1.0         Creación de Proceso                       |
  +======================================================================================*/
  FUNCTION get_direccion_receptor(p_site_use_id IN NUMBER) RETURN VARCHAR2
  AS
  
    l_direccion VARCHAR2(250);
  
  BEGIN
  
    SELECT 
           hl.address2 || ',' ||
           hl.address3 || ',' ||
           hl.city
    INTO l_direccion
    FROM   hz_parties hp
         , hz_party_sites hps
         , hz_locations hl
         , hz_cust_accounts_all hca
         , hz_cust_acct_sites_all hcsa
         , hz_cust_site_uses_all hcsu
    WHERE  hp.party_id = hps.party_id
    AND    hps.location_id = hl.location_id
    AND    hp.party_id = hca.party_id
    AND    hcsa.party_site_id = hps.party_site_id
    AND    hcsu.cust_acct_site_id = hcsa.cust_acct_site_id
    AND    hca.cust_account_id = hcsa.cust_account_id
    AND    hcsu.site_use_id = p_site_use_id
    ;
    
    RETURN l_direccion;
  
  EXCEPTION
    WHEN OTHERS THEN
        fnd_file.put_line(fnd_file.LOG,'Error al get_direccion_receptor ' || sqlerrm);
        RETURN null;
  END get_direccion_receptor;
  
 /*========================================================================================+
  |FUNCTION
  |         get_postal_code
  |DESCRIPTION                                                                           
  |                         Función que obtiene el codigo postal del receptor por site
  |                                                                                      |
  |ARGUMENTS  
  |                         IN:
  |                                  p_site_use_id:  Id del site del cliente a tomar el correo
  |                         OUT:
  |
  |RETURNS
  |                         VARCHAR2:  Regresa el codigo postal
  |HISTORY                                                                               |
  | Date         Author                 Version     Change Reference                     |
  |------------------------------------------------------------------------------------- |
  |2019/09/10   Amauri Cuahutle      1.0         Creación de Proceso                       |
  +======================================================================================*/
  FUNCTION get_postal_code(p_site_use_id IN NUMBER) RETURN VARCHAR2
  AS
  
    l_postal_code VARCHAR2(100);
  
  BEGIN
  
        SELECT 
             hl.postal_code
             INTO l_postal_code
        FROM   hz_parties hp
             , hz_party_sites hps
             , hz_locations hl
             , hz_cust_accounts_all hca
             , hz_cust_acct_sites_all hcsa
             , hz_cust_site_uses_all hcsu
        WHERE  hp.party_id = hps.party_id
        AND    hps.location_id = hl.location_id
        AND    hp.party_id = hca.party_id
        AND    hcsa.party_site_id = hps.party_site_id
        AND    hcsu.cust_acct_site_id = hcsa.cust_acct_site_id
        AND    hca.cust_account_id = hcsa.cust_account_id
        AND    hcsu.site_use_id = p_site_use_id
        ;
        
    RETURN l_postal_code;
  
  EXCEPTION
    WHEN OTHERS THEN
        fnd_file.put_line(fnd_file.LOG,'Error en get_postal_code ' || sqlerrm);
        RETURN null;
  END get_postal_code;
  
 /*========================================================================================+
  |FUNCTION
  |         get_municipio
  |DESCRIPTION                                                                           
  |                         Función que obtiene el municipio de un site
  |                                                                                      |
  |ARGUMENTS  
  |                         IN:
  |                                  p_site_use_id:  Id del site del cliente a tomar el correo
  |                         OUT:
  |
  |RETURNS
  |                         VARCHAR2:  Regresa el municipio del site de un cliente
  |HISTORY                                                                               |
  | Date         Author                 Version     Change Reference                     |
  |------------------------------------------------------------------------------------- |
  |2019/09/10   Amauri Cuahutle      1.0         Creación de Proceso                       |
  +======================================================================================*/
  FUNCTION get_municipio(p_site_use_id IN NUMBER) RETURN VARCHAR2
  AS
  
    l_municipio VARCHAR2(250);
  
  BEGIN
  
        SELECT 
             hl.county
             INTO l_municipio
        FROM   hz_parties hp
             , hz_party_sites hps
             , hz_locations hl
             , hz_cust_accounts_all hca
             , hz_cust_acct_sites_all hcsa
             , hz_cust_site_uses_all hcsu
        WHERE  hp.party_id = hps.party_id
        AND    hps.location_id = hl.location_id
        AND    hp.party_id = hca.party_id
        AND    hcsa.party_site_id = hps.party_site_id
        AND    hcsu.cust_acct_site_id = hcsa.cust_acct_site_id
        AND    hca.cust_account_id = hcsa.cust_account_id
        AND    hcsu.site_use_id = p_site_use_id
        ;
        
        RETURN l_municipio;
  
  EXCEPTION
    WHEN OTHERS THEN
        fnd_file.put_line(fnd_file.LOG,'Error en get_municipio ' || sqlerrm);
        return null;
  END get_municipio;
  
 /*========================================================================================+
  |FUNCTION
  |         get_departamento
  |DESCRIPTION                                                                           
  |                         Función que obtiene el departamento de un site
  |                                                                                      |
  |ARGUMENTS  
  |                         IN:
  |                                  p_site_use_id:  Id del site del cliente a tomar el correo
  |                         OUT:
  |
  |RETURNS
  |                         VARCHAR2:  Regresa el departamento del site de un cliente
  |HISTORY                                                                               |
  | Date         Author                 Version     Change Reference                     |
  |------------------------------------------------------------------------------------- |
  |2019/09/10   Amauri Cuahutle      1.0         Creación de Proceso                       |
  +======================================================================================*/
  FUNCTION get_departamento(p_site_use_id IN NUMBER) RETURN VARCHAR2
  AS
  
    l_departamento VARCHAR2(250);
  
  BEGIN
  
        SELECT
             hl.state
             INTO l_departamento
        FROM   hz_parties hp
             , hz_party_sites hps
             , hz_locations hl
             , hz_cust_accounts_all hca
             , hz_cust_acct_sites_all hcsa
             , hz_cust_site_uses_all hcsu
        WHERE  hp.party_id = hps.party_id
        AND    hps.location_id = hl.location_id
        AND    hp.party_id = hca.party_id
        AND    hcsa.party_site_id = hps.party_site_id
        AND    hcsu.cust_acct_site_id = hcsa.cust_acct_site_id
        AND    hca.cust_account_id = hcsa.cust_account_id
        AND    hcsu.site_use_id = p_site_use_id
        ;
        
        RETURN l_departamento;

  EXCEPTION
    WHEN OTHERS THEN
         fnd_file.put_line(fnd_file.LOG,'Error en get_departamento ' || sqlerrm);
        RETURN null;
  END get_departamento;
  
   /*========================================================================================+
  |FUNCTION
  |         get_pais
  |DESCRIPTION                                                                           
  |                         Función que obtiene el país de un site
  |                                                                                      |
  |ARGUMENTS  
  |                         IN:
  |                                  p_site_use_id:  Id del site del cliente a tomar el correo
  |                         OUT:
  |
  |RETURNS
  |                         VARCHAR2:  Regresa el país del site de un cliente
  |HISTORY                                                                               |
  | Date         Author                 Version     Change Reference                     |
  |------------------------------------------------------------------------------------- |
  |2019/09/10   Amauri Cuahutle      1.0         Creación de Proceso                       |
  +======================================================================================*/
  FUNCTION get_pais(p_site_use_id IN NUMBER) RETURN VARCHAR2
  AS
  
    l_pais VARCHAR2(150);
  
  BEGIN
  
        SELECT 
             hl.country
             INTO l_pais
        FROM   hz_parties hp
             , hz_party_sites hps
             , hz_locations hl
             , hz_cust_accounts_all hca
             , hz_cust_acct_sites_all hcsa
             , hz_cust_site_uses_all hcsu
        WHERE  hp.party_id = hps.party_id
        AND    hps.location_id = hl.location_id
        AND    hp.party_id = hca.party_id
        AND    hcsa.party_site_id = hps.party_site_id
        AND    hcsu.cust_acct_site_id = hcsa.cust_acct_site_id
        AND    hca.cust_account_id = hcsa.cust_account_id
        AND    hcsu.site_use_id = 184765
        ;
        
        RETURN l_pais;
  
  EXCEPTION
    WHEN OTHERS THEN
        fnd_file.put_line(fnd_file.LOG,'Error en get_pais ' || sqlerrm);
        RETURN null;
  END get_pais;
  
   /*========================================================================================+
  |PROCEDURE
  |         genera_datos_fiscales
  |DESCRIPTION                                                                           
  |                         Procedimiento que genera la sección de los datos fiscales
  |                                                                                      |
  |ARGUMENTS  
  |                         IN:
                                        p_type:  tipo de transacción
                                        p_tipo : tipo calculado
                                        p_exp: exp calculado
                                        p_fechahora_emision: fecha de la factura
                                        p_codigo_moneda : divisa
                                        p_numero_acceso : numero acceso
                                        p_nit_emisor : nit del emisor
                                        p_nombre_emisor : nombre del emisor
                                        p_codigo_establecimiento: codigo del establecimiento
                                        p_nombre_comercial: nombre comercial
                                        p_correo_emisor : correo emisor
                                        p_afiliacion_iva : afiliación iva
                                        p_direccion : dirección
                                        p_codigo_postal : codigo postal
                                        p_municipio : municpio
                                        p_departamento : departamento
                                        p_pais : pais
                                        p_id_receptor: cuenta del cliente,
                                        p_tipo_especial: tipo especial
                                        p_nombre_receptor : nombre receptor
                                        p_correo_receptor: correo receptor
                                        p_direccion_r : dirección receptor
                                        p_codigo_postal_r codigo postal receptor
                                        p_municipio_r municipio receptor
                                        p_departamento_r : departamento receptor
                                        p_pais_r : país receptor
  |                         OUT:
  |
  |
  |HISTORY                                                                               |
  | Date         Author                 Version     Change Reference                     |
  |------------------------------------------------------------------------------------- |
  |2019/09/10   Amauri Cuahutle      1.0         Creación de Proceso                       |
  +======================================================================================*/
  PROCEDURE genera_datos_fiscales_cabecero( p_type IN VARCHAR2,
                                                                  p_tipo IN VARCHAR2,
                                                                  p_exp IN VARCHAR2,
                                                                  p_fechahora_emision IN VARCHAR2,
                                                                  p_codigo_moneda IN VARCHAR2,
                                                                  p_numero_acceso IN VARCHAR2,
                                                                  p_nit_emisor IN VARCHAR2,
                                                                  p_nombre_emisor IN VARCHAR2,
                                                                  p_codigo_establecimiento IN VARCHAR2,
                                                                  p_nombre_comercial IN VARCHAR2,
                                                                  p_correo_emisor IN VARCHAR2,
                                                                  p_afiliacion_iva IN VARCHAR2,
                                                                  p_direccion IN VARCHAR2,
                                                                  p_codigo_postal IN VARCHAR2,
                                                                  p_municipio IN VARCHAR2,
                                                                  p_departamento IN VARCHAR2,
                                                                  p_pais IN VARCHAR2,
                                                                  p_id_receptor IN VARCHAR2,
                                                                  p_tipo_especial IN VARCHAR2,
                                                                  p_nombre_receptor IN VARCHAR2,
                                                                  p_correo_receptor IN VARCHAR2,
                                                                  p_direccion_r IN VARCHAR2,
                                                                  p_codigo_postal_r IN VARCHAR2,
                                                                  p_municipio_r IN VARCHAR2,
                                                                  p_departamento_r IN VARCHAR2,
                                                                  p_pais_r IN VARCHAR2
                                                                  )
  AS
  
    l_frase_aux NUMBER := 0;
    
    CURSOR c_frases
    IS
    SELECT meaning,
                  NVL(upper(trim(tag)),' ') tag,
                  apps.XXCMX_AR_XML_FACT_GT_PKG.get_datos_frases(1,meaning) TipoFrase,
                  apps.XXCMX_AR_XML_FACT_GT_PKG.get_datos_frases(2,meaning) CodigoEscenario
    FROM fnd_lookup_values
    WHERE 1=1
    AND lookup_type = 'XXCMX_AR_FEL_GTM_FRASES_COD'
    AND language = USERENV('LANG')
    AND enabled_flag = 'Y'
    ;

  
  BEGIN
  
    null;
        --make a DatosEmision element 
        g_DatosEmisionElement := dbms_xmldom.createelement( 
            doc => g_xmlDoc, 
            tagName => 'dte:DatosEmision'
        ); 
        
        apps.XXCMX_AR_XML_FACT_GT_PKG.add_attribute(g_DatosEmisionElement,'ID', 'DatosEmision');
        
        g_DatosEmisionElementNode := dbms_xmldom.makenode( 
            elem => g_DatosEmisionElement 
        );
        
            -----------------------------------------------------------------------------
                    --make a DatosGenerales element 
                    g_DatosGeneralesElement := dbms_xmldom.createelement( 
                        doc => g_xmlDoc, 
                        tagName => 'dte:DatosGenerales'
                    ); 
                    
                    add_attribute(g_DatosGeneralesElement,'NumeroAcceso', p_numero_acceso);
                    add_attribute(g_DatosGeneralesElement,'CodigoMoneda', p_codigo_moneda);
                    add_attribute(g_DatosGeneralesElement,'FechaHoraEmision', p_fechahora_emision);
                    add_attribute(g_DatosGeneralesElement,'Exp', p_exp);
                    add_attribute(g_DatosGeneralesElement,'Tipo', p_tipo);
                    
                    g_DatosGeneralesElementNode := dbms_xmldom.makenode( 
                        elem => g_DatosGeneralesElement 
                    );
                    
                    g_childNode := dbms_xmldom.appendchild( 
                        n => g_DatosEmisionElementNode, 
                        newchild => g_DatosGeneralesElementNode 
                    );
            
            --end DatosGenerales
            -----------------------------------------------------------------------------
                    --make a Emisor element 
                    g_EmisorElement := dbms_xmldom.createelement( 
                        doc => g_xmlDoc, 
                        tagName => 'dte:Emisor'
                    ); 
                    add_attribute(g_EmisorElement,'AfiliacionIVA', p_afiliacion_iva);
                    add_attribute(g_EmisorElement,'CorreoEmisor', p_correo_emisor);
                    add_attribute(g_EmisorElement,'NombreComercial', p_nombre_comercial);
                    add_attribute(g_EmisorElement,'CodigoEstablecimiento', p_codigo_establecimiento);
                    add_attribute(g_EmisorElement,'NombreEmisor', p_nombre_emisor);
                    add_attribute(g_EmisorElement,'NITEmisor', p_nit_emisor);
                    
                    g_EmisorElementNode := dbms_xmldom.makenode( 
                        elem => g_EmisorElement 
                    );
                    
                    g_childNode := dbms_xmldom.appendchild( 
                        n => g_DatosEmisionElementNode, 
                        newchild => g_EmisorElementNode 
                    );
                        -----------------------------------------------------------------------------
                                --make a DireccionEmisor element 
                                g_DireccionEmisorElement := dbms_xmldom.createelement( 
                                    doc => g_xmlDoc, 
                                    tagName => 'dte:DireccionEmisor'
                                ); 
                                
                                g_DireccionEmisorElementNode := dbms_xmldom.makenode( 
                                    elem => g_DireccionEmisorElement 
                                );
                                
                                -----------------------------------------------------------------------------
                                            --make a Direccion element 
                                            g_DireccionElement := dbms_xmldom.createelement( 
                                                doc => g_xmlDoc, 
                                                tagName => 'dte:Direccion'
                                            ); 
                                            
                                            g_DireccionElementNode := dbms_xmldom.makenode( 
                                                elem => g_DireccionElement 
                                            );
                                            /*Se agrega el texto*/
                                                g_nameText := dbms_xmldom.createtextnode( 
                                                        doc => g_xmlDoc, 
                                                        data => HTF.ESCAPE_SC ( p_direccion ) 
                                                    ); 
                                                     
                                                    --convert it to a node 
                                                    g_nameTextNode := dbms_xmldom.makenode( 
                                                        t => g_nameText 
                                                    );
                                                     
                                                    --add the name text to the name element 
                                                    g_childNode := dbms_xmldom.appendchild( 
                                                        n => g_DireccionElementNode, 
                                                        newchild => g_nameTextNode 
                                                    ); 
                                             /*fin agrega el texto*/
                                             
                                            g_childNode := dbms_xmldom.appendchild( 
                                                n => g_DireccionEmisorElementNode, 
                                                newchild => g_DireccionElementNode 
                                            );
                                            --end Direccion element
                                            
                                            --make a CodigoPostal element 
                                            g_CPElement := dbms_xmldom.createelement( 
                                                doc => g_xmlDoc, 
                                                tagName => 'dte:CodigoPostal'
                                            ); 
                                            
                                            g_CPElementNode := dbms_xmldom.makenode( 
                                                elem => g_CPElement 
                                            );
                                            agrega_texto_nodo(p_codigo_postal,g_CPElementNode);
                                             
                                            g_childNode := dbms_xmldom.appendchild( 
                                                n => g_DireccionEmisorElementNode, 
                                                newchild => g_CPElementNode 
                                            );
                                            --end CodigoPostal element
                                            
                                            --make a Municipio element 
                                            g_MunicipioElement := dbms_xmldom.createelement( 
                                                doc => g_xmlDoc, 
                                                tagName => 'dte:Municipio'
                                            ); 
                                            
                                            g_MunicipioElementNode := dbms_xmldom.makenode( 
                                                elem => g_MunicipioElement 
                                            );
                                            /*Se agrega el texto*/
                                                g_nameText := dbms_xmldom.createtextnode( 
                                                        doc => g_xmlDoc, 
                                                        data => HTF.ESCAPE_SC ( p_municipio )
                                                    ); 
                                                     
                                                    --convert it to a node 
                                                    g_nameTextNode := dbms_xmldom.makenode( 
                                                        t => g_nameText 
                                                    );
                                                     
                                                    --add the name text to the name element 
                                                    g_childNode := dbms_xmldom.appendchild( 
                                                        n => g_MunicipioElementNode, 
                                                        newchild => g_nameTextNode 
                                                    ); 
                                             /*fin agrega el texto*/
                                             
                                            g_childNode := dbms_xmldom.appendchild( 
                                                n => g_DireccionEmisorElementNode, 
                                                newchild => g_MunicipioElementNode 
                                            );
                                            --end Municipio element
                                            
                                            --make a Departamento element 
                                            g_DepartamentoElement := dbms_xmldom.createelement( 
                                                doc => g_xmlDoc, 
                                                tagName => 'dte:Departamento'
                                            ); 
                                            
                                            g_DepartamentoElementNode := dbms_xmldom.makenode( 
                                                elem => g_DepartamentoElement 
                                            );
                                            /*Se agrega el texto*/
                                                g_nameText := dbms_xmldom.createtextnode( 
                                                        doc => g_xmlDoc, 
                                                        data => HTF.ESCAPE_SC ( p_departamento ) 
                                                    ); 
                                                     
                                                    --convert it to a node 
                                                    g_nameTextNode := dbms_xmldom.makenode( 
                                                        t => g_nameText 
                                                    );
                                                     
                                                    --add the name text to the name element 
                                                    g_childNode := dbms_xmldom.appendchild( 
                                                        n => g_DepartamentoElementNode, 
                                                        newchild => g_nameTextNode 
                                                    ); 
                                             /*fin agrega el texto*/
                                             
                                            g_childNode := dbms_xmldom.appendchild( 
                                                n => g_DireccionEmisorElementNode, 
                                                newchild => g_DepartamentoElementNode 
                                            );
                                            --end Departamento element
                                            
                                           --make a Pais element 
                                            g_PaisElement := dbms_xmldom.createelement( 
                                                doc => g_xmlDoc, 
                                                tagName => 'dte:Pais'
                                            ); 
                                            
                                            g_PaisElementNode := dbms_xmldom.makenode( 
                                                elem => g_PaisElement 
                                            );
                                            /*Se agrega el texto*/
                                                g_nameText := dbms_xmldom.createtextnode( 
                                                        doc => g_xmlDoc, 
                                                        data => HTF.ESCAPE_SC ( p_pais) 
                                                    ); 
                                                     
                                                    --convert it to a node 
                                                    g_nameTextNode := dbms_xmldom.makenode( 
                                                        t => g_nameText 
                                                    );
                                                     
                                                    --add the name text to the name element 
                                                    g_childNode := dbms_xmldom.appendchild( 
                                                        n => g_PaisElementNode, 
                                                        newchild => g_nameTextNode 
                                                    ); 
                                             /*fin agrega el texto*/
                                             
                                            g_childNode := dbms_xmldom.appendchild( 
                                                n => g_DireccionEmisorElementNode, 
                                                newchild => g_PaisElementNode 
                                            );
                                            --end Pais element
-----------------------------------------------------------end emisor
                                g_childNode := dbms_xmldom.appendchild( 
                                    n => g_EmisorElementNode, 
                                    newchild => g_DireccionEmisorElementNode 
                                );
-----------------------------------------------------------begin receptor
                    --make a Receptor element 
                    g_ReceptorElement := dbms_xmldom.createelement( 
                        doc => g_xmlDoc, 
                        tagName => 'dte:Receptor'
                    ); 
                    add_attribute(g_ReceptorElement,'IDReceptor', p_id_receptor);
                    add_attribute(g_ReceptorElement,'TipoEspecial', p_tipo_especial);
                    add_attribute(g_ReceptorElement,'NombreReceptor', p_nombre_receptor);
                    add_attribute(g_ReceptorElement,'CorreoReceptor', p_correo_receptor);
                    
                    g_ReceptorElementNode := dbms_xmldom.makenode( 
                        elem => g_ReceptorElement 
                    );
                    
                    g_childNode := dbms_xmldom.appendchild( 
                        n => g_DatosEmisionElementNode, 
                        newchild => g_ReceptorElementNode 
                    );
                    
-----------------------------------------------------------------------------
                                --make a DireccionReceptor element 
                                g_DireccionReceptorElement := dbms_xmldom.createelement( 
                                    doc => g_xmlDoc, 
                                    tagName => 'dte:DireccionReceptor'
                                ); 
                                
                                g_DireccionReceptorElementNode := dbms_xmldom.makenode( 
                                    elem => g_DireccionReceptorElement 
                                );
                                
                                g_childNode := dbms_xmldom.appendchild( 
                                    n => g_ReceptorElementNode, 
                                    newchild => g_DireccionReceptorElementNode 
                                );
                                -----------------------------------------------------------------------------
                                            --make a Direccion element 
                                            g_DireccionRElement := dbms_xmldom.createelement( 
                                                doc => g_xmlDoc, 
                                                tagName => 'dte:Direccion'
                                            ); 
                                            
                                            g_DireccionRElementNode := dbms_xmldom.makenode( 
                                                elem => g_DireccionRElement 
                                            );
                                            /*Se agrega el texto*/
                                                g_nameText := dbms_xmldom.createtextnode( 
                                                        doc => g_xmlDoc, 
                                                        data => HTF.ESCAPE_SC ( p_direccion_r ) 
                                                    ); 
                                                     
                                                    --convert it to a node 
                                                    g_nameTextNode := dbms_xmldom.makenode( 
                                                        t => g_nameText 
                                                    );
                                                     
                                                    --add the name text to the name element 
                                                    g_childNode := dbms_xmldom.appendchild( 
                                                        n => g_DireccionRElementNode, 
                                                        newchild => g_nameTextNode 
                                                    ); 
                                             /*fin agrega el texto*/
                                             
                                            g_childNode := dbms_xmldom.appendchild( 
                                                n => g_DireccionReceptorElementNode, 
                                                newchild => g_DireccionRElementNode 
                                            );
                                            --end Direccion element
                                            
                                            --make a CodigoPostal element 
                                            g_CodigoPostalRElement := dbms_xmldom.createelement( 
                                                doc => g_xmlDoc, 
                                                tagName => 'dte:CodigoPostal'
                                            ); 
                                            
                                            g_CodigoPostalRElementNode := dbms_xmldom.makenode( 
                                                elem => g_CodigoPostalRElement 
                                            );
                                            /*Se agrega el texto*/
                                                g_nameText := dbms_xmldom.createtextnode( 
                                                        doc => g_xmlDoc, 
                                                        data => HTF.ESCAPE_SC ( p_codigo_postal_r ) 
                                                    ); 
                                                     
                                                    --convert it to a node 
                                                    g_nameTextNode := dbms_xmldom.makenode( 
                                                        t => g_nameText 
                                                    );
                                                     
                                                    --add the name text to the name element 
                                                    g_childNode := dbms_xmldom.appendchild( 
                                                        n => g_CodigoPostalRElementNode, 
                                                        newchild => g_nameTextNode 
                                                    ); 
                                             /*fin agrega el texto*/
                                             
                                            g_childNode := dbms_xmldom.appendchild( 
                                                n => g_DireccionReceptorElementNode, 
                                                newchild => g_CodigoPostalRElementNode 
                                            );
                                            --end CodigoPostal element
                                            
                                            --make a Municipio element 
                                            g_MunicipioRElement := dbms_xmldom.createelement( 
                                                doc => g_xmlDoc, 
                                                tagName => 'dte:Municipio'
                                            ); 
                                            
                                            g_MunicipioRElementNode := dbms_xmldom.makenode( 
                                                elem => g_MunicipioRElement 
                                            );
                                            /*Se agrega el texto*/
                                                g_nameText := dbms_xmldom.createtextnode( 
                                                        doc => g_xmlDoc, 
                                                        data => HTF.ESCAPE_SC ( p_municipio_r )
                                                    ); 
                                                     
                                                    --convert it to a node 
                                                    g_nameTextNode := dbms_xmldom.makenode( 
                                                        t => g_nameText 
                                                    );
                                                     
                                                    --add the name text to the name element 
                                                    g_childNode := dbms_xmldom.appendchild( 
                                                        n => g_MunicipioRElementNode, 
                                                        newchild => g_nameTextNode 
                                                    ); 
                                             /*fin agrega el texto*/
                                             
                                            g_childNode := dbms_xmldom.appendchild( 
                                                n => g_DireccionReceptorElementNode, 
                                                newchild => g_MunicipioRElementNode 
                                            );
                                            --end Municipio element
                                            
                                            --make a Departamento element 
                                            g_DepartamentoRElement := dbms_xmldom.createelement( 
                                                doc => g_xmlDoc, 
                                                tagName => 'dte:Departamento'
                                            ); 
                                            
                                            g_DepartamentoRElementNode := dbms_xmldom.makenode( 
                                                elem => g_DepartamentoRElement 
                                            );
                                            /*Se agrega el texto*/
                                                g_nameText := dbms_xmldom.createtextnode( 
                                                        doc => g_xmlDoc, 
                                                        data => HTF.ESCAPE_SC ( p_departamento_r ) 
                                                    ); 
                                                     
                                                    --convert it to a node 
                                                    g_nameTextNode := dbms_xmldom.makenode( 
                                                        t => g_nameText 
                                                    );
                                                     
                                                    --add the name text to the name element 
                                                    g_childNode := dbms_xmldom.appendchild( 
                                                        n => g_DepartamentoRElementNode, 
                                                        newchild => g_nameTextNode 
                                                    ); 
                                             /*fin agrega el texto*/
                                             
                                            g_childNode := dbms_xmldom.appendchild( 
                                                n => g_DireccionReceptorElementNode, 
                                                newchild => g_DepartamentoRElementNode 
                                            );
                                            --end Departamento element
                                            
                                           --make a Pais element 
                                            g_PaisRElement := dbms_xmldom.createelement( 
                                                doc => g_xmlDoc, 
                                                tagName => 'dte:Pais'
                                            ); 
                                            
                                            g_PaisRElementNode := dbms_xmldom.makenode( 
                                                elem => g_PaisRElement 
                                            );
                                            /*Se agrega el texto*/
                                                g_nameText := dbms_xmldom.createtextnode( 
                                                        doc => g_xmlDoc, 
                                                        data => HTF.ESCAPE_SC ( p_pais_r) 
                                                    ); 
                                                     
                                                    --convert it to a node 
                                                    g_nameTextNode := dbms_xmldom.makenode( 
                                                        t => g_nameText 
                                                    );
                                                     
                                                    --add the name text to the name element 
                                                    g_childNode := dbms_xmldom.appendchild( 
                                                        n => g_PaisRElementNode, 
                                                        newchild => g_nameTextNode 
                                                    ); 
                                             /*fin agrega el texto*/
                                             
                                            g_childNode := dbms_xmldom.appendchild( 
                                                n => g_DireccionReceptorElementNode, 
                                                newchild => g_PaisRElementNode 
                                            );
                                            --end Pais element
                                            
-----------------------------------------------------------end receptor


-----------------------------------------------------------end frases
        IF(p_type != 'CM')THEN
            fnd_file.put_line(fnd_file.LOG,'VA A TENER FRASES');
            --make Frases element 
            g_FrasesElement := dbms_xmldom.createelement( 
                doc => g_xmlDoc, 
                tagName => 'dte:Frases'
            ); 
            
            g_FrasesElementNode := dbms_xmldom.makenode( 
                elem => g_FrasesElement 
            );
            
            
            /*Comienza el proceso para generar las frases*/
            FOR r_frases IN c_frases LOOP
                IF(p_exp IS NOT NULL)THEN
                    fnd_file.put_line(fnd_file.LOG,'es exportacion');
                    g_FraseElement := dbms_xmldom.createelement( 
                        doc => g_xmlDoc, 
                        tagName => 'dte:Frase'
                    ); 
                    
                    add_attribute(g_FraseElement,'TipoFrase', r_frases.TipoFrase);
                    add_attribute(g_FraseElement,'CodigoEscenario', r_frases.CodigoEscenario);
                    
                    g_FraseElementNode := dbms_xmldom.makenode(
                        elem => g_FraseElement 
                    );

                    g_childNode := dbms_xmldom.appendchild( 
                        n => g_FrasesElementNode, 
                        newchild => g_FraseElementNode 
                    );
                ELSE
                    fnd_file.put_line(fnd_file.LOG,'no es exportacion');
                    IF(r_frases.tag <> 'EXP')THEN
                        fnd_file.put_line(fnd_file.LOG,r_frases.meaning);
                        g_FraseElement := dbms_xmldom.createelement( 
                            doc => g_xmlDoc, 
                            tagName => 'dte:Frase'
                        ); 
                        
                        add_attribute(g_FraseElement,'TipoFrase', r_frases.TipoFrase);
                        add_attribute(g_FraseElement,'CodigoEscenario', r_frases.CodigoEscenario);
                        
                        g_FraseElementNode := dbms_xmldom.makenode(
                            elem => g_FraseElement 
                        );
                        
                        
                        g_childNode := dbms_xmldom.appendchild( 
                            n => g_FrasesElementNode, 
                            newchild => g_FraseElementNode 
                        );
                    END IF;
                END IF;
            END LOOP;
            /*Finaliza el proceso para generar las frases*/
                g_childNode := dbms_xmldom.appendchild( 
                    n => g_DatosEmisionElementNode, 
                    newchild => g_FrasesElementNode 
                );
        ELSE
            fnd_file.put_line(fnd_file.LOG,'NO VA A TENER FRASES');
        END IF;
-----------------------------------------------------------end frases
        g_childNode := dbms_xmldom.appendchild( 
            n => g_dteElementNode, 
            newchild => g_DatosEmisionElementNode 
        );
  EXCEPTION
    WHEN OTHERS THEN
        fnd_file.put_line(fnd_file.LOG,'Error general en genera_datos_fiscales_cabecero ' || sqlerrm);
        fnd_file.put_line(fnd_file.LOG,'Error en genera_datos_fiscales_cabecero ' || sqlerrm);
  END genera_datos_fiscales_cabecero;
  
 /*========================================================================================+
  |FUNCTION
  |         get_datos_frases
  |DESCRIPTION                                                                           
  |                         Función que obtiene los datos de las frases en el orden correcto
  |                                                                                      |
  |ARGUMENTS  
  |                         IN:
  |                                  p_level: orden de los datos de la frase
  |                         OUT:
  |
  |RETURNS
  |                         VARCHAR2:  Regresa el tipo de frase o el codigo escenario de acuerdo al parametro
  |HISTORY                                                                               |
  | Date         Author                 Version     Change Reference                     |
  |------------------------------------------------------------------------------------- |
  |2019/09/10   Amauri Cuahutle      1.0         Creación de Proceso                       |
  +======================================================================================*/
  FUNCTION get_datos_frases(p_level IN NUMBER,
                                                     p_frase IN VARCHAR2) RETURN VARCHAR2
  AS
    l_dato VARCHAR2(250);
  BEGIN
  
        SELECT
            regexp_substr(p_frase,'[^-]+',1,level)AS valores
            INTO l_dato
        FROM
            dual a
        WHERE level = p_level
        CONNECT BY
            regexp_substr(p_frase,'[^-]+',1,level)IS NOT NULL
        ORDER BY level;
        
        RETURN l_dato;
  
  EXCEPTION
    WHEN OTHERS THEN
        fnd_file.put_line(fnd_file.LOG,'Error en la funcion get_datos_frases ' || sqlerrm);
        RETURN null;
  END get_datos_frases;
  
   /*========================================================================================+
  |FUNCTION
  |         get_unidad_medida
  |DESCRIPTION                                                                           
  |                         Función que obtiene la unidad de medida cuando es una factura
  |                                                                                      |
  |ARGUMENTS  
  |                         IN:
  |                                  p_description: descripción de la linea de la factura de ar
  |                                  p_org_id: org id a contemplar
  |                                  p_uom_code: codigo de unidad de medida
  |                         OUT:
  |
  |RETURNS
  |                         VARCHAR2:  Regresa la unidad de medida desde el memo line
  |HISTORY                                                                               |
  | Date         Author                 Version     Change Reference                     |
  |------------------------------------------------------------------------------------- |
  |2019/09/10   Amauri Cuahutle      1.0         Creación de Proceso                       |
  +======================================================================================*/
  FUNCTION get_unidad_medida(p_description IN VARCHAR2,
                                                            p_org_id IN NUMBER,
                                                            p_uom_code IN VARCHAR2) RETURN VARCHAR2
  AS
  
    l_unidad_mediad fnd_lookup_values.description%TYPE;
    l_code ar_memo_lines_all_b.uom_code%TYPE;
  
  BEGIN
  
        SELECT description
        INTO l_unidad_mediad
        FROM fnd_lookup_values
        WHERE 1=1
        AND lookup_type = 'XXCMX_AR_FEL_GTM_SAT'
        AND enabled_flag = 'Y'
        AND language = userenv('lang')
        AND meaning = p_uom_code
        ;
        
        RETURN l_unidad_mediad;
  
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
        IF(p_uom_code IS NOT NULL)THEN
            l_unidad_mediad := p_uom_code;
        ELSE
                SELECT
                    b.uom_code
                    INTO l_code
                FROM
                    hr_operating_units     hou,
                    ar_memo_lines_all_tl   t,
                    ar_memo_lines_all_b    b
                WHERE
                    hou.organization_id = b.org_id
                    AND b.memo_line_id = t.memo_line_id
                    AND b.org_id = p_org_id
                    AND t.name = p_description
                    AND t.language = userenv('lang');
                    
                    SELECT description
                    INTO l_unidad_mediad
                    FROM fnd_lookup_values
                    WHERE 1=1
                    AND lookup_type = 'XXCMX_AR_FEL_GTM_SAT'
                    AND enabled_flag = 'Y'
                    AND language = userenv('lang')
                    AND UPPER(meaning) = UPPER(l_code)
                    ;
        END IF;
            
            RETURN l_unidad_mediad;
    WHEN OTHERS THEN
        fnd_file.put_line(fnd_file.LOG,'Error en la funcion get_unidad_medida ' || sqlerrm);
        RETURN null;
  END get_unidad_medida;
  
     /*========================================================================================+
  |FUNCTION
  |         get_descripcion_line
  |DESCRIPTION                                                                           
  |                         Función que obtiene la descripcion del long text o short text de la orden o de ar
  |                                                                                      |
  |ARGUMENTS  
  |                         IN:
  |                                  p_tx_line_id: ID de la linea a validar
  |                         OUT:
  |
  |RETURNS
  |                         VARCHAR2:  Regresa la descripción
  |HISTORY                                                                               |
  | Date         Author                 Version     Change Reference                     |
  |------------------------------------------------------------------------------------- |
  |2019/09/10   Amauri Cuahutle      1.0         Creación de Proceso                       |
  +======================================================================================*/
  FUNCTION get_descripcion_line(p_tx_line_id IN NUMBER,
                                                            p_attribute_6 IN NUMBER) RETURN VARCHAR2
  AS
    l_line_attch_long    fnd_documents_long_text.long_text%TYPE;
    l_line_attch_short   fnd_documents_short_text.short_text%TYPE;
    l_aux NUMBER;

BEGIN

    SELECT ool.line_id
    INTO l_aux
    FROM oe_order_headers_all ooh,
                 oe_order_lines_all ool
    WHERE 1=1
    AND ooh.header_id = ool.header_id
    AND TO_CHAR (ool.line_id) = p_attribute_6
    ;
    
    fnd_file.put_line(fnd_file.LOG,'Tiene relación con una orden de compra, es la correcta? => ' || l_aux);
    
    BEGIN
    
         SELECT TO_CHAR(TRIM(fdl.long_text))
           INTO l_line_attch_long
           FROM fnd_documents_long_text fdl
               ,fnd_documents           fd
               ,fnd_attached_documents  fad
          WHERE fdl.media_id = fd.media_id
            AND fd.document_id = fad.document_id
            AND fad.entity_name = 'OE_ORDER_LINES'
            AND fad.pk1_value = l_aux;
            
            fnd_file.put_line(fnd_file.LOG,'long text => ' || l_line_attch_long);
            
            RETURN l_line_attch_long;
    
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            fnd_file.put_line(fnd_file.LOG,'No hay nada en long text ');
            BEGIN
                SELECT TO_CHAR(TRIM(FDS.SHORT_TEXT))
                  INTO l_line_attch_short
                  FROM fnd_documents_short_text    fds
                      ,fnd_documents               fd
                      ,fnd_attached_documents      fad
                 WHERE fds.media_id = fd.media_id
                   AND fd.document_id = fad.document_id
                   AND fad.entity_name = 'OE_ORDER_HEADERS_LINES'
                   AND fd.datatype_id = 1
                   AND fad.pk1_value = l_aux;
                   
                   fnd_file.put_line(fnd_file.LOG,'short text => ' || l_line_attch_short);
                   
                   RETURN l_line_attch_short;
                   
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    fnd_file.put_line(fnd_file.LOG,'No hay nada en short text ');
                    RETURN null;
            END;
    END;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        fnd_file.put_line(fnd_file.LOG,'Financiera?');
        BEGIN
        
            SELECT fdl.long_text
              INTO l_line_attch_long
              FROM fnd_documents_long_text fdl
                  ,fnd_documents           fd
                  ,fnd_attached_documents  fad
             WHERE fad.pk1_value   = p_tx_line_id
               AND fad.entity_name = 'RA_CUSTOMER_TRX_LINES'
               AND fad.document_id = fd.document_id
               AND fd.media_id     = fdl.media_id;
               
               fnd_file.put_line(fnd_file.LOG,'long finn ' || l_line_attch_long);
               
               RETURN l_line_attch_long;
        
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                fnd_file.put_line(fnd_file.LOG,'Nada en long text finn ');
                BEGIN
                
                   SELECT fds.short_text
                     INTO l_line_attch_short
                     FROM fnd_documents_short_text fds
                         ,fnd_documents            fd
                         ,fnd_attached_documents   fad
                    WHERE fad.pk1_value   = p_tx_line_id
                      AND fad.entity_name = 'RA_CUSTOMER_TRX_LINES'
                      AND fad.document_id = fd.document_id
                      AND fd.media_id     = fds.media_id
                      AND fd.datatype_id  = 1;
                      
                      fnd_file.put_line(fnd_file.LOG,'short finn ' || l_line_attch_long);
                      
                      RETURN l_line_attch_short;
                
                EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                        fnd_file.put_line(fnd_file.LOG,'Nada en short text finn ');
                        RETURN null;
                END;
        END;
    WHEN OTHERS THEN
        fnd_file.put_line(fnd_file.LOG,'Error en la funcion get_descripcion_line ' || sqlerrm);
        RETURN null;
END get_descripcion_line;
  
   /*========================================================================================+
  |PROCEDURE
  |         genera_datos_fiscales
  |DESCRIPTION                                                                           
  |                         Procedimiento que genera la sección de los datos fiscales
  |                                                                                      |
  |ARGUMENTS  
  |                         IN:
                                 p_NumeroLinea : numero de linea,
                                p_BienOServicio: identificado bien o servicio,
                                P_Cantidad: cnatidad de la linea,
                                p_UnidadMedida : unidad de medida linea,
                                p_Descripcion: descripcion linea,
                                p_PrecioUnitario: precio unitario linea
                                p_Precio: precio linea
                                p_descuento: descuento linea
                                p_NombreCorto: nombre corto
                                p_CodigoUnidadGravable: monto unidad gravable
                                p_MontoGravable: monto gravable
                                p_CantidadUnidadesGravables:  cantidad gravable
                                p_MontoImpuesto: monto impuesto
  |                         OUT:
  |
  |
  |HISTORY                                                                               |
  | Date         Author                 Version     Change Reference                     |
  |------------------------------------------------------------------------------------- |
  |2019/09/10   Amauri Cuahutle      1.0         Creación de Proceso                       |
  +======================================================================================*/
  PROCEDURE genera_datos_fiscales_lines( p_NumeroLinea IN NUMBER,
                                                                            p_BienOServicio IN VARCHAR2,
                                                                            P_Cantidad IN NUMBER,
                                                                            p_UnidadMedida IN VARCHAR2,
                                                                            p_Descripcion IN VARCHAR2,
                                                                            p_PrecioUnitario IN NUMBER,
                                                                            p_Precio IN NUMBER,
                                                                            p_descuento IN NUMBER,
                                                                            p_NombreCorto IN VARCHAR2,
                                                                            p_CodigoUnidadGravable IN NUMBER,
                                                                            p_MontoGravable IN NUMBER,
                                                                            p_CantidadUnidadesGravables IN NUMBER,
                                                                            p_MontoImpuesto IN NUMBER,
                                                                            p_total IN NUMBER
                                                                          )
    AS
    
    
    BEGIN
    
        fnd_file.put_line(fnd_file.LOG,'Comienza el proceso de las líneas');
            --make Item element 
            g_ItemElement := dbms_xmldom.createelement( 
                doc => g_xmlDoc, 
                tagName => 'dte:Item'
            ); 
            
            add_attribute(g_ItemElement,'NumeroLinea', p_NumeroLinea);
            add_attribute(g_ItemElement,'BienOServicio', p_BienOServicio);
            
            g_ItemElementNode := dbms_xmldom.makenode( 
                elem => g_ItemElement 
            );
            
            --------------------------elementos del item--------------------------
                    --make Cantidad element 
                    g_CantidadElement := dbms_xmldom.createelement( 
                        doc => g_xmlDoc, 
                        tagName => 'dte:Cantidad'
                    ); 
                    
                    g_CantidadElementNode := dbms_xmldom.makenode( 
                        elem => g_CantidadElement 
                    );
                    
                        /*Se agrega el texto*/
                            g_nameText := dbms_xmldom.createtextnode( 
                                    doc => g_xmlDoc, 
                                    data => HTF.ESCAPE_SC ( p_Cantidad) 
                                ); 
                                 
                                --convert it to a node 
                                g_nameTextNode := dbms_xmldom.makenode( 
                                    t => g_nameText 
                                );
                                 
                                --add the name text to the name element 
                                g_childNode := dbms_xmldom.appendchild( 
                                    n => g_CantidadElementNode, 
                                    newchild => g_nameTextNode 
                                ); 
                         /*fin agrega el texto*/
                    
                    g_childNode := dbms_xmldom.appendchild( 
                        n => g_ItemElementNode, 
                        newchild => g_CantidadElementNode 
                    );
                    ------
                    --make UnidadMedida element 
                    g_UnidadMedidaElement := dbms_xmldom.createelement( 
                        doc => g_xmlDoc, 
                        tagName => 'dte:UnidadMedida'
                    ); 
                    
                    g_UnidadMedidaElementNode := dbms_xmldom.makenode( 
                        elem => g_UnidadMedidaElement 
                    );
                    
                        /*Se agrega el texto*/
                            g_nameText := dbms_xmldom.createtextnode( 
                                    doc => g_xmlDoc, 
                                    data => HTF.ESCAPE_SC ( p_UnidadMedida) 
                                ); 
                                 
                                --convert it to a node 
                                g_nameTextNode := dbms_xmldom.makenode( 
                                    t => g_nameText 
                                );
                                 
                                --add the name text to the name element 
                                g_childNode := dbms_xmldom.appendchild( 
                                    n => g_UnidadMedidaElementNode, 
                                    newchild => g_nameTextNode 
                                ); 
                         /*fin agrega el texto*/
                    
                    g_childNode := dbms_xmldom.appendchild( 
                        n => g_ItemElementNode, 
                        newchild => g_UnidadMedidaElementNode 
                    );
                    ------
                    --make Descripcion element 
                    g_DescripcionElement := dbms_xmldom.createelement( 
                        doc => g_xmlDoc, 
                        tagName => 'dte:Descripcion'
                    ); 
                    
                    g_DescripcionElementNode := dbms_xmldom.makenode( 
                        elem => g_DescripcionElement 
                    );
                    
                        /*Se agrega el texto*/
                            g_nameText := dbms_xmldom.createtextnode( 
                                    doc => g_xmlDoc, 
                                    data => HTF.ESCAPE_SC ( p_Descripcion) 
                                ); 
                                 
                                --convert it to a node 
                                g_nameTextNode := dbms_xmldom.makenode( 
                                    t => g_nameText 
                                );
                                 
                                --add the name text to the name element 
                                g_childNode := dbms_xmldom.appendchild( 
                                    n => g_DescripcionElementNode, 
                                    newchild => g_nameTextNode 
                                ); 
                         /*fin agrega el texto*/
                    
                    g_childNode := dbms_xmldom.appendchild( 
                        n => g_ItemElementNode, 
                        newchild => g_DescripcionElementNode 
                    );
                    ------
                    --make PrecioUnitario element 
                    g_PrecioUnitarioElement := dbms_xmldom.createelement( 
                        doc => g_xmlDoc, 
                        tagName => 'dte:PrecioUnitario'
                    ); 
                    
                    g_PrecioUnitarioElementNode := dbms_xmldom.makenode( 
                        elem => g_PrecioUnitarioElement 
                    );
                    
                        /*Se agrega el texto*/
                            g_nameText := dbms_xmldom.createtextnode( 
                                    doc => g_xmlDoc, 
                                    data => HTF.ESCAPE_SC ( p_PrecioUnitario) 
                                ); 
                                 
                                --convert it to a node 
                                g_nameTextNode := dbms_xmldom.makenode( 
                                    t => g_nameText 
                                );
                                 
                                --add the name text to the name element 
                                g_childNode := dbms_xmldom.appendchild( 
                                    n => g_PrecioUnitarioElementNode, 
                                    newchild => g_nameTextNode 
                                ); 
                         /*fin agrega el texto*/
                    
                    g_childNode := dbms_xmldom.appendchild( 
                        n => g_ItemElementNode, 
                        newchild => g_PrecioUnitarioElementNode 
                    );
                    ------
                    --make Precio element 
                    g_PrecioElement := dbms_xmldom.createelement( 
                        doc => g_xmlDoc, 
                        tagName => 'dte:Precio'
                    ); 
                    
                    g_PrecioElementNode := dbms_xmldom.makenode( 
                        elem => g_PrecioElement 
                    );
                    
                        /*Se agrega el texto*/
                            g_nameText := dbms_xmldom.createtextnode( 
                                    doc => g_xmlDoc, 
                                    data => HTF.ESCAPE_SC ( p_precio) 
                                ); 
                                 
                                --convert it to a node 
                                g_nameTextNode := dbms_xmldom.makenode( 
                                    t => g_nameText 
                                );
                                 
                                --add the name text to the name element 
                                g_childNode := dbms_xmldom.appendchild( 
                                    n => g_PrecioElementNode, 
                                    newchild => g_nameTextNode 
                                ); 
                         /*fin agrega el texto*/
                    
                    g_childNode := dbms_xmldom.appendchild( 
                        n => g_ItemElementNode, 
                        newchild => g_PrecioElementNode 
                    );
                    ------
                    --make Descuento element 
                    g_DescuentoElement := dbms_xmldom.createelement( 
                        doc => g_xmlDoc, 
                        tagName => 'dte:Descuento'
                    ); 
                    
                    g_DescuentoElementNode := dbms_xmldom.makenode( 
                        elem => g_DescuentoElement 
                    );
                    
                        /*Se agrega el texto*/
                            g_nameText := dbms_xmldom.createtextnode( 
                                    doc => g_xmlDoc, 
                                    data => HTF.ESCAPE_SC ( p_descuento) 
                                ); 
                                 
                                --convert it to a node 
                                g_nameTextNode := dbms_xmldom.makenode( 
                                    t => g_nameText 
                                );
                                 
                                --add the name text to the name element 
                                g_childNode := dbms_xmldom.appendchild( 
                                    n => g_DescuentoElementNode, 
                                    newchild => g_nameTextNode 
                                ); 
                         /*fin agrega el texto*/
                    
                    g_childNode := dbms_xmldom.appendchild( 
                        n => g_ItemElementNode, 
                        newchild => g_DescuentoElementNode 
                    );
                    ------
                    --make Impuestos element 
                    g_ImpuestosElement := dbms_xmldom.createelement( 
                        doc => g_xmlDoc, 
                        tagName => 'dte:Impuestos'
                    ); 
                    
                    g_ImpuestosElementNode := dbms_xmldom.makenode( 
                        elem => g_ImpuestosElement 
                    );
                    
                    --make Impuesto element 
                    g_ImpuestoElement := dbms_xmldom.createelement( 
                        doc => g_xmlDoc, 
                        tagName => 'dte:Impuesto'
                    ); 
                    
                    g_ImpuestoElementNode := dbms_xmldom.makenode( 
                        elem => g_ImpuestoElement 
                    );
                    
                    --------impuestos elements
                                --make NombreCorto element 
                                    g_NombreCortoElement := dbms_xmldom.createelement( 
                                        doc => g_xmlDoc, 
                                        tagName => 'dte:NombreCorto'
                                    ); 
                                    
                                    g_NombreCortoElementNode := dbms_xmldom.makenode( 
                                        elem => g_NombreCortoElement 
                                    );
                                    
                                        /*Se agrega el texto*/
                                            g_nameText := dbms_xmldom.createtextnode( 
                                                    doc => g_xmlDoc, 
                                                    data => HTF.ESCAPE_SC ( p_NombreCorto) 
                                                ); 
                                                 
                                                --convert it to a node 
                                                g_nameTextNode := dbms_xmldom.makenode( 
                                                    t => g_nameText 
                                                );
                                                 
                                                --add the name text to the name element 
                                                g_childNode := dbms_xmldom.appendchild( 
                                                    n => g_NombreCortoElementNode, 
                                                    newchild => g_nameTextNode 
                                                ); 
                                         /*fin agrega el texto*/
                                    
                                    g_childNode := dbms_xmldom.appendchild( 
                                        n => g_ImpuestoElementNode, 
                                        newchild => g_NombreCortoElementNode 
                                    );
                    ---------
                                --make CodigoUnidadGravable element 
                                    g_CodigoUnidadGrElement := dbms_xmldom.createelement( 
                                        doc => g_xmlDoc, 
                                        tagName => 'dte:CodigoUnidadGravable'
                                    ); 
                                    
                                    g_CodigoUnidadGrElementNode := dbms_xmldom.makenode( 
                                        elem => g_CodigoUnidadGrElement 
                                    );
                                    
                                        /*Se agrega el texto*/
                                            g_nameText := dbms_xmldom.createtextnode( 
                                                    doc => g_xmlDoc, 
                                                    data => HTF.ESCAPE_SC ( p_CodigoUnidadGravable) 
                                                ); 
                                                 
                                                --convert it to a node 
                                                g_nameTextNode := dbms_xmldom.makenode( 
                                                    t => g_nameText 
                                                );
                                                 
                                                --add the name text to the name element 
                                                g_childNode := dbms_xmldom.appendchild( 
                                                    n => g_CodigoUnidadGrElementNode, 
                                                    newchild => g_nameTextNode 
                                                ); 
                                         /*fin agrega el texto*/
                                    
                                    g_childNode := dbms_xmldom.appendchild( 
                                        n => g_ImpuestoElementNode, 
                                        newchild => g_CodigoUnidadGrElementNode 
                                    );
                    ---------
                                --make MontoGravable element 
                                    g_MontoGravableElement := dbms_xmldom.createelement( 
                                        doc => g_xmlDoc, 
                                        tagName => 'dte:MontoGravable'
                                    ); 
                                    
                                    g_MontoGravableElementNode := dbms_xmldom.makenode( 
                                        elem => g_MontoGravableElement 
                                    );
                                    
                                        /*Se agrega el texto*/
                                            g_nameText := dbms_xmldom.createtextnode( 
                                                    doc => g_xmlDoc, 
                                                    data => HTF.ESCAPE_SC ( p_MontoGravable) 
                                                ); 
                                                 
                                                --convert it to a node 
                                                g_nameTextNode := dbms_xmldom.makenode( 
                                                    t => g_nameText 
                                                );
                                                 
                                                --add the name text to the name element 
                                                g_childNode := dbms_xmldom.appendchild( 
                                                    n => g_MontoGravableElementNode, 
                                                    newchild => g_nameTextNode 
                                                ); 
                                         /*fin agrega el texto*/
                                    
                                    g_childNode := dbms_xmldom.appendchild( 
                                        n => g_ImpuestoElementNode, 
                                        newchild => g_MontoGravableElementNode 
                                    );
                    ---------
                                --make CantidadUnidadesGravables element 
                                  /*  g_CantidadUnidadesGElement := dbms_xmldom.createelement( 
                                        doc => g_xmlDoc, 
                                        tagName => 'dte:CantidadUnidadesGravables'
                                    ); 
                                    
                                    g_CantidadUnidadesGElementNode := dbms_xmldom.makenode( 
                                        elem => g_CantidadUnidadesGElement 
                                    );
                                    
                                            g_nameText := dbms_xmldom.createtextnode( 
                                                    doc => g_xmlDoc, 
                                                    data => HTF.ESCAPE_SC ( p_CantidadUnidadesGravables) 
                                                ); 
                                                 
                                                g_nameTextNode := dbms_xmldom.makenode( 
                                                    t => g_nameText 
                                                );
                                                 
                                                g_childNode := dbms_xmldom.appendchild( 
                                                    n => g_CantidadUnidadesGElementNode, 
                                                    newchild => g_nameTextNode 
                                                ); 
                                    
                                    g_childNode := dbms_xmldom.appendchild( 
                                        n => g_ImpuestoElementNode, 
                                        newchild => g_CantidadUnidadesGElementNode 
                                    );
                                    */
                    ---------
                                --make MontoImpuesto element 
                                    g_MontoImpuestoElement := dbms_xmldom.createelement( 
                                        doc => g_xmlDoc, 
                                        tagName => 'dte:MontoImpuesto'
                                    ); 
                                    
                                    g_MontoImpuestoElementNode := dbms_xmldom.makenode( 
                                        elem => g_MontoImpuestoElement 
                                    );
                                    
                                        /*Se agrega el texto*/
                                            g_nameText := dbms_xmldom.createtextnode( 
                                                    doc => g_xmlDoc, 
                                                    data => HTF.ESCAPE_SC ( p_MontoImpuesto) 
                                                ); 
                                                 
                                                --convert it to a node 
                                                g_nameTextNode := dbms_xmldom.makenode( 
                                                    t => g_nameText 
                                                );
                                                 
                                                --add the name text to the name element 
                                                g_childNode := dbms_xmldom.appendchild( 
                                                    n => g_MontoImpuestoElementNode, 
                                                    newchild => g_nameTextNode 
                                                ); 
                                         /*fin agrega el texto*/
                                    
                                    g_childNode := dbms_xmldom.appendchild( 
                                        n => g_ImpuestoElementNode, 
                                        newchild => g_MontoImpuestoElementNode 
                                    );
                    ---------
                    g_childNode := dbms_xmldom.appendchild( 
                        n => g_ImpuestosElementNode, 
                        newchild => g_ImpuestoElementNode 
                    );
                    
                    g_childNode := dbms_xmldom.appendchild( 
                        n => g_ItemElementNode, 
                        newchild => g_ImpuestosElementNode 
                    );
                    ------
                        --------------------------------------------------------------------------------------------------------------------
                        --make a Total element 
                        g_TotalElement := dbms_xmldom.createelement( 
                            doc => g_xmlDoc, 
                            tagName => 'dte:Total'
                        ); 
                        
                        g_TotalElementNode := dbms_xmldom.makenode( 
                            elem => g_TotalElement 
                        ); 
                        agrega_texto_nodo(p_total,g_TotalElementNode);
                        
                        g_childNode := dbms_xmldom.appendchild( 
                            n => g_ItemElementNode, 
                            newchild => g_TotalElementNode 
                        );
                    --------------------------------------------------------------------------------------------------------------------
             --------------------------end lementos del item--------------------------
            g_childNode := dbms_xmldom.appendchild( 
                n => g_ItemsElementNode, 
                newchild => g_ItemElementNode 
            );
        
    EXCEPTION
        WHEN OTHERS THEN
            fnd_file.put_line(fnd_file.LOG,'Error en el procedimiento genera_datos_fiscales_lines ' || sqlerrm);
    END genera_datos_fiscales_lines;
  
     /*========================================================================================+
  |PROCEDURE
  |         genera_totales
  |DESCRIPTION                                                                           
  |                         Procedimiento que genera la sección de los totales
  |                                                                                      |
  |ARGUMENTS  
  |                         IN:
                                 p_NumeroLinea : numero de linea,
  |
  |                         OUT:
  |
  |
  |HISTORY                                                                               |
  | Date         Author                 Version     Change Reference                     |
  |------------------------------------------------------------------------------------- |
  |2019/09/10   Amauri Cuahutle      1.0         Creación de Proceso                       |
  +======================================================================================*/
  PROCEDURE genera_totales( p_customer_trx_id IN NUMBER
                                                    )
    AS
    
    
    BEGIN
    
        SELECT 'IVA' NombreCorto, --46
                      SUM(zlv.tax_amt) TotalMontoImpuesto --47
        INTO g_NombreCorto,g_TotalMontoImpuesto
        FROM ra_customer_trx_all rcta,
                    ra_customer_trx_lines_all rctla,
                    zx_lines_v zlv
        WHERE 1=1
        AND rcta.customer_trx_id = rctla.customer_trx_id
        -----parametros------
        AND rcta.customer_trx_id = p_customer_trx_id
        -----end parametros------
        ----lineas
        AND rctla.line_type = 'LINE'
        AND zlv.trx_id = rcta.customer_trx_id
        AND zlv.trx_line_id = rctla.customer_trx_line_id
        AND zlv.trx_level_type = 'LINE'
        ;
        
        SELECT 
                      SUM(amount_due_original)
        INTO g_amount_due_original
        FROM ar_payment_schedules_all
        WHERE 1=1
        AND customer_trx_id = p_customer_trx_id
        ;
        
            --make Totales element 
            g_TotalesElement := dbms_xmldom.createelement( 
                doc => g_xmlDoc, 
                tagName => 'dte:Totales'
            ); 
            
            g_TotalesElementNode := dbms_xmldom.makenode( 
                elem => g_TotalesElement 
            );
            
                    --make TotalImpuestos element 
                    g_TotalImpElement := dbms_xmldom.createelement( 
                        doc => g_xmlDoc, 
                        tagName => 'dte:TotalImpuestos'
                    ); 
                    
                    g_TotalImpElementNode := dbms_xmldom.makenode( 
                        elem => g_TotalImpElement 
                    );
                    
                        --make TotalImpuesto element 
                        g_TotalImpuestoElement := dbms_xmldom.createelement( 
                            doc => g_xmlDoc, 
                            tagName => 'dte:TotalImpuesto'
                        ); 
                        
                        add_attribute(g_TotalImpuestoElement,'NombreCorto', g_NombreCorto);
                        add_attribute(g_TotalImpuestoElement,'TotalMontoImpuesto', g_TotalMontoImpuesto);
                        
                        g_TotalImpuestoElementNode := dbms_xmldom.makenode( 
                            elem => g_TotalImpuestoElement 
                        );
                        
                        g_childNode := dbms_xmldom.appendchild( 
                            n => g_TotalImpElementNode, 
                            newchild => g_TotalImpuestoElementNode 
                        );
                    
                    g_childNode := dbms_xmldom.appendchild( 
                        n => g_TotalesElementNode, 
                        newchild => g_TotalImpElementNode 
                    );
                    
                    --make GranTotal element 
                    g_GranTotalElement := dbms_xmldom.createelement( 
                        doc => g_xmlDoc, 
                        tagName => 'dte:GranTotal'
                    ); 
                    
                    g_GranTotalElementNode := dbms_xmldom.makenode( 
                        elem => g_GranTotalElement 
                    );
                    
                            /*Se agrega el texto*/
                                g_nameText := dbms_xmldom.createtextnode( 
                                        doc => g_xmlDoc, 
                                        data => HTF.ESCAPE_SC ( g_amount_due_original ) 
                                    ); 
                                     
                                    --convert it to a node 
                                    g_nameTextNode := dbms_xmldom.makenode( 
                                        t => g_nameText 
                                    );
                                     
                                    --add the name text to the name element 
                                    g_childNode := dbms_xmldom.appendchild( 
                                        n => g_GranTotalElementNode, 
                                        newchild => g_nameTextNode 
                                    ); 
                             /*fin agrega el texto*/
                    
                    g_childNode := dbms_xmldom.appendchild( 
                        n => g_TotalesElementNode, 
                        newchild => g_GranTotalElementNode 
                    );
            
            g_childNode := dbms_xmldom.appendchild( 
                n => g_DatosEmisionElementNode, 
                newchild => g_TotalesElementNode 
            );
    
    EXCEPTION
        WHEN OTHERS THEN
            fnd_file.put_line(fnd_file.LOG,'Error en el procedimiento genera_totales ' || sqlerrm);
    END genera_totales;

     /*========================================================================================+
  |FUNCTION
  |         get_intercom
  |DESCRIPTION                                                                           
  |                         Procedimiento que obtiene el intercom de un pedido
  |                                                                                      |
  |ARGUMENTS  
  |                         IN:
                                 p_customer_tx_id : Id de la factura
  |                              p_order_num: Numero de la orden de compra
  |
  |
  |RETURNS
  |                 VARCHAR2:  Regresa el intecom del pedido
  |
  |HISTORY                                                                               |
  | Date         Author                 Version     Change Reference                     |
  |------------------------------------------------------------------------------------- |
  |2019/09/10   Amauri Cuahutle      1.0         Creación de Proceso                       |
  +======================================================================================*/
  FUNCTION get_intercom(p_customer_tx_id IN NUMBER, p_order_num IN VARCHAR2) RETURN VARCHAR2
  AS
  
    l_intercom oe_order_headers_all.attribute6%TYPE;
    l_header_id NUMBER;
  
  BEGIN
  
    SELECT 
           MAX(ooh.attribute6)
      INTO l_intercom
      FROM oe_order_headers_all ooh,
           oe_order_lines_all ool,
           ra_customer_trx_all rcta,
           ra_customer_trx_lines_all rctl
     WHERE ooh.header_id = ool.header_id
       AND rctl.interface_line_attribute1 = TO_CHAR (ooh.order_number)
       AND rctl.interface_line_attribute6 = TO_CHAR (ool.line_id)
       AND rctl.customer_trx_id = rcta.customer_trx_id
       AND ooh.order_number = p_order_num
       AND rcta.customer_trx_id = p_customer_tx_id
    ;
    fnd_file.put_line(fnd_file.LOG,'Regresa el intercom ' || l_intercom);
    IF(l_intercom IS NULL)THEN
            SELECT attribute6
            INTO l_intercom
            FROM oe_order_headers_all
            WHERE order_number = p_order_num
            AND org_id = MO_GLOBAL.GET_CURRENT_ORG_ID
            ;
    END IF;
    
    IF(l_intercom IS NULL)THEN
        fnd_file.put_line(fnd_file.LOG,'No se encontro el intercom en el pedido, se buscara en el adjunto ');
        RAISE NO_DATA_FOUND;
    END IF;
    
    RETURN l_intercom;
    
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
        SELECT header_id
        INTO l_header_id
        FROM oe_order_headers_all
        WHERE order_number = p_order_num
        AND org_id = MO_GLOBAL.GET_CURRENT_ORG_ID
        ;
    
    BEGIN
             SELECT TO_CHAR(TRIM(fdl.long_text))
               INTO l_intercom
               FROM fnd_documents_long_text fdl
                   ,fnd_documents           fd
                   ,fnd_attached_documents  fad
              WHERE fdl.media_id = fd.media_id
                AND fd.document_id = fad.document_id
                AND fad.entity_name = 'OE_ORDER_HEADERS'
                AND fad.pk1_value = l_header_id;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                    SELECT TO_CHAR(TRIM(FDS.SHORT_TEXT))
                      INTO l_intercom
                      FROM fnd_documents_short_text    fds
                          ,fnd_documents               fd
                          ,fnd_attached_documents      fad
                     WHERE fds.media_id = fd.media_id
                       AND fd.document_id = fad.document_id
                       AND fad.entity_name = 'OE_ORDER_HEADERS'
                       AND fd.datatype_id = 1
                       AND fad.pk1_value = l_header_id;
        END;
        RETURN l_intercom;
    WHEN OTHERS THEN
        fnd_file.put_line(fnd_file.LOG,'Error en  get_intercom ' || sqlerrm);
        RETURN l_intercom;
  END get_intercom;
     /*========================================================================================+
  |PROCEDURE
  |         genera_complementos
  |DESCRIPTION                                                                           
  |                         Procedimiento que genera la sección de los complementos
  |                                                                                      |
  |ARGUMENTS  
  |                         IN:
                                 p_type : tipo de documento
  |                              p_tipo: tipo del documento calculado
  |                              p_exp:  identificador de eportación
  |                              P_customer_trx_id:  id de la factura de AR
  |
  |                         OUT:
  |
  |
  |HISTORY                                                                               |
  | Date         Author                 Version     Change Reference                     |
  |------------------------------------------------------------------------------------- |
  |2019/09/10   Amauri Cuahutle      1.0         Creación de Proceso                       |
  +======================================================================================*/
  PROCEDURE genera_complementos( p_type IN VARCHAR2,
                                                                    p_tipo IN VARCHAR2,
                                                                    p_exp IN VARCHAR2,
                                                                    P_customer_trx_id IN NUMBER,
                                                                    p_nombrer IN VARCHAR2,
                                                                    p_direccionr IN VARCHAR2,
                                                                    p_order_num IN VARCHAR2
                                                                   )
  AS
  
    CURSOR c_abonos
    IS
    SELECT terms_sequence_number,
              TO_CHAR(Due_Date,'YYYY-MM-DD')Due_Date,
              amount_due_original
    FROM ar_payment_schedules_all
    WHERE 1=1
    AND customer_trx_id = P_customer_trx_id;
  
  BEGIN
  
    --make Complementos element 
    g_ComplementosElement := dbms_xmldom.createelement( 
        doc => g_xmlDoc, 
        tagName => 'dte:Complementos'
    ); 
    
    g_ComplementosElementNode := dbms_xmldom.makenode( 
        elem => g_ComplementosElement 
    );
                    --make Complemento element 
                    g_ComplementoElement := dbms_xmldom.createelement( 
                        doc => g_xmlDoc, 
                        tagName => 'dte:Complemento'
                    ); 
                    g_ComplementoElementNode := dbms_xmldom.makenode( 
                        elem => g_ComplementoElement 
                    );
   /*Factura cambiaria*/
    IF(p_tipo = 'FCAM' AND p_exp IS NULL)THEN
    
        fnd_file.put_line(fnd_file.LOG,'Comienza el proceso de complementos para la factura cambiaria');
            

                    add_attribute(g_ComplementoElement,'NombreComplemento', 'GT_Complemento_Cambiaria');
                    add_attribute(g_ComplementoElement,'URIComplemento', 'https://cat.desa.sat.gob.gt/xsd/alfa/GT_Complemento_Cambiaria-0.1.0.xsd');
                    
                            --make AbonosFacturaCambiaria element 
                            g_AbonosFactElement := dbms_xmldom.createelement( 
                                doc => g_xmlDoc, 
                                tagName => 'cfc:AbonosFacturaCambiaria'
                            ); 
                            add_attribute(g_AbonosFactElement,'Version', '1');
                            
                            g_AbonosFactElementNode := dbms_xmldom.makenode( 
                                elem => g_AbonosFactElement 
                            );
                            
            
        FOR r_abonos IN c_abonos LOOP
                                        
                                    --make Abono element 
                                    g_AbonosElement := dbms_xmldom.createelement( 
                                        doc => g_xmlDoc, 
                                        tagName => 'cfc:Abono'
                                    ); 
                                    
                                    g_AbonoElementNode := dbms_xmldom.makenode( 
                                        elem => g_AbonosElement 
                                    );
                                    
                                            --make NumeroAbono element 
                                            g_NumeroAbonoElement := dbms_xmldom.createelement( 
                                                doc => g_xmlDoc, 
                                                tagName => 'cfc:NumeroAbono'
                                            ); 
                                            
                                            g_NumeroAbonoElementNode := dbms_xmldom.makenode( 
                                                elem => g_NumeroAbonoElement 
                                            );
                                            
                                            agrega_texto_nodo(r_abonos.terms_sequence_number,g_NumeroAbonoElementNode);
                                            
                                            g_childNode := dbms_xmldom.appendchild( 
                                                n => g_AbonoElementNode, 
                                                newchild => g_NumeroAbonoElementNode 
                                            );
                                            
                                            --make FechaVencimiento element 
                                            g_FechaVencElement := dbms_xmldom.createelement( 
                                                doc => g_xmlDoc, 
                                                tagName => 'cfc:FechaVencimiento'
                                            ); 
                                            
                                            g_FechaVencElementNode := dbms_xmldom.makenode( 
                                                elem => g_FechaVencElement 
                                            );
                                            
                                            agrega_texto_nodo(r_abonos.Due_Date,g_FechaVencElementNode);
                                            
                                            g_childNode := dbms_xmldom.appendchild( 
                                                n => g_AbonoElementNode, 
                                                newchild => g_FechaVencElementNode 
                                            );
                                            
                                            --make MontoAbono element 
                                            g_MontoAbonoElement := dbms_xmldom.createelement( 
                                                doc => g_xmlDoc, 
                                                tagName => 'cfc:MontoAbono'
                                            ); 
                                            
                                            g_MontoAbonoElementNode := dbms_xmldom.makenode( 
                                                elem => g_MontoAbonoElement 
                                            );
                                            
                                            agrega_texto_nodo(r_abonos.amount_due_original,g_MontoAbonoElementNode);
                                            
                                            g_childNode := dbms_xmldom.appendchild( 
                                                n => g_AbonoElementNode, 
                                                newchild => g_MontoAbonoElementNode 
                                            );
                                    
                                    g_childNode := dbms_xmldom.appendchild( 
                                        n => g_AbonosFactElementNode, 
                                        newchild => g_AbonoElementNode 
                                    );
        END LOOP;
        
                            g_childNode := dbms_xmldom.appendchild( 
                                n => g_ComplementoElementNode, 
                                newchild => g_AbonosFactElementNode 
                            );
                    

        ELSIF(p_exp IS NOT NULL)THEN
        
            --------------------------------------------------------------------------------------------------------------------
                add_attribute(g_ComplementoElement,'NombreComplemento', 'GT_Complemento_Exportaciones');
                add_attribute(g_ComplementoElement,'URIComplemento', 'http://www.sat.gob.gt/face2/ComplementoExportaciones/0.1.0');
                        --------------------------------------------------------------------------------------------------------------------
                        --make a Exportacion element 
                        g_ExportacionElement := dbms_xmldom.createelement( 
                            doc => g_xmlDoc, 
                            tagName => 'cex:Exportacion'
                        ); 
                        add_attribute(g_ExportacionElement,'Version', '1');
                        
                        g_ExportacionElementNode := dbms_xmldom.makenode( 
                            elem => g_ExportacionElement 
                        ); 
                        
                                    --------------------------------------------------------------------------------------------------------------------
                                    --make a NombreConsignatarioODestinatario element 
                                    g_NombreCODElement := dbms_xmldom.createelement( 
                                        doc => g_xmlDoc, 
                                        tagName => 'cex:NombreConsignatarioODestinatario'
                                    ); 
                                    
                                    g_NombreCODElementNode := dbms_xmldom.makenode( 
                                        elem => g_NombreCODElement 
                                    ); 
                                    agrega_texto_nodo(p_nombrer,g_NombreCODElementNode);
                                    
                                    g_childNode := dbms_xmldom.appendchild( 
                                        n => g_ExportacionElementNode, 
                                        newchild => g_NombreCODElementNode 
                                    );
                                --------------------------------------------------------------------------------------------------------------------
                                    --------------------------------------------------------------------------------------------------------------------
                                    --make a DireccionConsignatarioODestinatario element 
                                    g_DireccionCODElement := dbms_xmldom.createelement( 
                                        doc => g_xmlDoc, 
                                        tagName => 'cex:DireccionConsignatarioODestinatario'
                                    ); 
                                    
                                    g_DireccionCODElementNode := dbms_xmldom.makenode( 
                                        elem => g_DireccionCODElement 
                                    ); 
                                    agrega_texto_nodo(p_direccionr,g_DireccionCODElementNode);
                                    
                                    g_childNode := dbms_xmldom.appendchild( 
                                        n => g_ExportacionElementNode, 
                                        newchild => g_DireccionCODElementNode 
                                    );
                                --------------------------------------------------------------------------------------------------------------------
                                    --------------------------------------------------------------------------------------------------------------------
                                    --make a DireccionConsignatarioODestinatario element 
                                    g_INCOTERMElement := dbms_xmldom.createelement( 
                                        doc => g_xmlDoc, 
                                        tagName => 'cex:INCOTERM'
                                    ); 
                                    
                                    g_INCOTERMElementNode := dbms_xmldom.makenode( 
                                        elem => g_INCOTERMElement 
                                    ); 
                                    agrega_texto_nodo(get_intercom(P_customer_trx_id,p_order_num),g_INCOTERMElementNode);
                                    
                                    g_childNode := dbms_xmldom.appendchild( 
                                        n => g_ExportacionElementNode, 
                                        newchild => g_INCOTERMElementNode 
                                    );
                                --------------------------------------------------------------------------------------------------------------------
                        
                        g_childNode := dbms_xmldom.appendchild( 
                            n => g_ComplementoElementNode, 
                            newchild => g_ExportacionElementNode 
                        );
                    --------------------------------------------------------------------------------------------------------------------
            --------------------------------------------------------------------------------------------------------------------
        ELSIF(p_tipo = 'NCRE')THEN
            null;
        END IF;
                    g_childNode := dbms_xmldom.appendchild( 
                        n => g_ComplementosElementNode, 
                        newchild => g_ComplementoElementNode 
                    );
    g_childNode := dbms_xmldom.appendchild( 
        n => g_DatosEmisionElementNode, 
        newchild => g_ComplementosElementNode 
    );
  EXCEPTION
    WHEN OTHERS THEN
        fnd_file.put_line(fnd_file.LOG,'Error en el procedimiento genera_complementos ' || sqlerrm);
  END genera_complementos;
  
     /*========================================================================================+
  |PROCEDURE
  |         genera_nodos_documento_adenda
  |DESCRIPTION                                                                           
  |                         Procedimiento que genera los nodos de documento
  |                                                                                      |
  |ARGUMENTS  
  |                         IN:
                                        p_type:  tipo de transacción
                                        p_tipo : tipo calculado
                                        p_exp: exp calculado
                                        p_fechahora_emision: fecha de la factura
                                        p_codigo_moneda : divisa
                                        p_numero_acceso : numero acceso
                                        p_nit_emisor : nit del emisor
                                        p_nombre_emisor : nombre del emisor
                                        p_codigo_establecimiento: codigo del establecimiento
                                        p_nombre_comercial: nombre comercial
                                        p_correo_emisor : correo emisor
                                        p_afiliacion_iva : afiliación iva
                                        p_direccion : dirección
                                        p_codigo_postal : codigo postal
                                        p_municipio : municpio
                                        p_departamento : departamento
                                        p_pais : pais
                                        p_id_receptor: cuenta del cliente,
                                        p_tipo_especial: tipo especial
                                        p_nombre_receptor : nombre receptor
                                        p_correo_receptor: correo receptor
                                        p_direccion_r : dirección receptor
                                        p_codigo_postal_r codigo postal receptor
                                        p_municipio_r municipio receptor
                                        p_departamento_r : departamento receptor
                                        p_pais_r : país receptor
  |
  |                         OUT:
  |
  |
  |HISTORY                                                                               |
  | Date         Author                 Version     Change Reference                     |
  |------------------------------------------------------------------------------------- |
  |2019/09/10   Amauri Cuahutle      1.0         Creación de Proceso                       |
  +======================================================================================*/
  PROCEDURE genera_nodos_documento_adenda(
                                                                                          p_tipo IN VARCHAR2,
                                                                                          p_exp IN VARCHAR2,
                                                                                          p_FechaHoraEmision IN VARCHAR2,
                                                                                          P_CodigoMoneda IN VARCHAR2,
                                                                                          P_NITEmisor IN VARCHAR2,
                                                                                          P_NombreEmisor IN VARCHAR2,
                                                                                          P_CodigoEstablecimiento IN VARCHAR2,
                                                                                          P_NombreComercial IN VARCHAR2,
                                                                                          P_CorreoEmisor IN VARCHAR2,
                                                                                          P_AfiliacionIVA IN VARCHAR2,
                                                                                          P_Direccion IN VARCHAR2,
                                                                                          P_CodigoPostal IN VARCHAR2,
                                                                                          P_Municipio IN VARCHAR2,
                                                                                          P_Departamento IN VARCHAR2,
                                                                                          P_Pais IN VARCHAR2,
                                                                                          P_IDReceptor IN VARCHAR2,
                                                                                          P_TipoEspecial IN VARCHAR2,
                                                                                          P_NombreReceptor IN VARCHAR2,
                                                                                          P_CorreoReceptor IN VARCHAR2,
                                                                                          P_DireccionR IN VARCHAR2,
                                                                                          P_CodigoPostalR IN VARCHAR2,
                                                                                          P_MunicipioR IN VARCHAR2,
                                                                                          P_DepartamentoR IN VARCHAR2,
                                                                                          p_PaisR IN VARCHAR2
                                                                                         )
  AS
  
    CURSOR c_frases
    IS
    SELECT meaning,
                  NVL(upper(trim(tag)),' ') tag,
                  apps.XXCMX_AR_XML_FACT_GT_PKG.get_datos_frases(1,meaning) TipoFrase,
                  apps.XXCMX_AR_XML_FACT_GT_PKG.get_datos_frases(2,meaning) CodigoEscenario
    FROM fnd_lookup_values
    WHERE 1=1
    AND lookup_type = 'XXCMX_AR_FEL_GTM_FRASES_COD'
    AND language = USERENV('LANG')
    AND enabled_flag = 'Y'
    ;
  
  BEGIN
  
            --------------------------------------------------------------------------------------------------------------------
                --make a Encabezado element 
                g_EncabezadoElement := dbms_xmldom.createelement( 
                    doc => g_xmlDoc, 
                    tagName => 'ecfd:Encabezado'
                ); 
                
                g_EncabezadoElementNode := dbms_xmldom.makenode( 
                    elem => g_EncabezadoElement 
                ); 
                
                        --------------------------------------------------------------------------------------------------------------------
                            --make a IdDoc element 
                            g_IdDocElement := dbms_xmldom.createelement( 
                                doc => g_xmlDoc, 
                                tagName => 'ecfd:IdDoc'
                            ); 
                            
                            g_IdDocElementNode := dbms_xmldom.makenode( 
                                elem => g_IdDocElement 
                            ); 
                            
                                --------------------------------------------------------------------------------------------------------------------
                                    --make a Tipo element 
                                    g_TipoElement := dbms_xmldom.createelement( 
                                        doc => g_xmlDoc, 
                                        tagName => 'ecfd:Tipo'
                                    ); 
                                    
                                    g_TipoElementNode := dbms_xmldom.makenode( 
                                        elem => g_TipoElement 
                                    ); 
                                    agrega_texto_nodo('39',g_TipoElementNode);
                                    
                                    g_childNode := dbms_xmldom.appendchild( 
                                        n => g_IdDocElementNode, 
                                        newchild => g_TipoElementNode 
                                    );
                                --------------------------------------------------------------------------------------------------------------------
                                --------------------------------------------------------------------------------------------------------------------
                                    --make a FechaEmis element 
                                    g_FechaEmisElement := dbms_xmldom.createelement( 
                                        doc => g_xmlDoc, 
                                        tagName => 'ecfd:FechaEmis'
                                    ); 
                                    
                                    g_FechaEmisElementNode := dbms_xmldom.makenode( 
                                        elem => g_FechaEmisElement 
                                    ); 
                                    agrega_texto_nodo(p_FechaHoraEmision,g_FechaEmisElementNode);
                                    
                                    g_childNode := dbms_xmldom.appendchild( 
                                        n => g_IdDocElementNode, 
                                        newchild => g_FechaEmisElementNode 
                                    );
                                --------------------------------------------------------------------------------------------------------------------
                                --------------------------------------------------------------------------------------------------------------------
                                    --make a CodigoMoneda element 
                                    g_CodigoMonedaElement := dbms_xmldom.createelement( 
                                        doc => g_xmlDoc, 
                                        tagName => 'ecfd:CodigoMoneda'
                                    ); 
                                    
                                    g_CodigoMonedaElementNode := dbms_xmldom.makenode( 
                                        elem => g_CodigoMonedaElement 
                                    ); 
                                    agrega_texto_nodo(p_CodigoMoneda,g_CodigoMonedaElementNode);
                                    
                                    g_childNode := dbms_xmldom.appendchild( 
                                        n => g_IdDocElementNode, 
                                        newchild => g_CodigoMonedaElementNode 
                                    );
                                --------------------------------------------------------------------------------------------------------------------
                            
                            g_childNode := dbms_xmldom.appendchild( 
                                n => g_EncabezadoElementNode, 
                                newchild => g_IdDocElementNode 
                            );
                        --------------------------------------------------------------------------------------------------------------------
                        
                        --------------------------------------------------------------------------------------------------------------------
                            --make a ExEmisor element 
                            g_ExEmisorElement := dbms_xmldom.createelement( 
                                doc => g_xmlDoc, 
                                tagName => 'ecfd:ExEmisor'
                            ); 
                            
                            g_ExEmisorElementNode := dbms_xmldom.makenode( 
                                elem => g_ExEmisorElement 
                            ); 
                            
                                    --------------------------------------------------------------------------------------------------------------------
                                        --make a NITEmisor element 
                                        g_NITEmisorElement := dbms_xmldom.createelement( 
                                            doc => g_xmlDoc, 
                                            tagName => 'ecfd:NITEmisor'
                                        ); 
                                        
                                        g_NITEmisorElementNode := dbms_xmldom.makenode( 
                                            elem => g_NITEmisorElement 
                                        ); 
                                         agrega_texto_nodo(p_NITEmisor,g_NITEmisorElementNode);
                                        
                                        g_childNode := dbms_xmldom.appendchild( 
                                            n => g_ExEmisorElementNode, 
                                            newchild => g_NITEmisorElementNode 
                                        );
                                    --------------------------------------------------------------------------------------------------------------------
                                    --------------------------------------------------------------------------------------------------------------------
                                        --make a NmbEmisor element 
                                        g_NmbEmisorElement := dbms_xmldom.createelement( 
                                            doc => g_xmlDoc, 
                                            tagName => 'ecfd:NmbEmisor'
                                        ); 
                                        
                                        g_NmbEmisorElementNode := dbms_xmldom.makenode( 
                                            elem => g_NmbEmisorElement 
                                        ); 
                                         agrega_texto_nodo(p_NombreEmisor,g_NmbEmisorElementNode);
                                        
                                        g_childNode := dbms_xmldom.appendchild( 
                                            n => g_ExEmisorElementNode, 
                                            newchild => g_NmbEmisorElementNode 
                                        );
                                    --------------------------------------------------------------------------------------------------------------------
                                    --------------------------------------------------------------------------------------------------------------------
                                        --make a AfiliacionIVA element 
                                        g_AfiliacionIVAElement := dbms_xmldom.createelement( 
                                            doc => g_xmlDoc, 
                                            tagName => 'ecfd:AfiliacionIVA'
                                        ); 
                                        
                                        g_AfiliacionIVAElementNode := dbms_xmldom.makenode( 
                                            elem => g_AfiliacionIVAElement 
                                        ); 
                                         agrega_texto_nodo(p_AfiliacionIVA,g_AfiliacionIVAElementNode);
                                        
                                        g_childNode := dbms_xmldom.appendchild( 
                                            n => g_ExEmisorElementNode, 
                                            newchild => g_AfiliacionIVAElementNode 
                                        );
                                    --------------------------------------------------------------------------------------------------------------------
                                    --------------------------------------------------------------------------------------------------------------------
                                        --make a CodigoExEmisor element 
                                        g_CodigoExEmisorElement := dbms_xmldom.createelement( 
                                            doc => g_xmlDoc, 
                                            tagName => 'ecfd:CodigoExEmisor'
                                        ); 
                                        
                                        g_CodigoExEmisorElementNode := dbms_xmldom.makenode( 
                                            elem => g_CodigoExEmisorElement 
                                        ); 
                                        
                                                --------------------------------------------------------------------------------------------------------------------
                                                    --make a CdgSucursal element 
                                                    g_CdgSucursalElement := dbms_xmldom.createelement( 
                                                        doc => g_xmlDoc, 
                                                        tagName => 'ecfd:CdgSucursal'
                                                    ); 
                                                    
                                                    g_CdgSucursalElementNode := dbms_xmldom.makenode( 
                                                        elem => g_CdgSucursalElement 
                                                    ); 
                                                     agrega_texto_nodo(p_CodigoEstablecimiento,g_CdgSucursalElementNode);
                                                    
                                                    g_childNode := dbms_xmldom.appendchild( 
                                                        n => g_CodigoExEmisorElementNode, 
                                                        newchild => g_CdgSucursalElementNode 
                                                    );
                                                --------------------------------------------------------------------------------------------------------------------
                                                --------------------------------------------------------------------------------------------------------------------
                                                    --make a Sucursal element 
                                                    g_SucursalElement := dbms_xmldom.createelement( 
                                                        doc => g_xmlDoc, 
                                                        tagName => 'ecfd:Sucursal'
                                                    ); 
                                                    
                                                    g_SucursalElementNode := dbms_xmldom.makenode( 
                                                        elem => g_SucursalElement 
                                                    ); 
                                                     agrega_texto_nodo(p_NombreEmisor,g_SucursalElementNode);
                                                    
                                                    g_childNode := dbms_xmldom.appendchild( 
                                                        n => g_CodigoExEmisorElementNode, 
                                                        newchild => g_SucursalElementNode 
                                                    );
                                                --------------------------------------------------------------------------------------------------------------------
                                        
                                        
                                        
                                        g_childNode := dbms_xmldom.appendchild( 
                                            n => g_ExEmisorElementNode, 
                                            newchild => g_CodigoExEmisorElementNode 
                                        );
                                    --------------------------------------------------------------------------------------------------------------------
                                        --make a DomFiscal element 
                                        g_DomFiscalElement := dbms_xmldom.createelement( 
                                            doc => g_xmlDoc, 
                                            tagName => 'ecfd:DomFiscal'
                                        ); 
                                        
                                        g_DomFiscalElementNode := dbms_xmldom.makenode( 
                                            elem => g_DomFiscalElement 
                                        ); 
                                        
                                                --------------------------------------------------------------------------------------------------------------------
                                                    --make a Direccion element 
                                                    g_DireccionFlElement := dbms_xmldom.createelement( 
                                                        doc => g_xmlDoc, 
                                                        tagName => 'ecfd:Direccion'
                                                    ); 
                                                    
                                                    g_DireccionFElementNode := dbms_xmldom.makenode( 
                                                        elem => g_DireccionFlElement 
                                                    ); 
                                                    agrega_texto_nodo(p_Direccion,g_DireccionFElementNode);
                                                    
                                                    g_childNode := dbms_xmldom.appendchild( 
                                                        n => g_DomFiscalElementNode, 
                                                        newchild => g_DireccionFElementNode 
                                                    );
                                                --------------------------------------------------------------------------------------------------------------------
                                                --------------------------------------------------------------------------------------------------------------------
                                                    --make a CodigoPostal element 
                                                    g_CPFElement := dbms_xmldom.createelement( 
                                                        doc => g_xmlDoc, 
                                                        tagName => 'ecfd:CodigoPostal'
                                                    ); 
                                                    
                                                    g_CPFElementNode := dbms_xmldom.makenode( 
                                                        elem => g_CPFElement 
                                                    ); 
                                                    agrega_texto_nodo(p_CodigoPostal,g_CPFElementNode);
                                                    
                                                    g_childNode := dbms_xmldom.appendchild( 
                                                        n => g_DomFiscalElementNode, 
                                                        newchild => g_CPFElementNode 
                                                    );
                                                --------------------------------------------------------------------------------------------------------------------
                                                --------------------------------------------------------------------------------------------------------------------
                                                    --make a Municipio element 
                                                    g_MunicipioFElement := dbms_xmldom.createelement( 
                                                        doc => g_xmlDoc, 
                                                        tagName => 'ecfd:Municipio'
                                                    ); 
                                                    
                                                    g_MunicipioFElementNode := dbms_xmldom.makenode( 
                                                        elem => g_MunicipioFElement 
                                                    ); 
                                                    agrega_texto_nodo(p_Municipio,g_MunicipioFElementNode);
                                                    
                                                    g_childNode := dbms_xmldom.appendchild( 
                                                        n => g_DomFiscalElementNode, 
                                                        newchild => g_MunicipioFElementNode 
                                                    );
                                                --------------------------------------------------------------------------------------------------------------------
                                                --------------------------------------------------------------------------------------------------------------------
                                                    --make a Departamento element 
                                                    g_DepFElement := dbms_xmldom.createelement( 
                                                        doc => g_xmlDoc, 
                                                        tagName => 'ecfd:Departamento'
                                                    ); 
                                                    
                                                    g_DepFElementNode := dbms_xmldom.makenode( 
                                                        elem => g_DepFElement 
                                                    ); 
                                                    agrega_texto_nodo(p_Departamento,g_DepFElementNode);
                                                    
                                                    g_childNode := dbms_xmldom.appendchild( 
                                                        n => g_DomFiscalElementNode, 
                                                        newchild => g_DepFElementNode 
                                                    );
                                                --------------------------------------------------------------------------------------------------------------------
                                                --------------------------------------------------------------------------------------------------------------------
                                                    --make a Pais element 
                                                    g_PaisFlElement := dbms_xmldom.createelement( 
                                                        doc => g_xmlDoc, 
                                                        tagName => 'ecfd:Pais'
                                                    ); 
                                                    
                                                    g_PaisFElementNode := dbms_xmldom.makenode( 
                                                        elem => g_PaisFlElement 
                                                    ); 
                                                    agrega_texto_nodo(p_Pais,g_PaisFElementNode);
                                                    
                                                    g_childNode := dbms_xmldom.appendchild( 
                                                        n => g_DomFiscalElementNode, 
                                                        newchild => g_PaisFElementNode 
                                                    );
                                                --------------------------------------------------------------------------------------------------------------------
                                        
                                        g_childNode := dbms_xmldom.appendchild( 
                                            n => g_ExEmisorElementNode, 
                                            newchild => g_DomFiscalElementNode 
                                        );
                                    --------------------------------------------------------------------------------------------------------------------
                            
                            g_childNode := dbms_xmldom.appendchild( 
                                n => g_EncabezadoElementNode, 
                                newchild => g_ExEmisorElementNode 
                            );
                        --------------------------------------------------------------------------------------------------------------------
                        --------------------------------------------------------------------------------------------------------------------
                            --make a ExReceptor element 
                            g_ExReceptorElement := dbms_xmldom.createelement( 
                                doc => g_xmlDoc, 
                                tagName => 'ecfd:ExReceptor'
                            ); 
                            
                            g_ExReceptorElementNode := dbms_xmldom.makenode( 
                                elem => g_ExReceptorElement 
                            ); 
                            
                                    --------------------------------------------------------------------------------------------------------------------
                                        --make a IDReceptor element 
                                        g_IDReceptorElement := dbms_xmldom.createelement( 
                                            doc => g_xmlDoc, 
                                            tagName => 'ecfd:IDReceptor'
                                        ); 
                                        
                                        g_IDReceptorElementNode := dbms_xmldom.makenode( 
                                            elem => g_IDReceptorElement 
                                        ); 
                                        agrega_texto_nodo(p_IDReceptor,g_IDReceptorElementNode);
                                        
                                        g_childNode := dbms_xmldom.appendchild( 
                                            n => g_ExReceptorElementNode, 
                                            newchild => g_IDReceptorElementNode 
                                        );
                                    --------------------------------------------------------------------------------------------------------------------
                                    --------------------------------------------------------------------------------------------------------------------
                                        --make a NmbRecep element 
                                        g_NmbRecepElement := dbms_xmldom.createelement( 
                                            doc => g_xmlDoc, 
                                            tagName => 'ecfd:NmbRecep'
                                        ); 
                                        
                                        g_NmbRecepElementNode := dbms_xmldom.makenode( 
                                            elem => g_NmbRecepElement 
                                        ); 
                                        agrega_texto_nodo(p_NombreReceptor,g_NmbRecepElementNode);
                                        
                                        g_childNode := dbms_xmldom.appendchild( 
                                            n => g_ExReceptorElementNode, 
                                            newchild => g_NmbRecepElementNode 
                                        );
                                    --------------------------------------------------------------------------------------------------------------------
                                    --------------------------------------------------------------------------------------------------------------------
                                        --make a NmbRecep element 
                                        g_DomFiscalRcpElement := dbms_xmldom.createelement( 
                                            doc => g_xmlDoc, 
                                            tagName => 'ecfd:DomFiscalRcp'
                                        ); 
                                        
                                        g_DomFiscalRcpElementNode := dbms_xmldom.makenode( 
                                            elem => g_DomFiscalRcpElement 
                                        ); 
                                        
                                                --------------------------------------------------------------------------------------------------------------------
                                                    --make a Direccion element 
                                                    g_DirRcpElement := dbms_xmldom.createelement( 
                                                        doc => g_xmlDoc, 
                                                        tagName => 'ecfd:Direccion'
                                                    ); 
                                                    
                                                    g_DirRcpElementNode := dbms_xmldom.makenode( 
                                                        elem => g_DirRcpElement 
                                                    ); 
                                                    agrega_texto_nodo(p_DireccionR,g_DirRcpElementNode);
                                                    
                                                    g_childNode := dbms_xmldom.appendchild( 
                                                        n => g_DomFiscalRcpElementNode, 
                                                        newchild => g_DirRcpElementNode 
                                                    );
                                                --------------------------------------------------------------------------------------------------------------------
                                                --------------------------------------------------------------------------------------------------------------------
                                                    --make a CodigoPostal element 
                                                    g_CPRcpElement := dbms_xmldom.createelement( 
                                                        doc => g_xmlDoc, 
                                                        tagName => 'ecfd:CodigoPostal'
                                                    ); 
                                                    
                                                    g_CPRcpElementNode := dbms_xmldom.makenode( 
                                                        elem => g_CPRcpElement 
                                                    ); 
                                                    agrega_texto_nodo(p_CodigoPostalR,g_CPRcpElementNode);
                                                    
                                                    g_childNode := dbms_xmldom.appendchild( 
                                                        n => g_DomFiscalRcpElementNode, 
                                                        newchild => g_CPRcpElementNode 
                                                    );
                                                --------------------------------------------------------------------------------------------------------------------
                                                --------------------------------------------------------------------------------------------------------------------
                                                    --make a Municipio element 
                                                    g_MuniRcpElement := dbms_xmldom.createelement( 
                                                        doc => g_xmlDoc, 
                                                        tagName => 'ecfd:Municipio'
                                                    ); 
                                                    
                                                    g_MuniRcpElementNode := dbms_xmldom.makenode( 
                                                        elem => g_MuniRcpElement 
                                                    ); 
                                                    agrega_texto_nodo(p_MunicipioR,g_MuniRcpElementNode);
                                                    
                                                    g_childNode := dbms_xmldom.appendchild( 
                                                        n => g_DomFiscalRcpElementNode, 
                                                        newchild => g_MuniRcpElementNode 
                                                    );
                                                --------------------------------------------------------------------------------------------------------------------
                                                --------------------------------------------------------------------------------------------------------------------
                                                    --make a Departamento element 
                                                    g_DepRcpElement := dbms_xmldom.createelement( 
                                                        doc => g_xmlDoc, 
                                                        tagName => 'ecfd:Departamento'
                                                    ); 
                                                    
                                                    g_DepRcpElementNode := dbms_xmldom.makenode( 
                                                        elem => g_DepRcpElement 
                                                    ); 
                                                    agrega_texto_nodo(p_DepartamentoR,g_DepRcpElementNode);
                                                    
                                                    g_childNode := dbms_xmldom.appendchild( 
                                                        n => g_DomFiscalRcpElementNode, 
                                                        newchild => g_DepRcpElementNode 
                                                    );
                                                --------------------------------------------------------------------------------------------------------------------
                                                --------------------------------------------------------------------------------------------------------------------
                                                    --make a Pais element 
                                                    g_PaisRcpElement := dbms_xmldom.createelement( 
                                                        doc => g_xmlDoc, 
                                                        tagName => 'ecfd:Pais'
                                                    ); 
                                                    
                                                    g_PaisRcpElementNode := dbms_xmldom.makenode( 
                                                        elem => g_PaisRcpElement 
                                                    ); 
                                                    agrega_texto_nodo(p_PaisR,g_PaisRcpElementNode);
                                                    
                                                    g_childNode := dbms_xmldom.appendchild( 
                                                        n => g_DomFiscalRcpElementNode, 
                                                        newchild => g_PaisRcpElementNode 
                                                    );
                                                --------------------------------------------------------------------------------------------------------------------
                                        
                                        g_childNode := dbms_xmldom.appendchild( 
                                            n => g_ExReceptorElementNode, 
                                            newchild => g_DomFiscalRcpElementNode 
                                        );
                                    --------------------------------------------------------------------------------------------------------------------
                            
                            g_childNode := dbms_xmldom.appendchild( 
                                n => g_EncabezadoElementNode, 
                                newchild => g_ExReceptorElementNode 
                            );
                        --------------------------------------------------------------------------------------------------------------------
                        --------------------------------------------------------------------------------------------------------------------
                            --make a Frases element 
                            g_FrasesFdElement := dbms_xmldom.createelement( 
                                doc => g_xmlDoc, 
                                tagName => 'ecfd:Frases'
                            ); 
                            
                            g_FrasesFdElementNode := dbms_xmldom.makenode( 
                                elem => g_FrasesFdElement 
                            ); 
                            
                                --------------------------------------------------------------------------------------------------------------------
                                    --make a Frase element 
                                    /*Comienza el proceso para generar las frases*/
                                    FOR r_frases IN c_frases LOOP
                                        IF(p_exp IS NOT NULL)THEN
                                            g_FraseFdElement := dbms_xmldom.createelement( 
                                                doc => g_xmlDoc, 
                                                tagName => 'dte:Frase'
                                            ); 
                                            
                                            add_attribute(g_FraseFdElement,'TipoFrase', r_frases.TipoFrase);
                                            add_attribute(g_FraseFdElement,'CodigoEscenario', r_frases.CodigoEscenario);
                                            
                                            g_FraseFdElementNode := dbms_xmldom.makenode(
                                                elem => g_FraseFdElement 
                                            );
                        
                                            g_childNode := dbms_xmldom.appendchild( 
                                                n => g_FrasesFdElementNode, 
                                                newchild => g_FraseFdElementNode 
                                            );
                                        ELSE
                                            IF(r_frases.tag <> 'EXP')THEN
                                                g_FraseFdElement := dbms_xmldom.createelement( 
                                                    doc => g_xmlDoc, 
                                                    tagName => 'dte:Frase'
                                                ); 
                                                
                                                add_attribute(g_FraseFdElement,'TipoFrase', r_frases.TipoFrase);
                                                add_attribute(g_FraseFdElement,'CodigoEscenario', r_frases.CodigoEscenario);
                                                
                                                g_FraseFdElementNode := dbms_xmldom.makenode(
                                                    elem => g_FraseFdElement 
                                                );
                                                
                                                
                                                g_childNode := dbms_xmldom.appendchild( 
                                                    n => g_FrasesFdElementNode, 
                                                    newchild => g_FraseFdElementNode 
                                                );
                                            END IF;
                                        END IF;
                                    END LOOP;
                                    /*Finaliza el proceso para generar las frases*/
                                --------------------------------------------------------------------------------------------------------------------
                            
                            g_childNode := dbms_xmldom.appendchild( 
                                n => g_EncabezadoElementNode, 
                                newchild => g_FrasesFdElementNode 
                            );
                        --------------------------------------------------------------------------------------------------------------------
                g_childNode := dbms_xmldom.appendchild( 
                    n => g_DocumentoElementNode, 
                    newchild => g_EncabezadoElementNode 
                );
            --------------------------------------------------------------------------------------------------------------------
            --------------------------------------------------------------------------------------------------------------------
                          --make a Detalle element 
                FOR r_i IN g_lines.FIRST .. g_lines.LAST LOOP
                        g_DetalleElement := dbms_xmldom.createelement( 
                            doc => g_xmlDoc, 
                            tagName => 'ecfd:Detalle'
                        ); 
                        
                        g_DetalleElementNode := dbms_xmldom.makenode( 
                            elem => g_DetalleElement 
                        ); 
                        
                            --------------------------------------------------------------------------------------------------------------------
                                --make a NroLinDet element 
                                g_NroLinDetElement := dbms_xmldom.createelement( 
                                    doc => g_xmlDoc, 
                                    tagName => 'ecfd:NroLinDet'
                                ); 
                                
                                g_NroLinDetElementNode := dbms_xmldom.makenode( 
                                    elem => g_NroLinDetElement 
                                ); 
                                agrega_texto_nodo(g_lines(r_i).NumeroLinea,g_NroLinDetElementNode);
                                
                                g_childNode := dbms_xmldom.appendchild( 
                                    n => g_DetalleElementNode, 
                                    newchild => g_NroLinDetElementNode 
                                );
                            --------------------------------------------------------------------------------------------------------------------
                            --------------------------------------------------------------------------------------------------------------------
                                --make a BienOServicio element 
                                g_BienOSDElement := dbms_xmldom.createelement( 
                                    doc => g_xmlDoc, 
                                    tagName => 'ecfd:BienOServicio'
                                ); 
                                
                                g_BienOSDElementNode := dbms_xmldom.makenode( 
                                    elem => g_BienOSDElement 
                                ); 
                                agrega_texto_nodo(g_lines(r_i).BienOServicio,g_BienOSDElementNode);
                                
                                g_childNode := dbms_xmldom.appendchild( 
                                    n => g_DetalleElementNode, 
                                    newchild => g_BienOSDElementNode 
                                );
                            --------------------------------------------------------------------------------------------------------------------
                            --------------------------------------------------------------------------------------------------------------------
                                --make a QtyItem element 
                                g_QtyItemElement := dbms_xmldom.createelement( 
                                    doc => g_xmlDoc, 
                                    tagName => 'ecfd:QtyItem'
                                ); 
                                
                                g_QtyItemElementNode := dbms_xmldom.makenode( 
                                    elem => g_QtyItemElement 
                                ); 
                                agrega_texto_nodo(g_lines(r_i).Cantidad,g_QtyItemElementNode);
                                
                                g_childNode := dbms_xmldom.appendchild( 
                                    n => g_DetalleElementNode, 
                                    newchild => g_QtyItemElementNode 
                                );
                            --------------------------------------------------------------------------------------------------------------------
                            --------------------------------------------------------------------------------------------------------------------
                                --make a UnmdItem element 
                                g_UnmdItemElement := dbms_xmldom.createelement( 
                                    doc => g_xmlDoc, 
                                    tagName => 'ecfd:UnmdItem'
                                ); 
                                
                                g_UnmdItemElementNode := dbms_xmldom.makenode( 
                                    elem => g_UnmdItemElement 
                                ); 
                                agrega_texto_nodo(g_lines(r_i).UnidadMedida,g_UnmdItemElementNode);
                                
                                g_childNode := dbms_xmldom.appendchild( 
                                    n => g_DetalleElementNode, 
                                    newchild => g_UnmdItemElementNode 
                                );
                            --------------------------------------------------------------------------------------------------------------------
                            --------------------------------------------------------------------------------------------------------------------
                                --make a Descripcion element 
                                g_DescripcionDElement := dbms_xmldom.createelement( 
                                    doc => g_xmlDoc, 
                                    tagName => 'ecfd:Descripcion'
                                ); 
                                
                                g_DescripcionDElementNode := dbms_xmldom.makenode( 
                                    elem => g_DescripcionDElement 
                                ); 
                                agrega_texto_nodo(g_lines(r_i).Descripcion,g_DescripcionDElementNode);
                                
                                g_childNode := dbms_xmldom.appendchild( 
                                    n => g_DetalleElementNode, 
                                    newchild => g_DescripcionDElementNode 
                                );
                            --------------------------------------------------------------------------------------------------------------------
                            --------------------------------------------------------------------------------------------------------------------
                                --make a Precio element 
                                g_PrecioDElement := dbms_xmldom.createelement( 
                                    doc => g_xmlDoc, 
                                    tagName => 'ecfd:Precio'
                                ); 
                                
                                g_PrecioDElementNode := dbms_xmldom.makenode( 
                                    elem => g_PrecioDElement 
                                ); 
                                agrega_texto_nodo(g_lines(r_i).PrecioUnitario,g_PrecioDElementNode);
                                
                                g_childNode := dbms_xmldom.appendchild( 
                                    n => g_DetalleElementNode, 
                                    newchild => g_PrecioDElementNode 
                                );
                            --------------------------------------------------------------------------------------------------------------------
                            --------------------------------------------------------------------------------------------------------------------
                                --make a MontoBrutoItem element 
                                g_MontoBrutoItemElement := dbms_xmldom.createelement( 
                                    doc => g_xmlDoc, 
                                    tagName => 'ecfd:MontoBrutoItem'
                                ); 
                                
                                g_MontoBrutoItemElementNode := dbms_xmldom.makenode( 
                                    elem => g_MontoBrutoItemElement 
                                ); 
                                agrega_texto_nodo(g_lines(r_i).precio,g_MontoBrutoItemElementNode);
                                
                                g_childNode := dbms_xmldom.appendchild( 
                                    n => g_DetalleElementNode, 
                                    newchild => g_MontoBrutoItemElementNode 
                                );
                            --------------------------------------------------------------------------------------------------------------------
                            --------------------------------------------------------------------------------------------------------------------
                                --make a Total element 
                                g_TotalDElement := dbms_xmldom.createelement( 
                                    doc => g_xmlDoc, 
                                    tagName => 'ecfd:Total'
                                ); 
                                
                                g_TotalDElementNode := dbms_xmldom.makenode( 
                                    elem => g_TotalDElement 
                                ); 
                                agrega_texto_nodo(g_lines(r_i).Total,g_TotalDElementNode);
                                
                                g_childNode := dbms_xmldom.appendchild( 
                                    n => g_DetalleElementNode, 
                                    newchild => g_TotalDElementNode 
                                );
                            --------------------------------------------------------------------------------------------------------------------
                            --------------------------------------------------------------------------------------------------------------------
                                --make a DescuentoMonto element 
                                g_DescuentoMDElement := dbms_xmldom.createelement( 
                                    doc => g_xmlDoc, 
                                    tagName => 'ecfd:DescuentoMonto'
                                ); 
                                
                                g_DescuentoMDElementNode := dbms_xmldom.makenode( 
                                    elem => g_DescuentoMDElement 
                                ); 
                                agrega_texto_nodo(g_lines(r_i).descuento,g_DescuentoMDElementNode);
                                
                                g_childNode := dbms_xmldom.appendchild( 
                                    n => g_DetalleElementNode, 
                                    newchild => g_DescuentoMDElementNode 
                                );
                            --------------------------------------------------------------------------------------------------------------------
                            --------------------------------------------------------------------------------------------------------------------
                                --make a Impuestos element 
                                g_ImpuestosDElement := dbms_xmldom.createelement( 
                                    doc => g_xmlDoc, 
                                    tagName => 'ecfd:Impuestos'
                                ); 
                                
                                g_ImpuestosDElementNode := dbms_xmldom.makenode( 
                                    elem => g_ImpuestosDElement 
                                ); 
                                
                                            --------------------------------------------------------------------------------------------------------------------
                                                --make a NombreCorto element 
                                                g_NombreCortoDElement := dbms_xmldom.createelement( 
                                                    doc => g_xmlDoc, 
                                                    tagName => 'ecfd:NombreCorto'
                                                ); 
                                                
                                                g_NombreCortoDElementNode := dbms_xmldom.makenode( 
                                                    elem => g_NombreCortoDElement 
                                                ); 
                                                agrega_texto_nodo(g_lines(r_i).NombreCorto,g_NombreCortoDElementNode);
                                                
                                                g_childNode := dbms_xmldom.appendchild( 
                                                    n => g_ImpuestosDElementNode, 
                                                    newchild => g_NombreCortoDElementNode 
                                                );
                                            --------------------------------------------------------------------------------------------------------------------
                                            --------------------------------------------------------------------------------------------------------------------
                                                --make a CodigoUnidadGravable element 
                                                g_CodUGDElement := dbms_xmldom.createelement( 
                                                    doc => g_xmlDoc, 
                                                    tagName => 'ecfd:CodigoUnidadGravable'
                                                ); 
                                                
                                                g_CodUGDElementNode := dbms_xmldom.makenode( 
                                                    elem => g_CodUGDElement 
                                                ); 
                                                agrega_texto_nodo(g_lines(r_i).CodigoUnidadGravable,g_CodUGDElementNode);
                                                
                                                g_childNode := dbms_xmldom.appendchild( 
                                                    n => g_ImpuestosDElementNode, 
                                                    newchild => g_CodUGDElementNode 
                                                );
                                            --------------------------------------------------------------------------------------------------------------------
                                            --------------------------------------------------------------------------------------------------------------------
                                                --make a MontoGravable element 
                                                g_MontoGravableDElement := dbms_xmldom.createelement( 
                                                    doc => g_xmlDoc, 
                                                    tagName => 'ecfd:MontoGravable'
                                                ); 
                                                
                                                g_MontoGravableDElementNode := dbms_xmldom.makenode( 
                                                    elem => g_MontoGravableDElement 
                                                ); 
                                                agrega_texto_nodo(g_lines(r_i).MontoGravable,g_MontoGravableDElementNode);
                                                
                                                g_childNode := dbms_xmldom.appendchild( 
                                                    n => g_ImpuestosDElementNode, 
                                                    newchild => g_MontoGravableDElementNode 
                                                );
                                            --------------------------------------------------------------------------------------------------------------------
                                            --------------------------------------------------------------------------------------------------------------------
                                                --make a MontoImpuesto element 
                                                g_MontoImpuestoDElement := dbms_xmldom.createelement( 
                                                    doc => g_xmlDoc, 
                                                    tagName => 'ecfd:MontoImpuesto'
                                                ); 
                                                
                                                g_MontoImpuestoDElementNode := dbms_xmldom.makenode( 
                                                    elem => g_MontoImpuestoDElement 
                                                ); 
                                                agrega_texto_nodo(g_lines(r_i).MontoImpuesto,g_MontoImpuestoDElementNode);
                                                
                                                g_childNode := dbms_xmldom.appendchild( 
                                                    n => g_ImpuestosDElementNode, 
                                                    newchild => g_MontoImpuestoDElementNode 
                                                );
                                            --------------------------------------------------------------------------------------------------------------------
                                
                                g_childNode := dbms_xmldom.appendchild( 
                                    n => g_DetalleElementNode, 
                                    newchild => g_ImpuestosDElementNode 
                                );
                            --------------------------------------------------------------------------------------------------------------------
                        g_childNode := dbms_xmldom.appendchild( 
                            n => g_DocumentoElementNode, 
                            newchild => g_DetalleElementNode 
                        );
                END LOOP;
            --------------------------------------------------------------------------------------------------------------------
            --------------------------------------------------------------------------------------------------------------------
                --make a Totales element 
                g_TotalesecfdElement := dbms_xmldom.createelement( 
                    doc => g_xmlDoc, 
                    tagName => 'ecfd:Totales'
                ); 
                
                g_TotalesecfdElementNode := dbms_xmldom.makenode( 
                    elem => g_TotalesecfdElement 
                ); 
                
                        --------------------------------------------------------------------------------------------------------------------
                            --make a GranTotal element 
                            g_GranTotalecfdElement := dbms_xmldom.createelement( 
                                doc => g_xmlDoc, 
                                tagName => 'ecfd:GranTotal'
                            ); 
                            
                            g_GranTotalecfdElementNode := dbms_xmldom.makenode( 
                                elem => g_GranTotalecfdElement 
                            ); 
                            agrega_texto_nodo(g_amount_due_original,g_GranTotalecfdElementNode);
                            
                            g_childNode := dbms_xmldom.appendchild( 
                                n => g_TotalesecfdElementNode, 
                                newchild => g_GranTotalecfdElementNode 
                            );
                        --------------------------------------------------------------------------------------------------------------------
                        --------------------------------------------------------------------------------------------------------------------
                            --make a TotalImpuestos element 
                            g_TotalImpecfdElement := dbms_xmldom.createelement( 
                                doc => g_xmlDoc, 
                                tagName => 'ecfd:TotalImpuestos'
                            ); 
                            add_attribute(g_TotalImpecfdElement,'NombreCorto', g_NombreCorto);
                            add_attribute(g_TotalImpecfdElement,'TotalMontoImpuesto', g_TotalMontoImpuesto);
                            
                            g_TotalImpecfdElementNode := dbms_xmldom.makenode( 
                                elem => g_TotalImpecfdElement 
                            ); 
                            
                            g_childNode := dbms_xmldom.appendchild( 
                                n => g_TotalesecfdElementNode, 
                                newchild => g_TotalImpecfdElementNode 
                            );
                        --------------------------------------------------------------------------------------------------------------------
                
                g_childNode := dbms_xmldom.appendchild( 
                    n => g_DocumentoElementNode, 
                    newchild => g_TotalesecfdElementNode 
                );
            --------------------------------------------------------------------------------------------------------------------
  
  EXCEPTION
    WHEN OTHERS THEN
        fnd_file.put_line(fnd_file.LOG,'Error en el procedimiento genera_nodos_documento ' || sqlerrm);
  END genera_nodos_documento_adenda;
     /*========================================================================================+
  |PROCEDURE
  |         genera_adenda
  |DESCRIPTION                                                                           
  |                         Procedimiento que genera la sección de adenda
  |                                                                                      |
  |ARGUMENTS  
  |                         IN:
                                 p_fecha_emision : fecha emisión de la factura
  |                              P_customer_trx_id: id de la factura a procesar
  |
  |                         OUT:
  |
  |
  |HISTORY                                                                               |
  | Date         Author                 Version     Change Reference                     |
  |------------------------------------------------------------------------------------- |
  |2019/09/10   Amauri Cuahutle      1.0         Creación de Proceso                       |
  +======================================================================================*/
  PROCEDURE genera_adenda(
                                                      p_tipo IN VARCHAR2,
                                                      p_exp IN VARCHAR2,
                                                      p_FechaHoraEmision IN VARCHAR2,
                                                      P_CodigoMoneda IN VARCHAR2,
                                                      P_NITEmisor IN VARCHAR2,
                                                      P_NombreEmisor IN VARCHAR2,
                                                      P_CodigoEstablecimiento IN VARCHAR2,
                                                      P_NombreComercial IN VARCHAR2,
                                                      P_CorreoEmisor IN VARCHAR2,
                                                      P_AfiliacionIVA IN VARCHAR2,
                                                      P_Direccion IN VARCHAR2,
                                                      P_CodigoPostal IN VARCHAR2,
                                                      P_Municipio IN VARCHAR2,
                                                      P_Departamento IN VARCHAR2,
                                                      P_Pais IN VARCHAR2,
                                                      P_IDReceptor IN VARCHAR2,
                                                      P_TipoEspecial IN VARCHAR2,
                                                      P_NombreReceptor IN VARCHAR2,
                                                      P_CorreoReceptor IN VARCHAR2,
                                                      P_DireccionR IN VARCHAR2,
                                                      P_CodigoPostalR IN VARCHAR2,
                                                      P_MunicipioR IN VARCHAR2,
                                                      P_DepartamentoR IN VARCHAR2,
                                                      PaisR IN VARCHAR2
                                                      )
   AS
   
   BEGIN
   
                --------------------------------------------------------------------------------------------------------------------
                --make a Adenda element 
                g_AdendaElement := dbms_xmldom.createelement( 
                    doc => g_xmlDoc, 
                    tagName => 'dte:Adenda'
                ); 
                
                g_AdendaElementNode := dbms_xmldom.makenode( 
                    elem => g_AdendaElement 
                ); 
                
                    --------------------------------------------------------------------------------------------------------------------
                        --make a ECFD element 
                        g_ECFDElement := dbms_xmldom.createelement( 
                            doc => g_xmlDoc, 
                            tagName => 'ecfd:ECFD'
                        ); 
                        add_attribute(g_ECFDElement,'version','0.4');
                        add_attribute(g_ECFDElement,'xmlns:ecfd','http://www.edxsolutions.gt/schemas/fel');
                        add_attribute(g_ECFDElement,'xsi:schemaLocation','http://www.edxsolutions.gt/schemas/fel/ecfd.xsd');
                        add_attribute(g_ECFDElement,'xmlns:xsi','http://www.w3.org/2001/XMLSchema-instance');
                        
                        g_ECFDElementNode := dbms_xmldom.makenode( 
                            elem => g_ECFDElement 
                        ); 
                        
                                --------------------------------------------------------------------------------------------------------------------
                                    --make a Documento element 
                                    g_DocumentoElement := dbms_xmldom.createelement( 
                                        doc => g_xmlDoc, 
                                        tagName => 'ecfd:Documento'
                                    ); 
                                    add_attribute(g_DocumentoElement,'ID','dte');
                                    
                                    g_DocumentoElementNode := dbms_xmldom.makenode( 
                                        elem => g_DocumentoElement 
                                    ); 
                                    
                                    genera_nodos_documento_adenda(
                                                                                                      p_tipo,
                                                                                                      p_exp,
                                                                                                      p_FechaHoraEmision,
                                                                                                      P_CodigoMoneda,
                                                                                                      P_NITEmisor,
                                                                                                      P_NombreEmisor,
                                                                                                      P_CodigoEstablecimiento,
                                                                                                      P_NombreComercial,
                                                                                                      P_CorreoEmisor,
                                                                                                      P_AfiliacionIVA,
                                                                                                      P_Direccion,
                                                                                                      P_CodigoPostal,
                                                                                                      P_Municipio,
                                                                                                      P_Departamento,
                                                                                                      P_Pais,
                                                                                                      P_IDReceptor,
                                                                                                      P_TipoEspecial,
                                                                                                      P_NombreReceptor,
                                                                                                      P_CorreoReceptor,
                                                                                                      P_DireccionR,
                                                                                                      P_CodigoPostalR,
                                                                                                      P_MunicipioR,
                                                                                                      P_DepartamentoR,
                                                                                                      PaisR
                                                                                                    );
                                    
                                    g_childNode := dbms_xmldom.appendchild( 
                                        n => g_ECFDElementNode, 
                                        newchild => g_DocumentoElementNode 
                                    );
                                --------------------------------------------------------------------------------------------------------------------
                                --------------------------------------------------------------------------------------------------------------------
                                    --make a Personalizados element 
                                    g_PersonalizadosElement := dbms_xmldom.createelement( 
                                        doc => g_xmlDoc, 
                                        tagName => 'ecfd:Personalizados'
                                    ); 
                                    
                                    g_PersonalizadosElementNode := dbms_xmldom.makenode( 
                                        elem => g_PersonalizadosElement 
                                    ); 
                                    
                                    
                                    
                                    g_childNode := dbms_xmldom.appendchild( 
                                        n => g_ECFDElementNode, 
                                        newchild => g_PersonalizadosElementNode 
                                    );
                                --------------------------------------------------------------------------------------------------------------------
                        
                        g_childNode := dbms_xmldom.appendchild( 
                            n => g_AdendaElementNode, 
                            newchild => g_ECFDElementNode 
                        );
                    --------------------------------------------------------------------------------------------------------------------
                
                g_childNode := dbms_xmldom.appendchild( 
                    n => g_nameElementNode, 
                    newchild => g_AdendaElementNode 
                );
            --------------------------------------------------------------------------------------------------------------------
   
   EXCEPTION
    WHEN OTHERS THEN
        fnd_file.put_line(fnd_file.LOG,'Error en el procedimiento genera_adenda ' || sqlerrm);
   END genera_adenda;
  
   /*========================================================================================+
  |PROCEDURE
  |         launch_ftp
  |DESCRIPTION                                                                           
  |                         Procedimiento principal que genera el xml para la factua de guatemala
  |                                                                                      |
  |ARGUMENTS  
  |                         IN:
  |                                  p_host:  IP a la que deceamos conectarnos
  |                                  p_user: Usuario de conexión
  |                                  p_remmote_path: p_remmote_path
  |                                  p_local_path: Carpeta local de envío.
  |                                  p_file: Archivo a procesar
  |                                  p_opcion: Opción para envió(E) o extracción(G)
  |                                  p_respaldo: Carperta de respaldo archivos xml
  |                                  p_org_id: id de la organización
  |                                  
  |
  |HISTORY                                                                               |
  | Date         Author                 Version     Change Reference                     |
  |------------------------------------------------------------------------------------- |
  |2019/09/10   Amauri Cuahutle      1.0         Creación de Proceso                       |
  +======================================================================================*/
   PROCEDURE sp_submit_ftp (p_host    VARCHAR2
                                                       ,p_user  VARCHAR2
                                                       ,p_remmote_path     VARCHAR2
                                                       ,p_local_path         VARCHAR2
                                                       ,p_file         VARCHAR2
                                                       ,p_opcion         VARCHAR2
                                                       ,p_respaldo         VARCHAR2
                                                       ,p_org_id         VARCHAR2
                                                       ) IS
   
      l_request_id      NUMBER;
   
   BEGIN

      
      --Lanza concurrente
      l_request_id := fnd_request.submit_request (application => 'XXCMX'
                                                 ,program     => 'XXCMX_AR_FTP_FEL_GT'
                                                 ,argument1   => p_host
                                                 ,argument2   => p_user
                                                 ,argument3   => p_remmote_path
                                                 ,argument4   => p_local_path
                                                 ,argument5   => p_file
                                                 ,argument6   => p_opcion
                                                 ,argument7   => p_respaldo
                                                 ,argument8   => p_org_id
                                                 );
                                                 
      COMMIT;
   
   EXCEPTION
      WHEN OTHERS THEN
         fnd_file.put_line(fnd_file.log, 'Error en proceso SP_SUBMIT_FTP - '||SQLERRM);
   END sp_submit_ftp;
   /*========================================================================================+
  |PROCEDURE
  |         MAIN
  |DESCRIPTION                                                                           
  |                         Procedimiento principal que genera el xml para la factua de guatemala
  |                                                                                      |
  |ARGUMENTS  
  |                         IN:
  |                                  p_org_id:  ID de la unidad operativa a procesar
  |                                  p_tipo_documento: Clase de documento a filtrar
  |                                  p_dias_atras: días hacia atras que se procesaran
  |                                  p_numero_documento: numero de la factura/docuemto de ar
  |                                  p_cuenta: número de cuenta (location del bill to)
  |                         OUT:
  |                                  x_errbuf: parametro estandard de oracle que regresa el mensaje de error
  |                                  x_retcode: parametro estandard de oracle que regresa el código de error
  |
  |HISTORY                                                                               |
  | Date         Author                 Version     Change Reference                     |
  |------------------------------------------------------------------------------------- |
  |2019/09/10   Amauri Cuahutle      1.0         Creación de Proceso                       |
  +======================================================================================*/
  PROCEDURE main(x_errbuf         OUT VARCHAR2
                                   ,x_retcode        OUT VARCHAR2
                                   ,p_tipo_documento IN VARCHAR2
                                   ,p_dias_atras IN NUMBER
                                   ,p_numero_documento IN VARCHAR2
                                   ,p_cuenta IN VARCHAR2
                                   )
    AS
    
        l_name_file VARCHAR2(250);
        l_type_factura VARCHAR2(50);
        l_date DATE;
        l_months NUMBER;
        l_val NUMBER;
        
        l_indx NUMBER :=0;
        l_file_name VARCHAR2(150);
         l_xmltype                     XMLTYPE;
         
         l_directory_path fnd_lookup_values.description%TYPE;
         l_directory_bd fnd_lookup_values.meaning%TYPE;
         l_remote_path fnd_lookup_values.description%TYPE;
         l_ip_remote fnd_lookup_values.description%TYPE;
         l_user_remote fnd_lookup_values.tag%TYPE;
        
        CURSOR c_documentos(p_mes NUMBER,
                                                    p_val NUMBER)
        IS
        SELECT 
              rctt.type,
              hcsua.location cuenta_cliente,
              rcta.customer_trx_id,
              rcta.trx_number,
              rcta.interface_header_attribute1 rct_order_number,
              apps.XXCMX_AR_XML_FACT_GT_PKG.get_tipo(rcta.trx_number) tipo, --2
              apps.XXCMX_AR_XML_FACT_GT_PKG.get_exp(rcta.Bill_To_Site_Use_Id) exp, --3
              REPLACE(to_char(rcta.creation_date,'YYYY-MM-DD hh:mm:ss'),' ','T') || '-04:00' FechaHoraEmision, -- 4 
              rcta.invoice_currency_code CodigoMoneda, --5 CodigoMoneda
              '' NumeroAcceso, --6 NumeroAcceso
              REPLACE(xacfda.rfc_fiscal,'-') NITEmisor, --7 NITEmisor
              haou.name NombreEmisor, --8
              apps.XXCMX_AR_XML_FACT_GT_PKG.get_data_emisor('COD_ESTABLECIMIENTO') CodigoEstablecimiento, --9
              apps.XXCMX_AR_XML_FACT_GT_PKG.get_data_emisor('NOM_COMERCIAL') NombreComercial, --10
              apps.XXCMX_AR_XML_FACT_GT_PKG.get_data_emisor('EMI_CORREO') CorreoEmisor, --11
              apps.XXCMX_AR_XML_FACT_GT_PKG.get_data_emisor('AFILIA_IVA') AfiliacionIVA,--12
              hla.address_line_1 || ',' || hla.address_line_3 || ',' || hla.address_line_2 || ',' || hla.town_or_city || ',' || ft.territory_short_name Direccion, --13
              nvl(hla.postal_code,'00000') CodigoPostal, --14
              hla.region_1 Municipio, --15
              hla.region_2 Departamento, --16
              hla.country Pais, --17
              REPLACE(hp.tax_reference,'-') IDReceptor, --18
              DECODE(hp.party_type,'ORGANIZATION','','PERSON','CUI', '') TipoEspecial, --19
              hp.party_name NombreReceptor,--20
              apps.XXCMX_AR_XML_FACT_GT_PKG.get_correoreceptor(rcta.Bill_To_Site_Use_Id) CorreoReceptor, --21
              apps.XXCMX_AR_XML_FACT_GT_PKG.get_direccion_receptor(rcta.Bill_To_Site_Use_Id)DireccionR, --22
              apps.XXCMX_AR_XML_FACT_GT_PKG.get_postal_code(rcta.Bill_To_Site_Use_Id)CodigoPostalR, --23
              apps.XXCMX_AR_XML_FACT_GT_PKG.get_municipio(rcta.Bill_To_Site_Use_Id)MunicipioR, --24
              apps.XXCMX_AR_XML_FACT_GT_PKG.get_departamento(rcta.Bill_To_Site_Use_Id)DepartamentoR, --25
              apps.XXCMX_AR_XML_FACT_GT_PKG.get_pais(rcta.Bill_To_Site_Use_Id)PaisR --26
        FROM ra_customer_trx_all rcta,
                    ra_cust_trx_types_all rctt,
                    hz_cust_site_uses_all hcsua,
                    RA_BATCH_SOURCES_ALL rbsa,
                    --------------------------
                    --------------------------
                    xxcmx_ap_cert_fis_dig_all xacfda,
                    hr_all_organization_units haou,
                    hr_locations_all hla,
                    FND_TERRITORIES_VL ft,
                    hz_cust_accounts hca,
                    hz_parties hp
        WHERE 1=1
        AND rcta.trx_number = nvl(p_numero_documento,rcta.trx_number)
        AND rcta.org_id = MO_GLOBAL.GET_CURRENT_ORG_ID
        AND rctt.type = NVL(p_tipo_documento,rctt.type)
        AND rcta.cust_trx_type_id = rctt.cust_trx_type_id
        AND rctt.org_id = rcta.org_id
        AND rcta.batch_source_id = rbsa.batch_source_id
        ----------------------------------------------------------
        AND rcta.creation_date >= sysdate - p_dias_atras
        and rcta.creation_date >= add_months(trunc(sysdate),-p_mes)
        AND hcsua.site_use_id = rcta.Bill_To_Site_Use_Id
        AND hcsua.location = NVL(p_cuenta,hcsua.location)
        ----------------------------------------------------------
        AND rcta.org_id = haou.organization_id
        AND haou.location_id = hla.location_id
        AND hla.country = ft.territory_code
        AND hca.cust_account_id = rcta.bill_to_customer_id
        AND hp.party_id = hca.party_id
        AND xacfda.org_id = rcta.org_id
        AND NOT EXISTS(
                                            SELECT 1
                                            FROM fnd_lookup_values fl
                                            WHERE 1=1
                                            AND fl.lookup_type = 'XXCMX_AR_VALUES_FEL_GTM'
                                            AND fl.language = userenv('lang')
                                            AND fl.enabled_flag = 'Y'
                                            AND rbsa.NAME = fl.description
                                         )
        AND NOT EXISTS (
                                            SELECT 1
                                            FROM XXCMX_AR_CONTROL_XML_GT xac
                                            WHERE 1=p_val
                                            AND rcta.customer_trx_id = xac.customer_trx_id
                                         )
        ;
        
        CURSOR c_documentos_lines(p_customer_trx_id NUMBER)
        IS
        SELECT rcta.customer_trx_id,
                      rctla.customer_trx_line_id,
                      rctla.interface_line_attribute6,
                      zlv.TAX_TYPE_CODE,
                      zlv.TAX_CODE,
                      rctla.line_number NumeroLinea, --29
                      DECODE(NVL(rctla.inventory_item_id,0),0,'S',rctla.inventory_item_id,'B') BienOServicio, --30
                      NVL(ABS(rctla.quantity_invoiced),1) Cantidad,--31
                      apps.XXCMX_AR_XML_FACT_GT_PKG.get_unidad_medida(rctla.description,rcta.org_id,rctla.Uom_Code) UnidadMedida, --32
                      rctla.description || ',' ||apps.XXCMX_AR_XML_FACT_GT_PKG.get_descripcion_line(rctla.customer_trx_line_id,rctla.interface_line_attribute6) Descripcion,  --33
                      ABS(nvl(rctla.gross_unit_selling_price,rctla.unit_selling_price)) PrecioUnitario, --34
                      ABS(NVL(ABS(rctla.quantity_invoiced),1) * nvl(rctla.gross_unit_selling_price,rctla.unit_selling_price)) precio, --35
                      0 descuento, --36
                      'IVA' NombreCorto, --37
                      flv.tag CodigoUnidadGravable, --38
                      ABS(zlv.taxable_amt) MontoGravable, --39
                      NVL(ABS(rctla.quantity_invoiced),1) CantidadUnidadesGravables, --40
                      zlv.tax_amt MontoImpuesto, --41
                       ABS(NVL(ABS(rctla.quantity_invoiced),1) * nvl(rctla.gross_unit_selling_price,rctla.unit_selling_price))Total--42
        FROM ra_customer_trx_all rcta,
                    ra_customer_trx_lines_all rctla,
                    zx_lines_v zlv,
                    fnd_lookup_values flv
        WHERE 1=1
        AND rcta.customer_trx_id = rctla.customer_trx_id
        -----parametros------
        AND rcta.customer_trx_id = p_customer_trx_id
        -----end parametros------
        ----lineas
        AND rctla.line_type = 'LINE'
        AND zlv.trx_id = rcta.customer_trx_id
        AND zlv.trx_line_id = rctla.customer_trx_line_id
        AND zlv.trx_level_type = 'LINE'
        AND zlv.tax_rate(+) = flv.description
        AND flv.lookup_type = 'XXCMX_AR_FEL_GTM_IMPUESTOS'
        AND flv.enabled_flag = 'Y'
        AND flv.language = USERENV('lang')
        --end lineas
        ORDER BY rctla.line_number
        ;
        
    BEGIN
    
        fnd_file.put_line(fnd_file.LOG,'Org ID con el nuevo parametro ' || MO_GLOBAL.GET_CURRENT_ORG_ID);
        
        /*Obtiene el mes de ejecución*/
        BEGIN
                SELECT meaning
                INTO l_months
                FROM fnd_lookup_values
                WHERE 1=1
                AND lookup_type = 'XXCMX_AR_XML_MONTH_EXEC_GT'
                AND language = USERENV('lang')
                AND meaning > 0
                ;
                fnd_file.put_line(fnd_file.LOG,'=> ' || l_months);
        EXCEPTION
            WHEN OTHERS THEN
                    l_months := EXTRACT(MONTH FROM SYSDATE);
                    fnd_file.put_line(fnd_file.LOG,'=> ' || l_months);
                    fnd_file.put_line(fnd_file.LOG,'Error al obtener los meses a contemplar ' || sqlerrm);
        END;
        
        /*Obtiene directorio bd y ruta servidor aplicaciones*/
        BEGIN
        
            SELECT meaning,description
            INTO l_directory_bd,l_directory_path
            FROM fnd_lookup_values
            WHERE 1=1
            AND lookup_type = 'XXCMX_AR_FEL_GTM_DIR_OEBS'
            AND language = USERENV('lang')
            AND enabled_flag = 'Y'
            AND tag = MO_GLOBAL.GET_CURRENT_ORG_ID
            ;
        
        EXCEPTION
            WHEN OTHERS THEN
                 l_directory_path := NULL;
                 l_directory_bd := NULL;
                 fnd_file.put_line(fnd_file.LOG,'Error al obtener el directorio de base de datos y ruta servidor de aplicaciones ' || sqlerrm);
        END;
        
        /*Obtiene directorio remoto*/
        BEGIN
        
            SELECT description
            INTO l_remote_path
            FROM fnd_lookup_values
            WHERE 1=1
            AND lookup_type = 'XXCMX_AR_FEL_GTM_DIR_TIM'
            AND language = USERENV('lang')
            AND enabled_flag = 'Y'
            AND tag = MO_GLOBAL.GET_CURRENT_ORG_ID
            ;
            
            SELECT description,tag
            INTO l_ip_remote, l_user_remote
            FROM fnd_lookup_values
            WHERE 1=1
            AND lookup_type = 'XXCMX_AR_FEL_GTM_IP_TIM'
            AND enabled_flag = 'Y'
            AND language = userenv('lang')
            AND meaning = sys_context('USERENV','DB_NAME')
            ORDER BY lookup_code
            ;
        
        EXCEPTION
            WHEN OTHERS THEN
                 l_directory_path := NULL;
                 l_directory_bd := NULL;
                 fnd_file.put_line(fnd_file.LOG,'Error al obtener el directorio de base de datos y ruta servidor de aplicaciones ' || sqlerrm);
        END;
        
        --Revisa si se reprocesara
        IF(p_numero_documento IS NOT NULL AND p_cuenta IS NOT NULL)THEN
            fnd_file.put_line(fnd_file.LOG,'Se reprocesara el documento');
            l_val := 117;
        ELSE
            fnd_file.put_line(fnd_file.LOG,'No Se reprocesaran documentos');
            l_val := 1;
        END IF;
        
        EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_LANGUAGE = AMERICAN';
        fnd_file.put_line(fnd_file.LOG,'Inicia proceso, lang  ' || userenv('lang'));
        fnd_file.put_line(fnd_file.output,'Lista de archvios que se transferiran ');
        /*Comienza la creacion de los xml por factura header*/
        FOR r_head IN c_documentos(l_months,l_val) LOOP
            --initialise the document 
            fnd_file.put_line(fnd_file.LOG,'Factrua ' || r_head.trx_number);
            g_xmlDoc := dbms_xmldom.newDOMDocument(); 
            dbms_xmldom.setVersion(g_xmlDoc, '1.0" encoding="UTF-8'); 
            dbms_xmldom.setcharset(g_xmlDoc, 'UTF-8'); 
             
            --convert it to a node. everything needs to be a node eventually 
            g_xmlDocNode := dbms_xmldom.makenode( 
                doc => g_xmlDoc 
            ); 
             
            --make a new root element containing employee information 
            g_GTDocumentoElement := dbms_xmldom.createelement( 
                doc => g_xmlDoc, 
                tagName => 'dte:GTDocumento' 
            ); 
        
             add_attribute(g_GTDocumentoElement,'Version', '0.4');
             add_attribute(g_GTDocumentoElement,'xmlns:cno', 'http://www.sat.gob.gt/face2/ComplementoReferenciaNota/0.1.0');
             add_attribute(g_GTDocumentoElement,'xmlns:ds', 'http://www.w3.org/2000/09/xmldsig#');
             add_attribute(g_GTDocumentoElement,'xmlns:cfe', 'http://www.sat.gob.gt/face2/ComplementoFacturaEspecial/0.1.0');
             add_attribute(g_GTDocumentoElement,'xmlns:cex', 'http://www.sat.gob.gt/face2/ComplementoExportaciones/0.1.0');
             add_attribute(g_GTDocumentoElement,'xmlns:cfc', 'http://www.sat.gob.gt/dte/fel/CompCambiaria/0.1.0');
             add_attribute(g_GTDocumentoElement,'xmlns:dte', 'http://www.sat.gob.gt/dte/fel/0.1.0');
             add_attribute(g_GTDocumentoElement,'xmlns:xsi', 'http://www.w3.org/2000/09/xmldsig#');
             add_attribute(g_GTDocumentoElement,'xmlns:xs', 'http://www.w3.org/2001/XMLSchema');
             
            --convert it to a node 
            g_GTDocumentoElementNode := dbms_xmldom.makenode( 
                elem => g_GTDocumentoElement 
            ); 
            
                ----------------------------------------------------------------------------------------------------------------
                --make a sat element 
                g_nameElement := dbms_xmldom.createelement( 
                    doc => g_xmlDoc, 
                    tagName => 'dte:SAT' 
                ); 
                
                add_attribute(g_nameElement,'ClaseDocumento', 'dte');
                 
                --convert it to a node 
                g_nameElementNode := dbms_xmldom.makenode( 
                    elem => g_nameElement 
                ); 
                ----------------------------------------------------------------------------------------------------------------
                    --make a dte element 
                    g_dteElement := dbms_xmldom.createelement( 
                        doc => g_xmlDoc, 
                        tagName => 'dte:DTE'
                    ); 
                    
                    add_attribute(g_dteElement,'ID', 'DatosCertificados');
                    
                    g_dteElementNode := dbms_xmldom.makenode( 
                        elem => g_dteElement 
                    ); 
                        g_childNode := dbms_xmldom.appendchild( 
                        n => g_nameElementNode, 
                        newchild => g_dteElementNode 
                    );
                ----------------------------------------------------------------------------------------------------------------
            
              GENERA_DATOS_FISCALES_CABECERO(
                P_TYPE => r_head.type,
                P_TIPO => r_head.tipo,
                P_EXP => r_head.exp,
                P_FECHAHORA_EMISION => r_head.FechaHoraEmision,
                P_CODIGO_MONEDA => r_head.CodigoMoneda,
                P_NUMERO_ACCESO => r_head.NumeroAcceso,
                P_NIT_EMISOR => r_head.NITEmisor,
                P_NOMBRE_EMISOR => r_head.NombreEmisor,
                P_CODIGO_ESTABLECIMIENTO => r_head.CodigoEstablecimiento,
                P_NOMBRE_COMERCIAL => r_head.NombreComercial,
                P_CORREO_EMISOR => r_head.CorreoEmisor,
                P_AFILIACION_IVA => r_head.AfiliacionIVA,
                P_DIRECCION => r_head.Direccion,
                P_CODIGO_POSTAL => r_head.CodigoPostal,
                P_MUNICIPIO => r_head.Municipio,
                P_DEPARTAMENTO => r_head.Departamento,
                P_PAIS => r_head.Pais,
                P_ID_RECEPTOR => r_head.IDReceptor,
                P_TIPO_ESPECIAL => r_head.TipoEspecial,
                P_NOMBRE_RECEPTOR => r_head.NombreReceptor,
                P_CORREO_RECEPTOR => r_head.CorreoReceptor,
                P_DIRECCION_R => r_head.DireccionR,
                P_CODIGO_POSTAL_R => r_head.CodigoPostalR,
                P_MUNICIPIO_R => r_head.MunicipioR,
                P_DEPARTAMENTO_R => r_head.DepartamentoR,
                P_PAIS_R => r_head.PaisR
              );
              
                --make items element 
                g_ItemsElement := dbms_xmldom.createelement( 
                    doc => g_xmlDoc, 
                    tagName => 'dte:Items'
                ); 
                
                g_ItemsElementNode := dbms_xmldom.makenode( 
                    elem => g_ItemsElement 
                );
                
              FOR c_lines IN c_documentos_lines(r_head.customer_trx_id)LOOP
                    l_indx := l_indx +1;
                    g_lines(l_indx).customer_trx_id := c_lines.customer_trx_id;
                    g_lines(l_indx).customer_trx_line_id := c_lines.customer_trx_line_id;
                    g_lines(l_indx).interface_line_attribute6 := c_lines.interface_line_attribute6;
                    g_lines(l_indx).TAX_TYPE_CODE := c_lines.TAX_TYPE_CODE;
                    g_lines(l_indx).TAX_CODE := c_lines.TAX_CODE;
                    g_lines(l_indx).NumeroLinea := c_lines.NumeroLinea;
                    g_lines(l_indx).BienOServicio := c_lines.BienOServicio;
                    g_lines(l_indx).Cantidad := c_lines.Cantidad;
                    g_lines(l_indx).UnidadMedida := c_lines.UnidadMedida;
                    g_lines(l_indx).Descripcion := c_lines.Descripcion;
                    g_lines(l_indx).PrecioUnitario := c_lines.PrecioUnitario;
                    g_lines(l_indx).precio := c_lines.precio;
                    g_lines(l_indx).descuento := c_lines.descuento;
                    g_lines(l_indx).NombreCorto := c_lines.NombreCorto;
                    g_lines(l_indx).CodigoUnidadGravable := c_lines.CodigoUnidadGravable;
                    g_lines(l_indx).MontoGravable := c_lines.MontoGravable;
                    g_lines(l_indx).CantidadUnidadesGravables := c_lines.CantidadUnidadesGravables;
                    g_lines(l_indx).MontoImpuesto := c_lines.MontoImpuesto;
                    g_lines(l_indx).Total := c_lines.Total;
                    
                    genera_datos_fiscales_lines(
                                                                    c_lines.NumeroLinea,
                                                                    c_lines.BienOServicio,
                                                                    c_lines.Cantidad,
                                                                    c_lines.UnidadMedida,
                                                                    c_lines.Descripcion,
                                                                    c_lines.PrecioUnitario,
                                                                    c_lines.precio,
                                                                    c_lines.descuento,
                                                                    c_lines.NombreCorto,
                                                                    c_lines.CodigoUnidadGravable,
                                                                    c_lines.MontoGravable,
                                                                    c_lines.CantidadUnidadesGravables,
                                                                    c_lines.MontoImpuesto,
                                                                    c_lines.Total
                                                                    );
              END LOOP;
              
              /*agrega el nodo items*/
                g_childNode := dbms_xmldom.appendchild( 
                    n => g_DatosEmisionElementNode, 
                    newchild => g_ItemsElementNode 
                ); 
                
                
                genera_totales(r_head.customer_trx_id);
                
                genera_complementos(r_head.type,r_head.tipo,r_head.exp,r_head.customer_trx_id,r_head.NombreReceptor,r_head.direccionr, r_head.rct_order_number);

            --add the det:SAT node to the GTDocumento node 
            g_childNode := dbms_xmldom.appendchild( 
                n => g_GTDocumentoElementNode, 
                newchild => g_nameElementNode 
            ); 
            
            fnd_file.put_line(fnd_file.LOG,'antes de genera_adenda  ' || l_file_name); 
            genera_adenda(
                                        r_head.tipo,
                                        r_head.exp,
                                        r_head.FechaHoraEmision,
                                        r_head.CodigoMoneda,
                                        r_head.NITEmisor,
                                        r_head.NombreEmisor,
                                        r_head.CodigoEstablecimiento,
                                        r_head.NombreComercial,
                                        r_head.CorreoEmisor,
                                        r_head.AfiliacionIVA,
                                        r_head.Direccion,
                                        r_head.CodigoPostal,
                                        r_head.Municipio,
                                        r_head.Departamento,
                                        r_head.Pais,
                                        r_head.IDReceptor,
                                        r_head.TipoEspecial,
                                        r_head.NombreReceptor,
                                        r_head.CorreoReceptor,
                                        r_head.DireccionR,
                                        r_head.CodigoPostalR,
                                        r_head.MunicipioR,
                                        r_head.DepartamentoR,
                                        r_head.PaisR
                                        );

            --append the employee element to the document 
            g_wholeDoc := dbms_xmldom.appendchild( 
                n => g_xmlDocNode, 
                newchild => g_GTDocumentoElementNode 
            ); 

             l_xmltype := dbms_xmldom.getXmlType(g_xmlDoc);
            
            l_file_name := r_head.type||'-'||r_head.trx_number||'-'||TO_CHAR(SYSDATE,'DDMMYY-HH24-MI-SS')||'.xml';
            fnd_file.put_line(fnd_file.LOG,'file name  ' || l_file_name); 
            dbms_xslprocessor.clob2file(l_xmltype.getClobVal, l_directory_bd, l_file_name, nls_charset_id('UTF8'));

             
             dbms_xmldom.freeDocument(g_xmlDoc);
             
             BEGIN
             
                INSERT INTO XXCMX_AR_CONTROL_XML_GT VALUES(
                    r_head.customer_trx_id,
                    l_file_name,
                    r_head.cuenta_cliente,
                    null,
                    null,
                    null,
                     SYSDATE,
                     fnd_profile.value('USER_ID'),
                     SYSDATE,
                     fnd_profile.value('USER_ID')
                );
                COMMIT;
             
             EXCEPTION
                WHEN OTHERS THEN
                    fnd_file.put_line(fnd_file.LOG,'Error al actualizar tabla de control  ' || sqlerrm);
             END;
             g_lines.DELETE;
             fnd_file.put_line(fnd_file.output,'=>  ' || l_file_name);
        END LOOP;  --end cursor principal

        sp_submit_ftp(p_host => l_ip_remote
                                 ,p_user => l_user_remote
                                 ,p_remmote_path => l_remote_path
                                 ,p_local_path => l_directory_path
                                 ,p_file => null
                                 ,p_opcion => 'E'
                                 ,p_respaldo => REPLACE(l_directory_path,'envio','respaldo')
                                 ,p_org_id => null
                                );
        
        fnd_file.put_line(fnd_file.output,'Revisar la salida del concurrente de transferencia ' );
        
    EXCEPTION
        WHEN OTHERS THEN
            fnd_file.put_line(fnd_file.LOG,'Error en el procedimiento pricipal ' || sqlerrm);
    END main;


END XXCMX_AR_XML_FACT_GT_PKG;
