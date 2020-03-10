CREATE OR REPLACE PACKAGE xxppg_1081_net_price_pkg AUTHID CURRENT_USER AS
  -- $Header: xxppg_1081_net_price_pkg.pks 120.2 21/03/2019 10:00:00 appldev ship $
  -- +==========================================================================================+
  -- |                   PPG do Brasil , Sao Paulo, Brasil                                      |
  -- |                       All rights reserved.                                               |
  -- +==========================================================================================+
  -- | FILENAME                                                                                 |
  -- |   xxppg_1081_net_price_pkg.pck                                                           |
  -- |                                                                                          |
  -- | PURPOSE                                                                                  |
  -- |   Script de criação da Package                                                           |
  -- |   xxppg_1081_net_price_pkg                                                               |
  -- |                                                                                          |
  -- | DESCRIPTION                                                                              |
  -- |   XXPPG 1081 - Net Price Project                                                         |
  -- |                                                                                          |
  -- | PARAMETERS                                                                               |
  -- |                                                                                          |
  -- | CREATED BY      Wellington Duarte      12/06/2019                                        |
  -- |                                                                                          |
  -- | UPDATED BY                                                                               |
  -- |                                                                                          |
  -- |                                                                                          |
   --|                  Amauri Essland 10/03/2019
   --|                  SSD2592 – Update ISO with the last standard cost
  -- +==========================================================================================+
  --
  -- Public function and procedure declarations
  TYPE t_string IS TABLE OF VARCHAR2(32767);
  TYPE xxppg_net_fci IS TABLE OF xxppg_1081_net_fci%ROWTYPE;
  TYPE xxppg_qp_list_header IS TABLE OF qp_list_headers_all_b%ROWTYPE;
  TYPE xxppg_qp_list_lines IS TABLE OF qp_list_lines%ROWTYPE;
  TYPE xxppg_1081_report_rec IS RECORD(
     header_id             oe_order_headers_all.header_id%TYPE
    ,line_id               oe_order_lines_all.line_id%TYPE
    ,net_price             oe_order_lines_all.unit_selling_price%TYPE
    ,organization_id       mtl_parameters.organization_id%TYPE
    ,cust_acct_site_id     hz_cust_site_uses_all.cust_acct_site_id%TYPE
    ,cust_trx_type_id      ra_cust_trx_types_all.cust_trx_type_id%TYPE
    ,inventory_item_id     mtl_system_items.inventory_item_id%TYPE
    ,order_number          oe_order_headers_all.order_number%TYPE
    ,line_number           VARCHAR2(30)
    ,organization_code     mtl_parameters.organization_code%TYPE
    ,party_id              hz_parties.party_id%TYPE
    ,party_name            hz_parties.party_name%TYPE
    ,party_site_name       hz_party_sites.party_site_name%TYPE
    ,cnpj                  VARCHAR2(20)
    ,transaction_name      ra_cust_trx_types_all.name%TYPE
    ,cod_item              mtl_system_items.segment1%TYPE
    ,source_state          cll_f189_states.state_code%TYPE
    ,dest_state            cll_f189_states.state_code%TYPE
    ,contributor_type      hz_cust_acct_sites_all.global_attribute8%TYPE
    ,establishment_type    hr_locations_all.global_attribute1%TYPE
    ,transaction_nature    mtl_system_items.global_attribute2%TYPE
    ,group_tax_name        ra_cust_trx_types_all.global_attribute4%TYPE
    ,group_tax_id          ar_vat_tax_vl.vat_tax_id%TYPE
    ,fiscal_classification mtl_item_categories_v.segment1%TYPE);

  TYPE xxppg_1081_report_type IS TABLE OF xxppg_1081_report_rec;
  TYPE p_rec_tax_rec IS RECORD(
     icms_tax_code   VARCHAR2(30)
    ,icms_tax_rate   VARCHAR2(10)
    ,pis_tax_code    VARCHAR2(30)
    ,pis_tax_rate    VARCHAR2(10)
    ,cofins_tax_code VARCHAR2(30)
    ,cofins_tax_rate VARCHAR2(10)
    ,ipi_tax_code    VARCHAR2(30)
    ,ipi_tax_rate    VARCHAR2(10));
  --
  TYPE p_rec_tax IS TABLE OF p_rec_tax_rec INDEX BY BINARY_INTEGER;
  rec_tax p_rec_tax;

  g_user_id      NUMBER;
  g_resp_id      NUMBER;
  g_resp_appl_id NUMBER;
  g_request_id   NUMBER;
  g_retcode      NUMBER := NULL;
  g_message      VARCHAR2(32727);
  --
  g_dir_name_in  VARCHAR2(1000);
  g_dir_name_out VARCHAR2(1000);
  g_dir_path_in  VARCHAR2(1000);
  g_dir_path_out VARCHAR2(1000);
  g_file_name    VARCHAR2(100);
  g_separador    VARCHAR2(1) DEFAULT ';';
  --
  --
  PROCEDURE p_initialize_globals;
  --
  FUNCTION f_add_ipi(p_transaction_name   IN VARCHAR2
                    ,p_transaction_nature IN VARCHAR2) RETURN NUMBER;
  --
  FUNCTION f_icms_except(p_ordet_type IN VARCHAR2) RETURN VARCHAR2;                  
  --
  FUNCTION f_get_conc_parameters(p_concurrent_prog_name IN VARCHAR2
                                ,p_end_user_column_name IN VARCHAR2)
    RETURN VARCHAR2;
  --
  FUNCTION f_splited_data(p_string    VARCHAR2
                         ,p_delimiter CHAR DEFAULT '*') RETURN t_string
    PIPELINED;
  --
  FUNCTION f_get_data(p_string    VARCHAR2
                     ,p_elemento  PLS_INTEGER
                     ,p_separador VARCHAR2 DEFAULT ';') RETURN VARCHAR2;
  --
  FUNCTION f_validate_list_hist(p_hist IN VARCHAR2) RETURN VARCHAR2;
  --
  FUNCTION f_validate_list_name(p_name IN VARCHAR2) RETURN VARCHAR2;
  --
  FUNCTION f_validate_list_date(p_date IN VARCHAR2) RETURN DATE;
  --
  FUNCTION f_get_order_number(p_header_id IN NUMBER) RETURN VARCHAR2;
  --  
  FUNCTION f_get_line_details(p_line_id IN NUMBER
                             ,p_field   IN VARCHAR2) RETURN NUMBER;
  --
  FUNCTION f_get_org_details(p_organization_id IN NUMBER
                            ,p_field           IN VARCHAR2) RETURN VARCHAR2;
  --   
  FUNCTION f_get_cust_details(p_cust_acct_site_id IN NUMBER
                             ,p_field             IN VARCHAR2)
    RETURN VARCHAR2;
  --                
  FUNCTION f_get_transaction_details(p_cust_trx_type_id IN NUMBER
                                    ,p_field            IN VARCHAR2)
    RETURN VARCHAR2;
  --
  FUNCTION f_get_list_id(p_list_name IN VARCHAR2) RETURN NUMBER;
  --
  FUNCTION f_get_list_name(p_list_header_id IN NUMBER) RETURN VARCHAR2;
  --
  FUNCTION f_get_item_id(p_cod_item IN VARCHAR2) RETURN NUMBER;
  --
  FUNCTION f_get_item_details(p_inventory_item_id IN NUMBER
                             ,p_field             IN VARCHAR2)
    RETURN VARCHAR2;
  --
  FUNCTION f_get_unit_price(p_unit_selling_price IN NUMBER
                           ,p_price_list_id IN NUMBER
                           ,p_inventory_item_id IN NUMBER
                           ,p_header_id IN NUMBER DEFAULT NULL) RETURN NUMBER;  
  --
  FUNCTION f_get_list_line_id(p_list_header_id    IN NUMBER
                             ,p_inventory_item_id IN NUMBER) RETURN NUMBER;
  --
  FUNCTION f_get_header_id(p_order_number IN NUMBER) RETURN NUMBER;
  --
  FUNCTION f_get_line_id(p_header_id   IN NUMBER
                        ,p_line_number IN VARCHAR2) RETURN NUMBER;
  --
  FUNCTION f_get_org_id(p_organization_code IN VARCHAR2) RETURN NUMBER;
  -- 
  FUNCTION f_get_party_id(p_party_name IN VARCHAR2) RETURN NUMBER;
  --
  FUNCTION f_get_acct_site_id(p_party_id        IN NUMBER
                             ,p_cnpj            IN VARCHAR2
                             ,p_party_site_name IN VARCHAR2) RETURN NUMBER;
  --
  FUNCTION f_get_trx_type_id(p_transaction_name IN VARCHAR2) RETURN NUMBER;
  --
  FUNCTION f_read_fci_data(p_dir       IN VARCHAR2
                          ,p_file      IN VARCHAR2
                          ,p_separador IN VARCHAR2) RETURN xxppg_net_fci
    PIPELINED;
  --                        
  FUNCTION f_read_header(p_type      IN VARCHAR2
                        ,p_dir       IN VARCHAR2
                        ,p_file      IN VARCHAR2
                        ,p_separador IN VARCHAR2) RETURN xxppg_qp_list_header
    PIPELINED;
  --
  FUNCTION f_read_lines(p_type      IN VARCHAR2
                       ,p_dir       IN VARCHAR2
                       ,p_file      IN VARCHAR2
                       ,p_separador IN VARCHAR2) RETURN xxppg_qp_list_lines
    PIPELINED;
  --
  FUNCTION f_read_data(p_directory_in IN VARCHAR2
                      ,p_file_name    IN VARCHAR2
                      ,p_separador    IN VARCHAR2)
    RETURN xxppg_1081_report_type
    PIPELINED;
  --
  FUNCTION f_get_tax_rate(p_rule                  IN VARCHAR2 -- REGRA PARA SELECAO
                         ,p_icms_exept            IN VARCHAR2
                         ,p_main_tax_type         IN VARCHAR2
                         ,p_group_tax_id          IN NUMBER -- ID GRUPO DE IMPOSTO
                         ,p_tax_category_id       IN NUMBER -- ID CATEGORIA IMPOSTO
                         ,p_contributor_type      IN VARCHAR2 -- TIPO CONTRIBUINTE
                         ,p_establishment_type    IN VARCHAR2 -- TIPO ESTABELECIMENTO
                         ,p_transaction_nature    IN VARCHAR2
                         ,p_source_state          IN VARCHAR2
                         ,p_dest_state            IN VARCHAR2
                         ,p_cust_acct_site_id     IN NUMBER
                         ,p_organization_id       IN NUMBER
                         ,p_inventory_item_id     IN NUMBER
                         ,p_fiscal_classification IN VARCHAR2
                         ,p_item_origin_code      IN VARCHAR2
                         ,p_module                IN VARCHAR2) RETURN NUMBER;
  --                       
  FUNCTION f_get_net_price(p_header_id             IN NUMBER
                          ,p_line_id               IN NUMBER
                          ,p_unit_selling_price    IN NUMBER DEFAULT NULL
                          ,p_module                IN VARCHAR2 DEFAULT NULL
                          ,p_source_state          IN VARCHAR2 DEFAULT NULL
                          ,p_dest_state            IN VARCHAR2 DEFAULT NULL
                          ,p_contributor_type      IN VARCHAR2 DEFAULT NULL
                          ,p_establishment_type    IN VARCHAR2 DEFAULT NULL
                          ,p_cust_trx_type_id      IN NUMBER DEFAULT NULL
                          ,p_fiscal_classification IN VARCHAR2 DEFAULT NULL
                          ,p_transaction_nature    IN VARCHAR2 DEFAULT NULL
                          ,p_group_tax_id          IN NUMBER DEFAULT NULL
                          ,p_tax_rule_level        IN VARCHAR2 DEFAULT 'RATE'
                          ,p_organization_id       IN NUMBER DEFAULT NULL
                          ,p_inventory_item_id     IN NUMBER DEFAULT NULL
                          ,p_cust_acct_site_id     IN NUMBER DEFAULT NULL
                          ,p_item_origin           IN VARCHAR2 DEFAULT NULL
                          ,p_reg                   IN NUMBER DEFAULT 0)
    RETURN NUMBER;
  --
  FUNCTION f_line_billed(p_header_id IN NUMBER
                         ,p_line_id   IN NUMBER) RETURN NUMBER;  
    
  --
  FUNCTION f_line_reserv(p_header_id IN NUMBER
                        ,p_line_id   IN NUMBER) RETURN NUMBER;
  --                      
  PROCEDURE p_tax_rate_simulation(p_errbuf              OUT VARCHAR2
                                 ,p_retcode             OUT NUMBER
                                 ,p_directory_temp      IN VARCHAR2
                                 ,p_directory           IN VARCHAR2
                                 ,p_dir_win_path        IN VARCHAR2
                                 ,p_file_name           IN VARCHAR2
                                 ,p_transaction_type_id IN NUMBER
                                 ,p_header_id           IN NUMBER
                                 ,p_line_id             IN NUMBER
                                 ,p_net_price           IN NUMBER
                                 ,p_rule                IN VARCHAR2
                                 ,p_organization_id     IN NUMBER
                                 ,p_cust_acct_site_id   IN NUMBER
                                 ,p_cust_trx_type_id    IN NUMBER
                                 ,p_inventory_item_id   IN NUMBER
                                 ,p_module              IN VARCHAR2
                                 ,p_separador           IN VARCHAR2);
  --
  PROCEDURE p_apply_hold(p_header_id         IN NUMBER
                        ,p_line_id           IN NUMBER
                        ,p_inventory_item_id IN NUMBER
                        ,p_xloh              IN xxppg_1081_line_order_hold%ROWTYPE);
  --
  PROCEDURE p_man_cancel_lines(p_line_id       IN NUMBER
                              ,p_motivo        IN VARCHAR2
                              ,p_obs           IN VARCHAR2
                              ,x_return_status OUT VARCHAR2
                              ,x_message       OUT VARCHAR2);
  --
  PROCEDURE p_cancel_lines(p_line_id       IN NUMBER
                          ,p_motivo        IN VARCHAR2
                          ,p_obs           IN VARCHAR2
                          ,x_return_status OUT VARCHAR2
                          ,x_message       OUT VARCHAR2);
  --                        

  PROCEDURE p_release_hold(errbuf            OUT VARCHAR2
                          ,retcode           OUT NUMBER
                          ,p_release_comment IN VARCHAR2);
  --
  PROCEDURE p_reprice_lines(p_line_id             IN NUMBER
                           ,p_unit_selling_prince IN NUMBER
                           ,p_new_price           IN NUMBER);
  --
  PROCEDURE p_active_inactive_list(errbuf      OUT VARCHAR2
                                  ,retcode     OUT NUMBER
                                  ,p_dir       IN VARCHAR2
                                  ,p_file_name IN VARCHAR2
                                  ,p_separador IN VARCHAR2);
  --
  PROCEDURE p_delete_sales_line(p_header_id     IN NUMBER
                               ,p_line_id       IN NUMBER
                               ,x_return_status OUT VARCHAR2
                               ,x_message       OUT VARCHAR2);
  --
  PROCEDURE p_net_price_fci(errbuf           OUT VARCHAR2
                           ,retcode          OUT NUMBER
                           ,p_reason         IN VARCHAR2 DEFAULT 'PPG CANC SOLUCAO PRECO NET'
                           ,p_comment        IN VARCHAR2 DEFAULT 'PPG Canc Solucao Preco Net'
                           ,p_directory_temp IN VARCHAR2 DEFAULT 'APPLOUT'
                           ,p_directory      IN VARCHAR2 DEFAULT 'XXPPG_BR_REPORTS_'
                           ,p_dir_win_path   IN VARCHAR2 DEFAULT 'I:\Oracle-EBS\Reports\Out\'
                           ,p_file_name      IN VARCHAR2 DEFAULT NULL
                           ,p_separador      IN VARCHAR2 DEFAULT ';');
  --
  PROCEDURE p_add_lines(p_header_id            IN NUMBER
                       ,p_inventory_item_id    IN NUMBER
                       ,p_shipping_method_code IN VARCHAR2
                       ,p_unit_list_price      IN NUMBER
                       ,p_unit_selling_price   IN NUMBER
                       ,p_line_type_id         IN NUMBER
                       ,p_ordered_quantity     IN NUMBER
                       ,p_ship_from_org_id     IN NUMBER
                       ,p_order_quantity_uom   IN VARCHAR2
                       ,p_schedule_ship_date    IN DATE
                       ,p_line_id              OUT NUMBER
                       ,x_return_status        OUT VARCHAR2
                       ,x_message              OUT VARCHAR2);
  --
  FUNCTION f_email_get_address(addr_list IN OUT VARCHAR2) RETURN VARCHAR2;
  --
  PROCEDURE p_send_email(p_from_email       IN VARCHAR2
                        ,p_to_email         IN VARCHAR2
                        ,p_subject          IN VARCHAR2
                        ,p_message          IN VARCHAR2
                        ,p_directory        IN VARCHAR2 DEFAULT NULL
                        ,p_filename         IN VARCHAR2 DEFAULT NULL
                        ,p_smtp_server_port IN NUMBER DEFAULT '25');
  --
  FUNCTION format_br_mask_f(p_value IN NUMBER
                           ,p_mask  IN VARCHAR2) RETURN VARCHAR2;
  --
  FUNCTION conv_spc_chr(p_char IN VARCHAR2) RETURN VARCHAR2;
  --
  
/*========================================================================================+
|FUNCTION
|         f_verify_inernal_order
|DESCRIPTION                                                                           
|                      Function to know if the current order is an Internal Sales Order and have an Internal Requisition referenced
|                                                                                      |
|ARGUMENTS  
|                         IN:
|                               p_header_id
|                         OUT:
|                                                                                      |
|RETURNS :
|                 BOOLEAN
|
|HISTORY                                                                               |
| Date         Author                 Version     Change Reference                     |
|------------------------------------------------------------------------------------- |
|2020/03/10   Amauri Cuahutle      1.0         Creation                       |
+======================================================================================*/
  FUNCTION f_verify_inernal_order(p_header_id IN NUMBER) RETURN BOOLEAN;
  --
END xxppg_1081_net_price_pkg;
----Indicativo de Final de Arquivo. Não deve ser removido.
/
SET define off  
CREATE OR REPLACE PACKAGE BODY xxppg_1081_net_price_pkg AS
  -- $Header: xxppg_1081_net_price_pkg.pks 120.2 21/03/2019 10:00:00 appldev ship $
  -- +==========================================================================================+
  -- |                   PPG do Brasil , Sao Paulo, Brasil                                      |
  -- |                       All rights reserved.                                               |
  -- +==========================================================================================+
  -- | FILENAME                                                                                 |
  -- |   xxppg_1081_net_price_pkg.pck                                                           |
  -- |                                                                                          |
  -- | PURPOSE                                                                                  |
  -- |   Script de criação da Package                                                           |
  -- |   xxppg_1081_net_price_pkg                                                               |
  -- |                                                                                          |
  -- | DESCRIPTION                                                                              |
  -- |   XXPPG 1081 - Net Price Project                                                         |
  -- |                                                                                          |
  -- | PARAMETERS                                                                               |
  -- |                                                                                          |
  -- | CREATED BY      Wellington Duarte      12/06/2019                                        |
  -- |                                                                                          |
  -- | UPDATED BY                                                                               |
  -- |                 Wellington Duarte      18/09/2019                                        |
  -- |                 SSD2515 - Manutencao para filtro por BU  e remocao HOLD                  |
   --|                  Amauri Essland 10/03/2019
   --|                  SSD2592 – Update ISO with the last standard cost
  -- +==========================================================================================+
  --

  /*
  p_errcode
  0–Success
  1–Success & warning
  2–Error
  */

  e_exit EXCEPTION;
  g_errcode       NUMBER;
  g_master_org_id mtl_parameters.organization_id%TYPE := oe_sys_parameters.value('MASTER_ORGANIZATION_ID',fnd_profile.value('ORG_ID'));
  g_program_name  VARCHAR2(50) := 'XXPPG_1081_NET_PRICE';

  PROCEDURE p_initialize_globals IS
  BEGIN
  
    g_request_id   := fnd_global.conc_request_id;
    g_program_name := 'XXPPG_1081_NET_PRICE';
    --
    mo_global.set_policy_context('S', fnd_global.org_id);
    mo_global.init('ONT');
    --
    SELECT decode(fnd_global.user_id, -1, 0, fnd_global.user_id)
          ,decode(fnd_global.resp_id, -1, 51201, fnd_global.resp_id)
          ,decode(fnd_global.resp_appl_id,-1,222,fnd_global.resp_appl_id)
    INTO   g_user_id, g_resp_id, g_resp_appl_id
    FROM   dual;
    --
    fnd_global.apps_initialize(user_id      => g_user_id
                              ,resp_id      => g_resp_id
                              ,resp_appl_id => g_resp_appl_id);
    --
  END p_initialize_globals;
  --
  --
  FUNCTION f_add_ipi(p_transaction_name   IN VARCHAR2
                    ,p_transaction_nature IN VARCHAR2) RETURN NUMBER IS
    l_add_ipi NUMBER := 0;
    --
  BEGIN
    BEGIN
      SELECT 1
      INTO   l_add_ipi
      FROM   fnd_lookup_values_vl flvv
      WHERE  lookup_type = 'XXPPG_1081_NETPRICE_ADD_IPI'
      AND    enabled_flag = 'Y'
      AND    nvl(flvv.end_date_active, SYSDATE) >= SYSDATE
      AND    f_get_data(flvv.meaning, 1, '*') = p_transaction_name
      AND    f_get_data(flvv.meaning, 2, '*') = p_transaction_nature;
    EXCEPTION
      WHEN no_data_found THEN
        l_add_ipi := 0;
      WHEN OTHERS THEN
        fnd_file.put_line(fnd_file.log,'Erro: XXPPG_1081_NETPRICE_ADD_IPI : ' ||SQLERRM);
        fnd_file.put_line(fnd_file.log,'p_transaction_name ..... : ' ||p_transaction_name);
        fnd_file.put_line(fnd_file.log,'p_transaction_nature ... : ' ||p_transaction_nature);
        l_add_ipi := 0;
    END;
    --
    RETURN l_add_ipi;
  END f_add_ipi;
  --
  --
  FUNCTION f_icms_except(p_ordet_type IN VARCHAR2) RETURN VARCHAR2 IS
    l_icms_exept VARCHAR2(50);
    --
  BEGIN
    fnd_file.put_line(fnd_file.log, 'f_icms_except - BEGIN'); 
    fnd_file.put_line(fnd_file.log, 'p_ordet_type .... : '||p_ordet_type); 
    fnd_file.put_line(fnd_file.log, 'l_icms_exept .... : '||l_icms_exept); 
    BEGIN
      SELECT upper(tag)
      INTO   l_icms_exept
      FROM   fnd_lookup_values_vl flvv
      WHERE  lookup_type = 'XXPPG_1081_NETPRICE_ICMS_EXEPT'
             AND enabled_flag = 'Y'
             AND nvl(flvv.end_date_active, SYSDATE) >= SYSDATE
             AND flvv.meaning = p_ordet_type;
    EXCEPTION
      WHEN no_data_found THEN
        l_icms_exept := NULL;
      WHEN OTHERS THEN
        fnd_file.put_line(fnd_file.log,'Erro: XXPPG_1081_NETPRICE_ICMS_EXEPT : ' ||SQLERRM);
        fnd_file.put_line(fnd_file.log,'p_transaction_name ..... : ' || p_ordet_type);
        l_icms_exept := NULL;
    END;
    --
    fnd_file.put_line(fnd_file.log, 'l_icms_exept .... : '||l_icms_exept);
    RETURN l_icms_exept;
  END f_icms_except;  
  
  --
  --
  FUNCTION f_get_conc_parameters(p_concurrent_prog_name IN VARCHAR2
                                ,p_end_user_column_name IN VARCHAR2)
    RETURN VARCHAR2 IS
    l_parameter VARCHAR2(250);
    --
  BEGIN
    BEGIN
      SELECT default_value
      INTO   l_parameter
      FROM   fnd_concurrent_programs_vl  fcpv
            ,fnd_descr_flex_col_usage_vl fdfcuv
      WHERE  fcpv.concurrent_program_name = p_concurrent_prog_name
      AND    fcpv.concurrent_program_name =
             substr(fdfcuv.descriptive_flexfield_name,instr(fdfcuv.descriptive_flexfield_name, '.', 1) + 1)
      AND    end_user_column_name = p_end_user_column_name;
      --
    EXCEPTION
      WHEN OTHERS THEN
        l_parameter := NULL;
    END;
    --
    RETURN l_parameter;
    --
  END f_get_conc_parameters;
  --
  --
  FUNCTION f_splited_data(p_string    VARCHAR2
                         ,p_delimiter CHAR DEFAULT '*') RETURN t_string
    PIPELINED AS
    l_tmp VARCHAR2(32000) := p_string || p_delimiter;
    l_pos NUMBER := 0;
  BEGIN
  
    LOOP
      l_pos := instr(l_tmp, p_delimiter);
      EXIT WHEN nvl(l_pos, 0) = 0;
      PIPE ROW(rtrim(ltrim(substr(l_tmp, 1, l_pos - 1))));
      l_tmp := substr(l_tmp, l_pos + 1);
    END LOOP;
  END f_splited_data;
  --
  --
  FUNCTION f_get_data(p_string    VARCHAR2
                     ,p_elemento  PLS_INTEGER
                     ,p_separador VARCHAR2 DEFAULT ';') RETURN VARCHAR2 IS
    v_string VARCHAR2(5000);
  BEGIN
    v_string := translate(p_string, 'ã', 'a') || p_separador;
    FOR i IN 1 .. p_elemento - 1 LOOP
      v_string := substr(v_string,instr(v_string, p_separador) + length(p_separador));
    END LOOP;
    --
    RETURN TRIM(substr(v_string, 1, instr(v_string, p_separador) - 1));
  END f_get_data;
  --
  --
  FUNCTION f_validate_list_hist(p_hist IN VARCHAR2) RETURN VARCHAR2 IS
    l_hist VARCHAR2(240);
    --
  BEGIN
    BEGIN
      SELECT substr(conv_spc_chr(p_hist), 1, 240)
      INTO   l_hist
      FROM   dual
      WHERE  p_hist IS NOT NULL;
    EXCEPTION
      WHEN OTHERS THEN
        l_hist := NULL;
        fnd_file.put_line(fnd_file.log,'Erro ao Validar Historico: ' || p_hist);
        fnd_file.put_line(fnd_file.log, SQLERRM);
    END;
    --
    RETURN l_hist;
    -- 
  END f_validate_list_hist;
  --
  --
  FUNCTION f_validate_list_name(p_name IN VARCHAR2) RETURN VARCHAR2 IS
    l_list_name qp_list_headers_all.name%TYPE;
    --
  BEGIN
    BEGIN
      SELECT NAME
      INTO   l_list_name
      FROM   qp_list_headers_all
      WHERE  upper(NAME) = upper(p_name);
    EXCEPTION
      WHEN OTHERS THEN
        l_list_name := NULL;
        fnd_file.put_line(fnd_file.log,'Erro ao Recuperar Lista de Preco: ' || p_name);
        fnd_file.put_line(fnd_file.log, SQLERRM);
    END;
    RETURN l_list_name;
    -- 
  END f_validate_list_name;
  --
  --
  FUNCTION f_validate_list_date(p_date IN VARCHAR2) RETURN DATE IS
    l_date DATE;
    --
  BEGIN
    BEGIN
      SELECT to_date(p_date, 'dd/mm/rr') INTO l_date FROM dual;
      RETURN l_date;
    EXCEPTION
      WHEN OTHERS THEN
        l_date := NULL;
    END;
  
    IF l_date IS NULL THEN
      BEGIN
        SELECT to_date(p_date, 'dd/mm/rrrr') INTO l_date FROM dual;
        RETURN l_date;
      EXCEPTION
        WHEN OTHERS THEN
          l_date := NULL;
      END;
    END IF;
    --
    IF l_date IS NULL THEN
      BEGIN
        SELECT to_date(p_date, 'dd/mmm/rr') INTO l_date FROM dual;
        RETURN l_date;
      EXCEPTION
        WHEN OTHERS THEN
          l_date := NULL;
      END;
    END IF;
    --
    IF l_date IS NULL THEN
      BEGIN
        SELECT to_date(p_date, 'dd/mmm/rrrr') INTO l_date FROM dual;
        RETURN l_date;
      EXCEPTION
        WHEN OTHERS THEN
          l_date := NULL;
      END;
    END IF;
    --
    IF l_date IS NULL THEN
      BEGIN
        SELECT to_date(p_date, 'dd-mm-rr') INTO l_date FROM dual;
        RETURN l_date;
      EXCEPTION
        WHEN OTHERS THEN
          l_date := NULL;
      END;
    END IF;
    --
    IF l_date IS NULL THEN
      BEGIN
        SELECT to_date(p_date, 'dd-mm-rrrr') INTO l_date FROM dual;
        RETURN l_date;
      EXCEPTION
        WHEN OTHERS THEN
          l_date := NULL;
      END;
    END IF;
    --
    IF l_date IS NULL THEN
      BEGIN
        SELECT to_date(p_date, 'dd-mmm-rr') INTO l_date FROM dual;
        RETURN l_date;
      EXCEPTION
        WHEN OTHERS THEN
          l_date := NULL;
      END;
    END IF;
    --
    IF l_date IS NULL THEN
      BEGIN
        SELECT to_date(p_date, 'dd-mmm-rrrr') INTO l_date FROM dual;
        RETURN l_date;
      EXCEPTION
        WHEN OTHERS THEN
          l_date := NULL;
      END;
    END IF;
    --
    IF l_date IS NULL THEN
      fnd_file.put_line(fnd_file.log,'Informacao no campo data de vigencia nao e valida : ' ||p_date);
    END IF;
    --
    RETURN l_date;
    -- 
  END f_validate_list_date;
  --
  --
  FUNCTION f_get_order_number(p_header_id IN NUMBER) RETURN VARCHAR2 IS
    l_order_number oe_order_headers_all.order_number%TYPE;
  BEGIN
    BEGIN
      SELECT order_number
      INTO   l_order_number
      FROM   oe_order_headers_all
      WHERE  header_id = p_header_id;
    EXCEPTION
      WHEN OTHERS THEN
        l_order_number := NULL;
    END;
    RETURN l_order_number;
  END f_get_order_number;
  --
  --
  FUNCTION f_get_line_details(p_line_id IN NUMBER
                             ,p_field   IN VARCHAR2) RETURN NUMBER IS
    l_field NUMBER;
  BEGIN
    BEGIN
      SELECT CASE
               WHEN p_field = 'LINE_NUMBER' THEN
                line_number
               WHEN p_field = 'UNIT_SELLING_PRICE' THEN
                unit_selling_price
             END
      INTO   l_field
      FROM   oe_order_lines_all
      WHERE  line_id = p_line_id;
    EXCEPTION
      WHEN OTHERS THEN
        l_field := NULL;
    END;
    RETURN l_field;
  END f_get_line_details;
  --
  --
  FUNCTION f_get_org_details(p_organization_id IN NUMBER
                            ,p_field           IN VARCHAR2) RETURN VARCHAR2 IS
    --
    l_field VARCHAR2(100);
  BEGIN
  
    BEGIN
      SELECT CASE
               WHEN p_field = 'STATE_CODE' THEN
                cfs.state_code
               WHEN p_field = 'ORG_NAME' THEN
                haou.name
             END
      INTO   l_field
      FROM   hr_locations_all             hla
            ,hr_all_organization_units    haou
            ,cll_f189_fiscal_entities_all cffea
            ,cll_f189_states              cfs
      WHERE  haou.organization_id = hla.inventory_organization_id
      AND    hla.location_id = cffea.location_id
      AND    cffea.entity_type_lookup_code = 'LOCATION'
      AND    cfs.state_id = cffea.state_id
      AND    haou.organization_id = p_organization_id;
    EXCEPTION
      WHEN OTHERS THEN
        l_field := NULL;
    END;
    --
    RETURN l_field;
  END f_get_org_details;
  --
  --
  FUNCTION f_get_cust_details(p_cust_acct_site_id IN NUMBER
                             ,p_field             IN VARCHAR2)
    RETURN VARCHAR2 IS
    l_field VARCHAR2(100);
    --
  BEGIN
    IF p_field = 'ESTABLISHMENT_TYPE' THEN
      RETURN 'INDUSTRIAL';
    END IF;
  
    BEGIN
      SELECT CASE
               WHEN upper(p_field) = 'STATE_CODE' THEN
                hl.state
               WHEN upper(p_field) = 'SALES_CHANNEL_CODE' THEN
                sales_channel_code
               WHEN upper(p_field) = 'PARTY_NAME' THEN
                hp.party_name
               WHEN upper(p_field) = 'CONTRIBUTOR_TYPE' THEN
                hcasa.global_attribute8
               WHEN upper(p_field) = 'STATE' THEN
                hp.state
               WHEN upper(p_field) = 'COUNTRY_CODE' THEN
                hp.country
               WHEN upper(p_field) = 'CNPJ' THEN
                substr(hcasa.global_attribute3, 2) ||
                hcasa.global_attribute4 || hcasa.global_attribute5
             END
      INTO   l_field
      FROM   apps.hz_parties             hp
            ,apps.hz_cust_accounts       hca
            ,apps.hz_cust_site_uses_all  hcsua
            ,apps.hz_cust_acct_sites_all hcasa
            ,apps.hz_party_sites         hps
            ,apps.hz_locations           hl
      WHERE  hcsua.cust_acct_site_id = hcasa.cust_acct_site_id
      AND    hcasa.party_site_id = hps.party_site_id
      AND    hps.party_id = hp.party_id
      AND    hp.party_id = hca.party_id
      AND    hps.location_id = hl.location_id
      AND    hcsua.site_use_code = 'SHIP_TO'
      AND    hcsua.cust_acct_site_id = p_cust_acct_site_id;
    
    EXCEPTION
      WHEN OTHERS THEN
        l_field := NULL;
    END;
    --
    RETURN l_field;
  END f_get_cust_details;
  --
  --
  FUNCTION f_get_transaction_details(p_cust_trx_type_id IN NUMBER
                                    ,p_field            IN VARCHAR2)
    RETURN VARCHAR2 IS
    l_field VARCHAR2(100);
    --
  BEGIN
    --
    IF p_field = 'ORDER_TYPE' THEN
			BEGIN
				SELECT max(otth.name)
				INTO   l_field
				FROM   oe_transaction_types_v otth
             , oe_transaction_types_v ottl
				WHERE  otth.default_outbound_line_type_id = ottl.transaction_type_id
				AND    ottl.cust_trx_type_id = p_cust_trx_type_id;
			EXCEPTION
				WHEN OTHERS THEN
					l_field := NULL;
			END;      
    ELSE  
  
    BEGIN
      SELECT CASE
               WHEN p_field = 'TRANSACTION_NAME' THEN
                rctta.name
               WHEN p_field = 'GROUP_TAX_ID' THEN
                to_char(avtv.vat_tax_id)
               WHEN p_field = 'GROUP_TAX_NAME' THEN
                rctta.global_attribute4
             END
      INTO   l_field
      FROM   ra_cust_trx_types_all rctta, ar_vat_tax_vl avtv
      WHERE  avtv.tax_code(+) = rctta.global_attribute4
      AND    avtv.tax_type(+) = 'TAX_GROUP'
      AND    rctta.cust_trx_type_id = p_cust_trx_type_id;
    EXCEPTION
      WHEN OTHERS THEN
        l_field := NULL;
    END;
    --
    END IF;
    
    RETURN l_field;
    --  
  END f_get_transaction_details;
  --
  --
  FUNCTION f_get_list_id(p_list_name IN VARCHAR2) RETURN NUMBER IS
    l_list_header_id qp_list_headers_all_b.list_header_id%TYPE;
    --
  BEGIN
    BEGIN
      SELECT list_header_id
      INTO   l_list_header_id
      FROM   qp_list_headers_all
      WHERE  upper(NAME) = upper(p_list_name);
    EXCEPTION
      WHEN OTHERS THEN
        l_list_header_id := NULL;
        fnd_file.put_line(fnd_file.log,'Erro ao Recuperar Lista de Preco para Lista ' ||p_list_name);
        fnd_file.put_line(fnd_file.log, SQLERRM);
    END;
    --
    RETURN l_list_header_id;
    -- 
  END f_get_list_id;
  --
  --
  FUNCTION f_get_list_name(p_list_header_id IN NUMBER) RETURN VARCHAR2 IS
    l_list_name qp_list_headers_all.name%TYPE;
    --
  BEGIN
    BEGIN
      SELECT NAME
      INTO   l_list_name
      FROM   qp_list_headers_all
      WHERE  list_header_id = p_list_header_id;
    EXCEPTION
      WHEN OTHERS THEN
        l_list_name := NULL;
        fnd_file.put_line(fnd_file.log,'Erro ao Recuperar Lista de Preco para Lista ID ' ||p_list_header_id);
        fnd_file.put_line(fnd_file.log, SQLERRM);
    END;
    --
    RETURN l_list_name;
    -- 
  END f_get_list_name;
  --
  --
  FUNCTION f_get_item_id(p_cod_item IN VARCHAR2) RETURN NUMBER IS
    l_inventory_item_id mtl_system_items.inventory_item_id%TYPE;
    --
  BEGIN
    BEGIN
      SELECT inventory_item_id
      INTO   l_inventory_item_id
      FROM   mtl_system_items msi
      WHERE  upper(segment1) = upper(p_cod_item)
      AND    organization_id = g_master_org_id;
    EXCEPTION
      WHEN OTHERS THEN
        l_inventory_item_id := NULL;
        fnd_file.put_line(fnd_file.log,'Erro ao Recuperar INVENTORY_ITEM_ID para Item ' ||p_cod_item);
        fnd_file.put_line(fnd_file.log, SQLERRM);
        g_errcode := 1;
    END;
    --
    RETURN l_inventory_item_id;
    -- 
  END f_get_item_id;
  --
  --
  FUNCTION f_get_item_details(p_inventory_item_id IN NUMBER
                             ,p_field             IN VARCHAR2)
    RETURN VARCHAR2 IS
    l_field VARCHAR2(100);
    --
  BEGIN
    BEGIN
      SELECT CASE
               WHEN p_field = 'COD_ITEM' THEN
                msi.segment1
               WHEN p_field = 'TRANSACTION_NATURE' THEN
                msi.global_attribute2
               WHEN p_field = 'FISCAL_CLASSIFICATION' THEN
                micv.segment1
               WHEN p_field = 'ITEM_ORIG' THEN
                msi.global_attribute3   
             END
      INTO   l_field
      FROM   mtl_system_items msi, mtl_item_categories_v micv
      WHERE  msi.inventory_item_id = p_inventory_item_id
      AND    msi.organization_id = g_master_org_id
      AND    msi.inventory_item_id = micv.inventory_item_id
      AND    msi.organization_id = micv.organization_id
      AND    micv.category_set_id = 1100000022; -- FISCAL_CLASSIFICATION
    EXCEPTION
      WHEN OTHERS THEN
        l_field := NULL;
        fnd_file.put_line(fnd_file.log,'Erro ao Recuperar ' || p_field ||' para INVENTORY_ITEM_ID ' ||p_inventory_item_id);
        fnd_file.put_line(fnd_file.log, SQLERRM);
        g_errcode := 1;
    END;
    --
    RETURN l_field;
    -- 
  END f_get_item_details;
  --
  --

/*========================================================================================+
|FUNCTION
|         f_verify_inernal_order
|DESCRIPTION                                                                           
|                      Function to know if the current order is an Internal Sales Order and have an Internal Requisition referenced
|                                                                                      |
|ARGUMENTS  
|                         IN:
|                               p_header_id
|                         OUT:
|                                                                                      |
|RETURNS :
|                 BOOLEAN
|
|HISTORY                                                                               |
| Date         Author                 Version     Change Reference                     |
|------------------------------------------------------------------------------------- |
|2020/03/10   Amauri Cuahutle      1.0         Creation                       |
+======================================================================================*/
FUNCTION f_verify_inernal_order(p_header_id IN NUMBER) RETURN BOOLEAN
AS

    l_exist NUMBER;

BEGIN

    SELECT 
                1
                INTO l_exist
    FROM   oe_order_headers_all       ooha
                ,oe_order_lines_all         oola
                ,oe_order_sources           oos
                ,po_requisition_headers_all prha
                ,po_requisition_lines_all   prla
    WHERE  ooha.header_id = oola.header_id
    AND    oos.order_source_id = ooha.order_source_id
    AND    oos.name = 'Internal'
    AND    prha.requisition_header_id = prla.requisition_header_id
    AND    prla.requisition_line_id = oola.source_document_line_id
    AND    oola.orig_sys_document_ref = prha.segment1
    AND    oola.source_document_id = prha.requisition_header_id
    AND    ooha.header_id = p_header_id
    ;
    
    RETURN TRUE;
    
EXCEPTION
    WHEN TOO_MANY_ROWS THEN
        RETURN TRUE;
    WHEN NO_DATA_FOUND THEN
        RETURN FALSE;
END f_verify_inernal_order;

--
  FUNCTION f_get_unit_price(p_unit_selling_price IN NUMBER
                           ,p_price_list_id IN NUMBER
                           ,p_inventory_item_id IN NUMBER
                           ,p_header_id IN NUMBER DEFAULT NULL) RETURN NUMBER IS
    l_unit_selling_price NUMBER;
    BEGIN
    --
    IF  p_unit_selling_price IS NOT NULL THEN
      RETURN p_unit_selling_price;
    ELSIF(f_verify_inernal_order(p_header_id))THEN  --Added by Amauri Essland SSD2592
        DBMS_OUTPUT.PUT_LINE('Es una orden interna');
    ELSE   
      BEGIN
      SELECT operand
      INTO   l_unit_selling_price
      FROM   apps.qp_list_lines_v
      WHERE  list_header_id = p_price_list_id
      AND    product_id = p_inventory_item_id;
    EXCEPTION
      WHEN too_many_rows THEN
        SELECT MAX(operand)
        INTO   l_unit_selling_price
        FROM   apps.qp_list_lines_v
        WHERE list_header_id = p_price_list_id
        AND    product_id = p_inventory_item_id;
      WHEN OTHERS THEN
        l_unit_selling_price := nvl(p_unit_selling_price,0);
        fnd_file.put_line(fnd_file.log,'Erro Recuperar Preco Unitario : '||SQLERRM);
        fnd_file.put_line(fnd_file.log,'p_unit_selling_price .........: '||p_unit_selling_price); 
        fnd_file.put_line(fnd_file.log,'p_price_list_id ..............: '||p_price_list_id);
        fnd_file.put_line(fnd_file.log,'p_inventory_item_id ..........: '||p_inventory_item_id);
        fnd_file.put_line(fnd_file.log,'');
    END;
    END IF;    
  
  RETURN  l_unit_selling_price;
  
  END f_get_unit_price;        
  --
  --
  FUNCTION f_get_list_line_id(p_list_header_id    IN NUMBER
                             ,p_inventory_item_id IN NUMBER) RETURN NUMBER IS
    l_list_line_id qp_list_lines.list_line_id%TYPE;
    --
  BEGIN
    BEGIN
      SELECT list_line_id
      INTO   l_list_line_id
      FROM   apps.qp_list_lines_v
      WHERE  /*SYSDATE BETWEEN nvl(start_date_active, SYSDATE) AND
             nvl(end_date_active, SYSDATE + 1)
      AND    */list_header_id = p_list_header_id
      AND    product_id = p_inventory_item_id;
    EXCEPTION
      WHEN too_many_rows THEN
        SELECT MAX(list_line_id)
        INTO   l_list_line_id
        FROM   apps.qp_list_lines_v
        WHERE  /*SYSDATE BETWEEN nvl(start_date_active, SYSDATE) AND
               nvl(end_date_active, SYSDATE + 1)
        AND    */list_header_id = p_list_header_id
        AND    product_id = p_inventory_item_id;
      WHEN OTHERS THEN
        l_list_line_id := NULL;
        fnd_file.put_line(fnd_file.log,'Erro ao Recuperar LIST_LINE_ID para LIST_HEADER_ID ' ||p_list_header_id || ' - INVENTORY_ITEM_ID: ' ||p_inventory_item_id);
        fnd_file.put_line(fnd_file.log, SQLERRM);
        g_errcode := 1;
    END;
    --
    RETURN l_list_line_id;
    -- 
  END f_get_list_line_id;
  --
  --
  FUNCTION f_get_header_id(p_order_number IN NUMBER) RETURN NUMBER IS
    --
    l_header_id oe_order_headers_all.header_id%TYPE;
    --
  BEGIN
    IF p_order_number IS NULL THEN
      RETURN NULL;
    END IF;
    --
    BEGIN
      SELECT header_id
      INTO   l_header_id
      FROM   oe_order_headers_all
      WHERE  order_number = p_order_number;
    EXCEPTION
      WHEN OTHERS THEN
        fnd_file.put_line(fnd_file.log,'Erro ao recuperar HEADER_ID para ordem : ' ||p_order_number);
        fnd_file.put_line(fnd_file.log, SQLERRM);
        l_header_id := NULL;
        g_errcode   := 1;
    END;
    RETURN l_header_id;
    --
  END f_get_header_id;
  --
  --
  FUNCTION f_get_line_id(p_header_id   IN NUMBER
                        ,p_line_number IN VARCHAR2) RETURN NUMBER IS
    l_line_id oe_order_lines_all.line_id%TYPE;
    --
  BEGIN
    IF p_header_id IS NULL THEN
      RETURN NULL;
    END IF;
    --
    BEGIN
      SELECT line_id
      INTO   l_line_id
      FROM   oe_order_lines_all
      WHERE  header_id = p_header_id
      AND    line_number || '.' || shipment_number = p_line_number;
    EXCEPTION
      WHEN OTHERS THEN
        fnd_file.put_line(fnd_file.log,'Erro ao recuperar LINE_ID para header_id : ' ||p_header_id || ' e linha : ' || p_line_number);
        fnd_file.put_line(fnd_file.log, SQLERRM);
        l_line_id := NULL;
        g_errcode := 1;
    END;
    RETURN l_line_id;
    --
  END f_get_line_id;
  --
  --
  FUNCTION f_get_org_id(p_organization_code IN VARCHAR2) RETURN NUMBER IS
    l_org_id mtl_parameters.organization_id%TYPE;
    --
  BEGIN
    BEGIN
      SELECT organization_id
      INTO   l_org_id
      FROM   mtl_parameters
      WHERE  organization_code = upper(p_organization_code);
    EXCEPTION
      WHEN OTHERS THEN
        fnd_file.put_line(fnd_file.log,'Erro ao recuperar ORGANIZATION_ID para org_code : ' ||p_organization_code);
        fnd_file.put_line(fnd_file.log, SQLERRM);
        l_org_id  := NULL;
        g_errcode := 1;
    END;
    RETURN l_org_id;
    --
  END f_get_org_id;
  --
  --
  FUNCTION f_get_party_id(p_party_name IN VARCHAR2) RETURN NUMBER IS
    l_party_id hz_parties.party_id%TYPE;
    --
  BEGIN
    BEGIN
      SELECT hp.party_id
      INTO   l_party_id
      FROM   apps.hz_parties hp
      WHERE  upper(hp.party_name) = upper(p_party_name);
    EXCEPTION
      WHEN OTHERS THEN
        fnd_file.put_line(fnd_file.log,'Erro ao recuperar PARTY_ID para party_name : ' ||p_party_name);
        fnd_file.put_line(fnd_file.log, SQLERRM);
        l_party_id := NULL;
        g_errcode  := 1;
    END;
    RETURN l_party_id;
    --
  END f_get_party_id;
  --
  --
  FUNCTION f_get_acct_site_id(p_party_id        IN NUMBER
                             ,p_cnpj            IN VARCHAR2
                             ,p_party_site_name IN VARCHAR2) RETURN NUMBER IS
    --
    l_cnpj              VARCHAR2(20);
    l_cust_acct_site_id hz_cust_site_uses_all.cust_acct_site_id%TYPE;
    l_qtd_dig           NUMBER;
    --
  BEGIN
    BEGIN
      SELECT length(p_cnpj) INTO l_qtd_dig FROM dual;
    EXCEPTION
      WHEN OTHERS THEN
        l_qtd_dig := 0;
        fnd_file.put_line(fnd_file.log,'Erro recuperar quantidade digitos CNPJ: ' ||p_cnpj || ' party_id : ' || p_party_id);
    END;
    --
    IF l_qtd_dig < 14 THEN
      fnd_file.put_line(fnd_file.log,'CNPJ Informado nao e valido : ' || p_cnpj);
      RETURN 0;
    ELSIF l_qtd_dig > 14 THEN
      l_cnpj := substr(p_cnpj, 2);
    ELSE
      l_cnpj := p_cnpj;
    END IF;
    --
    BEGIN
      SELECT hcsua.cust_acct_site_id
      INTO   l_cust_acct_site_id
      FROM   apps.hz_parties             hp
            ,apps.hz_cust_accounts       hca
            ,apps.hz_cust_site_uses_all  hcsua
            ,apps.hz_cust_acct_sites_all hcasa
            ,apps.hz_party_sites         hps
            ,apps.hz_locations           hl
      WHERE  hcsua.cust_acct_site_id = hcasa.cust_acct_site_id
      AND    hcasa.party_site_id = hps.party_site_id
      AND    hps.party_id = hp.party_id
      AND    hp.party_id = hca.party_id
      AND    hps.location_id = hl.location_id
      AND    hcsua.site_use_code = 'SHIP_TO'
      AND    substr(hcasa.global_attribute3, 2) || hcasa.global_attribute4 ||
             hcasa.global_attribute5 = l_cnpj
      AND    hp.party_id = p_party_id
      AND    hps.party_site_name =
             nvl(p_party_site_name, hps.party_site_name);
    EXCEPTION
      WHEN OTHERS THEN
        fnd_file.put_line(fnd_file.log,'Erro ao recuperar CUST_ACCT_SITE_ID para p_party_id : ' ||p_party_id || ' CNPJ : ' || p_cnpj);
        fnd_file.put_line(fnd_file.log, SQLERRM);
        l_cust_acct_site_id := NULL;
        g_errcode           := 1;
    END;
    RETURN l_cust_acct_site_id;
    --
  END f_get_acct_site_id;
  --
  --
  FUNCTION f_get_trx_type_id(p_transaction_name IN VARCHAR2) RETURN NUMBER IS
    --
    l_cust_trx_type_id ra_cust_trx_types_all.cust_trx_type_id%TYPE;
    --
  BEGIN
    BEGIN
      SELECT cust_trx_type_id
      INTO   l_cust_trx_type_id
      FROM   ra_cust_trx_types_all
      WHERE  upper(NAME) = upper(p_transaction_name);
    EXCEPTION
      WHEN OTHERS THEN
        fnd_file.put_line(fnd_file.log,'Erro ao recuperar CUST_TRX_TYPE_ID para transaction_name : ' ||p_transaction_name);
        fnd_file.put_line(fnd_file.log, SQLERRM);
        l_cust_trx_type_id := NULL;
        g_errcode          := 1;
    END;
    RETURN l_cust_trx_type_id;
    --
  END f_get_trx_type_id;
  --
  --
  FUNCTION f_read_fci_data(p_dir       IN VARCHAR2
                          ,p_file      IN VARCHAR2
                          ,p_separador IN VARCHAR2) RETURN xxppg_net_fci
    PIPELINED IS
    xnfci        xxppg_1081_net_fci%ROWTYPE;
    v_status_fat VARCHAR2(50);
    l_line_rec   oe_order_pub.line_rec_type;
    --
    nlidos NUMBER := 0;
    v_file utl_file.file_type;
    v_line VARCHAR2(32767);
    --  
  BEGIN
    --
    BEGIN
      v_file := utl_file.fopen(p_dir, p_file, 'r');
    EXCEPTION
      WHEN OTHERS THEN
        fnd_file.put_line(fnd_file.log, 'Erro ao Ler Arquivo');
        fnd_file.put_line(fnd_file.log, SQLERRM);
        fnd_file.put_line(fnd_file.log, 'p_dir ............. : ' || p_dir);
        fnd_file.put_line(fnd_file.log, 'p_file ............ : ' || p_file);
    END;
    --
    LOOP
      BEGIN
        utl_file.get_line(v_file, v_line, 32767);
        --
      EXCEPTION
        WHEN no_data_found THEN
          EXIT;
          --
        WHEN OTHERS THEN
          fnd_file.put_line(fnd_file.log,'Problemas na Leitura do arquivo. Erro - ' ||SQLERRM);
      END;
      v_line := translate(v_line, chr(13), ';');
      ---
      IF nlidos = 0 THEN
        nlidos := nlidos + 1;
        --    
      ELSE
        v_status_fat  := TRIM(f_get_data(v_line, 6, p_separador));
        xnfci.line_id := f_get_data(v_line, 8, p_separador);
      
        oe_line_util.query_row(p_line_id  => xnfci.line_id,x_line_rec => l_line_rec);
      
        fnd_file.put_line(fnd_file.log,'line_id ................ : ' || xnfci.line_id);
        fnd_file.put_line(fnd_file.log,'v_status_fat ........... : ' || v_status_fat);
        fnd_file.put_line(fnd_file.log,'flow_status_code ....... : ' ||l_line_rec.flow_status_code);
        fnd_file.put_line(fnd_file.log, '');
      
        IF TRIM(v_status_fat) IS NULL THEN
          IF TRIM(l_line_rec.flow_status_code) NOT IN
             ('CANCELLED', 'CLOSED') THEN
          
            xnfci.party_name         := f_get_data(v_line, 1, p_separador);
            xnfci.order_number       := f_get_data(v_line, 2, p_separador);
            xnfci.line_number        := f_get_data(v_line, 3, p_separador);
            xnfci.ordered_quantity   := f_get_data(v_line, 4, p_separador);
            xnfci.header_id          := f_get_data(v_line, 7, p_separador);
            xnfci.line_id            := f_get_data(v_line, 8, p_separador);
            xnfci.new_price          := f_get_data(v_line, 9, p_separador);
            xnfci.sales_channel_code := f_get_data(v_line, 10, p_separador);
            --
            fnd_file.put_line(fnd_file.log, '');
            fnd_file.put_line(fnd_file.log,'party_name ..................: ' ||xnfci.party_name);
            fnd_file.put_line(fnd_file.log,'order_number ................: ' ||xnfci.order_number);
            fnd_file.put_line(fnd_file.log,'line_number .................: ' ||xnfci.line_number);
            fnd_file.put_line(fnd_file.log,'header_id ...................: ' ||xnfci.header_id);
            fnd_file.put_line(fnd_file.log,'line_id .....................: ' ||xnfci.line_id);
            fnd_file.put_line(fnd_file.log,'flow_status_code ............: ' ||l_line_rec.flow_status_code);
            fnd_file.put_line(fnd_file.log,'new_price ...................: ' ||xnfci.new_price);
            fnd_file.put_line(fnd_file.log,'sales_channel_code ..........: ' ||xnfci.sales_channel_code);
            fnd_file.put_line(fnd_file.log, '');
            --
            PIPE ROW(xnfci);
            nlidos := nvl(nlidos, 0) + 1;
          END IF;
        END IF;
        --
      END IF;
      --
    END LOOP;
    --
    fnd_file.put_line(fnd_file.log, ' ');
    nlidos := nlidos - 1;
    fnd_file.put_line(fnd_file.log,'Quantidade Registros Processados .....: ' || nlidos);
    RETURN;
    --  
  EXCEPTION
    WHEN no_data_found THEN
      fnd_file.put_line(1, 'Não há dados no arquivo');
      utl_file.fclose(v_file);
    WHEN utl_file.invalid_operation THEN
      fnd_file.put_line(1, 'Erro: utl_file.invalid_operation');
    WHEN utl_file.access_denied THEN
      fnd_file.put_line(1, 'Erro: utl_file.access_denied');
  END f_read_fci_data;
  --
  --
  FUNCTION f_read_header(p_type      IN VARCHAR2
                        ,p_dir       IN VARCHAR2
                        ,p_file      IN VARCHAR2
                        ,p_separador IN VARCHAR2) RETURN xxppg_qp_list_header
    PIPELINED IS
    qplh        qp_list_headers_all_b%ROWTYPE;
    l_qplhid    qp_list_headers_all_b.list_header_id%TYPE := 1;
    l_qplhend_d qp_list_headers_all_b.end_date_active%TYPE := SYSDATE - 1000;
    l_qplhhist  qp_list_headers_all_b.attribute2%TYPE := '-1';
    nlidos      NUMBER := 0;
    v_count_tot NUMBER := 0;
    v_file      utl_file.file_type;
    v_line      VARCHAR2(32767);
    v_item      mtl_system_items.segment1%TYPE;
    --  
  BEGIN
    --
    BEGIN
      v_file := utl_file.fopen(p_dir, p_file, 'r');
    EXCEPTION
      WHEN OTHERS THEN
        fnd_file.put_line(fnd_file.log, 'Erro ao Ler Arquivo');
        fnd_file.put_line(fnd_file.log, SQLERRM);
        fnd_file.put_line(fnd_file.log, 'p_dir ............. : ' || p_dir);
        fnd_file.put_line(fnd_file.log, 'p_file ............ : ' || p_file);
    END;
    --
    qplh.context          := 'PPG_BR';
    qplh.last_update_date := SYSDATE;
    qplh.last_updated_by  := g_user_id;
    -- 
    LOOP
      BEGIN
        utl_file.get_line(v_file, v_line, 32767);
        --
      EXCEPTION
        WHEN no_data_found THEN
          EXIT;
        WHEN OTHERS THEN
          fnd_file.put_line(fnd_file.log,'Problemas na Leitura do arquivo. Erro - ' ||SQLERRM);
      END;
      v_line := translate(v_line, chr(13), ';');
      ---
      IF nlidos = 0 THEN
        nlidos := nlidos + 1;
        --    
      ELSE
        --
        qplh.attribute1      := f_validate_list_name(f_get_data(v_line,1,p_separador));
        qplh.list_header_id  := f_get_list_id(qplh.attribute1);
        v_item               := f_get_data(v_line, 2, p_separador);
        qplh.end_date_active := f_validate_list_date(f_get_data(v_line,3,p_separador));
        qplh.attribute2      := f_validate_list_hist(f_get_data(v_line,4,p_separador));
        --   
        IF v_item IS NULL THEN
          --
          v_count_tot := v_count_tot + 1;
          --  
          IF qplh.list_header_id IS NOT NULL AND
             qplh.end_date_active IS NOT NULL AND
             qplh.attribute2 IS NOT NULL THEN
            --
            IF l_qplhid <> qplh.list_header_id OR
               l_qplhend_d <> qplh.end_date_active OR
               l_qplhhist <> qplh.attribute2 THEN
              --
              fnd_file.put_line(fnd_file.log, ' ');
              fnd_file.put_line(fnd_file.log, ' ');
              fnd_file.put_line(fnd_file.log,'Iniciando Processo Leitura Arquivo - ********** ' ||p_type || ' **********');
              fnd_file.put_line(fnd_file.log,'list_header_id ..................: ' ||qplh.list_header_id);
              fnd_file.put_line(fnd_file.log,'name ............................: ' ||qplh.attribute1);
              fnd_file.put_line(fnd_file.log,'end_date_active .................: ' ||qplh.end_date_active);
              fnd_file.put_line(fnd_file.log,'historico .......................: ' ||qplh.attribute2);
              fnd_file.put_line(fnd_file.log, ' ');
              --
              l_qplhid    := qplh.list_header_id;
              l_qplhend_d := qplh.end_date_active;
              l_qplhhist  := qplh.attribute2;
              --
              PIPE ROW(qplh);
              nlidos := nvl(nlidos, 0) + 1;
              --
            END IF;
          ELSE
            --
            g_retcode := 1;
            IF qplh.list_header_id IS NULL THEN
              fnd_file.put_line(fnd_file.log,'Lista de Preco Informada esta nula ou nao e valida ' ||qplh.attribute1);
            END IF;
            --
            IF qplh.end_date_active IS NULL THEN
              fnd_file.put_line(fnd_file.log,'Data Fim Vigencia esta nula ou com formato invalido ' ||qplh.end_date_active);
            END IF;
            --
            IF qplh.attribute2 IS NULL THEN
              fnd_file.put_line(fnd_file.log,'Campo Historico nao possui informacao valida ' ||qplh.attribute2);
            END IF;
          END IF;
        END IF; --v_item IS NULL THEN
      END IF;
    END LOOP;
  
    fnd_file.put_line(fnd_file.log,'Fim Processo Leitura Arquivo : ' || p_type);
    fnd_file.put_line(fnd_file.log, ' ');
    nlidos := nlidos - 1;
    fnd_file.put_line(fnd_file.log,'Quantidade Registros Header lidos .....: ' ||v_count_tot);
    RETURN;
  EXCEPTION
    WHEN no_data_found THEN
      fnd_file.put_line(1, 'Não há dados no arquivo');
      utl_file.fclose(v_file);
    WHEN utl_file.invalid_operation THEN
      fnd_file.put_line(1, 'Erro: utl_file.invalid_operation');
    WHEN utl_file.access_denied THEN
      fnd_file.put_line(1, 'Erro: utl_file.access_denied');
  END f_read_header;
  --
  --
  FUNCTION f_read_lines(p_type      IN VARCHAR2
                       ,p_dir       IN VARCHAR2
                       ,p_file      IN VARCHAR2
                       ,p_separador IN VARCHAR2) RETURN xxppg_qp_list_lines
    PIPELINED IS
    --
    qpll        qp_list_lines%ROWTYPE;
    qpaitem_id  qp_pricing_attributes.pricing_attr_value_to%TYPE := 0;
    l_qlllhid   qp_list_lines.list_header_id%TYPE := 0;
    l_qllllid   qp_list_lines.list_line_id%TYPE := 0;
    l_qllhhist  qp_list_lines.attribute1%TYPE := '-1';
    nlidos      NUMBER := 0;
    v_count_tot NUMBER := 0;
    v_file      utl_file.file_type;
    v_line      VARCHAR2(32767);
    v_item      mtl_system_items.segment1%TYPE;
    --  
  BEGIN
    v_file := utl_file.fopen(p_dir, p_file, 'r');
    --
    qpll.context          := 'PPG_BR';
    qpll.last_update_date := SYSDATE;
    qpll.last_updated_by  := g_user_id;
    -- 
    LOOP
      BEGIN
        utl_file.get_line(v_file, v_line, 32767);
      EXCEPTION
        WHEN no_data_found THEN
          EXIT;
        WHEN OTHERS THEN
          fnd_file.put_line(fnd_file.log,'Problemas na Leitura do arquivo. Erro - ' ||SQLERRM);
      END;
      v_line := translate(v_line, chr(13), ';');
      ---
      IF nlidos = 0 THEN
        nlidos := nlidos + 1;
        --    
      ELSE
        qpll.attribute2     := f_validate_list_name(f_get_data(v_line,1,p_separador));
        qpll.list_header_id := f_get_list_id(qpll.attribute2);
        v_item              := f_get_data(v_line, 2, p_separador);
        ---
        IF v_item IS NOT NULL THEN
          v_count_tot            := v_count_tot + 1;
          qpaitem_id             := f_get_item_id(v_item);
          qpll.end_date_active   := f_validate_list_date(f_get_data(v_line,3,p_separador));
          qpll.attribute1        := f_validate_list_hist(f_get_data(v_line,4,p_separador));
          qpll.list_line_id      := f_get_list_line_id(qpll.list_header_id,qpaitem_id);
          qpll.inventory_item_id := qpaitem_id;
          --   
          IF qpll.list_line_id IS NOT NULL THEN
            IF qpll.list_header_id IS NOT NULL AND
               qpll.end_date_active IS NOT NULL AND
               qpll.attribute1 IS NOT NULL THEN
              IF l_qlllhid <> qpll.list_header_id OR
                 l_qllllid <> qpll.list_line_id OR
                 l_qllhhist <> qpll.attribute1 THEN
                --
                fnd_file.put_line(fnd_file.log, ' ');
                fnd_file.put_line(fnd_file.log, ' ');
                fnd_file.put_line(fnd_file.log,'Iniciando Processo Leitura Arquivo - ********** ' ||p_type || ' **********');
                fnd_file.put_line(fnd_file.log,'list_header_id ..................: ' ||qpll.list_header_id);
                fnd_file.put_line(fnd_file.log,'list_line_id ....................: ' ||qpll.list_line_id);
                fnd_file.put_line(fnd_file.log,'name ............................: ' ||qpll.attribute2);
                fnd_file.put_line(fnd_file.log,'end_date_active .................: ' ||qpll.end_date_active);
                fnd_file.put_line(fnd_file.log,'historico .......................: ' ||qpll.attribute1);
                fnd_file.put_line(fnd_file.log, ' ');
                --
                l_qlllhid  := qpll.list_header_id;
                l_qllllid  := qpll.list_line_id;
                l_qllhhist := qpll.attribute1;
                --
                PIPE ROW(qpll);
                nlidos := nvl(nlidos, 0) + 1;
              END IF;
            ELSE
              --
              g_retcode := 1;
              IF qpll.list_header_id IS NULL THEN
                fnd_file.put_line(fnd_file.log,'Lista de Preco Informada esta nula ou nao e valida ' ||qpll.attribute2);
              END IF;
              --
              IF qpll.end_date_active IS NULL THEN
                fnd_file.put_line(fnd_file.log,'Data Fim Vigencia esta nula ou com formato invalido ' ||qpll.end_date_active);
              END IF;
              --
              IF qpll.attribute1 IS NULL THEN
                fnd_file.put_line(fnd_file.log,'Campo Historico nao possui informacao valida ' ||qpll.attribute2);
              END IF;
            END IF;
          END IF;
        END IF; --IF v_item IS NOT NULL THEN
      END IF;
      --
    END LOOP;
  
    fnd_file.put_line(fnd_file.log,'Fim Processo Leitura Arquivo : ' || p_type);
    fnd_file.put_line(fnd_file.log, ' ');
    nlidos := nlidos - 1;
    fnd_file.put_line(fnd_file.log,'Quantidade Registros Linha lidos .....: ' ||v_count_tot);
    RETURN;
  
  EXCEPTION
    WHEN no_data_found THEN
      fnd_file.put_line(1, 'Não há dados no arquivo');
      utl_file.fclose(v_file);
    WHEN utl_file.invalid_operation THEN
      fnd_file.put_line(1, 'Erro: utl_file.invalid_operation');
    WHEN utl_file.access_denied THEN
      fnd_file.put_line(1, 'Erro: utl_file.access_denied');
  END f_read_lines;
  --
  --
  FUNCTION f_read_data(p_directory_in IN VARCHAR2
                      ,p_file_name    IN VARCHAR2
                      ,p_separador    IN VARCHAR2)
    RETURN xxppg_1081_report_type
    PIPELINED IS
  
    --PRAGMA AUTONOMOUS_TRANSACTION; 
    rep_data  xxppg_1081_report_rec;
    nlidos    NUMBER := 0;
    v_file    utl_file.file_type;
    v_line    VARCHAR2(32767);
    l_data_ok NUMBER := 0;
  
  BEGIN
    fnd_file.put_line(fnd_file.log,'Iniciando Processo Leitura Arquivo - RELATORIO : ' ||p_separador);
    v_file := utl_file.fopen(p_directory_in, p_file_name, 'r');
    --
    LOOP
      BEGIN
        utl_file.get_line(v_file, v_line, 32767);
        --
      EXCEPTION
        WHEN no_data_found THEN
          EXIT;
        WHEN OTHERS THEN
          fnd_file.put_line(fnd_file.log,'Problemas na Leitura do arquivo. Erro - ' ||SQLERRM);
      END;
      v_line := TRIM(translate(TRIM(v_line), chr(13), ';'));
    
      IF TRIM(translate(v_line, ';', ' ')) IS NULL THEN
        EXIT;
      END IF;
      ---
      IF nlidos = 0 THEN
        fnd_file.put_line(fnd_file.log, ' ');
        fnd_file.put_line(fnd_file.log,' Iniciando Leitura Cabecalho Arquivo');
        fnd_file.put_line(fnd_file.log, v_line);
        l_data_ok := 0;
        --HEADER
        NULL;
      ELSE
        l_data_ok := 0;
      
        fnd_file.put_line(fnd_file.log, ' ');
        fnd_file.put_line(fnd_file.log, v_line);
        fnd_file.put_line(fnd_file.log, ' ');
        ---
        rep_data.order_number      := f_get_data(v_line, 1, g_separador);
        rep_data.line_number       := f_get_data(v_line, 2, g_separador);
        rep_data.net_price         := f_get_data(v_line, 3, g_separador);
        rep_data.organization_code := f_get_data(v_line, 4, g_separador);
        rep_data.party_name        := f_get_data(v_line, 5, g_separador);
        rep_data.cnpj              := f_get_data(v_line, 6, g_separador);
        rep_data.party_site_name   := f_get_data(v_line, 7, g_separador);
        rep_data.transaction_name  := f_get_data(v_line, 8, g_separador);
        rep_data.cod_item          := f_get_data(v_line, 9, g_separador);
        --
        rep_data.header_id         := f_get_header_id(TRIM(rep_data.order_number));
        rep_data.line_id           := f_get_line_id(TRIM(rep_data.header_id),TRIM(rep_data.line_number));
        rep_data.organization_id   := f_get_org_id(rep_data.organization_code);
        rep_data.party_id          := f_get_party_id(rep_data.party_name);
        rep_data.cust_acct_site_id := f_get_acct_site_id(rep_data.party_id,rep_data.cnpj,rep_data.party_site_name);
        rep_data.cust_trx_type_id  := f_get_trx_type_id(rep_data.transaction_name);
        rep_data.inventory_item_id := f_get_item_id(rep_data.cod_item);
        -- 
        rep_data.source_state          := f_get_org_details(rep_data.organization_id,'STATE_CODE');
        rep_data.dest_state            := f_get_cust_details(rep_data.cust_acct_site_id,'STATE_CODE');
        rep_data.contributor_type      := f_get_cust_details(rep_data.cust_acct_site_id,'CONTRIBUTOR_TYPE');
        rep_data.establishment_type    := f_get_cust_details(rep_data.cust_acct_site_id,'ESTABLISHMENT_TYPE');
        rep_data.transaction_name      := f_get_transaction_details(rep_data.cust_trx_type_id,'TRANSACTION_NAME');
        rep_data.group_tax_id          := to_number(f_get_transaction_details(rep_data.cust_trx_type_id,'GROUP_TAX_ID'));
        rep_data.group_tax_name        := f_get_transaction_details(rep_data.cust_trx_type_id,'GROUP_TAX_NAME');
        rep_data.fiscal_classification := f_get_item_details(rep_data.inventory_item_id,'FISCAL_CLASSIFICATION');
        rep_data.transaction_nature    := f_get_item_details(rep_data.inventory_item_id,'TRANSACTION_NATURE');
        --  
        fnd_file.put_line(fnd_file.log,'order_number ..................: ' ||rep_data.order_number);
        fnd_file.put_line(fnd_file.log,'line_number ...................: ' ||rep_data.line_number);
        fnd_file.put_line(fnd_file.log,'net_price .....................: ' ||rep_data.net_price);
        fnd_file.put_line(fnd_file.log,'organization_code .............: ' ||rep_data.organization_code);
        fnd_file.put_line(fnd_file.log,'party_name ....................: ' ||rep_data.party_name);
        fnd_file.put_line(fnd_file.log,'cnpj ..........................: ' ||rep_data.cnpj);
        fnd_file.put_line(fnd_file.log,'party_site_name ...............: ' ||rep_data.party_site_name);
        fnd_file.put_line(fnd_file.log,'tipo_transacao ................: ' ||rep_data.transaction_name);
        fnd_file.put_line(fnd_file.log,'cod_item ......................: ' ||rep_data.cod_item);
        fnd_file.put_line(fnd_file.log,'header_id .....................: ' ||rep_data.header_id);
        fnd_file.put_line(fnd_file.log,'line_id .......................: ' ||rep_data.line_id);
        fnd_file.put_line(fnd_file.log,'organization_id ...............: ' ||rep_data.organization_id);
        fnd_file.put_line(fnd_file.log,'cust_acct_site_id .............: ' ||rep_data.cust_acct_site_id);
        fnd_file.put_line(fnd_file.log,'cust_trx_type_id ..............: ' ||rep_data.cust_trx_type_id);
        fnd_file.put_line(fnd_file.log,'inventory_item_id .............: ' ||rep_data.inventory_item_id);
        fnd_file.put_line(fnd_file.log,'source_state ..................: ' ||rep_data.source_state);
        fnd_file.put_line(fnd_file.log,'dest_state ....................: ' ||rep_data.dest_state);
        fnd_file.put_line(fnd_file.log,'contributor_type ..............: ' ||rep_data.contributor_type);
        fnd_file.put_line(fnd_file.log,'establishment_type ............: ' ||rep_data.establishment_type);
        fnd_file.put_line(fnd_file.log,'transaction_name ..............: ' ||rep_data.transaction_name);
        fnd_file.put_line(fnd_file.log,'group_tax_id ..................: ' ||rep_data.group_tax_id);
        fnd_file.put_line(fnd_file.log,'group_tax_name ................: ' ||rep_data.group_tax_name);
        fnd_file.put_line(fnd_file.log,'fiscal_classification .........: ' ||rep_data.fiscal_classification);
        fnd_file.put_line(fnd_file.log,'transaction_nature ............: ' ||rep_data.transaction_nature);
        fnd_file.put_line(fnd_file.log, ' ');
        --
        IF rep_data.organization_id IS NULL THEN
          g_errcode := 1;
          fnd_file.put_line(fnd_file.log,'ERRO VALIDACAO DADOS NA PLANILHA ');
          fnd_file.put_line(fnd_file.log,'Nao foi possivel recuperar o ID DA ORGANIZACAO para a transacao ');
          l_data_ok := 1;
        END IF;
        --
        IF rep_data.party_id IS NULL THEN
          g_errcode := 1;
          fnd_file.put_line(fnd_file.log,'ERRO VALIDACAO DADOS NA PLANILHA ');
          fnd_file.put_line(fnd_file.log,'Nao foi possivel recuperar o ID DO CLIENTE para a transacao ');
          l_data_ok := 1;
        END IF;
        --
        IF rep_data.cust_acct_site_id IS NULL THEN
          g_errcode := 1;
          fnd_file.put_line(fnd_file.log,'ERRO VALIDACAO DADOS NA PLANILHA ');
          fnd_file.put_line(fnd_file.log,'Nao foi possivel recuperar o ID DO ENDERECO DO CLIENTE para a transacao ');
          l_data_ok := 1;
        END IF;
        --
        IF rep_data.cust_trx_type_id IS NULL THEN
          g_errcode := 1;
          fnd_file.put_line(fnd_file.log,'ERRO VALIDACAO DADOS NA PLANILHA ');
          fnd_file.put_line(fnd_file.log,'Nao foi possivel recuperar o ID DA TRANSACAO DE VENDA para a transacao ');
          l_data_ok := 1;
        END IF;
        --
        IF rep_data.inventory_item_id IS NULL THEN
          g_errcode := 1;
          fnd_file.put_line(fnd_file.log,'ERRO VALIDACAO DADOS NA PLANILHA ');
          fnd_file.put_line(fnd_file.log,'Nao foi possivel recuperar o ID DO ITEM para a transacao ');
          l_data_ok := 1;
        END IF;
        --
        IF rep_data.source_state IS NULL THEN
          g_errcode := 1;
          fnd_file.put_line(fnd_file.log,'ERRO VALIDACAO DADOS NA PLANILHA ');
          fnd_file.put_line(fnd_file.log,'Nao foi possivel recuperar ESTADO DE ORIGEM para a transacao ');
          l_data_ok := 1;
        END IF;
        --
        IF rep_data.dest_state IS NULL THEN
          g_errcode := 1;
          fnd_file.put_line(fnd_file.log,'ERRO VALIDACAO DADOS NA PLANILHA ');
          fnd_file.put_line(fnd_file.log,'Nao foi possivel recuperar ESTADO DE DESTINO para a transacao ');
          l_data_ok := 1;
        END IF;
        --
        IF rep_data.contributor_type IS NULL THEN
          g_errcode := 1;
          fnd_file.put_line(fnd_file.log,'ERRO VALIDACAO DADOS NA PLANILHA ');
          fnd_file.put_line(fnd_file.log,'Nao foi possivel recuperar o TIPO DE CONTRIBUINTE para a transacao ');
          l_data_ok := 1;
        END IF;
        --
        IF rep_data.establishment_type IS NULL THEN
          g_errcode := 1;
          fnd_file.put_line(fnd_file.log,'ERRO VALIDACAO DADOS NA PLANILHA ');
          fnd_file.put_line(fnd_file.log,'Nao foi possivel recuperar o TIPO DE ESTABELECIMENTO para a transacao ');
          l_data_ok := 1;
        END IF;
        --
        IF rep_data.group_tax_name IS NULL THEN
          g_errcode := 1;
          fnd_file.put_line(fnd_file.log,'ERRO VALIDACAO DADOS NA PLANILHA ');
          fnd_file.put_line(fnd_file.log,'Nao foi possivel recuperar GRUPO DE IMPOSTO para a transacao ');
          l_data_ok := 1;
        END IF;
        --
        IF rep_data.fiscal_classification IS NULL THEN
          g_errcode := 1;
          fnd_file.put_line(fnd_file.log,'ERRO VALIDACAO DADOS NA PLANILHA ');
          fnd_file.put_line(fnd_file.log,'Nao foi possivel recuperar CLASSIFICACAO FISCAL DO ITEM para a transacao ');
          l_data_ok := 1;
        END IF;
        --
        IF rep_data.transaction_nature IS NULL THEN
          g_errcode := 1;
          fnd_file.put_line(fnd_file.log,'ERRO VALIDACAO DADOS NA PLANILHA ');
          fnd_file.put_line(fnd_file.log,'Nao foi possivel recuperar NATUREZA DA TRANSACAO para a transacao ');
          l_data_ok := 1;
        END IF;
        --
        IF l_data_ok = 0 THEN
          PIPE ROW(rep_data);
        END IF;
        --
      END IF;
      nlidos := nvl(nlidos, 0) + 1;
    END LOOP;
  
    fnd_file.put_line(fnd_file.log,'Fim Processo Leitura Arquivo - RELATORIO : ' ||p_separador);
    fnd_file.put_line(fnd_file.log, ' ');
    nlidos := nlidos - 1;
    fnd_file.put_line(fnd_file.log,'Quantidade Registros lidos .....: ' || nlidos);
    RETURN;
  EXCEPTION
    WHEN no_data_found THEN
      fnd_file.put_line(1, 'Não há datos no arquivo');
      utl_file.fclose(v_file);
    WHEN utl_file.invalid_operation THEN
      fnd_file.put_line(1, 'Erro: utl_file.invalid_operation');
    WHEN utl_file.access_denied THEN
      fnd_file.put_line(1, 'Erro: utl_file.access_denied');
  END f_read_data;
  --
  --
  FUNCTION f_get_tax_rate(p_rule                  IN VARCHAR2
                         ,p_icms_exept            IN VARCHAR2
                         ,p_main_tax_type         IN VARCHAR2
                         ,p_group_tax_id          IN NUMBER
                         ,p_tax_category_id       IN NUMBER
                         ,p_contributor_type      IN VARCHAR2
                         ,p_establishment_type    IN VARCHAR2
                         ,p_transaction_nature    IN VARCHAR2
                         ,p_source_state          IN VARCHAR2
                         ,p_dest_state            IN VARCHAR2
                         ,p_cust_acct_site_id     IN NUMBER
                         ,p_organization_id       IN NUMBER
                         ,p_inventory_item_id     IN NUMBER
                         ,p_fiscal_classification IN VARCHAR2
                         ,p_item_origin_code      IN VARCHAR2
                         ,p_module                IN VARCHAR2) RETURN NUMBER IS
    l_tax_rate NUMBER  := -1;
    l_base_rate NUMBER;
    --
  BEGIN
    fnd_file.put_line(fnd_file.log, '****************************'); 
    fnd_file.put_line(fnd_file.log, 'BEGIN f_get_tax_rate '||p_main_tax_type); 
    fnd_file.put_line(fnd_file.log, '****************************'); 
    fnd_file.put_line(fnd_file.log, ''); 
    fnd_file.put_line(fnd_file.log, 'p_rule ................ : '||p_rule); 
    fnd_file.put_line(fnd_file.log, 'p_icms_exept .......... : '||p_icms_exept);
    fnd_file.put_line(fnd_file.log, 'p_main_tax_type ....... : '||p_main_tax_type);
    fnd_file.put_line(fnd_file.log, 'p_group_tax_id ........ : '||p_group_tax_id);
    fnd_file.put_line(fnd_file.log, 'p_tax_category_id ..... : '||p_tax_category_id);
    fnd_file.put_line(fnd_file.log, 'p_contributor_type .... : '||p_contributor_type);
    fnd_file.put_line(fnd_file.log, 'p_establishment_type .. : '||p_establishment_type);
    fnd_file.put_line(fnd_file.log, 'p_transaction_nature .. : '||p_transaction_nature);
    fnd_file.put_line(fnd_file.log, 'p_source_state ........ : '||p_source_state);
    fnd_file.put_line(fnd_file.log, 'p_dest_state .......... : '||p_dest_state);
    fnd_file.put_line(fnd_file.log, 'p_cust_acct_site_id ... : '||p_cust_acct_site_id);
    fnd_file.put_line(fnd_file.log, 'p_organization_id ..... : '||p_organization_id);
    fnd_file.put_line(fnd_file.log, 'p_inventory_item_id ... : '||p_inventory_item_id);
    fnd_file.put_line(fnd_file.log, 'p_fiscal_classification : '||p_fiscal_classification);
    fnd_file.put_line(fnd_file.log, 'p_module .............. : '||p_module);
    fnd_file.put_line(fnd_file.log, ''); 
    fnd_file.put_line(fnd_file.log, '******************************'); 
    fnd_file.put_line(fnd_file.log, '');
    fnd_file.put_line(fnd_file.log, '');
    --
    --
    IF nvl(UPPER(p_icms_exept),'X') = 'NAO_CONTRIB' AND p_main_tax_type = 'ICMS' THEN
      --
      --
      fnd_file.put_line(fnd_file.log, 'f_get_tax_rate - NAO_CONTRIB'); 
      fnd_file.put_line(fnd_file.log, 'p_source_state ................. : '||p_source_state); 
      fnd_file.put_line(fnd_file.log, 'p_dest_state ................... : '||p_dest_state); 
      fnd_file.put_line(fnd_file.log, 'item_orig ...................... : '||lpad(nvl(f_get_item_details(p_inventory_item_id, 'ITEM_ORIG'),0),2,'0')); 
      BEGIN
        SELECT nvl(flv.attribute1, cfsr.icms_tax)
        INTO   l_tax_rate
        FROM   apps.cll_f189_state_relations cfsr
              ,apps.cll_f189_states          orig
              ,apps.cll_f189_states          dest
              ,apps.fnd_lookup_values        flv
        WHERE  cfsr.source_state_id = orig.state_id
               AND cfsr.destination_state_id = dest.state_id
               AND flv.lookup_type = 'JLBR_ITEM_ORIGIN'
               AND nvl(end_date_active, SYSDATE + 1) > SYSDATE
               AND LANGUAGE = 'PTB'
               AND lpad(flv.lookup_code, 2, '0') =lpad(nvl(f_get_item_details(p_inventory_item_id, 'ITEM_ORIG'),nvl(p_item_origin_code,0)),2,'0')
               AND orig.state_code = p_source_state
               AND dest.state_code = p_dest_state;
      EXCEPTION
        WHEN no_data_found THEN
          l_tax_rate := -1;
        WHEN OTHERS THEN
          l_tax_rate := -1;
          IF p_module IS NOT NULL THEN
            fnd_file.put_line(fnd_file.log,'Erro recuperar tax_rate para regra : ' ||p_rule || ' - p_icms_exept :' ||p_icms_exept);
            fnd_file.put_line(fnd_file.log, SQLERRM);
          END IF;
      END;      
      RETURN l_tax_rate;
    ----
    ELSIF nvl(UPPEr(p_icms_exept),'X') = 'DIFERENCIAL' AND p_main_tax_type = 'ICMS' THEN
      BEGIN
        SELECT nvl(TRIM(jzatlv.attribute1), avta.tax_rate)*(1-(abs(jzatlv.base_rate/100))) l_tax_rate
        INTO   l_tax_rate 
        FROM   jl_zz_ar_tx_locn_v jzatlv, ar_vat_tax_all avta
        WHERE  jzatlv.ship_from_state = p_source_state
        AND    jzatlv.ship_to = p_dest_state
        AND    nvl(jzatlv.start_date_active, SYSDATE) <= SYSDATE
        AND    nvl(jzatlv.end_date_active, SYSDATE) >= SYSDATE
        AND    jzatlv.tax_category_id = p_tax_category_id
        AND    avta.tax_code = jzatlv.tax_code
        AND    nvl(avta.start_date, SYSDATE) <= SYSDATE
        AND    nvl(avta.end_date, SYSDATE) >= SYSDATE
        AND    nvl(avta.enabled_flag, 'N') = 'Y'
        AND    avta.tax_type = 'VAT';
      EXCEPTION
        WHEN no_data_found THEN
          l_tax_rate := -1;
        WHEN OTHERS THEN
          l_tax_rate := -1;
          IF p_module IS NOT NULL THEN
            fnd_file.put_line(fnd_file.log,'Erro recuperar tax_rate para regra : ' ||p_rule);
            fnd_file.put_line(fnd_file.log, SQLERRM);
          END IF;
      END;
      -----
      --
      IF l_tax_rate IS NULL THEN
        l_tax_rate := -1;
      END IF;  
      -----
      RETURN l_tax_rate;
    
    ----
    ELSIF p_rule = 'GET_LATIN_TX_GRP_TX_CODE' THEN
      --3.7.1 GET_LATIN_TX_GRP_TX_CODE (JL_ZZ_AR_TX_GROUPS_V)
      BEGIN
        SELECT avta.tax_rate, jztgv.base_rate
        INTO   l_tax_rate,l_base_rate
        FROM   jl_zz_ar_tx_groups_v jztgv, ar_vat_tax_all avta
        WHERE  jztgv.contributor_type = p_contributor_type
        AND    jztgv.establishment_type = p_establishment_type
        AND    jztgv.transaction_nature = p_transaction_nature
        AND    jztgv.tax_category_id = p_tax_category_id
        AND    nvl(jztgv.end_date_active, SYSDATE) >= SYSDATE
        AND    jztgv.group_tax_id = p_group_tax_id
        AND    avta.tax_code = jztgv.tax_code
        AND    nvl(avta.start_date, SYSDATE) <= SYSDATE
        AND    nvl(avta.end_date, SYSDATE) >= SYSDATE
        AND    nvl(avta.enabled_flag, 'N') = 'Y'
        AND    avta.tax_type = 'VAT';
      EXCEPTION
        WHEN no_data_found THEN
          l_tax_rate := -1;
        WHEN OTHERS THEN
          l_tax_rate := -1;
          IF p_module IS NOT NULL THEN
            fnd_file.put_line(fnd_file.log,'Erro recuperar tax_rate para regra : ' ||p_rule);
            fnd_file.put_line(fnd_file.log, SQLERRM);
          END IF;
      END;
      RETURN l_tax_rate;
      --
    ELSIF p_rule = 'GET_LOCATION_TX_CODE' THEN
      --3.7.2 GET_LOCATION_TX_CODE (JL_ZZ_AR_TX_LOCN_V)
      BEGIN
        SELECT nvl(TRIM(jzatlv.attribute1), avta.tax_rate), jzatlv.base_rate
        INTO   l_tax_rate, l_base_rate 
        FROM   jl_zz_ar_tx_locn_v jzatlv, ar_vat_tax_all avta
        WHERE  jzatlv.ship_from_state = p_source_state
        AND    jzatlv.ship_to = p_dest_state
        AND    nvl(jzatlv.start_date_active, SYSDATE) <= SYSDATE
        AND    nvl(jzatlv.end_date_active, SYSDATE) >= SYSDATE
        AND    jzatlv.tax_category_id = p_tax_category_id
        AND    avta.tax_code = jzatlv.tax_code
        AND    nvl(avta.start_date, SYSDATE) <= SYSDATE
        AND    nvl(avta.end_date, SYSDATE) >= SYSDATE
        AND    nvl(avta.enabled_flag, 'N') = 'Y'
        AND    avta.tax_type = 'VAT';
      EXCEPTION
        WHEN no_data_found THEN
          l_tax_rate := -1;
        WHEN OTHERS THEN
          l_tax_rate := -1;
          IF p_module IS NOT NULL THEN
            fnd_file.put_line(fnd_file.log,'Erro recuperar tax_rate para regra : ' ||p_rule);
            fnd_file.put_line(fnd_file.log, SQLERRM);
          END IF;
      END;
      RETURN l_tax_rate;
      --
    ELSIF p_rule = 'GET_FISC_CLAS_TX_CODE' THEN
      --3.7.3 GET_FISC_CLAS_TX_CODE (JL_ZZ_AR_TX_FSC_CLS_V)
      BEGIN
        SELECT avta.tax_rate, jzatfcv.base_rate
        INTO   l_tax_rate, l_base_rate
        FROM   jl_zz_ar_tx_fsc_cls_v jzatfcv, ar_vat_tax_all avta
        WHERE  jzatfcv.fiscal_classification_code = p_fiscal_classification
        AND    jzatfcv.tax_category_id = p_tax_category_id
        AND    nvl(jzatfcv.start_date_active, SYSDATE) <= SYSDATE
        AND    nvl(jzatfcv.end_date_active, SYSDATE) >= SYSDATE
        AND    jzatfcv.enabled_flag = 'Y'
        AND    avta.tax_code = jzatfcv.tax_code
        AND    nvl(avta.start_date, SYSDATE) <= SYSDATE
        AND    nvl(avta.end_date, SYSDATE) >= SYSDATE
        AND    nvl(avta.enabled_flag, 'N') = 'Y'
        AND    avta.tax_type = 'VAT';
      EXCEPTION
        WHEN no_data_found THEN
          l_tax_rate := -1;
        WHEN OTHERS THEN
          l_tax_rate := -1;
          IF p_module IS NOT NULL THEN
            fnd_file.put_line(fnd_file.log,'Erro recuperar tax_rate para regra : ' ||p_rule);
            fnd_file.put_line(fnd_file.log, SQLERRM);
          END IF;
      END;
      --
    ELSIF p_rule = 'GET_EXC_FISC_CLAS_TX_CODE' THEN
      --3.7.4 GET_EXC_FISC_CLAS_TX_CODE (JL_ZZ_AR_TX_EXC_FSC_V)
      BEGIN
        SELECT avta.tax_rate , jzatefv.base_rate
        INTO   l_tax_rate, l_base_rate
        FROM   jl_zz_ar_tx_exc_fsc_v jzatefv, ar_vat_tax_all avta
        WHERE  jzatefv.ship_from_state = p_source_state
        AND    jzatefv.ship_to_state = p_dest_state
        AND    jzatefv.tax_category_id = p_tax_category_id
        AND    jzatefv.fiscal_classification_code = p_fiscal_classification
        AND    nvl(jzatefv.start_date_active, SYSDATE) <= SYSDATE
        AND    nvl(jzatefv.end_date_active, SYSDATE) >= SYSDATE
        AND    avta.tax_code = jzatefv.tax_code
        AND    nvl(avta.start_date, SYSDATE) <= SYSDATE
        AND    nvl(avta.end_date, SYSDATE) >= SYSDATE
        AND    nvl(avta.enabled_flag, 'N') = 'Y'
        AND    avta.tax_type = 'VAT';
      EXCEPTION
        WHEN no_data_found THEN
          l_tax_rate := -1;
        WHEN OTHERS THEN
          l_tax_rate := -1;
          IF p_module IS NOT NULL THEN
            fnd_file.put_line(fnd_file.log,'Erro recuperar tax_rate para regra : ' ||p_rule);
            fnd_file.put_line(fnd_file.log, SQLERRM);
          END IF;
      END;
      -- 
    ELSIF p_rule = 'GET_EXC_ITEM_TX_CODE' THEN
      --3.7.5 GET_EXC_ITEM_TX_CODE (JL_ZZ_AR_TX_EXC_ITM_V)
      BEGIN
        SELECT avta.tax_rate, jzateiv.base_rate
        INTO   l_tax_rate, l_base_rate
        FROM   jl_zz_ar_tx_exc_itm_v jzateiv, ar_vat_tax_all avta
        WHERE  jzateiv.ship_from_state = p_source_state
        AND    jzateiv.ship_to_state = p_dest_state
        AND    jzateiv.organization_id = p_organization_id
        AND    jzateiv.inventory_item_id = p_inventory_item_id
        AND    jzateiv.tax_category_id = p_tax_category_id
        AND    nvl(jzateiv.start_date_active, SYSDATE) <= SYSDATE
        AND    nvl(jzateiv.end_date_active, SYSDATE) >= SYSDATE
        AND    avta.tax_code = jzateiv.tax_code
        AND    nvl(avta.start_date, SYSDATE) <= SYSDATE
        AND    nvl(avta.end_date, SYSDATE) >= SYSDATE
        AND    nvl(avta.enabled_flag, 'N') = 'Y'
        AND    avta.tax_type = 'VAT';
      EXCEPTION
        WHEN no_data_found THEN
          l_tax_rate := -1;
        WHEN OTHERS THEN
          l_tax_rate := -1;
          IF p_module IS NOT NULL THEN
            fnd_file.put_line(fnd_file.log,'Erro recuperar tax_rate para regra : ' ||p_rule);
            fnd_file.put_line(fnd_file.log, SQLERRM);
          END IF;
      END;
      --
    ELSIF p_rule = 'GET_CUST_EXC_TX_CODE' THEN
      --3.7.6 GET_CUST_EXC_TX_CODE (JL_ZZ_AR_TX_EXC_CUS_V)
      BEGIN
        SELECT avta.tax_rate , jzatecv.base_rate
        INTO   l_tax_rate, l_base_rate
        FROM   jl_zz_ar_tx_exc_cus_v jzatecv, ar_vat_tax_all avta
        WHERE  address_id = p_cust_acct_site_id
        AND    tax_category_id = p_tax_category_id
        AND    nvl(jzatecv.start_date_active, SYSDATE) <= SYSDATE
        AND    nvl(jzatecv.end_date_active, SYSDATE) >= SYSDATE
        AND    avta.tax_code = jzatecv.tax_code
        AND    nvl(avta.start_date, SYSDATE) <= SYSDATE
        AND    nvl(avta.end_date, SYSDATE) >= SYSDATE
        AND    nvl(avta.enabled_flag, 'N') = 'Y'
        AND    avta.tax_type = 'VAT';
      EXCEPTION
        WHEN no_data_found THEN
          l_tax_rate := -1;
        WHEN OTHERS THEN
          l_tax_rate := -1;
          IF p_module IS NOT NULL THEN
            fnd_file.put_line(fnd_file.log,'Erro recuperar tax_rate para regra : ' ||p_rule);
            fnd_file.put_line(fnd_file.log, SQLERRM);
          END IF;
      END;
    END IF;
    ---
    
    
    
    --
    IF p_module IS NOT NULL THEN
      fnd_file.put_line(fnd_file.log,'l_tax_rate ................... : ' || l_tax_rate);
      fnd_file.put_line(fnd_file.log, '');
    END IF;
  
    RETURN l_tax_rate;
  END f_get_tax_rate;
  --
  --
  FUNCTION f_get_net_price(p_header_id             IN NUMBER
                          ,p_line_id               IN NUMBER
                          ,p_unit_selling_price    IN NUMBER DEFAULT NULL
                          ,p_module                IN VARCHAR2 DEFAULT NULL
                          ,p_source_state          IN VARCHAR2 DEFAULT NULL
                          ,p_dest_state            IN VARCHAR2 DEFAULT NULL
                          ,p_contributor_type      IN VARCHAR2 DEFAULT NULL
                          ,p_establishment_type    IN VARCHAR2 DEFAULT NULL
                          ,p_cust_trx_type_id      IN NUMBER DEFAULT NULL
                          ,p_fiscal_classification IN VARCHAR2 DEFAULT NULL
                          ,p_transaction_nature    IN VARCHAR2 DEFAULT NULL
                          ,p_group_tax_id          IN NUMBER DEFAULT NULL
                          ,p_tax_rule_level        IN VARCHAR2 DEFAULT 'RATE'
                          ,p_organization_id       IN NUMBER DEFAULT NULL
                          ,p_inventory_item_id     IN NUMBER DEFAULT NULL
                          ,p_cust_acct_site_id     IN NUMBER DEFAULT NULL
                          ,p_item_origin           IN VARCHAR2 DEFAULT NULL -----22112019
                          ,p_reg                   IN NUMBER DEFAULT 0)
    RETURN NUMBER IS
    --
    l_net_price             NUMBER := 0;
    l_source_state          cll_f189_states.state_code%TYPE;
    l_sales_channel_code    oe_order_headers_all.sales_channel_code%type; --SSD2515
    l_dest_state            cll_f189_states.state_code%TYPE;
    l_contributor_type      hz_cust_acct_sites_all.global_attribute8%TYPE;
    l_establishment_type    hr_locations_all.global_attribute1%TYPE;
    l_cust_trx_type_id      ra_cust_trx_types_all.cust_trx_type_id%TYPE;
    l_fiscal_classification mtl_item_categories_v.segment1%TYPE;
    l_transaction_nature    mtl_system_items.global_attribute2%TYPE;
    l_order_type            VARCHAR2(100);
    l_group_tax             ra_cust_trx_types_all.global_attribute4%TYPE;
    l_group_tax_id          ar_vat_tax_vl.vat_tax_id%TYPE;
    l_organization_id       mtl_parameters.organization_id%TYPE;
    l_inventory_item_id     mtl_system_items.inventory_item_id%TYPE;
    l_cust_acct_site_id     hz_cust_acct_sites_all.cust_acct_site_id%TYPE;
    l_unit_selling_price    oe_order_lines_all.unit_selling_price%TYPE;
    l_item_code             mtl_system_items.segment1%TYPE;
    l_tax_category          VARCHAR2(50);
    l_count                 NUMBER := 0;
    l_tax_rule_level        VARCHAR2(10);
    l_rate                  NUMBER := -1;
    l_required_tax          NUMBER := 1;
    l_count_req_tax         NUMBER := 0;
    l_icms_rate             NUMBER := 0;
    l_pis_rate              NUMBER := 0;
    l_cofins_rate           NUMBER := 0;
    l_ipi_rate              NUMBER := 0;
    l_icms_exept            VARCHAR2(50);                        
    l_transaction_name      ra_cust_trx_types_all.name%TYPE;
    l_add_ipi               NUMBER := 0; --0 Não  / 1 SIM
    l_ipi_base              VARCHAR2(10) := 'IPI_BASE';
    xlt                     xxppg_1081_line_order_hold%ROWTYPE;
    l_exception_type        NUMBER := 0;
    l_price_list_name       qp_list_headers_all.name%TYPE;
    
    
  
    ---  
    --Recuperar Impostos Obrigatórios
    CURSOR c_required_tax(p_add_ipi            IN NUMBER
                         ,p_order_type         IN VARCHAR2
                         ,p_transaction_nature IN VARCHAR2) IS
      SELECT lookup_code required_tax
      FROM   fnd_lookup_values_vl flv
      WHERE  flv.lookup_type = 'XXPPG_1081_NET_REQUIRED_TAX'
      AND    flv.enabled_flag = 'Y'
      AND    nvl(flv.end_date_active, SYSDATE) >= SYSDATE
      AND    lookup_code IN
             (SELECT nvl(column_value
                         ,REPLACE(flv.lookup_code, flv.tag, ''))
               FROM   TABLE(xxppg_1081_net_price_pkg.f_splited_data((
                                                                    
                                                                    SELECT flv2.description imposto
                                                                    FROM   fnd_lookup_values_vl flv2
                                                                    WHERE  flv2.lookup_type =
                                                                           'XXPPG_1081_SETUP_SERVICO'
                                                                    AND    nvl(flv2.end_date_active,SYSDATE) >=SYSDATE
                                                                    AND    flv2.enabled_flag = 'Y'
                                                                    AND    ((xxppg_1081_net_price_pkg.f_get_data(flv2.lookup_code,1,'*') =p_order_type AND
                                                                          (nvl(xxppg_1081_net_price_pkg.f_get_data(flv2.lookup_code,2,'*'),'X') =nvl(nvl(p_transaction_nature
                                                                                     ,xxppg_1081_net_price_pkg.f_get_data(flv2.lookup_code,2,'*')),'X') OR
                                                                          nvl(xxppg_1081_net_price_pkg.f_get_data(flv2.lookup_code,2,'*'),'X') = 'X')) OR
                                                                          (xxppg_1081_net_price_pkg.f_get_data(flv2.tag,1,'*') =p_order_type AND
                                                                          (nvl(xxppg_1081_net_price_pkg.f_get_data(flv2.tag,2,'*'),'X') =nvl(nvl(p_transaction_nature
                                                                                     ,xxppg_1081_net_price_pkg.f_get_data(flv2.lookup_code,2,'*')),'X') OR
                                                                          nvl(xxppg_1081_net_price_pkg.f_get_data(flv2.tag,2,'*'),'X') = 'X'))
                                                                          )))) imposto)
      UNION
      SELECT l_ipi_base required_tax
      FROM   dual
      WHERE  p_add_ipi = 1;
    ---
    ---
  
    CURSOR c_get_tax(p_add_ipi            IN NUMBER
                    ,p_order_type         IN VARCHAR2
                    ,p_transaction_nature IN VARCHAR2) IS
      SELECT DISTINCT flvv.attribute1 tax_type
                     ,REPLACE(flvv.attribute1, flvv.attribute2, '') main_tax_type
      FROM   apps.jl_zz_ar_tx_rules_all regra
            ,apps.jl_zz_ar_tx_categ_all cat
            ,apps.fnd_lookup_values_vl  flvv
            ,jl_zz_ar_tx_groups_v       jztgv -----
      WHERE  regra.cust_trx_type_id = l_cust_trx_type_id
      AND    regra.contributor_type = l_contributor_type
      AND    regra.tax_rule_level = l_tax_rule_level
      AND    regra.tax_category_id = cat.tax_category_id
      AND    flvv.lookup_type = 'JLZZ_AR_TX_CATEGRY'
      AND    cat.tax_category = flvv.lookup_code
      AND    flvv.enabled_flag = 'Y'
      AND    nvl(flvv.end_date_active, SYSDATE) >= SYSDATE
      AND    flvv.attribute1 IS NOT NULL
      AND    flvv.attribute1 <> l_ipi_base
      --
      AND    jztgv.tax_category_id = regra.tax_category_id    ---
      AND    jztgv.contributor_type = regra.contributor_type  ---
      AND    jztgv.establishment_type = l_establishment_type  ---
      AND    jztgv.transaction_nature = l_transaction_nature ----
      AND    jztgv.group_tax_id = l_group_tax_id             ----
      --
      AND    flvv.attribute1 IN
             (SELECT nvl(column_value
                         ,REPLACE(flvv.attribute1, flvv.attribute2, ''))
               FROM   TABLE(xxppg_1081_net_price_pkg.f_splited_data((SELECT flv2.description imposto
                                                                    FROM   fnd_lookup_values_vl flv2
                                                                    WHERE  flv2.lookup_type =
                                                                           'XXPPG_1081_SETUP_SERVICO'
                                                                    AND    nvl(flv2.end_date_active,SYSDATE) >=SYSDATE
                                                                    AND    flv2.enabled_flag = 'Y'
                                                                    AND    ((xxppg_1081_net_price_pkg.f_get_data(flv2.lookup_code,1,'*') =p_order_type AND
                                                                          (nvl(xxppg_1081_net_price_pkg.f_get_data(flv2.lookup_code,2,'*'),'X') =
                                                                          nvl(nvl(p_transaction_nature,xxppg_1081_net_price_pkg.f_get_data(flv2.lookup_code,2,'*')),'X') OR
                                                                          nvl(xxppg_1081_net_price_pkg.f_get_data(flv2.lookup_code,2,'*'),'X') = 'X')) OR
                                                                          (xxppg_1081_net_price_pkg.f_get_data(flv2.tag,1,'*') =p_order_type AND
                                                                          (nvl(xxppg_1081_net_price_pkg.f_get_data(flv2.tag,2,'*'),'X') =nvl(nvl(p_transaction_nature
                                                                                     ,xxppg_1081_net_price_pkg.f_get_data(flv2.lookup_code,2,'*')),'X') OR
                                                                          nvl(xxppg_1081_net_price_pkg.f_get_data(flv2.tag,2,'*'),'X') = 'X'))
                                                                          )))) imposto)
      UNION
      SELECT l_ipi_base tax_type, l_ipi_base main_tax_type
      FROM   dual
      WHERE  p_add_ipi = 1;
  
    ---
    ---
    CURSOR c_get_tax_priority(p_tax_type IN VARCHAR2) IS
        SELECT cat.tax_category
              ,flvv.attribute1 tax_type
              ,regra.rule
              ,regra.tax_category_id
        FROM   apps.jl_zz_ar_tx_rules_all regra
              ,apps.jl_zz_ar_tx_categ_all cat
              ,jl_zz_ar_tx_groups_v       jztgv
              ,apps.fnd_lookup_values_vl  flvv
        WHERE  regra.cust_trx_type_id = l_cust_trx_type_id
        AND    regra.contributor_type = l_contributor_type
        AND    regra.tax_rule_level = l_tax_rule_level
        AND    regra.tax_category_id = cat.tax_category_id
        AND    flvv.lookup_type = 'JLZZ_AR_TX_CATEGRY'
        AND    flvv.enabled_flag = 'Y'
        AND    nvl(flvv.end_date_active, SYSDATE) >= SYSDATE
        AND    cat.tax_category = flvv.lookup_code
        AND    flvv.attribute1 = p_tax_type
              --
        AND    jztgv.tax_category_id = regra.tax_category_id
        AND    jztgv.contributor_type = regra.contributor_type
        AND    jztgv.establishment_type = l_establishment_type
        AND    jztgv.transaction_nature = l_transaction_nature
        AND    jztgv.group_tax_id = l_group_tax_id
        --
        ORDER  BY regra.tax_category_id, regra.priority;
  
  BEGIN
    IF p_unit_selling_price IS NOT NULL THEN
      l_unit_selling_price := p_unit_selling_price;
    END IF;
    --
  
    IF p_module IS NULL OR
       (p_module IS NOT NULL AND p_header_id IS NOT NULL) THEN
    
      fnd_file.put_line(fnd_file.log, ' IF p_module IS NULL OR');
      BEGIN
        SELECT cfs.state_code l_source_state
              ,ship_loc.state l_dest_state
              ,ship_cas.global_attribute8 l_contributor_type
              ,'INDUSTRIAL' l_establishment_type
              ,rctta.cust_trx_type_id l_cust_trx_type_id
              ,micv.segment1 l_fiscal_classification
              ,msi.global_attribute2 l_transaction_nature
              ,rctta.global_attribute4 l_group_tax
              ,'RATE' l_tax_rule_level
              ,avtv.vat_tax_id l_group_tax_id
              ,ship_from_org.organization_id l_organization_id
              ,msi.inventory_item_id l_inventory_item_id
              ,ship_cas.cust_acct_site_id l_cust_acct_site_id
              ,rctta.name l_transaction_name
              ,f_get_unit_price(NULL
                               ,ooha.price_list_id
                               ,msi.inventory_item_id)  l_unit_selling_price
              ,msi.segment1 l_item_code
              ,oth.name     l_order_type
              ,f_get_list_name(ooha.price_list_id) l_price_list_name
              ,ooha.sales_channel_code
        INTO   l_source_state
              ,l_dest_state
              ,l_contributor_type
              ,l_establishment_type
              ,l_cust_trx_type_id
              ,l_fiscal_classification
              ,l_transaction_nature
              ,l_group_tax
              ,l_tax_rule_level
              ,l_group_tax_id
              ,l_organization_id
              ,l_inventory_item_id
              ,l_cust_acct_site_id
              ,l_transaction_name
              ,l_unit_selling_price
              ,l_item_code
              ,l_order_type
              ,l_price_list_name
              ,l_sales_channel_code
        FROM   mtl_parameters               ship_from_org
              ,hz_cust_site_uses_all        ship_su
              ,hz_party_sites               ship_ps
              ,hz_locations                 ship_loc
              ,hz_cust_acct_sites_all       ship_cas
              ,hz_cust_site_uses_all        bill_su
              ,hz_party_sites               bill_ps
              ,hz_locations                 bill_loc
              ,hz_cust_acct_sites_all       bill_cas
              ,hz_parties                   party
              ,hz_cust_accounts             cust_acct
              ,ra_terms_tl                  term
              ,oe_order_headers_all         ooha
              ,oe_order_lines_all           oola
              ,hz_cust_account_roles        sold_roles
              ,hz_parties                   sold_party
              ,hz_cust_accounts             sold_acct
              ,hz_relationships             sold_rel
              ,hz_cust_account_roles        ship_roles
              ,hz_parties                   ship_party
              ,hz_relationships             ship_rel
              ,hz_cust_accounts             ship_acct
              ,hz_cust_account_roles        invoice_roles
              ,hz_parties                   invoice_party
              ,hz_relationships             invoice_rel
              ,hz_cust_accounts             invoice_acct
              ,fnd_currencies               fndcur
              ,oe_transaction_types_tl      oth
              ,oe_transaction_types_vl      otvh
              ,oe_transaction_types_tl      otl
              ,oe_transaction_types_vl      otvl
              ,qp_list_headers_tl           pl
              ,ra_rules                     invrule
              ,ra_rules                     accrule
              ,oe_lookups                   olu
              ,ra_cust_trx_types_all        rctta
              ,mtl_item_categories_v        micv
              ,mtl_system_items             msi
              ,hr_locations_all             hla
              ,hr_all_organization_units    haou
              ,cll_f189_fiscal_entities_all cffea
              ,cll_f189_states              cfs
              ,ar_vat_tax_vl                avtv
        WHERE  ooha.order_type_id = oth.transaction_type_id
        AND    oola.line_type_id = otl.transaction_type_id
        AND    oth.transaction_type_id = otvh.transaction_type_id
        AND    otl.transaction_type_id = otvl.transaction_type_id
        AND    ooha.header_id = oola.header_id
              --
        AND    ooha.header_id = p_header_id
        AND    oola.line_id = p_line_id
              --
        AND    oth.language = userenv('LANG')
        AND    otl.language = userenv('LANG')
        AND    rctta.cust_trx_type_id = otvl.cust_trx_type_id
        AND    ooha.price_list_id = pl.list_header_id(+)
        AND    pl.language(+) = userenv('LANG')
        AND    oola.invoicing_rule_id = invrule.rule_id(+)
        AND    oola.accounting_rule_id = accrule.rule_id(+)
        AND    oola.payment_term_id = term.term_id(+)
        AND    term.language(+) = userenv('LANG')
        AND    ooha.transactional_curr_code = fndcur.currency_code
        AND    ooha.sold_to_org_id = cust_acct.cust_account_id(+)
        AND    cust_acct.party_id = party.party_id(+)
        AND    oola.ship_from_org_id = ship_from_org.organization_id(+)
        AND    oola.ship_to_org_id = ship_su.site_use_id(+)
        AND    ship_su.cust_acct_site_id = ship_cas.cust_acct_site_id(+)
        AND    ship_cas.party_site_id = ship_ps.party_site_id(+)
        AND    ship_loc.location_id(+) = ship_ps.location_id
        AND    oola.invoice_to_org_id = bill_su.site_use_id(+)
        AND    bill_su.cust_acct_site_id = bill_cas.cust_acct_site_id(+)
        AND    bill_cas.party_site_id = bill_ps.party_site_id(+)
        AND    bill_loc.location_id(+) = bill_ps.location_id
        AND    ooha.sold_to_contact_id = sold_roles.cust_account_role_id(+)
        AND    sold_roles.party_id = sold_rel.party_id(+)
        AND    sold_roles.role_type(+) = 'CONTACT'
        AND    sold_roles.cust_account_id = sold_acct.cust_account_id(+)
        AND    nvl(sold_rel.object_id, -1) = nvl(sold_acct.party_id, -1)
        AND    sold_rel.subject_id = sold_party.party_id(+)
        AND    oola.ship_to_contact_id = ship_roles.cust_account_role_id(+)
        AND    ship_roles.party_id = ship_rel.party_id(+)
        AND    ship_roles.role_type(+) = 'CONTACT'
        AND    ship_roles.cust_account_id = ship_acct.cust_account_id(+)
        AND    nvl(ship_rel.object_id, -1) = nvl(ship_acct.party_id, -1)
        AND    ship_rel.subject_id = ship_party.party_id(+)
        AND    ooha.invoice_to_contact_id =
               invoice_roles.cust_account_role_id(+)
        AND    invoice_roles.party_id = invoice_rel.party_id(+)
        AND    invoice_roles.role_type(+) = 'CONTACT'
        AND    invoice_roles.cust_account_id =
               invoice_acct.cust_account_id(+)
        AND    nvl(invoice_rel.object_id, -1) =
               nvl(invoice_acct.party_id, -1)
        AND    invoice_rel.subject_id = invoice_party.party_id(+)
        AND    olu.lookup_type(+) = 'OE_LINE_SET_POPLIST'
        AND    olu.lookup_code(+) = ooha.customer_preference_set_code
        AND    olu.enabled_flag(+) = 'Y'
        AND    SYSDATE BETWEEN nvl(olu.start_date_active, SYSDATE - 1) AND
               nvl(olu.end_date_active, SYSDATE + 1)
        AND    oola.inventory_item_id = micv.inventory_item_id
        AND    ship_from_org.organization_id = micv.organization_id
        AND    micv.category_set_name = 'FISCAL_CLASSIFICATION'
        AND    msi.inventory_item_id = oola.inventory_item_id
        AND    msi.organization_id = haou.organization_id
        AND    haou.organization_id = hla.inventory_organization_id
        AND    hla.location_id = cffea.location_id
        AND    cffea.entity_type_lookup_code = 'LOCATION'
        AND    cfs.state_id = cffea.state_id
        AND    haou.organization_id = ship_from_org.organization_id
        AND    avtv.tax_code = rctta.global_attribute4
        AND    avtv.tax_type = 'TAX_GROUP';
      
        ---
        BEGIN
          SELECT 1
          INTO   l_exception_type
          FROM   fnd_lookup_values_vl flvv
          WHERE  flvv.lookup_type = 'XXPPG_1081_PRICE_L_EXCEPTIONS'
          AND    flvv.lookup_code = l_price_list_name
          AND    flvv.enabled_flag = 'Y'
          AND    nvl(flvv.end_date_active, SYSDATE) >= SYSDATE;
        EXCEPTION
          WHEN too_many_rows THEN
            l_exception_type := 1;
          WHEN OTHERS THEN
            l_exception_type := 0;
        END;
        ---
        
       IF nvl(l_exception_type, 0) = 0 THEN --- SSD2515 
        BEGIN
          SELECT 1
          INTO   l_exception_type
          FROM   fnd_lookup_values_vl flvv
          WHERE  flvv.lookup_type = 'XXPPG_1081_CONT_ORDENS_BU'
          AND    flvv.lookup_code = l_sales_channel_code
          AND    upper(nvl(flvv.attribute1,'N')) IN ('N','NAO')
          AND    flvv.enabled_flag = 'Y'
          AND    nvl(flvv.end_date_active, SYSDATE) >= SYSDATE;
        EXCEPTION
          WHEN too_many_rows THEN
            l_exception_type := 1;
          WHEN OTHERS THEN
            l_exception_type := 0;
        END;
        END IF;
        
        ---
      
        fnd_file.put_line(fnd_file.log,'1 - l_exception_type ...... : ' ||l_exception_type);
        fnd_file.put_line(fnd_file.log, ' ');
      
        --
        IF nvl(l_exception_type, 0) = 0 THEN
          BEGIN
            SELECT 1
            INTO   l_exception_type
            FROM   fnd_lookup_values_vl flv
            WHERE  flv.lookup_code = l_order_type
            AND    flv.lookup_type = 'XXPPG_1081_EXCEPTION_TYPES'
            AND    flv.enabled_flag = 'Y'
            AND    nvl(flv.end_date_active, SYSDATE) >= SYSDATE;
          EXCEPTION
            WHEN too_many_rows THEN
              l_exception_type := 1;
            WHEN OTHERS THEN
              l_exception_type := 0;
          END;
          --
        
          fnd_file.put_line(fnd_file.log,'2 - l_exception_type ...... : ' ||l_exception_type);
          fnd_file.put_line(fnd_file.log, ' ');
        END IF;
        --
        IF l_exception_type = 1 THEN
          IF p_module IS NOT NULL THEN
            ----
            rec_tax(p_reg).icms_tax_code := NULL;
            rec_tax(p_reg).icms_tax_rate := l_rate || '%';
            rec_tax(p_reg).pis_tax_code := NULL;
            rec_tax(p_reg).pis_tax_rate := l_rate || '%';
            rec_tax(p_reg).cofins_tax_code := NULL;
            rec_tax(p_reg).cofins_tax_rate := l_rate || '%';
            rec_tax(p_reg).ipi_tax_code := NULL;
            rec_tax(p_reg).ipi_tax_rate := l_rate || '%';
            --
            RETURN - 1;
          ELSE
            RETURN l_unit_selling_price;
          END IF;
        END IF;
        ---
        
        BEGIN
          xlt.source_state          := l_source_state;
          xlt.dest_state            := l_dest_state;
          xlt.contributor_type      := l_contributor_type;
          xlt.establishment_type    := l_establishment_type;
          xlt.cust_trx_type_id      := l_cust_trx_type_id;
          xlt.fiscal_classification := l_fiscal_classification;
          xlt.transaction_nature    := l_transaction_nature;
          xlt.group_tax             := l_group_tax;
          xlt.tax_rule_level        := l_tax_rule_level;
          xlt.group_tax_id          := l_group_tax_id;
          xlt.organization_id       := l_organization_id;
          xlt.inventory_item_id     := l_inventory_item_id;
          xlt.cust_acct_site_id     := l_cust_acct_site_id;
          xlt.transaction_name      := l_transaction_name;
          xlt.unit_selling_price    := l_unit_selling_price;
          xlt.line_id               := p_line_id;
          xlt.add_ipi               := l_add_ipi;
          xlt.last_update_date      := SYSDATE;
          xlt.creation_date         := SYSDATE;
          xlt.next_notification     := SYSDATE;
          xlt.step_number           := 0;
          xlt.item_code             := l_item_code;
        EXCEPTION
          WHEN OTHERS THEN
            fnd_file.put_line(fnd_file.log,'ERRO ATRIBUIR VALORES XLT ' || SQLERRM);
        END;
      EXCEPTION
        WHEN OTHERS THEN
          l_net_price := 0;
        
          fnd_file.put_line(fnd_file.log,'l_add_ipi ...... : ' || l_add_ipi);
          fnd_file.put_line(fnd_file.log, ' ');
        
          IF p_module IS NOT NULL THEN
            ----
            rec_tax(p_reg).icms_tax_code := NULL;
            rec_tax(p_reg).icms_tax_rate := l_rate || '%';
            rec_tax(p_reg).pis_tax_code := NULL;
            rec_tax(p_reg).pis_tax_rate := l_rate || '%';
            rec_tax(p_reg).cofins_tax_code := NULL;
            rec_tax(p_reg).cofins_tax_rate := l_rate || '%';
            rec_tax(p_reg).ipi_tax_code := NULL;
            rec_tax(p_reg).ipi_tax_rate := l_rate || '%';
            --        
          END IF;
          IF p_module IS NULL THEN
            xlt.tax_category := l_group_tax;
            xlt.step_number  := 1;
            p_apply_hold(p_header_id         => p_header_id
                        ,p_line_id           => p_line_id
                        ,p_inventory_item_id => l_inventory_item_id
                        ,p_xloh              => xlt);
            RETURN xlt.unit_selling_price;
          ELSE
            RETURN - 1;
          END IF;
      END;
    ELSE
    
      -- NET PRICE SIMULATION REPORT
      fnd_file.put_line(fnd_file.log, 'Parameters : ');
      fnd_file.put_line(fnd_file.log, '');
      --
      l_source_state          := p_source_state;
      l_dest_state            := p_dest_state;
      l_contributor_type      := p_contributor_type;
      l_establishment_type    := p_establishment_type;
      l_cust_trx_type_id      := p_cust_trx_type_id;
      l_fiscal_classification := p_fiscal_classification;
      l_transaction_nature    := p_transaction_nature;
      l_tax_rule_level        := p_tax_rule_level;
      l_group_tax_id          := p_group_tax_id;
      l_organization_id       := p_organization_id;
      l_inventory_item_id     := p_inventory_item_id;
      l_cust_acct_site_id     := p_cust_acct_site_id;
      l_transaction_name      := f_get_transaction_details(p_cust_trx_type_id,'TRANSACTION_NAME');
      l_unit_selling_price    := p_unit_selling_price;
      --
      xlt.source_state          := p_source_state;
      xlt.dest_state            := p_dest_state;
      xlt.contributor_type      := p_contributor_type;
      xlt.establishment_type    := p_establishment_type;
      xlt.cust_trx_type_id      := p_cust_trx_type_id;
      xlt.transaction_name      := l_transaction_name;
      xlt.fiscal_classification := p_fiscal_classification;
      xlt.transaction_nature    := p_transaction_nature;
      xlt.tax_rule_level        := p_tax_rule_level;
      xlt.group_tax_id          := p_group_tax_id;
      xlt.organization_id       := p_organization_id;
      xlt.inventory_item_id     := p_inventory_item_id;
      xlt.item_code             := f_get_item_details(p_inventory_item_id,'COD_ITEM');
      xlt.cust_acct_site_id     := p_cust_acct_site_id;
      xlt.line_id               := p_line_id;
      xlt.add_ipi               := l_add_ipi;
      xlt.unit_selling_price    := l_unit_selling_price;
      xlt.last_update_date      := SYSDATE;
      xlt.creation_date         := SYSDATE;
      --
      
      
      fnd_file.put_line(fnd_file.log,'l_source_state ............... : ' ||xlt.source_state);
      fnd_file.put_line(fnd_file.log,'l_dest_state ................. : ' ||xlt.dest_state);
      fnd_file.put_line(fnd_file.log,'l_contributor_type ........... : ' ||xlt.contributor_type);
      fnd_file.put_line(fnd_file.log,'l_establishment_type ......... : ' ||xlt.establishment_type);
      fnd_file.put_line(fnd_file.log,'l_cust_trx_type_id ........... : ' ||xlt.cust_trx_type_id);
      fnd_file.put_line(fnd_file.log,'l_fiscal_classification ...... : ' ||xlt.fiscal_classification);
      fnd_file.put_line(fnd_file.log,'l_transaction_nature ......... : ' ||xlt.transaction_nature);
      fnd_file.put_line(fnd_file.log,'l_tax_rule_level ............. : ' ||xlt.tax_rule_level);
      fnd_file.put_line(fnd_file.log,'l_group_tax_id ............... : ' ||xlt.group_tax_id);
      fnd_file.put_line(fnd_file.log,'l_organization_id ............ : ' ||xlt.organization_id);
      fnd_file.put_line(fnd_file.log,'l_inventory_item_id .......... : ' ||xlt.inventory_item_id);
      fnd_file.put_line(fnd_file.log,'item_code .................... : ' ||xlt.item_code);
      fnd_file.put_line(fnd_file.log,'l_cust_acct_site_id .......... : ' ||xlt.cust_acct_site_id);
      fnd_file.put_line(fnd_file.log,'l_order_type ................. : ' ||l_order_type);
      fnd_file.put_line(fnd_file.log,'l_add_ipi .................... : ' || l_add_ipi);
      fnd_file.put_line(fnd_file.log, ' ');
      --
    END IF;
    --
    --Verificar se para os parametros informados existem todos os impostos obrigatórios.
    BEGIN
      --
      l_order_type := f_get_transaction_details(p_cust_trx_type_id,'ORDER_TYPE');
      l_add_ipi    := f_add_ipi(xlt.transaction_name, xlt.transaction_nature);
      fnd_file.put_line(fnd_file.log, 'l_add_ipi ...... : ' || l_add_ipi);
      fnd_file.put_line(fnd_file.log, ' ');
      --
      l_icms_exept := f_icms_except(l_order_type);
      
      IF nvl(l_icms_exept,'X') = 'NAO_CONTRIB' AND  
         nvl(xlt.source_state,'X') = nvl(xlt.dest_state,'X')  THEN
         l_icms_exept := NULL;
      END IF;
      
      fnd_file.put_line(fnd_file.log,'l_icms_exept ................. : ' ||l_icms_exept);
            
      
      IF p_module IS NOT NULL THEN
       
        fnd_file.put_line(fnd_file.log, '');
        fnd_file.put_line(fnd_file.log,'l_order_type ................. : ' ||l_order_type);
        fnd_file.put_line(fnd_file.log,'l_transaction_nature ......... : ' ||l_transaction_nature);
        fnd_file.put_line(fnd_file.log,'l_add_ipi .................... : ' || l_add_ipi);
        fnd_file.put_line(fnd_file.log,'l_icms_exept ................. : ' ||l_icms_exept);
        fnd_file.put_line(fnd_file.log, '');
        fnd_file.put_line(fnd_file.log, '');
      END IF;
      -- 
      
      fnd_file.put_line(fnd_file.log, '*********************************************');
      fnd_file.put_line(fnd_file.log, 'BEGIN FOR r_required_tax IN c_required_tax');
      fnd_file.put_line(fnd_file.log, '*********************************************');
      fnd_file.put_line(fnd_file.log, '');  
      fnd_file.put_line(fnd_file.log, 'l_add_ipi ............. : '||l_add_ipi); 
      fnd_file.put_line(fnd_file.log, 'l_order_type .......... : '||l_order_type);
      fnd_file.put_line(fnd_file.log, 'l_transaction_nature .. : '||l_transaction_nature); 
      fnd_file.put_line(fnd_file.log, ''); 
      fnd_file.put_line(fnd_file.log, 'Verificando Impostos Obrigatorios');  
      FOR r_required_tax IN c_required_tax(l_add_ipi
                                          ,l_order_type
                                          ,l_transaction_nature) LOOP
        l_count_req_tax := l_count_req_tax + 1;
      
      
        
        IF l_required_tax > 0 THEN
          BEGIN
            SELECT COUNT(1)
            INTO   l_required_tax
            FROM   apps.jl_zz_ar_tx_rules_all regra
                  ,apps.jl_zz_ar_tx_categ_all cat
                  ,apps.fnd_lookup_values_vl  flvv
                  ,jl_zz_ar_tx_groups_v       jztgv -----
            WHERE  regra.cust_trx_type_id = l_cust_trx_type_id
            AND    regra.contributor_type = l_contributor_type
            AND    regra.tax_rule_level = l_tax_rule_level
            AND    regra.tax_category_id = cat.tax_category_id
            AND    flvv.lookup_type = 'JLZZ_AR_TX_CATEGRY'
            AND    cat.tax_category = flvv.lookup_code
            AND    flvv.enabled_flag = 'Y'
            AND    nvl(flvv.end_date_active, SYSDATE) >= SYSDATE
            --
             AND    jztgv.tax_category_id = regra.tax_category_id
             AND    jztgv.contributor_type = regra.contributor_type
             AND    jztgv.establishment_type = l_establishment_type
             AND    jztgv.transaction_nature = l_transaction_nature
             AND    jztgv.group_tax_id = l_group_tax_id
            --
            AND    nvl(flvv.attribute1, 'X') = r_required_tax.required_tax;
            fnd_file.put_line(fnd_file.log, ''); 
            fnd_file.put_line(fnd_file.log, 'required_tax ..... : '||r_required_tax.required_tax); 
            fnd_file.put_line(fnd_file.log, 'l_required_tax ... : '||l_required_tax); 
            fnd_file.put_line(fnd_file.log, ''); 
            IF l_required_tax = 0 THEN
              
            fnd_file.put_line(fnd_file.log, 'Nao existe configuracao para o imposto : '||r_required_tax.required_tax); 
            END IF;
          EXCEPTION
            WHEN OTHERS THEN
              l_required_tax := 0;
              fnd_file.put_line(fnd_file.log,'Erro ao validar impostos obrigatorios ');
            
              IF p_module IS NULL THEN
                xlt.tax_category := r_required_tax.required_tax;
                xlt.step_number  := 2;
                p_apply_hold(p_header_id         => p_header_id
                            ,p_line_id           => p_line_id
                            ,p_inventory_item_id => l_inventory_item_id
                            ,p_xloh              => xlt);
              END IF;
              --
              IF p_module IS NOT NULL THEN
                ----
                rec_tax(p_reg).icms_tax_code := NULL;
                rec_tax(p_reg).icms_tax_rate := l_rate || '%';
                rec_tax(p_reg).pis_tax_code := NULL;
                rec_tax(p_reg).pis_tax_rate := l_rate || '%';
                rec_tax(p_reg).cofins_tax_code := NULL;
                rec_tax(p_reg).cofins_tax_rate := l_rate || '%';
                rec_tax(p_reg).ipi_tax_code := NULL;
                rec_tax(p_reg).ipi_tax_rate := l_rate || '%';
                --        
              END IF;
              IF p_module IS NULL THEN
                RETURN xlt.unit_selling_price;
              ELSE
                RETURN - 1;
              END IF;
          END;
        END IF;
      END LOOP; --FOR r_required_tax IN c_required_tax LOOP 
      fnd_file.put_line(fnd_file.log, '*********************************************');
      fnd_file.put_line(fnd_file.log, 'END FOR r_required_tax IN c_required_tax');
      fnd_file.put_line(fnd_file.log, '*********************************************');
      fnd_file.put_line(fnd_file.log, '');   
    END;
  
    --Continuar apenas se todos impostos obrigatorios existirem no setup
    IF l_count_req_tax > 0 AND l_required_tax > 0 THEN
      fnd_file.put_line(fnd_file.log,'cust_trx_type_id ......... : ' ||xlt.cust_trx_type_id);
      fnd_file.put_line(fnd_file.log,'contributor_type ......... : ' ||xlt.contributor_type);
      fnd_file.put_line(fnd_file.log,'l_order_type ............. : ' || l_order_type);
      fnd_file.put_line(fnd_file.log,'l_transaction_nature ..... : ' ||l_transaction_nature);
      fnd_file.put_line(fnd_file.log,'l_add_ipi ................ : ' || l_add_ipi);
      fnd_file.put_line(fnd_file.log,'l_icms_exept ............. : ' ||l_icms_exept);
      fnd_file.put_line(fnd_file.log, '');
      --Recupera todos os tipos de impostos para os parametros enviados. (ICMS / PIS / COFINS)
      fnd_file.put_line(fnd_file.log, '*********************************************');
      fnd_file.put_line(fnd_file.log, 'BEGIN FOR r_get_tax IN c_get_tax');
      fnd_file.put_line(fnd_file.log, '*********************************************');
      fnd_file.put_line(fnd_file.log, '');  
      FOR r_get_tax IN c_get_tax(l_add_ipi
                                ,l_order_type
                                ,l_transaction_nature) LOOP
        fnd_file.put_line(fnd_file.log, '');
        fnd_file.put_line(fnd_file.log,'r_tax_type ............ : ' ||r_get_tax.tax_type);
        fnd_file.put_line(fnd_file.log,'r_main_tax_type ....... : ' ||r_get_tax.main_tax_type);
        fnd_file.put_line(fnd_file.log,'l_rate ................ : ' ||l_rate);
        fnd_file.put_line(fnd_file.log,'l_icms_exept .......... : ' ||l_icms_exept);
        fnd_file.put_line(fnd_file.log, '');
      
        ---Tentar Recuperar a aliquota a partir da prioridade para cada tipo de imposto.
        l_rate := -1;
        
        
        
        fnd_file.put_line(fnd_file.log, '*********************************************');
        fnd_file.put_line(fnd_file.log, 'BEGIN FOR r_get_tax_priority IN c_get_tax_priority '||r_get_tax.tax_type);
        fnd_file.put_line(fnd_file.log, '*********************************************');
        fnd_file.put_line(fnd_file.log, ''); 
        FOR r_get_tax_priority IN c_get_tax_priority(r_get_tax.tax_type) LOOP
          --
          fnd_file.put_line(fnd_file.log, '');
          fnd_file.put_line(fnd_file.log,'Dentro Loop get_priority : ' ||r_get_tax.tax_type);
          fnd_file.put_line(fnd_file.log,'l_icms_exept ........... : ' ||l_icms_exept ); 
          fnd_file.put_line(fnd_file.log,'p_rule ................. : ' ||r_get_tax_priority.rule);
          fnd_file.put_line(fnd_file.log,'p_group_tax_id ......... : ' ||xlt.group_tax_id);
          fnd_file.put_line(fnd_file.log,'p_tax_category_id ...... : ' ||r_get_tax_priority.tax_category_id);
          fnd_file.put_line(fnd_file.log,'p_contributor_type ..... : ' ||xlt.contributor_type);
          fnd_file.put_line(fnd_file.log,'p_establishment_type.... : ' ||xlt.establishment_type);
          fnd_file.put_line(fnd_file.log,'p_transaction_nature ... : ' ||xlt.transaction_nature);
          fnd_file.put_line(fnd_file.log,'p_source_state ......... : ' ||xlt.source_state);
          fnd_file.put_line(fnd_file.log,'p_dest_state ........... : ' ||xlt.dest_state);
          fnd_file.put_line(fnd_file.log,'p_cust_acct_site_id .... : ' ||xlt.cust_acct_site_id);
          fnd_file.put_line(fnd_file.log,'p_organization_id ...... : ' ||xlt.organization_id);
          fnd_file.put_line(fnd_file.log,'p_inventory_item_id .... : ' ||xlt.inventory_item_id);
          fnd_file.put_line(fnd_file.log,'p_fiscal_classification  : ' ||xlt.fiscal_classification);
          fnd_file.put_line(fnd_file.log,'p_module ............... : ' || p_module);
        
          fnd_file.put_line(fnd_file.log, '');
          fnd_file.put_line(fnd_file.log,'tax_category ............... : ' ||r_get_tax_priority.tax_category);
          fnd_file.put_line(fnd_file.log,'r_tax_type ................. : ' ||r_get_tax.tax_type);
          fnd_file.put_line(fnd_file.log,'l_ipi_base ................. : ' ||l_ipi_base);
          fnd_file.put_line(fnd_file.log,'l_rate ..................... : ' ||l_rate);
          fnd_file.put_line(fnd_file.log, '');
        
        
          fnd_file.put_line(fnd_file.log, '');
          IF l_rate = -1 THEN
            BEGIN
              fnd_file.put_line(fnd_file.log, r_get_tax.tax_type);
              l_rate := f_get_tax_rate(p_rule                  => r_get_tax_priority.rule
                                      ,p_icms_exept            => l_icms_exept
                                      ,p_main_tax_type         => r_get_tax.main_tax_type
                                      ,p_group_tax_id          => xlt.group_tax_id
                                      ,p_tax_category_id       => r_get_tax_priority.tax_category_id
                                      ,p_contributor_type      => xlt.contributor_type
                                      ,p_establishment_type    => xlt.establishment_type
                                      ,p_transaction_nature    => xlt.transaction_nature
                                      ,p_source_state          => xlt.source_state
                                      ,p_dest_state            => xlt.dest_state
                                      ,p_cust_acct_site_id     => xlt.cust_acct_site_id
                                      ,p_organization_id       => xlt.organization_id
                                      ,p_inventory_item_id     => xlt.inventory_item_id
                                      ,p_fiscal_classification => xlt.fiscal_classification
                                      ,p_item_origin_code      => p_item_origin
                                      ,p_module                => p_module);
            
            
            fnd_file.put_line(fnd_file.log,'l_icms_exept ......... : '||l_icms_exept); 
            fnd_file.put_line(fnd_file.log,'main_tax_type ........ : '||r_get_tax.main_tax_type); 
            fnd_file.put_line(fnd_file.log,'l_rate ............... : '||l_rate); 
            IF l_icms_exept IS NOT NULL
              AND r_get_tax.main_tax_type = 'ICMS'
              AND l_rate = -1 THEN
              ---
              fnd_file.put_line(fnd_file.log, 'IF l_icms_exept IS NOT NULL');
              
              IF p_module IS NOT NULL THEN
                fnd_file.put_line(fnd_file.log,'l_icms_exept = NAO_CONTRIB/DIFERENCIAL - HOLD ');
                fnd_file.put_line(fnd_file.log,'l_tax_category ........... : ' ||xlt.tax_category);
                fnd_file.put_line(fnd_file.log,'l_rate ................... : ' || l_rate);
                fnd_file.put_line(fnd_file.log,'tax_type ................. : ' ||r_get_tax.tax_type);
                fnd_file.put_line(fnd_file.log,'r_main_tax_type ......... : ' ||r_get_tax.main_tax_type);
                fnd_file.put_line(fnd_file.log,'l_unit_selling_price ..... : ' ||xlt.unit_selling_price);
                ----
                rec_tax(p_reg).icms_tax_code := NULL;
                rec_tax(p_reg).icms_tax_rate := l_rate || '%';
                rec_tax(p_reg).pis_tax_code := NULL;
                rec_tax(p_reg).pis_tax_rate := l_rate || '%';
                rec_tax(p_reg).cofins_tax_code := NULL;
                rec_tax(p_reg).cofins_tax_rate := l_rate || '%';
                rec_tax(p_reg).ipi_tax_code := NULL;
                rec_tax(p_reg).ipi_tax_rate := l_rate || '%';
              --        
              END IF;
              --Caso nao tenha encontrado aliquota para determinado imposto (aplica HOLD)
              IF p_module IS NULL THEN
                xlt.tax_category := l_tax_category;
                xlt.step_number  := 3;
                p_apply_hold(p_header_id         => p_header_id
                            ,p_line_id           => p_line_id
                            ,p_inventory_item_id => l_inventory_item_id
                            ,p_xloh              => xlt);
          
              END IF;
              IF p_module IS NULL THEN
                RETURN xlt.unit_selling_price;
              ELSE
                RETURN - 1;
              END IF;
              ---
            END IF;  
            --
            EXCEPTION
              WHEN OTHERS THEN
                fnd_file.put_line(fnd_file.log,'Erro chamada funcao f_get_tax_rate ');
                fnd_file.put_line(fnd_file.log, SQLERRM);
            END;
            l_tax_category := r_get_tax_priority.tax_category;
            fnd_file.put_line(fnd_file.log,'l_rate calculado .... : ' || l_rate);
            fnd_file.put_line(fnd_file.log,'l_tax_category .......: ' || l_tax_category);
            fnd_file.put_line(fnd_file.log, '');
          
          END IF;
        END LOOP; -- FOR r_get_tax_priority IN c_get_tax_priority   
        fnd_file.put_line(fnd_file.log, '*********************************************');
        fnd_file.put_line(fnd_file.log, 'BEGIN FOR r_get_tax_priority IN c_get_tax_priority '||r_get_tax.tax_type);
        fnd_file.put_line(fnd_file.log, '*********************************************');
        fnd_file.put_line(fnd_file.log, '');                                                      
        ---
        /*IF p_module IS NOT NULL THEN
          fnd_file.put_line(fnd_file.log,'l_tax_category ........... : ' ||l_tax_category);
          fnd_file.put_line(fnd_file.log,'l_rate ................... : ' || l_rate);
          fnd_file.put_line(fnd_file.log,'tax_type ................. : ' ||r_get_tax.tax_type);
          fnd_file.put_line(fnd_file.log,'r_main_tax_type .......... : ' ||r_get_tax.main_tax_type);
          fnd_file.put_line(fnd_file.log,'l_unit_selling_price ..... : ' ||xlt.unit_selling_price);
          fnd_file.put_line(fnd_file.log, '');
        END IF;*/
      
        IF l_rate = -1 AND r_get_tax.tax_type <> l_ipi_base THEN
          IF p_module IS NOT NULL THEN
            fnd_file.put_line(fnd_file.log,'IF l_rate = -1 AND r_get_tax.tax_type <> l_ipi_base THEN ');
            fnd_file.put_line(fnd_file.log,'l_tax_category ........... : ' ||xlt.tax_category);
            fnd_file.put_line(fnd_file.log,'l_rate ................... : ' || l_rate);
            fnd_file.put_line(fnd_file.log,'tax_type ................. : ' ||r_get_tax.tax_type);
            fnd_file.put_line(fnd_file.log,'r_main_tax_type ......... : ' ||r_get_tax.main_tax_type);
            fnd_file.put_line(fnd_file.log,'l_unit_selling_price ..... : ' ||xlt.unit_selling_price);
            ----
            rec_tax(p_reg).icms_tax_code := NULL;
            rec_tax(p_reg).icms_tax_rate := l_rate || '%';
            rec_tax(p_reg).pis_tax_code := NULL;
            rec_tax(p_reg).pis_tax_rate := l_rate || '%';
            rec_tax(p_reg).cofins_tax_code := NULL;
            rec_tax(p_reg).cofins_tax_rate := l_rate || '%';
            rec_tax(p_reg).ipi_tax_code := NULL;
            rec_tax(p_reg).ipi_tax_rate := l_rate || '%';
            --        
          END IF;
          --Caso nao tenha encontrado aliquota para determinado imposto (aplica HOLD)
          IF p_module IS NULL THEN
            xlt.tax_category := l_tax_category;
            xlt.step_number  := 3;
            p_apply_hold(p_header_id         => p_header_id
                        ,p_line_id           => p_line_id
                        ,p_inventory_item_id => l_inventory_item_id
                        ,p_xloh              => xlt);
          
          END IF;
          IF p_module IS NULL THEN
            RETURN xlt.unit_selling_price;
          ELSE
            RETURN - 1;
          END IF;
        END IF;
        --  
        --
        IF r_get_tax.main_tax_type = 'ICMS' THEN
          l_icms_rate := l_rate / 100;
          IF p_module IS NOT NULL THEN
            rec_tax(p_reg).icms_tax_code := l_tax_category;
            rec_tax(p_reg).icms_tax_rate := l_rate || '%';
          END IF;
          --  
        ELSIF r_get_tax.main_tax_type = 'PIS' THEN
          l_pis_rate := l_rate / 100;
          IF p_module IS NOT NULL THEN
            rec_tax(p_reg).pis_tax_code := l_tax_category;
            rec_tax(p_reg).pis_tax_rate := l_rate || '%';
          END IF;
          --
        ELSIF r_get_tax.main_tax_type = 'COFINS' THEN
          l_cofins_rate := l_rate / 100;
          IF p_module IS NOT NULL THEN
            rec_tax(p_reg).cofins_tax_code := l_tax_category;
            rec_tax(p_reg).cofins_tax_rate := l_rate || '%';
          END IF;
          --
        ELSIF r_get_tax.main_tax_type = 'IPI_BASE' THEN
          l_ipi_rate := l_rate / 100;
          IF p_module IS NOT NULL THEN
            rec_tax(p_reg).ipi_tax_code := l_tax_category;
            rec_tax(p_reg).ipi_tax_rate := l_rate || '%';
          END IF;
        END IF;
        --
      END LOOP; -- FOR r_get_tax  IN c_get_tax LOOP  
      fnd_file.put_line(fnd_file.log, '*********************************************');
      fnd_file.put_line(fnd_file.log, 'END FOR r_get_tax IN c_get_tax');
      fnd_file.put_line(fnd_file.log, '*********************************************');
      fnd_file.put_line(fnd_file.log, ''); 
      --
    ELSE
      IF p_module IS NOT NULL THEN
        fnd_file.put_line(fnd_file.log,'ELSE l_count_req_tax > 0 AND l_required_tax > 0');
        fnd_file.put_line(fnd_file.log,'l_count_req_tax .......... : ' ||l_count_req_tax);
        fnd_file.put_line(fnd_file.log,'l_required_tax ........... : ' ||l_required_tax);
        fnd_file.put_line(fnd_file.log,'l_tax_category ........... : ' ||l_tax_category);
        fnd_file.put_line(fnd_file.log,'l_rate ................... : ' || l_rate);
        fnd_file.put_line(fnd_file.log,'l_unit_selling_price ..... : ' ||xlt.unit_selling_price);
      END IF;
      IF p_module IS NULL THEN
        xlt.step_number := 4;
        p_apply_hold(p_header_id         => p_header_id
                    ,p_line_id           => p_line_id
                    ,p_inventory_item_id => l_inventory_item_id
                    ,p_xloh              => xlt);
      
      END IF;
      IF p_module IS NOT NULL THEN
        ----
        rec_tax(p_reg).icms_tax_code := NULL;
        rec_tax(p_reg).icms_tax_rate := l_rate || '%';
        rec_tax(p_reg).pis_tax_code := NULL;
        rec_tax(p_reg).pis_tax_rate := l_rate || '%';
        rec_tax(p_reg).cofins_tax_code := NULL;
        rec_tax(p_reg).cofins_tax_rate := l_rate || '%';
        rec_tax(p_reg).ipi_tax_code := NULL;
        rec_tax(p_reg).ipi_tax_rate := l_rate || '%';
        --        
      END IF;
      IF p_module IS NULL THEN
        RETURN xlt.unit_selling_price;
      ELSE
        RETURN - 1;
      END IF;
    END IF; --IF l_count_req_tax >0 AND l_required_tax> 0 THEN
    --
    fnd_file.put_line(fnd_file.log, '');
    fnd_file.put_line(fnd_file.log, 'END LOOP');
    fnd_file.put_line(fnd_file.log,'l_add_ipi ................. : ' || l_add_ipi);
    fnd_file.put_line(fnd_file.log,'l_net_price ............... : ' || l_net_price);
    fnd_file.put_line(fnd_file.log,'l_unit_selling_price ...... : ' ||l_unit_selling_price);
    fnd_file.put_line(fnd_file.log,'l_icms_rate ............... : ' || l_icms_rate);
    fnd_file.put_line(fnd_file.log,'l_pis_rate ................ : ' || l_pis_rate);
    fnd_file.put_line(fnd_file.log,'l_cofins_rate ............. : ' || l_cofins_rate);
  
    fnd_file.put_line(fnd_file.log, '');
    IF l_add_ipi = 0 THEN
      l_net_price := (nvl(l_unit_selling_price, 0)) /
                     (1 - nvl(l_icms_rate, 0) - nvl(l_pis_rate, 0) -
                     nvl(l_cofins_rate, 0));
    ELSE
      l_net_price := (nvl(l_unit_selling_price, 0)) /
                     (1 - nvl(l_icms_rate, 0) - nvl(l_pis_rate, 0) -
                     nvl(l_cofins_rate, 0) -
                     (nvl(l_icms_rate, 0) * nvl(l_ipi_rate, 0)));
    END IF;
    --
    xlt.new_unit_selling_price := l_net_price;
    --
    IF p_module IS NULL THEN
      BEGIN
        UPDATE oe_order_lines_all
        SET    calculate_price_flag = 'N'
        WHERE  line_id = p_line_id;
      EXCEPTION
        WHEN OTHERS THEN
          NULL;
      END;
    END IF;
  
    RETURN round(l_net_price, 2);
  END f_get_net_price;
  --
  --
  FUNCTION f_line_billed(p_header_id IN NUMBER
                         ,p_line_id   IN NUMBER) RETURN NUMBER IS
    --
    l_line_id NUMBER := 0;
  BEGIN
    BEGIN
      SELECT p_line_id
      INTO   l_line_id
      FROM   apps.oe_order_headers_all      ooha
            ,apps.oe_order_lines_all        oola
            ,apps.ra_customer_trx_lines_all rctla
            ,apps.ra_customer_trx_all       rcta
      WHERE  ooha.header_id = p_header_id
      AND    oola.line_id  = p_line_id
      AND    ooha.header_id = oola.header_id
      AND    ooha.order_number = rctla.interface_line_attribute1
      AND    to_char(oola.line_id) = rctla.interface_line_attribute6
      AND    rcta.customer_trx_id = rctla.customer_trx_id
      AND    rctla.line_type = 'LINE'
      AND    rcta.interface_header_context = 'ORDER ENTRY';
    EXCEPTION
      WHEN too_many_rows THEN
        l_line_id := p_line_id;
      WHEN OTHERS THEN
        l_line_id := 0;
    END;
    RETURN l_line_id;
  END f_line_billed;
  --
  --
  FUNCTION f_line_reserv(p_header_id IN NUMBER
                        ,p_line_id   IN NUMBER) RETURN NUMBER IS
    --
    l_line_id NUMBER := 0;
  BEGIN
    BEGIN
      SELECT source_line_id
      INTO   l_line_id
      FROM   apps.wsh_delivery_details wdd
      WHERE  wdd.source_header_id = p_header_id
      AND    wdd.source_line_id = p_line_id
      AND    wdd.released_status IN ('C', 'I', 'S', 'Y'); /* Shipped 
                                                              /  Interfaced 
                                                              /  Release to Warehouse 
                                                              /  Staged*/
    EXCEPTION
      WHEN too_many_rows THEN
        l_line_id := p_line_id;
      WHEN OTHERS THEN
        l_line_id := 0;
    END;
    --
    RETURN l_line_id;
  END f_line_reserv;
  
  --
  --
  PROCEDURE p_tax_rate_simulation(p_errbuf              OUT VARCHAR2
                                 ,p_retcode             OUT NUMBER
                                 ,p_directory_temp      IN VARCHAR2
                                 ,p_directory           IN VARCHAR2
                                 ,p_dir_win_path        IN VARCHAR2
                                 ,p_file_name           IN VARCHAR2
                                 ,p_transaction_type_id IN NUMBER
                                 ,p_header_id           IN NUMBER
                                 ,p_line_id             IN NUMBER
                                 ,p_net_price           IN NUMBER
                                 ,p_rule                IN VARCHAR2
                                 ,p_organization_id     IN NUMBER
                                 ,p_cust_acct_site_id   IN NUMBER
                                 ,p_cust_trx_type_id    IN NUMBER
                                 ,p_inventory_item_id   IN NUMBER
                                 ,p_module              IN VARCHAR2
                                 ,p_separador           IN VARCHAR2) IS
  
    l_module                VARCHAR2(30) := NULL;
    l_net_price             NUMBER;
    l_unit_selling_price    NUMBER;
    l_order_number          oe_order_headers_all.order_number%TYPE;
    l_line_number           VARCHAR2(10);
    l_organization_name     hr_all_organization_units.name%TYPE;
    l_customer_name         hz_parties.party_name%TYPE;
    l_cnpj                  VARCHAR2(14);
    l_transaction_name      ra_cust_trx_types_all.name%TYPE;
    l_cod_item              mtl_system_items.segment1%TYPE;
    l_source_state          cll_f189_states.state_code%TYPE;
    l_dest_state            cll_f189_states.state_code%TYPE;
    l_contributor_type      hz_cust_acct_sites_all.global_attribute8%TYPE;
    l_establishment_type    hr_locations_all.global_attribute1%TYPE;
    l_fiscal_classification mtl_item_categories_v.segment1%TYPE;
    l_transaction_nature    mtl_system_items.global_attribute2%TYPE;
    l_group_tax_name        ra_cust_trx_types_all.global_attribute4%TYPE;
    l_group_tax_id          ar_vat_tax_vl.vat_tax_id%TYPE;
    l_reg                   NUMBER := 0;
    ---
    l_file_name VARCHAR2(100);
    l_file      utl_file.file_type;
    --
    CURSOR c_net_price IS
      SELECT *
      FROM   TABLE(f_read_data(g_dir_name_in, p_file_name, p_separador)) inpdata
      WHERE  net_price IS NOT NULL
      ORDER  BY organization_id
               ,party_name
               ,cust_acct_site_id
               ,cust_trx_type_id
               ,header_id
               ,line_id
               ,inventory_item_id;
    --
  BEGIN
    --
    BEGIN
      p_initialize_globals;
      g_dir_name_in  := p_directory || 'IN';
      g_dir_name_out := p_directory || 'OUT';
      g_file_name    := p_file_name;
      --
      BEGIN
        SELECT directory_path
        INTO   g_dir_path_in
        FROM   all_directories
        WHERE  directory_name = g_dir_name_in
        AND    rownum = 1;
      EXCEPTION
        WHEN no_data_found THEN
          fnd_file.put_line(fnd_file.log
                           ,'   Directory ' || g_dir_name_in ||
                            ' does not exists');
      END;
      --
      BEGIN
        SELECT directory_path
        INTO   g_dir_path_out
        FROM   all_directories
        WHERE  directory_name = g_dir_name_out
        AND    rownum = 1;
      EXCEPTION
        WHEN no_data_found THEN
          fnd_file.put_line(fnd_file.log,'   Directory ' || g_dir_name_out ||' does not exists');
      END;
    EXCEPTION
      WHEN OTHERS THEN
        fnd_file.put_line(fnd_file.log
                         ,' Erro na Inicializacao das Variaveis Globais');
        fnd_file.put_line(fnd_file.log, SQLCODE || ' - ' || SQLERRM);
        p_retcode := 2;
    END;
    --
    fnd_file.put_line(fnd_file.log, '');
    fnd_file.put_line(fnd_file.log,'p_directory_temp..................... : ' ||p_directory_temp);
    fnd_file.put_line(fnd_file.log,'p_directory ......................... : ' ||p_directory);
    fnd_file.put_line(fnd_file.log,'p_dir_win_path ...................... : ' ||p_dir_win_path);
    fnd_file.put_line(fnd_file.log,'p_file_name ......................... : ' ||p_file_name);
    fnd_file.put_line(fnd_file.log,'g_dir_name_in ....................... : ' ||g_dir_name_in);
    fnd_file.put_line(fnd_file.log,'g_dir_name_out ...................... : ' ||g_dir_name_out);
    fnd_file.put_line(fnd_file.log,'g_dir_path_in ....................... : ' ||g_dir_path_in);
    fnd_file.put_line(fnd_file.log, '');
    fnd_file.put_line(fnd_file.log, '');
    --
    l_file_name := g_request_id ||'_XXPPG - Simulacao Preco de Vendas_TEMP.csv';
    l_file      := utl_file.fopen(p_directory_temp, l_file_name, 'W', 32767);
    --
    utl_file.put_line(l_file
                     ,'ORDEM DE VENDA' || p_separador || --A
                      'LINHA ORDEM' || p_separador || --B
                      'PRECO LIQUIDO' || p_separador || --C
                      'ALIQUOTA ICMS' || p_separador || --D
                      'ALIQUOTA PIS' || p_separador || --E
                      'ALIQUOTA COFINS' || p_separador || --F
                      'ALIQUOTA IPI' || p_separador || --G
                      'PRECO COM IMPOSTO' || p_separador || --H
                      'ORGANIZACAO DE FATURAMENTO' || p_separador || --I
                      'TIPO DE TRANSACAO' || p_separador || --J
                      'CLIENTE' || p_separador || --K
                      'CNPJ CLIENTE' || p_separador || --L
                      'TIPO DE CONTRIBUINTE' || p_separador || --M
                      'CODIGO DO ITEM' || p_separador || --N
                      'NATUREZA DA OPERACAO' --O
                      );
    --
    FOR r_net_price IN c_net_price LOOP
      --
      fnd_file.put_line(fnd_file.log, '');
      fnd_file.put_line(fnd_file.log,'------------------------------------------------------------------------ ');
      fnd_file.put_line(fnd_file.log,'------------------------------------------------------------------------ ');
      fnd_file.put_line(fnd_file.log, 'REGISTRO >> ' || l_reg);
      fnd_file.put_line(fnd_file.log,'p_header_id ................. : ' ||r_net_price.header_id);
      fnd_file.put_line(fnd_file.log,'p_line_id ................... : ' ||r_net_price.line_id);
      fnd_file.put_line(fnd_file.log,'p_unit_selling_price ........ : ' ||r_net_price.net_price);
      fnd_file.put_line(fnd_file.log,'p_module .................... : ' || p_module);
      fnd_file.put_line(fnd_file.log,'p_source_state .............. : ' ||r_net_price.source_state);
      fnd_file.put_line(fnd_file.log,'p_dest_state ................ : ' ||r_net_price.dest_state);
      fnd_file.put_line(fnd_file.log,'p_contributor_type .......... : ' ||r_net_price.contributor_type);
      fnd_file.put_line(fnd_file.log,'p_establishment_type ........ : ' ||r_net_price.establishment_type);
      fnd_file.put_line(fnd_file.log,'p_fiscal_classification ..... : ' ||r_net_price.fiscal_classification);
      fnd_file.put_line(fnd_file.log,'p_transaction_nature ........ : ' ||r_net_price.transaction_nature);
      fnd_file.put_line(fnd_file.log,'p_group_tax_id .............. : ' ||r_net_price.group_tax_id);
      fnd_file.put_line(fnd_file.log,'p_tax_rule_level ............ : ' || p_rule);
      fnd_file.put_line(fnd_file.log,'p_organization_id ........... : ' ||r_net_price.organization_id);
      fnd_file.put_line(fnd_file.log,'p_inventory_item_id ......... : ' ||r_net_price.inventory_item_id);
      fnd_file.put_line(fnd_file.log,'p_cust_acct_site_id ......... : ' ||r_net_price.cust_acct_site_id);
    
      BEGIN
        ---
        l_net_price := f_get_net_price(p_header_id             => r_net_price.header_id
                                      ,p_line_id               => r_net_price.line_id
                                      ,p_unit_selling_price    => r_net_price.net_price
                                      ,p_module                => p_module
                                      ,p_source_state          => r_net_price.source_state
                                      ,p_dest_state            => r_net_price.dest_state
                                      ,p_contributor_type      => r_net_price.contributor_type
                                      ,p_establishment_type    => r_net_price.establishment_type
                                      ,p_cust_trx_type_id      => r_net_price.cust_trx_type_id
                                      ,p_fiscal_classification => r_net_price.fiscal_classification
                                      ,p_transaction_nature    => r_net_price.transaction_nature
                                      ,p_group_tax_id          => r_net_price.group_tax_id
                                      ,p_tax_rule_level        => p_rule
                                      ,p_organization_id       => r_net_price.organization_id
                                      ,p_inventory_item_id     => r_net_price.inventory_item_id
                                      ,p_cust_acct_site_id     => r_net_price.cust_acct_site_id
                                      ,p_reg                   => l_reg);
        -- 
        fnd_file.put_line(fnd_file.log, '');
        fnd_file.put_line(fnd_file.log,'l_net_price ................. : ' ||l_net_price);
        fnd_file.put_line(fnd_file.log, '');
        --
      EXCEPTION
        WHEN OTHERS THEN
          fnd_file.put_line(fnd_file.log
                           ,'Erro Geral p_tax_rate_simulation');
          fnd_file.put_line(fnd_file.log, SQLERRM);
      END;
      --
    
      utl_file.put_line(l_file
                       ,r_net_price.order_number || p_separador || --A
                        r_net_price.line_number || p_separador || --B
                        r_net_price.net_price || p_separador || --C
                        rec_tax(l_reg).icms_tax_rate || p_separador || --D
                        rec_tax(l_reg).pis_tax_rate || p_separador || --E
                        rec_tax(l_reg).cofins_tax_rate || p_separador || --F
                        rec_tax(l_reg).ipi_tax_rate || p_separador || --G
                        l_net_price || p_separador || --H
                        r_net_price.organization_code || p_separador || --I
                        r_net_price.transaction_name || p_separador || --J
                        r_net_price.party_name || p_separador || --K
                        r_net_price.cnpj || p_separador || --L
                        r_net_price.contributor_type || p_separador || --M
                        r_net_price.cod_item || p_separador || --N
                        r_net_price.transaction_nature); --O
    
      l_reg := l_reg + 1;
    END LOOP;
    IF utl_file.is_open(l_file) THEN
      utl_file.fclose(l_file);
    END IF;
    --
    IF l_reg > 0 THEN
      BEGIN
        utl_file.fcopy(p_directory_temp
                      ,l_file_name
                      ,g_dir_name_out
                      ,REPLACE(l_file_name, '_TEMP', ''));
        utl_file.fremove(p_directory_temp, l_file_name);
        utl_file.fremove(g_dir_name_in, p_file_name);
      EXCEPTION
        WHEN OTHERS THEN
          fnd_file.put_line(fnd_file.log,' Erro ao Copiar / Remover Arquivo  - ' ||SQLERRM);
      END;
      -- 
      fnd_file.put_line(fnd_file.log,'Relatorio : ' ||REPLACE(l_file_name, '_TEMP', '') ||' Salvo em : ' || p_dir_win_path);
      fnd_file.put_line(fnd_file.output,'Relatorio : ' ||REPLACE(l_file_name, '_TEMP', '') ||' Salvo em : ' || p_dir_win_path);
      --
    END IF;
    --  
    p_retcode := g_retcode;
    IF l_reg = 0 THEN
      --
      l_order_number          := f_get_order_number(p_header_id);
      l_line_number           := f_get_line_details(p_line_id,'LINE_NUMBER');
      l_organization_name     := f_get_org_details(p_organization_id,'ORG_NAME');
      l_source_state          := f_get_org_details(p_organization_id,'STATE_CODE');
      l_customer_name         := f_get_cust_details(p_cust_acct_site_id,'PARTY_NAME');
      l_cnpj                  := f_get_cust_details(p_cust_acct_site_id,'CNPJ');
      l_dest_state            := f_get_cust_details(p_cust_acct_site_id,'STATE_CODE');
      l_contributor_type      := f_get_cust_details(p_cust_acct_site_id,'CONTRIBUTOR_TYPE');
      l_establishment_type    := f_get_cust_details(p_cust_acct_site_id,'ESTABLISHMENT_TYPE');
      l_transaction_name      := f_get_transaction_details(p_cust_trx_type_id,'TRANSACTION_NAME');
      l_group_tax_id          := f_get_transaction_details(p_cust_trx_type_id,'GROUP_TAX_ID');
      l_group_tax_name        := f_get_transaction_details(p_cust_trx_type_id,'GROUP_TAX_NAME');
      l_cod_item              := f_get_item_details(p_inventory_item_id,'COD_ITEM');
      l_fiscal_classification := f_get_item_details(p_inventory_item_id,'FISCAL_CLASSIFICATION');
      l_transaction_nature    := f_get_item_details(p_inventory_item_id,'TRANSACTION_NATURE');
      l_unit_selling_price    := nvl(p_net_price, 0);
      --
      fnd_file.put_line(fnd_file.log, '--');
      fnd_file.put_line(fnd_file.log,'l_order_number ...................... : ' ||l_order_number);
      fnd_file.put_line(fnd_file.log,'l_line_number ....................... : ' ||l_line_number);
      fnd_file.put_line(fnd_file.log,'l_customer_name ..................... : ' ||l_customer_name);
      fnd_file.put_line(fnd_file.log,'l_cnpj .............................. : ' ||l_cnpj);
      fnd_file.put_line(fnd_file.log,'l_transaction_name .................. : ' ||l_transaction_name);
      fnd_file.put_line(fnd_file.log,'l_cod_item .......................... : ' ||l_cod_item);
      fnd_file.put_line(fnd_file.log,'l_unit_selling_price ................ : ' ||l_unit_selling_price);
      fnd_file.put_line(fnd_file.log,'l_source_state ...................... : ' ||l_source_state);
      fnd_file.put_line(fnd_file.log,'l_dest_state ........................ : ' ||l_dest_state);
      fnd_file.put_line(fnd_file.log,'l_contributor_type .................. : ' ||l_contributor_type);
      fnd_file.put_line(fnd_file.log,'l_establishment_type ................ : ' ||l_establishment_type);
      fnd_file.put_line(fnd_file.log,'l_fiscal_classification ............. : ' ||l_fiscal_classification);
      fnd_file.put_line(fnd_file.log,'l_transaction_nature ................ : ' ||l_transaction_nature);
      fnd_file.put_line(fnd_file.log,'l_group_tax_id ...................... : ' ||l_group_tax_id);
      fnd_file.put_line(fnd_file.log,'l_group_tax_name .................... : ' ||l_group_tax_name);
      ---
      BEGIN
        ---
        l_net_price := f_get_net_price(p_header_id             => p_header_id
                                      ,p_line_id               => p_line_id
                                      ,p_unit_selling_price    => l_unit_selling_price
                                      ,p_module                => p_module
                                      ,p_source_state          => l_source_state
                                      ,p_dest_state            => l_dest_state
                                      ,p_contributor_type      => l_contributor_type
                                      ,p_establishment_type    => l_establishment_type
                                      ,p_cust_trx_type_id      => p_cust_trx_type_id
                                      ,p_fiscal_classification => l_fiscal_classification
                                      ,p_transaction_nature    => l_transaction_nature
                                      ,p_group_tax_id          => l_group_tax_id
                                      ,p_tax_rule_level        => p_rule
                                      ,p_organization_id       => p_organization_id
                                      ,p_inventory_item_id     => p_inventory_item_id
                                      ,p_cust_acct_site_id     => p_cust_acct_site_id);
        --
      EXCEPTION
        WHEN OTHERS THEN
          fnd_file.put_line(fnd_file.log,'Erro Geral p_tax_rate_simulation');
          fnd_file.put_line(fnd_file.log, SQLERRM);
      END;
      --
      fnd_file.put_line(fnd_file.output
                       ,'ORDEM DE VENDA' || p_separador || --A
                        'LINHA ORDEM' || p_separador || --B
                        'PRECO LIQUIDO' || p_separador || --C
                        'ALIQUOTA ICMS' || p_separador || --D
                        'ALIQUOTA PIS' || p_separador || --E
                        'ALIQUOTA COFINS' || p_separador || --F
                        'ALIQUOTA IPI' || p_separador || --G
                        'PRECO COM IMPOSTO' || p_separador || --H
                        'ORGANIZACAO DE FATURAMENTO' || p_separador || --I
                        'TIPO DE TRANSACAO' || p_separador || --J
                        'CLIENTE' || p_separador || --K
                        'CNPJ CLIENTE' || p_separador || --L
                        'TIPO DE CONTRIBUINTE' || p_separador || --M
                        'CODIGO DO ITEM' || p_separador || --N
                        'NATUREZA DA OPERACAO' --O
                        );
      ---
      fnd_file.put_line(fnd_file.output
                       ,l_order_number || p_separador || --A
                        l_line_number || p_separador || --B
                        l_unit_selling_price || p_separador || --C
                        rec_tax(l_reg).icms_tax_rate || p_separador || --D
                        rec_tax(l_reg).pis_tax_rate || p_separador || --E
                        rec_tax(l_reg).cofins_tax_rate || p_separador || --F
                        rec_tax(l_reg).ipi_tax_rate || p_separador || --G
                        l_net_price || p_separador || --H
                        l_organization_name || p_separador || --I
                        l_transaction_name || p_separador || --J
                        l_customer_name || p_separador || --K
                        l_cnpj || p_separador || --L
                        l_contributor_type || p_separador || --M
                        l_cod_item || p_separador || --N
                        l_transaction_nature); --O
      --
      utl_file.put_line(l_file
                       ,l_order_number || p_separador || --A
                        l_line_number || p_separador || --B
                        l_unit_selling_price || p_separador || --C
                        rec_tax(l_reg).icms_tax_rate || p_separador || --D
                        rec_tax(l_reg).pis_tax_rate || p_separador || --E
                        rec_tax(l_reg).cofins_tax_rate || p_separador || --F
                        rec_tax(l_reg).ipi_tax_rate || p_separador || --G
                        l_net_price || p_separador || --H
                        l_organization_name || p_separador || --I
                        l_transaction_name || p_separador || --J
                        l_customer_name || p_separador || --K
                        l_cnpj || p_separador || --L
                        l_contributor_type || p_separador || --M
                        l_cod_item || p_separador || --N
                        l_transaction_nature); --O
      --
      IF utl_file.is_open(l_file) THEN
        utl_file.fclose(l_file);
      END IF;
    END IF;
  
  END p_tax_rate_simulation;
  --
  --
  PROCEDURE p_apply_hold(p_header_id         IN NUMBER
                        ,p_line_id           IN NUMBER
                        ,p_inventory_item_id IN NUMBER
                        ,p_xloh              IN xxppg_1081_line_order_hold%ROWTYPE) IS
    --
    --l_msg_count       NUMBER;
    --l_msg_data        VARCHAR2(2000);
    --l_return_status   VARCHAR2(100);
    --l_hold_source_rec oe_holds_pvt.hold_source_rec_type;
    --i                 NUMBER;
    --l_update          DATE := SYSDATE;
    --xloh              xxppg_1081_line_order_hold%ROWTYPE;
   -- l_hold_id         NUMBER := apps.fnd_profile.value('XXPPG_1081_NET_PRICE_OM_HOLD_NAME'); --SSD2515
    l_line_release_hold       NUMBER := 0;
    l_line_apply_hold         NUMBER := 0;
    ---
    --v_errbuf              VARCHAR2(100);
    --v_retcode             NUMBER;
    --v_release_reason_code VARCHAR2(100);
    --v_release_comment     VARCHAR2(100);
    --
  BEGIN
    BEGIN
      SELECT COUNT(1)
      INTO   l_line_release_hold
      FROM   xxppg_1081_line_order_hold
      WHERE  line_id = p_line_id;
    EXCEPTION
      WHEN OTHERS THEN
        l_line_release_hold := 0;
    END;
    --
    
    BEGIN
      SELECT COUNT(1)
      INTO   l_line_apply_hold
      FROM   xxppg_1081_line_apply_hold
      WHERE  line_id = p_line_id;
    EXCEPTION
      WHEN OTHERS THEN
        l_line_apply_hold := 0;
    END;
    
    --
  
    IF l_line_release_hold = 0 THEN
     -- p_initialize_globals;
    
   --   xloh := p_xloh;
      --
      --SSD2515
      /*l_hold_source_rec                  := oe_holds_pvt.g_miss_hold_source_rec;
      l_hold_source_rec.hold_id          := l_hold_id;
      l_hold_source_rec.hold_entity_code := 'O';
      l_hold_source_rec.hold_entity_id   := p_header_id;
      l_hold_source_rec.header_id        := p_header_id;
      l_hold_source_rec.line_id          := p_line_id;
      l_hold_source_rec.hold_comment     := 'XXPPG 1081 - NET Price Retention';
      --
      oe_holds_pub.apply_holds(p_api_version      => 1.0
                              ,p_commit           => fnd_api.g_true
                              ,p_validation_level => fnd_api.g_valid_level_none
                              ,p_hold_source_rec  => l_hold_source_rec
                              ,x_msg_count        => l_msg_count
                              ,x_msg_data         => l_msg_data
                              ,x_return_status    => l_return_status);
      --                        
      xloh.status := l_return_status;
      IF l_return_status = 'S' THEN
        NULL; --COMMIT;
      ELSE
        FOR j IN 1 .. oe_msg_pub.count_msg LOOP
          oe_msg_pub.get(p_msg_index     => j
                        ,p_encoded       => 'F'
                        ,p_data          => l_msg_data
                        ,p_msg_index_out => i);
        END LOOP;
        xloh.err_msg := substr(l_msg_data, 1, 500);
      END IF;
      
      */
      --
      BEGIN
        INSERT INTO xxppg_1081_line_order_hold VALUES p_xloh;
      EXCEPTION
        WHEN OTHERS THEN
          fnd_file.put_line(fnd_file.log,'Erro Inser tabela xxppg_1081_line_order_hold ' ||SQLERRM);
      END;
    END IF;
    
    ---
    IF l_line_apply_hold = 0 THEN
      BEGIN
        INSERT INTO xxppg_1081_line_apply_hold VALUES p_xloh;
      EXCEPTION
        WHEN OTHERS THEN
          fnd_file.put_line(fnd_file.log,'Erro Inser tabela xxppg_1081_line_order_hold ' ||SQLERRM);
      END;
    END IF;
    
    --                        
  END p_apply_hold;
  --
  --
  PROCEDURE p_man_cancel_lines(p_line_id       IN NUMBER
                              ,p_motivo        IN VARCHAR2
                              ,p_obs           IN VARCHAR2
                              ,x_return_status OUT VARCHAR2
                              ,x_message       OUT VARCHAR2) IS
    l_version_number NUMBER := 0;
    l_reason_type    VARCHAR2(20) := 'CANCEL_CODE';
    l_entity_code    VARCHAR2(10) := 'LINE';
    l_reason_id      NUMBER;
    l_return_status  VARCHAR2(10) := NULL;
    l_line_rec       oe_order_pub.line_rec_type;
    l_hist_type_code VARCHAR2(30) := 'CANCELLATION';
    l_success        VARCHAR2(10) := NULL;
    l_message        CLOB;
    l_count          NUMBER := 0;
  
  BEGIN
    p_initialize_globals;
    FOR c_cancel_lines IN (SELECT oola.*
                           FROM   oe_order_lines_all oola
                           WHERE  line_id = p_line_id) LOOP
      BEGIN
        l_count := l_count + 1;
        fnd_file.put_line(fnd_file.log, 'Chamada p_cancel_lines ');
        p_cancel_lines(c_cancel_lines.line_id
                      ,p_motivo
                      ,p_obs
                      ,x_return_status
                      ,x_message);
        IF x_return_status = 'S' THEN
          l_message := 'Linha ' || c_cancel_lines.line_number || '.' ||c_cancel_lines.shipment_number ||'   cancelada com sucesso';
          apps.fnd_file.put_line(apps.fnd_file.output,'     Linha ' ||c_cancel_lines.line_number || '.' ||c_cancel_lines.shipment_number ||'  cancelada com sucesso');
          COMMIT;
        ELSE
          fnd_file.put_line(fnd_file.log,'Linha nao canceladada automaticamente por API ');
          fnd_file.put_line(fnd_file.log,'Sera cancelada atraves de UPDATE ');
        
          BEGIN
            SELECT oe_reasons_s.nextval INTO l_reason_id FROM dual;
          EXCEPTION
            WHEN OTHERS THEN
              x_return_status := 'E';
              x_message       := 'ERRO AO RECUPERAR SEQUENCIA REASON_ID ' ||SQLERRM;
              apps.fnd_file.put_line(apps.fnd_file.output,'ERRO AO RECUPERAR SEQUENCIA REASON_ID ' ||SQLERRM);
            
              IF nvl(l_success, 'S') = 'E' THEN
                l_success := 'E';
              ELSE
                l_success := x_return_status;
              END IF;
          END;
          --
          BEGIN
            UPDATE oe_order_lines_all
            SET    promise_date          = NULL
                  ,schedule_ship_date    = NULL
                  ,pricing_quantity      = 0
                  ,cancelled_quantity    = ordered_quantity
                  ,cancelled_quantity2   = ordered_quantity
                  ,ordered_quantity      = 0
                  ,ordered_quantity2     = 0
                  ,tax_value             = 0
                  ,visible_demand_flag   = NULL
                  ,schedule_arrival_date = NULL
                  ,schedule_status_code  = NULL
                  ,cancelled_flag        = 'Y'
                  ,open_flag             = 'N'
                  ,flow_status_code      = 'CANCELLED'
            WHERE  line_id = c_cancel_lines.line_id;
          EXCEPTION
            WHEN OTHERS THEN
              x_return_status := 'E';
              x_message       := 'ERRO AO CANCELAR LINHA (OOLA) MANUALMENTE - LINE_ID: ' ||c_cancel_lines.line_id || ' -' || SQLERRM;
              apps.fnd_file.put_line(apps.fnd_file.output,'ERRO AO CANCELAR LINHA (OOLA) MANUALMENTE - LINE_ID: ' ||c_cancel_lines.line_id || ' -' ||SQLERRM);
              IF nvl(l_success, 'S') = 'E' THEN
                l_success := 'E';
              ELSE
                l_success := x_return_status;
              END IF;
          END;
          BEGIN
            UPDATE wsh_delivery_details
            SET    cancelled_quantity        = src_requested_quantity
                  ,cancelled_quantity2       = src_requested_quantity
                  ,src_requested_quantity    = 0
                  ,src_requested_quantity2   = 0
                  ,requested_quantity        = 0
                  ,requested_quantity2       = 0
                  ,shipped_quantity          = 0
                  ,shipped_quantity2         = 0
                  ,delivered_quantity        = 0
                  ,quality_control_quantity  = 0
                  ,quality_control_quantity2 = 0
                  ,cycle_count_quantity      = 0
                  ,cycle_count_quantity2     = 0
                  ,latest_pickup_date        = NULL
                  ,released_status           = 'D'
                  ,date_scheduled            = NULL
            WHERE  source_line_id = c_cancel_lines.line_id;
          EXCEPTION
            WHEN OTHERS THEN
              x_return_status := 'E';
              x_message       := 'ERRO AO CANCELAR LINHA (WDD) MANUALMENTE - LINE_ID: ' ||c_cancel_lines.line_id || ' -' || SQLERRM;
              apps.fnd_file.put_line(apps.fnd_file.output,'ERRO AO CANCELAR LINHA (WDD) MANUALMENTE - LINE_ID: ' ||c_cancel_lines.line_id || ' -' ||SQLERRM);
              IF nvl(l_success, 'S') = 'E' THEN
                l_success := 'E';
              ELSE
                l_success := x_return_status;
              END IF;
          END;
          ---
          BEGIN
            INSERT INTO oe_reasons
              (reason_id
              ,entity_code
              ,entity_id
              ,header_id
              ,version_number
              ,reason_type
              ,reason_code
              ,comments
              ,creation_date
              ,created_by
              ,last_updated_by
              ,last_update_date)
            VALUES
              (l_reason_id
              ,l_entity_code
              ,c_cancel_lines.line_id
              ,c_cancel_lines.header_id
              ,l_version_number
              ,l_reason_type
              ,p_motivo
              ,p_obs
              ,SYSDATE
              ,nvl(fnd_global.user_id, -1)
              ,nvl(fnd_global.user_id, -1)
              ,SYSDATE);
          EXCEPTION
            WHEN OTHERS THEN
              x_return_status := 'E';
              x_message       := 'ERRO AO INSERIR LINHA OE_REASONS - LINE_ID: ' ||c_cancel_lines.line_id || ' -' || SQLERRM;
              apps.fnd_file.put_line(apps.fnd_file.output,'ERRO AO INSERIR LINHA OE_REASONS - LINE_ID: ' ||c_cancel_lines.line_id || ' -' ||SQLERRM);
            
              IF nvl(l_success, 'S') = 'E' THEN
                l_success := 'E';
              ELSE
                l_success := x_return_status;
              END IF;
          END;
          --
          BEGIN
            FOR c_hist IN (SELECT *
                           FROM   oe_order_lines_history
                           WHERE  line_id = c_cancel_lines.line_id
                           AND    hist_creation_date =
                                  (SELECT MAX(hist_creation_date)
                                    FROM   oe_order_lines_history
                                    WHERE  line_id = c_cancel_lines.line_id)) LOOP
              l_line_rec.header_id            := c_hist.header_id;
              l_line_rec.org_id               := c_hist.org_id;
              l_line_rec.line_type_id         := c_hist.line_type_id;
              l_line_rec.line_number          := c_hist.line_number;
              l_line_rec.request_date         := c_hist.request_date;
              l_line_rec.promise_date         := c_hist.promise_date;
              l_line_rec.schedule_ship_date   := c_hist.schedule_ship_date;
              l_line_rec.order_quantity_uom   := c_hist.order_quantity_uom;
              l_line_rec.ordered_quantity     := c_hist.ordered_quantity;
              l_line_rec.pricing_quantity     := c_hist.pricing_quantity;
              l_line_rec.cancelled_quantity   := c_hist.cancelled_quantity;
              l_line_rec.delivery_lead_time   := c_hist.delivery_lead_time;
              l_line_rec.tax_exempt_flag      := c_hist.tax_exempt_flag;
              l_line_rec.pricing_quantity_uom := c_hist.pricing_quantity_uom;
              l_line_rec.sold_from_org_id     := c_hist.sold_from_org_id;
              l_line_rec.ship_from_org_id     := c_hist.ship_from_org_id;
              l_line_rec.ship_to_org_id       := c_hist.ship_to_org_id;
              l_line_rec.invoice_to_org_id    := c_hist.invoice_to_org_id;
              l_line_rec.sold_to_org_id       := c_hist.sold_to_org_id;
              l_line_rec.visible_demand_flag  := c_hist.visible_demand_flag;
              l_line_rec.schedule_status_code := c_hist.schedule_status_code;
            END LOOP;
            oe_chg_order_pvt.recordlinehist(p_line_id           => c_cancel_lines.line_id
                                           ,p_line_rec          => l_line_rec
                                           ,p_hist_type_code    => l_hist_type_code
                                           ,p_reason_code       => NULL
                                           ,p_comments          => NULL
                                           ,p_audit_flag        => 'Y'
                                           ,p_version_flag      => NULL
                                           ,p_phase_change_flag => NULL
                                           ,p_version_number    => NULL
                                           ,p_reason_id         => l_reason_id
                                           ,p_wf_activity_code  => NULL
                                           ,p_wf_result_code    => NULL
                                           ,x_return_status     => l_return_status);
            BEGIN
              UPDATE oe_order_lines_history
              SET    latest_cancelled_quantity = l_line_rec.ordered_quantity
              WHERE  line_id = c_cancel_lines.line_id
              AND    reason_id = l_reason_id;
            EXCEPTION
              WHEN OTHERS THEN
                x_return_status := 'E';
                x_message       := 'ERRO ATUALIZAR QTD CANCELADA NA OE_ORDER_LINES_HISTORY - LINE_ID: ' ||c_cancel_lines.line_id || ' -' ||SQLERRM;
                IF nvl(l_success, 'S') = 'E' THEN
                  l_success := 'E';
                ELSE
                  l_success := x_return_status;
                END IF;
            END;
            --
            IF l_return_status <> 'S' THEN
              x_return_status := 'E';
              x_message       := 'ERRO AO INSERIR LINHA OE_ORDER_LINES_HISTORY - LINE_ID: ' ||c_cancel_lines.line_id || ' -' || SQLERRM;
              apps.fnd_file.put_line(apps.fnd_file.output,'ERRO AO INSERIR LINHA OE_ORDER_LINES_HISTORY - LINE_ID: ' ||c_cancel_lines.line_id || ' -' ||SQLERRM);
              IF nvl(l_success, 'S') = 'E' THEN
                l_success := 'E';
              ELSE
                l_success := x_return_status;
              END IF;
            END IF;
          END;
        END IF;
      END;
      IF nvl(l_success, 'X') <> 'E' THEN
        l_message := 'Linhas Canceladas';
        apps.fnd_file.put_line(apps.fnd_file.output,'     Linha ' || c_cancel_lines.line_number || '.' ||c_cancel_lines.shipment_number ||'  cancelada com sucesso');
        x_return_status := 'S';
      ELSE
        apps.fnd_file.put_line(apps.fnd_file.output,'     Linha ' || c_cancel_lines.line_number || '.' ||c_cancel_lines.shipment_number ||'  NAO cancelada');
        apps.fnd_file.put_line(apps.fnd_file.output,'     x_message ' || x_message);
      END IF;
    END LOOP;
    IF l_count > 0 THEN
      fnd_file.put_line(fnd_file.log,'Iniciando Cancelamento Manual - Nao foi possivel cancelar todas as linhas por API');
    END IF;
    --
  END p_man_cancel_lines;
  --
  --
  PROCEDURE p_cancel_lines(p_line_id       IN NUMBER
                          ,p_motivo        IN VARCHAR2
                          ,p_obs           IN VARCHAR2
                          ,x_return_status OUT VARCHAR2
                          ,x_message       OUT VARCHAR2) IS
    --                      
    l_line_tbl_in                oe_order_pub.line_tbl_type;
    l_header_rec_out             oe_order_pub.header_rec_type;
    l_line_tbl_out               oe_order_pub.line_tbl_type;
    l_header_val_rec_out         oe_order_pub.header_val_rec_type;
    l_header_adj_tbl_out         oe_order_pub.header_adj_tbl_type;
    l_header_adj_val_tbl_out     oe_order_pub.header_adj_val_tbl_type;
    l_header_price_att_tbl_out   oe_order_pub.header_price_att_tbl_type;
    l_header_adj_att_tbl_out     oe_order_pub.header_adj_att_tbl_type;
    l_header_adj_assoc_tbl_out   oe_order_pub.header_adj_assoc_tbl_type;
    l_header_scredit_tbl_out     oe_order_pub.header_scredit_tbl_type;
    l_header_scredit_val_tbl_out oe_order_pub.header_scredit_val_tbl_type;
    l_line_val_tbl_out           oe_order_pub.line_val_tbl_type;
    l_line_adj_tbl_out           oe_order_pub.line_adj_tbl_type;
    l_line_adj_val_tbl_out       oe_order_pub.line_adj_val_tbl_type;
    l_line_price_att_tbl_out     oe_order_pub.line_price_att_tbl_type;
    l_line_adj_att_tbl_out       oe_order_pub.line_adj_att_tbl_type;
    l_line_adj_assoc_tbl_out     oe_order_pub.line_adj_assoc_tbl_type;
    l_line_scredit_tbl_out       oe_order_pub.line_scredit_tbl_type;
    l_line_scredit_val_tbl_out   oe_order_pub.line_scredit_val_tbl_type;
    l_lot_serial_tbl_out         oe_order_pub.lot_serial_tbl_type;
    l_lot_serial_val_tbl_out     oe_order_pub.lot_serial_val_tbl_type;
    l_action_request_tbl_out     oe_order_pub.request_tbl_type;
    l_ret_status                 VARCHAR2(1000) := NULL;
    l_msg_count                  NUMBER := 0;
    l_msg_data                   VARCHAR2(32670);
    l_api_version                NUMBER := 1.0;
    l_line_rec                   oe_order_pub.line_rec_type;
    l_reg                        NUMBER := 1;
    --
  BEGIN
    p_initialize_globals;
  
    fnd_file.put_line(fnd_file.log, '');
    fnd_file.put_line(fnd_file.log, 'begin p_cancel_lines');
    fnd_file.put_line(fnd_file.log,'p_line_id .............. : ' || p_line_id);
    fnd_file.put_line(fnd_file.log,'p_motivo ............... : ' || p_motivo);
    fnd_file.put_line(fnd_file.log, 'p_obs .................. : ' || p_obs);
    fnd_file.put_line(fnd_file.log, '');
    --
    l_line_tbl_in(l_reg) := oe_order_pub.g_miss_line_rec;
    l_line_tbl_in(l_reg).line_id := p_line_id;
    l_line_tbl_in(l_reg).ordered_quantity := 0;
    l_line_tbl_in(l_reg).cancelled_flag := 'Y';
    l_line_tbl_in(l_reg).change_reason := p_motivo;
    l_line_tbl_in(l_reg).change_comments := p_obs;
    l_line_tbl_in(l_reg).operation := oe_globals.g_opr_update;
    oe_msg_pub.delete_msg;
  
    fnd_file.put_line(fnd_file.log,'oe_order_pub.process_order - P_CANCEL_LINES');
    --
    oe_order_pub.process_order(p_api_version_number     => l_api_version
                              ,p_init_msg_list          => fnd_api.g_false
                              ,p_return_values          => fnd_api.g_false
                              ,p_action_commit          => fnd_api.g_false
                              ,p_line_tbl               => l_line_tbl_in
                              ,x_header_rec             => l_header_rec_out
                              ,x_header_val_rec         => l_header_val_rec_out
                              ,x_header_adj_tbl         => l_header_adj_tbl_out
                              ,x_header_adj_val_tbl     => l_header_adj_val_tbl_out
                              ,x_header_price_att_tbl   => l_header_price_att_tbl_out
                              ,x_header_adj_att_tbl     => l_header_adj_att_tbl_out
                              ,x_header_adj_assoc_tbl   => l_header_adj_assoc_tbl_out
                              ,x_header_scredit_tbl     => l_header_scredit_tbl_out
                              ,x_header_scredit_val_tbl => l_header_scredit_val_tbl_out
                              ,x_line_tbl               => l_line_tbl_out
                              ,x_line_val_tbl           => l_line_val_tbl_out
                              ,x_line_adj_tbl           => l_line_adj_tbl_out
                              ,x_line_adj_val_tbl       => l_line_adj_val_tbl_out
                              ,x_line_price_att_tbl     => l_line_price_att_tbl_out
                              ,x_line_adj_att_tbl       => l_line_adj_att_tbl_out
                              ,x_line_adj_assoc_tbl     => l_line_adj_assoc_tbl_out
                              ,x_line_scredit_tbl       => l_line_scredit_tbl_out
                              ,x_line_scredit_val_tbl   => l_line_scredit_val_tbl_out
                              ,x_lot_serial_tbl         => l_lot_serial_tbl_out
                              ,x_lot_serial_val_tbl     => l_lot_serial_val_tbl_out
                              ,x_action_request_tbl     => l_action_request_tbl_out
                              ,x_return_status          => l_ret_status
                              ,x_msg_count              => l_msg_count
                              ,x_msg_data               => l_msg_data);
    l_msg_data := NULL;
    fnd_file.put_line(fnd_file.log, 'l_ret_status := ' || l_ret_status);
    --
    IF l_ret_status = 'S' THEN
      x_return_status := 'S';
      x_message       := ' Cancelamento Realizado com sucesso';
    ELSE
      FOR iindx IN 1 .. l_msg_count LOOP
        l_msg_data := l_msg_data || '  ' || oe_msg_pub.get(iindx);
      END LOOP;
      fnd_file.put_line(fnd_file.log
                       ,'Erro Cancelamento := ' || substr(l_msg_data,100));
      x_return_status := 'E';
      x_message       := 'Cancelamento nao realizado';
      fnd_file.put_line(fnd_file.log, x_message); 
    END IF;
    fnd_file.put_line(fnd_file.log, 'FIM p_cancel_lines');
    fnd_file.put_line(fnd_file.log, '');
    --
  EXCEPTION
    WHEN OTHERS THEN
      x_return_status := 'E';
      x_message       := 'Erro ao cancelar a linha ' || SQLERRM;
      fnd_file.put_line(fnd_file.output, ' sqlerrm: ' || SQLERRM);
  END p_cancel_lines;
  --
  --
  PROCEDURE p_release_hold(errbuf            OUT VARCHAR2
                          ,retcode           OUT NUMBER
                          ,p_release_comment IN VARCHAR2) IS
    --
    l_count         NUMBER := 0;
    l_order_tbl     oe_holds_pvt.order_tbl_type;
    l_return_status VARCHAR2(5);
    l_msg_count     NUMBER;
    l_msg_data      VARCHAR2(2000);
    --
    l_hold_source_rec     oe_holds_pvt.hold_source_rec_type;
    i                     NUMBER;
    l_resp                VARCHAR2(100) := nvl(fnd_profile.value('RESP_ID')
                                              ,51202);
    l_usr_id              NUMBER := nvl(fnd_profile.value('USER_ID'), 2322);
    l_org_id              NUMBER := nvl(fnd_profile.value('ORG_ID'), 82);
    l_application_id      NUMBER;
    l_hold_name           VARCHAR2(150);
    l_net_price           NUMBER;
    l_hold_id             NUMBER := apps.fnd_profile.value('XXPPG_1081_NET_PRICE_OM_HOLD_NAME');
    l_release_reason_code VARCHAR2(150) := apps.fnd_profile.value('XXPPG_1081_NET_PRICE_OM_RELEASE_REASON');
    --
    l_update          DATE := SYSDATE;
    ---
    CURSOR c_apply_hold IS
    SELECT oola.header_id, xlah.* --xlah.rowid row_id, xlah.*
    FROM   apps.xxppg_1081_line_apply_hold xlah
          ,apps.oe_order_lines_all         oola
    WHERE  xlah.line_id = oola.line_id;    ---
    --
    --Recuperar Linhas que HOLD nao foi aplicado corretamente e enviar email
    CURSOR c_hold_applied IS
      SELECT ooha.order_number
            ,ooha.header_id
            ,oola.line_number || '.' || oola.shipment_number line
            ,CASE
               WHEN xloh.status = 'S' THEN
                ' Nao foi atualizado o preco de venda da Linha ' ||
                oola.line_number || '.' || oola.shipment_number ||
                ' da Ordem ' || ooha.order_number || chr(10) ||
                ' Por favor, entrar em contato com a equipe fiscal para revisao do setup fiscal ' ||
                chr(10) || chr(10) ||
                ' Tipo Transacao AR ............... : ' ||
                xloh.transaction_name || chr(10) ||
                ' Tipo Contribuinte ................ : ' ||
                xloh.contributor_type || chr(10) ||
                ' Item ..................................... : ' ||
                xloh.item_code || chr(10) ||
                ' Natureza Transacao Item .... : ' ||
                xloh.transaction_nature || chr(10) ||
                ' Estado de Origem ................ : ' || xloh.source_state ||
                chr(10) || ' Estado de Destino ................ : ' ||
                xloh.dest_state || chr(10) ||
                ' Categoria de Imposto ........... : ' || xloh.tax_category
             
               ELSE
                'A Linha ' || oola.line_number || '.' ||
                oola.shipment_number || ' da Ordem ' || ooha.order_number ||
                ' possui problemas de configuracao,  e NAO foi possivel aplicar a retencao automaticamente ' ||
                chr(10) ||
                ' Por favor, entrar em contato com a equipe fiscal para revisao do setup fiscal' ||
                chr(10) || chr(10) ||
                ' Tipo Transacao AR ............... : ' ||
                xloh.transaction_name || chr(10) ||
                ' Tipo Contribuinte ................ : ' ||
                xloh.contributor_type || chr(10) ||
                ' Item ..................................... : ' ||
                xloh.item_code || chr(10) ||
                ' Natureza Transacao Item .... : ' ||
                xloh.transaction_nature || chr(10) ||
                ' Estado de Origem ................ : ' || xloh.source_state ||
                chr(10) || ' Estado de Destino ................ : ' ||
                xloh.dest_state || chr(10) ||
                ' Categoria de Imposto ........... : ' || xloh.tax_category
             END body_msg
            ,flvv.lookup_code ||
             ' - IMPORTANTE - Falha ao Calcular Preco de Venda da Ordem: ' ||
             ooha.order_number subject
            ,'workflowlapoea@ppg.com' from_email
            ,flvv.description to_email
            ,xloh.*
      FROM   xxppg_1081_line_order_hold xloh
            ,oe_order_lines_all         oola
            ,oe_order_headers_all       ooha
            ,fnd_lookup_values_vl       flvv
      WHERE  xloh.line_id = oola.line_id
      AND    oola.header_id = ooha.header_id
      AND    flvv.lookup_type = 'XXPPG_NOTIFICA_BU_FALHA_PRECO'
      AND    flvv.lookup_code = ooha.sales_channel_code
      AND    nvl(flvv.end_date_active, SYSDATE) >= SYSDATE
      AND    flvv.enabled_flag = 'Y'
      AND    ooha.sales_channel_code = flvv.lookup_code
      AND    xloh.next_notification <= SYSDATE;
    --
    CURSOR c_release_hold IS
      SELECT ooha.order_number
            ,ooha.header_id
            ,oola.line_number || '.' || oola.shipment_number line
            ,ohs.released_flag
            ,ohr.creation_date hold_release_date
            ,ohd.name hold_name
            ,ooha.flow_status_code
            ,ohd.attribute1 retencao
            ,ohs.hold_source_id
            ,ohs.hold_id
            ,nvl(flvv.attribute1, 'N') reprice_line
            ,xloh.*
      FROM   apps.oe_order_headers_all       ooha
            ,apps.oe_order_lines_all         oola
            ,apps.oe_order_holds_all         ohld
            ,apps.oe_hold_sources_all        ohs
            ,apps.oe_hold_definitions        ohd
            ,apps.oe_hold_releases           ohr
            ,apps.xxppg_1081_line_order_hold xloh
            ,fnd_lookup_values_vl       flvv
      WHERE  ooha.order_category_code = 'ORDER'
      AND    ooha.header_id = oola.header_id
      AND    ohld.header_id = ooha.header_id
      AND    ohld.line_id = oola.line_id
      AND    xloh.line_id = oola.line_id
      AND    ohs.hold_source_id(+) = ohld.hold_source_id
      AND    ohd.hold_id(+) = ohs.hold_id
      AND    ohr.hold_release_id(+) = ohs.hold_release_id
      AND    ooha.flow_status_code NOT IN ('CANCELLED', 'CLOSED')
      AND    oola.flow_status_code NOT IN ('CANCELLED', 'CLOSED')
      AND    ohs.released_flag = 'N'
      AND    flvv.lookup_type = 'XXPPG_NOTIFICA_BU_FALHA_PRECO'
      AND    flvv.lookup_code = ooha.sales_channel_code
      AND    nvl(flvv.end_date_active, SYSDATE) >= SYSDATE
      AND    flvv.enabled_flag = 'Y'
      AND    ooha.sales_channel_code = flvv.lookup_code
      AND    ohd.hold_id = l_hold_id;
  
  BEGIN
    p_initialize_globals;
  
    SELECT application_id
    INTO   l_application_id
    FROM   fnd_application_vl
    WHERE  application_short_name = 'ONT';
    ---
    mo_global.set_policy_context('S', l_org_id);
    l_return_status := 'S';
    oe_msg_pub.initialize;
    fnd_global.apps_initialize(l_usr_id, l_resp, l_application_id);
  
    --
    fnd_file.put_line(fnd_file.log,'l_application_id ............. : ' ||l_application_id);
    fnd_file.put_line(fnd_file.log,'l_org_id ..................... : ' || l_org_id);
    fnd_file.put_line(fnd_file.log,'l_usr_id ..................... : ' || l_usr_id);
    fnd_file.put_line(fnd_file.log,'l_resp ....................... : ' || l_resp);
    fnd_file.put_line(fnd_file.log,'l_hold_id .................... : ' || l_hold_id);
    --
    fnd_file.put_line(fnd_file.log, ' ');
    fnd_file.put_line(fnd_file.log, '   ---------- Inicio Processo Aplicacao Retencoes na Linha da Ordem ---------');
    fnd_file.put_line(fnd_file.log, ' ');
    --
    FOR r_apply_hold IN c_apply_hold LOOP
      l_hold_source_rec                  := oe_holds_pvt.g_miss_hold_source_rec;
      l_hold_source_rec.hold_id          := l_hold_id;
      l_hold_source_rec.hold_entity_code := 'O';
      l_hold_source_rec.hold_entity_id   := r_apply_hold.header_id;
      l_hold_source_rec.header_id        := r_apply_hold.header_id;
      l_hold_source_rec.line_id          := r_apply_hold.line_id;
      l_hold_source_rec.hold_comment     := 'XXPPG 1081 - NET Price Retention';
      --
      oe_holds_pub.apply_holds(p_api_version      => 1.0
                              ,p_commit           => fnd_api.g_true
                              ,p_validation_level => fnd_api.g_valid_level_none
                              ,p_hold_source_rec  => l_hold_source_rec
                              ,x_msg_count        => l_msg_count
                              ,x_msg_data         => l_msg_data
                              ,x_return_status    => l_return_status);
      --    
        BEGIN
          UPDATE xxppg_1081_line_order_hold
          SET    status = l_return_status
          WHERE  line_id = r_apply_hold.line_id;
        EXCEPTION
          WHEN OTHERS THEN
            fnd_file.put_line(fnd_file.log,'Erro ao atualizar status tabela xxppg_1081_line_order_hold');
            fnd_file.put_line(fnd_file.log, SQLERRM);
            fnd_file.put_line(fnd_file.log,'header_id ............. : ' ||r_apply_hold.header_id);
            fnd_file.put_line(fnd_file.log,'line_id ............... : ' ||r_apply_hold.line_id);
            fnd_file.put_line(fnd_file.log, '');
        END;   
        --
                                 
      IF l_return_status = 'S' THEN
        fnd_file.put_line(fnd_file.log, 'Hold Aplicado com sucesso');
        fnd_file.put_line(fnd_file.log, 'Header ID ............... : '||r_apply_hold.header_id);  
        fnd_file.put_line(fnd_file.log, 'Line ID ................. : '||r_apply_hold.line_id);
        fnd_file.put_line(fnd_file.log, '');
        
          
        COMMIT;
      ELSE
        FOR j IN 1 .. oe_msg_pub.count_msg LOOP
          oe_msg_pub.get(p_msg_index     => j
                        ,p_encoded       => 'F'
                        ,p_data          => l_msg_data
                        ,p_msg_index_out => i);
        END LOOP;
        --
        fnd_file.put_line(fnd_file.log, 'Falha ao Aplicar Hold para Linha da Ordem ');
        fnd_file.put_line(fnd_file.log, 'header_id ............. : '||r_apply_hold.header_id); 
        fnd_file.put_line(fnd_file.log, 'line_id ............... : '||r_apply_hold.line_id); 
        fnd_file.put_line(fnd_file.log, l_msg_data); 
        fnd_file.put_line(fnd_file.log, '');  
        --
        BEGIN
          UPDATE xxppg_1081_line_order_hold
          SET err_msg = substr(err_msg||'-'||l_msg_data, 1, 500)
          WHERE  line_id = r_apply_hold.line_id;
        EXCEPTION
          WHEN OTHERS THEN
            fnd_file.put_line(fnd_file.log, 'Erro ao atualizar dados tabela xxppg_1081_line_order_hold'); 
            fnd_file.put_line(fnd_file.log, SQLERRM);
            fnd_file.put_line(fnd_file.log, 'header_id ............. : '||r_apply_hold.header_id); 
            fnd_file.put_line(fnd_file.log, 'line_id ............... : '||r_apply_hold.line_id); 
            fnd_file.put_line(fnd_file.log, ''); 
          END; 
      END IF;  
    
      
    END LOOP; 
    
        BEGIN
          DELETE FROM xxppg_1081_line_apply_hold;
        EXCEPTION
          WHEN OTHERS THEN
            fnd_file.put_line(fnd_file.log,'Erro ao deletar dados tabela xxppg_1081_line_apply_hold');
            fnd_file.put_line(fnd_file.log, SQLERRM);
            fnd_file.put_line(fnd_file.log, '');
        END; 
    
    
    fnd_file.put_line(fnd_file.log, ' ');
    fnd_file.put_line(fnd_file.log, '   ---------- Fim Processo Aplicacao Retencoes na Linha da Ordem ---------');
    fnd_file.put_line(fnd_file.log, ' ');
    
    
    --
    fnd_file.put_line(fnd_file.log, ' ');
    fnd_file.put_line(fnd_file.log, '   ---------- Inicio Processo Liberacao Retencoes de Ordem ---------');
    fnd_file.put_line(fnd_file.log, ' ');
  
    fnd_file.put_line(fnd_file.log,'l_release_reason_code .... : ' ||l_release_reason_code);
    fnd_file.put_line(fnd_file.log,'p_release_comment ........ : ' || p_release_comment);
    fnd_file.put_line(fnd_file.log,'l_return_status .......... : ' || l_return_status);
    fnd_file.put_line(fnd_file.log, ' ');
    fnd_file.put_line(fnd_file.log, ' ');
  
    FOR r_release_hold IN c_release_hold LOOP
    
      fnd_file.put_line(fnd_file.log, '');
      fnd_file.put_line(fnd_file.log,'Ordem de Venda ........... : ' ||r_release_hold.order_number);
      fnd_file.put_line(fnd_file.log,'Linha da Ordem ........... : ' ||r_release_hold.line);
      fnd_file.put_line(fnd_file.log,'Preco Ordem .............. : ' ||r_release_hold.unit_selling_price);
      fnd_file.put_line(fnd_file.log,'Hold_id .................. : ' ||r_release_hold.hold_id);
    
      l_net_price := f_get_net_price(p_header_id          => r_release_hold.header_id
                                    ,p_line_id            => r_release_hold.line_id
                                    ,p_unit_selling_price => r_release_hold.unit_selling_price
                                    ,p_module             => 'SIMULACAO_RELEASE_HOLD');
    
      fnd_file.put_line(fnd_file.log, ' ');
      fnd_file.put_line(fnd_file.log,'Preco com Impostos ....... : ' || l_net_price);
    
      IF l_net_price >= r_release_hold.unit_selling_price THEN
        --
        l_count := l_count + 1;
        l_order_tbl(1).header_id := r_release_hold.header_id;
        l_order_tbl(1).line_id := r_release_hold.line_id;
        --
        oe_holds_pub.release_holds(p_api_version         => 1.0
                                  ,p_order_tbl           => l_order_tbl
                                  ,p_hold_id             => r_release_hold.hold_id
                                  ,p_release_reason_code => l_release_reason_code
                                  ,p_release_comment     => p_release_comment
                                  ,x_return_status       => l_return_status
                                  ,x_msg_count           => l_msg_count
                                  ,x_msg_data            => l_msg_data);
        --
        IF l_return_status = 'S' THEN
          fnd_file.put_line(fnd_file.log,'Retencao : ' || r_release_hold.hold_name ||' Ordem: ' || r_release_hold.order_number ||' - Liberada com Sucesso!');
          --
          COMMIT;
          fnd_file.put_line(fnd_file.log, '');
          DELETE FROM xxppg_1081_line_order_hold
          WHERE  line_id = r_release_hold.line_id;
          --
         IF r_release_hold.reprice_line NOT IN ('N','NAO') THEN 
          
          p_reprice_lines(r_release_hold.line_id
                         ,r_release_hold.unit_selling_price
                         ,l_net_price);
         
         END IF;                
          --
        ELSE
          FOR j IN 1 .. oe_msg_pub.count_msg LOOP
            oe_msg_pub.get(p_msg_index     => j
                          ,p_encoded       => 'F'
                          ,p_data          => l_msg_data
                          ,p_msg_index_out => i);
          END LOOP;
          fnd_file.put_line(fnd_file.log,'Ordem: ' || r_release_hold.order_number ||' - nao Liberada com Sucesso! MsgErro: ' ||l_msg_data);
          fnd_file.put_line(fnd_file.log, '');
        END IF;
        l_msg_data := NULL;
      END IF; -- IF l_net_price > r_release_hold.unit_selling_price THEN
    END LOOP;
    --
    fnd_file.put_line(fnd_file.log, ' ');
    fnd_file.put_line(fnd_file.log,'   ----------  Fim Retencoes de Ordem ---------');
    IF l_count = 0 THEN
      fnd_file.put_line(fnd_file.log, 'Nao existem ordens para liberacao');
    END IF;
    fnd_file.put_line(fnd_file.log, ' ');
  
    FOR r_hold_applied IN c_hold_applied LOOP
      xxppg_send_mail(errbuf             => errbuf
                     ,retcode            => retcode
                     ,from_name          => r_hold_applied.from_email
                     ,p_oracle_directory => NULL
                     ,p_binary_file      => NULL
                     ,to_name            => r_hold_applied.to_email
                     ,p_subject          => r_hold_applied.subject
                     ,p_body             => r_hold_applied.body_msg);
      --
      UPDATE xxppg_1081_line_order_hold
      SET    next_notification = SYSDATE + 1
      WHERE  line_id = r_hold_applied.line_id;
      --     
    END LOOP;
    BEGIN
      DELETE FROM xxppg_1081_line_order_hold WHERE nvl(status, 'X') <> 'S';
    EXCEPTION
      WHEN OTHERS THEN
        fnd_file.put_line(fnd_file.log
                         ,'Erro Delete xxppg_1081_line_order_hold');
        fnd_file.put_line(fnd_file.log, SQLERRM);
    END;
    -- 
  END p_release_hold;
  --
  --
  PROCEDURE p_reprice_lines(p_line_id             IN NUMBER
                           ,p_unit_selling_prince IN NUMBER
                           ,p_new_price           IN NUMBER) IS
    --                       
    l_line_rec           oe_order_pub.line_rec_type;
    l_return_status      VARCHAR2(10);
    l_msg_data           VARCHAR2(250);
    l_unit_selling_price oe_order_lines_all.unit_selling_price%TYPE;
    i                    NUMBER;
  
  BEGIN
    fnd_file.put_line(fnd_file.log,'Inicio Processo Reprecificacao da Linha ');
  
    p_initialize_globals;
    oe_line_util.query_row(p_line_id  => p_line_id
                          ,x_line_rec => l_line_rec);
  
    fnd_file.put_line(fnd_file.log,'Line Id .................. : ' || p_line_id);
    fnd_file.put_line(fnd_file.log,'Ordered_item ............. : ' ||l_line_rec.ordered_item);
  
    oe_line_reprice.reprice_line(p_line_rec         => l_line_rec
                                ,p_repricing_date   => 'SYSDATE'
                                ,p_repricing_event  => 'LINE'
                                ,p_honor_price_flag => 'Y'
                                ,x_return_status    => l_return_status);
    --
    fnd_file.put_line(fnd_file.log, 'Status Retorno : ' || l_return_status);
    --
    IF l_return_status = 'S' THEN
      fnd_file.put_line(fnd_file.log,'Reprecificacao efetuado com Sucesso!');
      fnd_file.put_line(fnd_file.log, '');
      -- 
      BEGIN
        UPDATE oe_order_lines_all
        SET    calculate_price_flag = 'N'
        WHERE  line_id = p_line_id;
      EXCEPTION
        WHEN OTHERS THEN
          NULL;
      END;
      --
    ELSE
      FOR j IN 1 .. oe_msg_pub.count_msg LOOP
        oe_msg_pub.get(p_msg_index     => j
                      ,p_encoded       => 'F'
                      ,p_data          => l_msg_data
                      ,p_msg_index_out => i);
      END LOOP;
      fnd_file.put_line(fnd_file.log,'Nao foi possivel efetuar reprecificacao! MsgErro: ' ||l_msg_data);
      fnd_file.put_line(fnd_file.log, '');
    END IF;
    --      
    BEGIN
      SELECT unit_selling_price
      INTO   l_unit_selling_price
      FROM   oe_order_lines_all oola
      WHERE  oola.line_id = p_line_id;
    
    EXCEPTION
      WHEN OTHERS THEN
        l_unit_selling_price := 0;
        fnd_file.put_line(fnd_file.log,'Erro ao recuperar novo preco da linha da Ordem ' ||SQLERRM);
    END;
    -- 
    fnd_file.put_line(fnd_file.log,'Preco Anterior ........... : ' ||p_unit_selling_prince);
    fnd_file.put_line(fnd_file.log,'Preco Recalculado ........ : ' || p_new_price);
    fnd_file.put_line(fnd_file.log,'Preco da Linha da Ordem .. : ' ||l_unit_selling_price);
    --
  END p_reprice_lines;
  --
  --
  PROCEDURE p_active_inactive_list(errbuf      OUT VARCHAR2
                                  ,retcode     OUT NUMBER
                                  ,p_dir       IN VARCHAR2
                                  ,p_file_name IN VARCHAR2
                                  ,p_separador IN VARCHAR2) IS
    --
    CURSOR c_headers IS
      SELECT *
      FROM   TABLE(f_read_header('HEADER', p_dir, g_file_name, p_separador));
    ---
    CURSOR c_lines IS
      SELECT *
      FROM   TABLE(f_read_lines('LINES', p_dir, g_file_name, p_separador));
  
    l_count NUMBER := 0;
    e_stop EXCEPTION;
  BEGIN
    --
    p_initialize_globals;
    --
    BEGIN
      SELECT directory_path
      INTO   g_dir_path_in
      FROM   all_directories
      WHERE  directory_name = p_dir
      AND    rownum = 1;
    EXCEPTION
      WHEN no_data_found THEN
        fnd_file.put_line(fnd_file.log,'   Directory ' || p_dir || ' does not exists');
    END;
    BEGIN
      g_file_name := p_file_name;
      fnd_file.put_line(fnd_file.log,'Inicio Processamento (Cabecalho Lista de Preco) Arquivo : ' ||p_file_name);
      fnd_file.put_line(fnd_file.log, '');
      --   
      FOR r_headers IN c_headers LOOP
        BEGIN
          l_count := l_count + 1;
          ---
          BEGIN
            UPDATE qp_list_headers_all_b
            SET    end_date_active  = r_headers.end_date_active
                  ,attribute2       = r_headers.attribute2
                  ,CONTEXT          = r_headers.context
                  ,last_update_date = r_headers.last_update_date
                  ,last_updated_by  = r_headers.last_updated_by
            WHERE  list_header_id = r_headers.list_header_id;
          
            IF SQL%ROWCOUNT > 0 THEN
              fnd_file.put_line(fnd_file.log,'Lista de Preco : ' ||r_headers.attribute1 ||' atualizada com sucesso ');
              fnd_file.put_line(fnd_file.log, '');
            ELSE
              retcode := 1;
              fnd_file.put_line(fnd_file.log,'Nao foi possivel atualizar lista de Preco : ' ||r_headers.attribute1);
              fnd_file.put_line(fnd_file.log,'list_header_id ..................: ' ||r_headers.list_header_id);
              fnd_file.put_line(fnd_file.log,'name ............................: ' ||r_headers.attribute1);
              fnd_file.put_line(fnd_file.log,'end_date_active .................: ' ||r_headers.end_date_active);
              fnd_file.put_line(fnd_file.log,'context .........................: ' ||r_headers.context);
              fnd_file.put_line(fnd_file.log,'last_update_date ................: ' ||r_headers.last_update_date);
              fnd_file.put_line(fnd_file.log,'last_updated_by .................: ' ||r_headers.last_updated_by);
              fnd_file.put_line(fnd_file.log, '');
            END IF;
          
          EXCEPTION
            WHEN OTHERS THEN
              retcode := 1;
              fnd_file.put_line(fnd_file.log,'Erro Ao Atualizar Lista de Preco ');
              fnd_file.put_line(fnd_file.log, SQLERRM);
              fnd_file.put_line(fnd_file.log, '');
              fnd_file.put_line(fnd_file.log,'list_header_id ..................: ' ||r_headers.list_header_id);
              fnd_file.put_line(fnd_file.log,'name ............................: ' ||r_headers.attribute1);
              fnd_file.put_line(fnd_file.log,'end_date_active .................: ' ||r_headers.end_date_active);
              fnd_file.put_line(fnd_file.log,'context .........................: ' ||r_headers.context);
              fnd_file.put_line(fnd_file.log,'last_update_date ................: ' ||r_headers.last_update_date);
              fnd_file.put_line(fnd_file.log,'last_updated_by .................: ' ||r_headers.last_updated_by);
              fnd_file.put_line(fnd_file.log, '');
          END;
          --
        EXCEPTION
          WHEN OTHERS THEN
            fnd_file.put_line(fnd_file.log,'Erro Geral Ao Atualizar Lista de Preco: ' ||r_headers.attribute1 || ' - ' || SQLERRM);
        END;
        --
      END LOOP;
      IF l_count > 0 THEN
      
        fnd_file.put_line(fnd_file.log,'Quantidade de Lista(s) de Preco(s) (Cabecalho) Atualizada : ' ||l_count);
        fnd_file.put_line(fnd_file.log, ' ');
        fnd_file.put_line(fnd_file.log, ' ');
      ELSE
        fnd_file.put_line(fnd_file.log,'Nao existem registros do tipo Cabecalho para atualizacao');
      END IF;
      --
      fnd_file.put_line(fnd_file.log,'Inicio Processamento (Linhas Lista de Preco) Arquivo : ' ||g_file_name);
      fnd_file.put_line(fnd_file.log, '');
      l_count := 0;
    
      BEGIN
        FOR r_lines IN c_lines LOOP
          BEGIN
            l_count := l_count + 1;
            --
            BEGIN
              UPDATE qp_list_lines
              SET    end_date_active  = r_lines.end_date_active
                    ,attribute1       = r_lines.attribute1
                    ,CONTEXT          = r_lines.context
                    ,last_update_date = r_lines.last_update_date
                    ,last_updated_by  = r_lines.last_updated_by
              WHERE  list_line_id = r_lines.list_line_id;
            
              IF SQL%ROWCOUNT > 0 THEN
                fnd_file.put_line(fnd_file.log,'Item ' ||f_get_item_details(r_lines.inventory_item_id,'COD_ITEM') ||'da Lista de Preco : ' ||r_lines.attribute2 ||' atualizado com sucesso ');
              
              ELSE
                retcode := 1;
                fnd_file.put_line(fnd_file.log,'Nao foi possivel Item ' ||f_get_item_details(r_lines.inventory_item_id,'COD_ITEM') ||' da Lista de Preco : ' ||r_lines.attribute2);
                fnd_file.put_line(fnd_file.log,'list_header_id ..................: ' ||r_lines.list_header_id);
                fnd_file.put_line(fnd_file.log,'list_line_id ....................: ' ||r_lines.list_line_id);
                fnd_file.put_line(fnd_file.log,'name ............................: ' ||r_lines.attribute2);
                fnd_file.put_line(fnd_file.log,'inventory_item_id ...............: ' ||r_lines.inventory_item_id);
                fnd_file.put_line(fnd_file.log,'end_date_active .................: ' ||r_lines.end_date_active);
                fnd_file.put_line(fnd_file.log,'context .........................: ' ||r_lines.context);
                fnd_file.put_line(fnd_file.log,'last_update_date ................: ' ||r_lines.last_update_date);
                fnd_file.put_line(fnd_file.log,'last_updated_by .................: ' ||r_lines.last_updated_by);
                fnd_file.put_line(fnd_file.log, '');
              END IF;
            
            EXCEPTION
              WHEN OTHERS THEN
                retcode := 1;
                fnd_file.put_line(fnd_file.log,'Erro ao Atualizar linha da Lista de Preco ');
                fnd_file.put_line(fnd_file.log, SQLERRM);
                fnd_file.put_line(fnd_file.log, '');
                fnd_file.put_line(fnd_file.log,'list_header_id ..................: ' ||r_lines.list_header_id);
                fnd_file.put_line(fnd_file.log,'list_line_id ....................: ' ||r_lines.list_line_id);
                fnd_file.put_line(fnd_file.log,'name ............................: ' ||r_lines.attribute2);
                fnd_file.put_line(fnd_file.log,'inventory_item_id ...............: ' ||r_lines.inventory_item_id);
                fnd_file.put_line(fnd_file.log,'end_date_active .................: ' ||r_lines.end_date_active);
                fnd_file.put_line(fnd_file.log,'context .........................: ' ||r_lines.context);
                fnd_file.put_line(fnd_file.log,'last_update_date ................: ' ||r_lines.last_update_date);
                fnd_file.put_line(fnd_file.log,'last_updated_by .................: ' ||r_lines.last_updated_by);
                fnd_file.put_line(fnd_file.log, '');
            END;
            --
          EXCEPTION
            WHEN OTHERS THEN
              fnd_file.put_line(fnd_file.log,'Erro Geral Ao Atualizar Linha da Lista de Preco: ' ||r_lines.attribute2 || ' - ' || SQLERRM);
          END;
        END LOOP;
        --
        IF l_count > 0 THEN
          fnd_file.put_line(fnd_file.log,'Quantidade de Linha da Lista de Preco Atualizada : ' ||l_count);
          fnd_file.put_line(fnd_file.log, ' ');
          fnd_file.put_line(fnd_file.log, ' ');
        ELSE
          fnd_file.put_line(fnd_file.log,'Nao existem registros do tipo Linha para atualizacao');
        END IF;
      END;
      --
    EXCEPTION
      WHEN e_stop THEN
        retcode := 1;
        errbuf  := 'ERROR execute';
    END;
    utl_file.fremove(p_dir, p_file_name);
    fnd_file.put_line(fnd_file.log, 'Arquivo de Entrada Removido');
    retcode := g_retcode;
  
  END p_active_inactive_list;
  --
  --
  PROCEDURE p_delete_sales_line(p_header_id     IN NUMBER
                               ,p_line_id       IN NUMBER
                               ,x_return_status OUT VARCHAR2
                               ,x_message       OUT VARCHAR2) IS
    --
    v_api_version_number NUMBER := 1;
    v_return_status      VARCHAR2(2000);
    v_msg_count          NUMBER;
    v_msg_data           VARCHAR2(2000);
    --
    -- IN Variables --
    v_header_rec         oe_order_pub.header_rec_type;
    v_line_tbl           oe_order_pub.line_tbl_type;
    v_action_request_tbl oe_order_pub.request_tbl_type;
    v_line_adj_tbl       oe_order_pub.line_adj_tbl_type;
    --
    -- OUT Variables --
    v_header_rec_out             oe_order_pub.header_rec_type;
    v_header_val_rec_out         oe_order_pub.header_val_rec_type;
    v_header_adj_tbl_out         oe_order_pub.header_adj_tbl_type;
    v_header_adj_val_tbl_out     oe_order_pub.header_adj_val_tbl_type;
    v_header_price_att_tbl_out   oe_order_pub.header_price_att_tbl_type;
    v_header_adj_att_tbl_out     oe_order_pub.header_adj_att_tbl_type;
    v_header_adj_assoc_tbl_out   oe_order_pub.header_adj_assoc_tbl_type;
    v_header_scredit_tbl_out     oe_order_pub.header_scredit_tbl_type;
    v_header_scredit_val_tbl_out oe_order_pub.header_scredit_val_tbl_type;
    v_line_tbl_out               oe_order_pub.line_tbl_type;
    v_line_val_tbl_out           oe_order_pub.line_val_tbl_type;
    v_line_adj_tbl_out           oe_order_pub.line_adj_tbl_type;
    v_line_adj_val_tbl_out       oe_order_pub.line_adj_val_tbl_type;
    v_line_price_att_tbl_out     oe_order_pub.line_price_att_tbl_type;
    v_line_adj_att_tbl_out       oe_order_pub.line_adj_att_tbl_type;
    v_line_adj_assoc_tbl_out     oe_order_pub.line_adj_assoc_tbl_type;
    v_line_scredit_tbl_out       oe_order_pub.line_scredit_tbl_type;
    v_line_scredit_val_tbl_out   oe_order_pub.line_scredit_val_tbl_type;
    v_lot_serial_tbl_out         oe_order_pub.lot_serial_tbl_type;
    v_lot_serial_val_tbl_out     oe_order_pub.lot_serial_val_tbl_type;
    v_action_request_tbl_out     oe_order_pub.request_tbl_type;
    --
    v_msg_index     NUMBER;
    v_data          VARCHAR2(2000);
    v_loop_count    NUMBER;
    v_debug_file    VARCHAR2(200);
    b_return_status VARCHAR2(200);
    b_msg_count     NUMBER;
    b_msg_data      VARCHAR2(2000);
    --
  BEGIN
    p_initialize_globals;
    --
    v_line_tbl(1) := oe_order_pub.g_miss_line_rec;
    v_line_tbl(1).operation := oe_globals.g_opr_delete;
    v_line_tbl(1).header_id := p_header_id;
    v_line_tbl(1).line_id := p_line_id;
    --
    fnd_file.put_line(fnd_file.log, 'Inicio Processo Delecao Line ID : '||p_line_id ); 
    oe_order_pub.process_order(p_api_version_number => v_api_version_number
                              ,p_header_rec         => v_header_rec
                              ,p_line_tbl           => v_line_tbl
                              ,p_action_request_tbl => v_action_request_tbl
                              ,p_line_adj_tbl       => v_line_adj_tbl
                               -- OUT variables
                              ,x_header_rec             => v_header_rec_out
                              ,x_header_val_rec         => v_header_val_rec_out
                              ,x_header_adj_tbl         => v_header_adj_tbl_out
                              ,x_header_adj_val_tbl     => v_header_adj_val_tbl_out
                              ,x_header_price_att_tbl   => v_header_price_att_tbl_out
                              ,x_header_adj_att_tbl     => v_header_adj_att_tbl_out
                              ,x_header_adj_assoc_tbl   => v_header_adj_assoc_tbl_out
                              ,x_header_scredit_tbl     => v_header_scredit_tbl_out
                              ,x_header_scredit_val_tbl => v_header_scredit_val_tbl_out
                              ,x_line_tbl               => v_line_tbl_out
                              ,x_line_val_tbl           => v_line_val_tbl_out
                              ,x_line_adj_tbl           => v_line_adj_tbl_out
                              ,x_line_adj_val_tbl       => v_line_adj_val_tbl_out
                              ,x_line_price_att_tbl     => v_line_price_att_tbl_out
                              ,x_line_adj_att_tbl       => v_line_adj_att_tbl_out
                              ,x_line_adj_assoc_tbl     => v_line_adj_assoc_tbl_out
                              ,x_line_scredit_tbl       => v_line_scredit_tbl_out
                              ,x_line_scredit_val_tbl   => v_line_scredit_val_tbl_out
                              ,x_lot_serial_tbl         => v_lot_serial_tbl_out
                              ,x_lot_serial_val_tbl     => v_lot_serial_val_tbl_out
                              ,x_action_request_tbl     => v_action_request_tbl_out
                              ,x_return_status          => v_return_status
                              ,x_msg_count              => v_msg_count
                              ,x_msg_data               => v_msg_data);
    --
    x_return_status := v_return_status;
    IF nvl(v_return_status,'E') = fnd_api.g_ret_sts_success THEN
      COMMIT;
      fnd_file.put_line(fnd_file.log,'Delete a line from an Existing Order Success ');
    ELSE
      fnd_file.put_line(fnd_file.log,'Delete a line from an Existing Order failed:' ||v_msg_data);
      FOR i IN 1 .. v_msg_count LOOP
        v_msg_data := oe_msg_pub.get(p_msg_index => i, p_encoded => 'F');
        fnd_file.put_line(fnd_file.log, i || ') ' || v_msg_data);
      END LOOP;
    
    fnd_file.put_line(fnd_file.log, 'Delecao Manual - '||p_line_id);
    
    BEGIN
    DELETE FROM oe_order_lines_all WHERE line_id =  p_line_id;
    EXCEPTION
      WHEN OTHERS THEN
        fnd_file.put_line(fnd_file.log, 'Erro Deletar LINE ID Manualmente '||SQLERRM);
    END;     
    
    END IF;
    x_message := v_msg_data;
    --  
  END p_delete_sales_line;
  --
  --
  PROCEDURE p_net_price_fci(errbuf           OUT VARCHAR2
                           ,retcode          OUT NUMBER
                           ,p_reason         IN VARCHAR2 DEFAULT 'PPG CANC SOLUCAO PRECO NET'
                           ,p_comment        IN VARCHAR2 DEFAULT 'PPG Canc Solucao Preco Net'
                           ,p_directory_temp IN VARCHAR2 DEFAULT 'APPLOUT'
                           ,p_directory      IN VARCHAR2 DEFAULT 'XXPPG_BR_REPORTS_'
                           ,p_dir_win_path   IN VARCHAR2 DEFAULT 'I:\Oracle-EBS\Reports\Out\'
                           ,p_file_name      IN VARCHAR2 DEFAULT NULL
                           ,p_separador      IN VARCHAR2 DEFAULT ';') IS
    --
    l_return_status VARCHAR2(1);
    l_message       VARCHAR2(1000);
    l_body_msg      VARCHAR2(1000);
    l_to_email      VARCHAR2(200);
    l_from_email    VARCHAR2(15) := 'noreply@ppg.com';
    l_subject       VARCHAR2(1000);
    x_line_id       NUMBER;
    l_file_name     VARCHAR2(100);
    l_file          utl_file.file_type;
    l_line_rec      oe_order_pub.line_rec_type;
    l_reg           NUMBER := 0;
    l_status        NUMBER;
    l_code_status   VARCHAR2(50);
    --
    CURSOR c_mass_update_sales IS
      SELECT DISTINCT flvv.lookup_code sales_channel_code
      FROM   TABLE(f_read_fci_data(g_dir_name_in, p_file_name, p_separador)) fci
            ,apps.fnd_lookup_values_vl flvv
            ,apps.oe_order_lines_all oola
      WHERE  flvv.lookup_type = 'XXPPG_1081_CONT_ORDENS_BU'
      AND    flvv.enabled_flag = 'Y'
      AND    nvl(flvv.end_date_active, SYSDATE) >= SYSDATE
      AND    oola.line_id = fci.line_id
      AND    oola.flow_status_code NOT IN ('CANCELLED', 'CLOSED')
      AND    flvv.lookup_code = fci.sales_channel_code;
  
  
    CURSOR c_mass_update(p_sales_channel_code IN VARCHAR2) IS
      SELECT 'Ordens de Venda Atualizadas - Retorno FCI - BU: ' ||
             flvv.lookup_code subject
            ,'Devido ao retorno do FCI, foi necessario cancelar e criar as linhas de ordens que constam no arquivo em anexo, para que os precos de venda fossem atualizados com base nas novas aliquotas de impostos' message
            ,flvv.description to_email
            ,oola.order_quantity_uom 
            ,fci.*
            ,f_get_unit_price(NULL
                             ,ooha.price_list_id
                             ,oola.inventory_item_id)  l_unit_selling_price 
      FROM   TABLE(f_read_fci_data(g_dir_name_in, p_file_name, p_separador)) fci
            ,apps.fnd_lookup_values_vl flvv
            ,apps.oe_order_lines_all oola
            ,apps.oe_order_headers_all ooha
      WHERE  flvv.lookup_type = 'XXPPG_1081_CONT_ORDENS_BU'
      AND    flvv.enabled_flag = 'Y'
      AND    nvl(flvv.end_date_active, SYSDATE) >= SYSDATE
      AND    oola.line_id = fci.line_id
      AND    oola.flow_status_code NOT IN ('CANCELLED', 'CLOSED')
      AND    ooha.header_id = oola.header_id
      AND    ooha.flow_status_code NOT IN ('CANCELLED', 'CLOSED')
      AND    flvv.lookup_code = fci.sales_channel_code
      AND    flvv.lookup_code = p_sales_channel_code;
  
    --
    CURSOR c_sales_code_s(p_tag IN VARCHAR2) IS
      SELECT flvv.lookup_code sales_channel_code
            ,flvv.description to_email
            ,'noreply@ppg.com' from_email
            ,CASE
               WHEN p_tag = 'SIM' THEN
                'Ordens de Venda Atualizadas - Retorno FCI - BU: ' ||
                flvv.lookup_code
               ELSE
                'Ordens de Vendas que devem ser Atualizadas - Retorno FCI - BU: ' ||
                flvv.lookup_code
             END subject
            ,CASE
               WHEN p_tag = 'SIM' THEN
                'Devido ao retorno do FCI, foi necessario cancelar e criar as linhas de ordens que constam no arquivo em anexo, para que os precos de venda fossem atualizados com base nas novas aliquotas de impostos'
               ELSE
                'Devido ao retorno do FCI, e necessario cancelar as linhas de ordens do arquivo em anexo e criar novas linhas, para que o preço de venda seja atualizado com base nas novas alíquotas de impostos. Por favor, definir quais linhas devem ser atualizadas e utilizar a solucao que fara a atualizacao em massa' ||
                chr(10) || chr(10) ||
                'ATENCAO: LINHAS EM PROCESSO DE FATURAMENTO DEVERAO SER CANCELADAS MANUALMENTE.'
             END message
      FROM   apps.fnd_lookup_values_vl flvv
      WHERE  flvv.lookup_type = 'XXPPG_1081_CONT_ORDENS_BU'
      AND    flvv.enabled_flag = 'Y'
      AND    nvl(flvv.end_date_active, SYSDATE) >= SYSDATE
      AND    nvl(upper(flvv.tag), 'NAO') = upper(p_tag);
    --
    CURSOR c_cancel_line(p_sales_channel_code IN VARCHAR2
                        ,p_status             IN NUMBER) IS
      SELECT xnf.sales_channel_code
            ,xnf.order_number
            ,xnf.line_number line
            ,xnf.party_name
            ,xnf.new_price
            ,f_get_net_price(p_header_id => oola.header_id
                            ,p_line_id   => oola.line_id
                            ,p_module    => 'SIMULACAO') l_updt_price
            ,xnf.num_embarque
            ,xnf.err_msg
            ,decode(xnf.status
                   ,1
                   ,'LINHA EM PROCESSO DE FATURAMENTO'
                   ,NULL) status_linha
            ,oola.*
      FROM   xxppg_1081_net_fci xnf, oe_order_lines_all oola
      WHERE  xnf.line_id = oola.line_id
      AND    xnf.status = nvl(p_status, xnf.status) --- 0 --sem faturamento / sem reserva
      AND    oola.flow_status_code NOT IN ('CANCELLED', 'CLOSED')
      AND    xnf.sales_channel_code = p_sales_channel_code;
  BEGIN
    --
    p_initialize_globals;
    g_dir_name_in  := p_directory || 'IN';
    g_dir_name_out := p_directory || 'OUT';
    g_file_name    := p_file_name;
    --
    BEGIN
      SELECT directory_path
      INTO   g_dir_path_in
      FROM   all_directories
      WHERE  directory_name = g_dir_name_in
      AND    rownum = 1;
    EXCEPTION
      WHEN no_data_found THEN
        fnd_file.put_line(fnd_file.log
                         ,'   Directory ' || g_dir_name_in ||
                          ' does not exists');
    END;
    --
    BEGIN
      SELECT directory_path
      INTO   g_dir_path_out
      FROM   all_directories
      WHERE  directory_name = g_dir_name_out
      AND    rownum = 1;
    EXCEPTION
      WHEN no_data_found THEN
        fnd_file.put_line(fnd_file.log
                         ,'   Directory ' || g_dir_name_out ||
                          ' does not exists');
    END;
  
    fnd_file.put_line(fnd_file.log, 'Inicio processo p_net_price_fci');
    fnd_file.put_line(fnd_file.log, 'Parametros');
    fnd_file.put_line(fnd_file.log, '');
    fnd_file.put_line(fnd_file.log,'p_reason ................. : ' || p_reason);
    fnd_file.put_line(fnd_file.log,'p_comment ................ : ' || p_comment);
    fnd_file.put_line(fnd_file.log,'p_directory_temp ......... : ' || p_directory_temp);
    fnd_file.put_line(fnd_file.log,'p_directory .............. : ' || p_directory);
    fnd_file.put_line(fnd_file.log,'p_dir_win_path ........... : ' || p_dir_win_path);
    fnd_file.put_line(fnd_file.log,'p_file_name .............. : ' || p_file_name);
    fnd_file.put_line(fnd_file.log,'p_separador .............. : ' || p_separador);
    fnd_file.put_line(fnd_file.log,'g_dir_name_in ............ : ' || g_dir_name_in);
    fnd_file.put_line(fnd_file.log,'g_dir_name_out ........... : ' || g_dir_name_out);
    fnd_file.put_line(fnd_file.log,'g_file_name .............. : ' || g_file_name);
    fnd_file.put_line(fnd_file.log, '');
    --
    IF p_file_name IS NULL THEN
      fnd_file.put_line(fnd_file.log,'=======================================================================');
      fnd_file.put_line(fnd_file.log,'INICIO PROCESSAMENTO CURSOR QUE DEVE ATUALIZAR LINHAS ');
      fnd_file.put_line(fnd_file.log,'=======================================================================');
      fnd_file.put_line(fnd_file.log, '');
      FOR r_sales_code_s IN c_sales_code_s('SIM') LOOP
        --
        fnd_file.put_line(fnd_file.log,'=======================================================================');
        fnd_file.put_line(fnd_file.log,'INICIO PROCESSAMENTO PARA BU : ' ||r_sales_code_s.sales_channel_code);
        fnd_file.put_line(fnd_file.log,'=======================================================================');
        fnd_file.put_line(fnd_file.log, '');
      
        l_file_name := 'Ordens_de_vendas_Retorno FCI_' ||r_sales_code_s.sales_channel_code || '.csv';
        l_file      := utl_file.fopen(p_directory_temp,l_file_name,'W',32767);
        utl_file.put_line(l_file
                         ,'CLIENTE' || p_separador || --A
                          'ORDEM DE VENDA' || p_separador || --B
                          'LINHA CANCELADA' || p_separador || --C
                          'QTD LINHA CANCELADA' || p_separador || --D
                          'LINHA CRIADA' || p_separador || --E
                          'QTD LINHA CRIADA' || p_separador || --F
                          'PRECO DE VENDA DA LINHA'); --G
        l_reg         := 0;
        l_status      := 0; --sem faturamento / sem reserva
        l_code_status := 'SEM FATURAMENTO / SEM RESERVA';
        --
        fnd_file.put_line(fnd_file.log,'Arquivo Criado ......... : ' || l_file_name);
        --
        fnd_file.put_line(fnd_file.log,'=======================================================================');
        fnd_file.put_line(fnd_file.log,'INICIO PROCESSAMENTO LINHAS QUE NAO ESTAO EM PROCESSO DE FATURAMENTO');
        fnd_file.put_line(fnd_file.log,'=======================================================================');
        fnd_file.put_line(fnd_file.log, '');
      
        FOR r_cancel_line IN c_cancel_line(r_sales_code_s.sales_channel_code
                                          ,l_status) LOOP
          --
          
            BEGIN
              UPDATE oe_order_lines_all
              SET    calculate_price_flag = 'N'
              WHERE  line_id = r_cancel_line.line_id;
            EXCEPTION
              WHEN OTHERS THEN
                fnd_file.put_line(fnd_file.log, 'Erro atualizar calculate_price_flag : '||SQLERRM); 
                fnd_file.put_line(fnd_file.log, 'line_id .......... : '||r_cancel_line.line_id); 
            END;          
          --
          fnd_file.put_line(fnd_file.log,'INICIO PROCESSAMENTO LINE_ID: ' ||r_cancel_line.line_id);
          fnd_file.put_line(fnd_file.log,'header_id ............... : ' ||r_cancel_line.header_id);
          fnd_file.put_line(fnd_file.log,'line_id ................. : ' ||r_cancel_line.line_id);
          fnd_file.put_line(fnd_file.log, '');
          IF r_cancel_line.flow_status_code = 'ENTERED' THEN
            fnd_file.put_line(fnd_file.log,'Inicio processo deletar linha ');
            --
            p_delete_sales_line(p_header_id     => r_cancel_line.header_id
                               ,p_line_id       => r_cancel_line.line_id
                               ,x_return_status => l_return_status
                               ,x_message       => l_message);
            fnd_file.put_line(fnd_file.log,'p_delete_sales_line ...... : ' ||l_return_status);
            --
            IF l_return_status = 'S' THEN
              fnd_file.put_line(fnd_file.log, '');
              fnd_file.put_line(fnd_file.log,'Linha ENTERED apagada com sucesso - LINE_ID : ' ||r_cancel_line.line_id);
            ELSE
              fnd_file.put_line(fnd_file.log, '');
              fnd_file.put_line(fnd_file.log,'Falha ao Apagar Linha ENTERED - LINE_ID : ' ||r_cancel_line.line_id);
            END IF;
          
          ELSE
            fnd_file.put_line(fnd_file.log,'Inicio Processo Cancelar Linha ');
            fnd_file.put_line(fnd_file.log, '');
            fnd_file.put_line(fnd_file.log,'line_id ........... : ' ||r_cancel_line.line_id);
            fnd_file.put_line(fnd_file.log,'p_reason ......... : ' || p_reason);
            fnd_file.put_line(fnd_file.log,'p_comment ........ : ' || p_comment);
            fnd_file.put_line(fnd_file.log,'l_return_status ...: ' || l_return_status);
            fnd_file.put_line(fnd_file.log,'l_message .........: ' || l_message);
            fnd_file.put_line(fnd_file.log, '');
            --
            fnd_file.put_line(fnd_file.log, 'Chamada p_man_cancel_lines');
            p_man_cancel_lines(p_line_id       => r_cancel_line.line_id
                              ,p_motivo        => p_reason
                              ,p_obs           => p_comment
                              ,x_return_status => l_return_status
                              ,x_message       => l_message);
            --                  
            fnd_file.put_line(fnd_file.log,'p_man_cancel_lines ..... : ' ||l_return_status);
            IF l_return_status = 'S' THEN
              fnd_file.put_line(fnd_file.log, '');
              fnd_file.put_line(fnd_file.log,'Linha Cancelada com sucesso - LINE_ID : ' ||r_cancel_line.line_id);
            ELSE
              fnd_file.put_line(fnd_file.log, '');
              fnd_file.put_line(fnd_file.log,'Falha ao Cancelar Linha - LINE_ID : ' ||r_cancel_line.line_id);
            END IF;
          
          END IF;
          IF l_return_status = 'S' THEN
            --Criar nova linha
            p_add_lines(p_header_id            => r_cancel_line.header_id
                       ,p_inventory_item_id    => r_cancel_line.inventory_item_id
                       ,p_shipping_method_code => r_cancel_line.shipping_method_code
                       ,p_unit_list_price      => r_cancel_line.new_price
                       ,p_unit_selling_price   => r_cancel_line.new_price
                       ,p_line_type_id         => r_cancel_line.line_type_id
                       ,p_ordered_quantity     => r_cancel_line.ordered_quantity
                       ,p_ship_from_org_id     => r_cancel_line.ship_from_org_id
                       ,p_order_quantity_uom   => r_cancel_line.order_quantity_uom
                       ,p_schedule_ship_date   => r_cancel_line.schedule_ship_date
                       ,p_line_id              => x_line_id
                       ,x_return_status        => l_return_status
                       ,x_message              => l_message);
            --           
            fnd_file.put_line(fnd_file.log,'p_add_lines .............. : ' ||l_return_status);
            IF l_return_status = 'S' THEN
              fnd_file.put_line(fnd_file.log, '');
              fnd_file.put_line(fnd_file.log,'Nova Linha Criada com Sucesso - LINE_ID : ' ||x_line_id);
              DELETE FROM xxppg_1081_net_fci
              WHERE  line_id = r_cancel_line.line_id;
            ELSE
              fnd_file.put_line(fnd_file.log, '');
              fnd_file.put_line(fnd_file.log,'Falha na Criacao da Nova Linha - ');
              fnd_file.put_line(fnd_file.log, l_message);
            END IF;
            --
            IF l_return_status = 'S' THEN
              oe_line_util.query_row(p_line_id  => x_line_id
                                    ,x_line_rec => l_line_rec);
              --
              utl_file.put_line(l_file
                               ,r_cancel_line.party_name || p_separador || --A
                                r_cancel_line.order_number || p_separador || --B
                                r_cancel_line.line || p_separador || --C
                                r_cancel_line.ordered_quantity ||
                                p_separador || --D
                                l_line_rec.line_number || '.' ||
                                l_line_rec.shipment_number || p_separador || --E
                                l_line_rec.ordered_quantity || p_separador || --F
                                l_line_rec.unit_selling_price); --G
              l_reg := l_reg + 1;
              fnd_file.put_line(fnd_file.log,'Linha Inserida no Arquivo..... : ' ||l_reg);
              fnd_file.put_line(fnd_file.log, '');
            END IF;
          END IF;
          ---
          fnd_file.put_line(fnd_file.log,'FIM PROCESSAMENTO LINE_ID: ' ||r_cancel_line.line_id);
          fnd_file.put_line(fnd_file.log, '');
          fnd_file.put_line(fnd_file.log, '');
        END LOOP; --FOR r_cancel_line IN c_cancel_line LOOP
        --
        fnd_file.put_line(fnd_file.log,'=======================================================================');
        fnd_file.put_line(fnd_file.log,'FIM PROCESSAMENTO LINHAS QUE NAO ESTAO EM PROCESSO DE FATURAMENTO');
        fnd_file.put_line(fnd_file.log,'=======================================================================');
        fnd_file.put_line(fnd_file.log, '');
        ---
        fnd_file.put_line(fnd_file.log, 'CLOSE FILE');
        IF utl_file.is_open(l_file) THEN
          utl_file.fclose(l_file);
          fnd_file.put_line(fnd_file.log, 'CLOSE FILE - OK');
        END IF;
        --
        IF l_reg > 0 THEN
          BEGIN
            fnd_file.put_line(fnd_file.log, 'inicio p_send_email');
            fnd_file.put_line(fnd_file.log,'p_from_email.............. : ' ||r_sales_code_s.from_email);
            fnd_file.put_line(fnd_file.log,'p_to_email................ : ' ||r_sales_code_s.to_email);
            fnd_file.put_line(fnd_file.log,'p_subject ................ : ' ||r_sales_code_s.subject);
            fnd_file.put_line(fnd_file.log,'p_message................. : ' ||r_sales_code_s.message);
            fnd_file.put_line(fnd_file.log,'p_directory .............. : ' ||p_directory_temp);
            fnd_file.put_line(fnd_file.log,'p_filename ............... : ' ||l_file_name);
            fnd_file.put_line(fnd_file.log, '');
            --
            p_send_email(p_from_email => r_sales_code_s.from_email
                        ,p_to_email   => r_sales_code_s.to_email
                        ,p_subject    => r_sales_code_s.subject
                        ,p_message    => r_sales_code_s.message
                        ,p_directory  => p_directory_temp
                        ,p_filename   => l_file_name);
            --            
            utl_file.fremove(p_directory_temp, l_file_name);
            fnd_file.put_line(fnd_file.log,'Arquivo : ' || l_file_name ||' Removido de : ' || p_directory_temp);
          EXCEPTION
            WHEN OTHERS THEN
              fnd_file.put_line(fnd_file.log,' Erro ao Enviar Email - ' || SQLERRM);
              utl_file.fcopy(p_directory_temp,l_file_name,g_dir_name_out,l_file_name);
              utl_file.fremove(p_directory_temp, l_file_name);
          END;
          -- 
        ELSE
          fnd_file.put_line(fnd_file.log,'Sem Dados para atualizacao para BU: ' ||r_sales_code_s.sales_channel_code || ' - ' ||l_code_status);
        END IF;
        -------
        fnd_file.put_line(fnd_file.log, 'Inicio Criacao de Novo Arquivo');
        l_file_name := 'Ordens_de_vendas_Retorno FCI_' ||r_sales_code_s.sales_channel_code || '.csv';
        l_file      := utl_file.fopen(p_directory_temp,l_file_name,'W',32767);
        utl_file.put_line(l_file
                         ,'CLIENTE' || p_separador || --A
                          'ORDEM DE VENDA' || p_separador || --B
                          'NUMERO LINHA ORDEM' || p_separador || --C
                          'QUANTIDADE PARA FATURAR' || p_separador || --D
                          'PRECO DE VENDA DA LINHA' || p_separador || --E
                          'NUMERO EMBARQUE'); --F
      
        l_status      := 1; --com faturamento / ou em processo de separacao/reserva
        l_code_status := 'LINHA EM PROCESSO DE FATURAMENTO';
        l_reg         := 0;
        l_subject     := 'Ordens de vendas que devem ser atualizadas - Retorno FCI - BU: ' ||r_sales_code_s.sales_channel_code;
        l_body_msg    := 'Devido ao retorno do FCI, e necessário cancelar as linhas de ordens do arquivo em anexo e criar novas linhas, para que o preço de venda seja atualizado com base nas novas aliquotas de impostos. Essas linhas nao foram canceladas automaticamente, pois ja estao em processo de faturamento.';
        --
        fnd_file.put_line(fnd_file.log,'l_file_name ............. : ' || l_file_name);
        fnd_file.put_line(fnd_file.log, '');
        fnd_file.put_line(fnd_file.log,'=======================================================================');
        fnd_file.put_line(fnd_file.log,'INICIO PROCESSAMENTO LINHAS QUE ESTAO EM PROCESSO DE FATURAMENTO');
        fnd_file.put_line(fnd_file.log,'=======================================================================');
        fnd_file.put_line(fnd_file.log, '');
        --
        FOR r_cancel_line IN c_cancel_line(r_sales_code_s.sales_channel_code,l_status) LOOP
          BEGIN
            ---
            BEGIN
              UPDATE oe_order_lines_all
              SET    calculate_price_flag = 'N'
              WHERE  line_id = r_cancel_line.line_id;
            EXCEPTION
              WHEN OTHERS THEN
                fnd_file.put_line(fnd_file.log, 'Erro atualizar calculate_price_flag : '||SQLERRM); 
                fnd_file.put_line(fnd_file.log, 'line_id .......... : '||r_cancel_line.line_id); 
            END;
            fnd_file.put_line(fnd_file.log,'sales_channel_code ....... : ' ||r_sales_code_s.sales_channel_code);
            fnd_file.put_line(fnd_file.log,'flow_status_code ......... : ' ||r_cancel_line.flow_status_code);
            fnd_file.put_line(fnd_file.log,'party_name ............... : ' ||r_cancel_line.party_name);
            fnd_file.put_line(fnd_file.log,'order_number ............. : ' ||r_cancel_line.order_number);
            fnd_file.put_line(fnd_file.log,'line ..................... : ' ||r_cancel_line.line);
          
            l_reg := l_reg + 1;
            fnd_file.put_line(fnd_file.log,'Registro Inserido Arquivo ..... : ' ||l_reg);
            fnd_file.put_line(fnd_file.log, '');
            utl_file.put_line(l_file
                             ,r_cancel_line.party_name || p_separador || --A
                              r_cancel_line.order_number || p_separador || --B
                              r_cancel_line.line || p_separador || --C
                              r_cancel_line.ordered_quantity ||
                              p_separador || --D
                              r_cancel_line.unit_selling_price ||
                              p_separador || --E
                              r_cancel_line.num_embarque); --F
          END;
          --
        END LOOP;
        fnd_file.put_line(fnd_file.log, 'CLOSE FILE');
        IF utl_file.is_open(l_file) THEN
          utl_file.fclose(l_file);
          fnd_file.put_line(fnd_file.log, 'CLOSE FILE - OK');
        END IF;
        fnd_file.put_line(fnd_file.log,'=======================================================================');
        fnd_file.put_line(fnd_file.log,'FIM PROCESSAMENTO LINHAS QUE ESTAO EM PROCESSO DE FATURAMENTO');
        fnd_file.put_line(fnd_file.log,'=======================================================================');
        fnd_file.put_line(fnd_file.log, '');
        --
        IF l_reg > 0 THEN
          BEGIN
            fnd_file.put_line(fnd_file.log, 'inicio p_send_email');
            fnd_file.put_line(fnd_file.log,'p_from_email.............. : ' ||r_sales_code_s.from_email);
            fnd_file.put_line(fnd_file.log,'p_to_email................ : ' ||r_sales_code_s.to_email);
            fnd_file.put_line(fnd_file.log,'p_subject ................ : ' ||r_sales_code_s.subject);
            fnd_file.put_line(fnd_file.log,'p_message................. : ' ||r_sales_code_s.message);
            fnd_file.put_line(fnd_file.log,'p_directory .............. : ' ||p_directory_temp);
            fnd_file.put_line(fnd_file.log,'p_filename ............... : ' ||l_file_name);
            fnd_file.put_line(fnd_file.log, '');
            --
            p_send_email(p_from_email => r_sales_code_s.from_email
                        ,p_to_email   => r_sales_code_s.to_email
                        ,p_subject    => l_subject
                        ,p_message    => l_body_msg
                        ,p_directory  => p_directory_temp
                        ,p_filename   => l_file_name);
            utl_file.fremove(p_directory_temp, l_file_name);
            fnd_file.put_line(fnd_file.log,'Arquivo : ' || l_file_name ||' Removido de : ' || p_directory_temp);
          EXCEPTION
            WHEN OTHERS THEN
              fnd_file.put_line(fnd_file.log,' Erro ao Enviar Email - ' || SQLERRM);
              utl_file.fcopy(p_directory_temp,l_file_name,g_dir_name_out,l_file_name);
              utl_file.fremove(p_directory_temp, l_file_name);
          END;
        ELSE
          fnd_file.put_line(fnd_file.log,'Sem Dados para atualizacao para BU: ' ||r_sales_code_s.sales_channel_code || ' - ' ||l_code_status);
        END IF;
        --
        fnd_file.put_line(fnd_file.log,'=======================================================================');
        fnd_file.put_line(fnd_file.log,'FIM PROCESSAMENTO PARA BU : ' ||r_sales_code_s.sales_channel_code);
        fnd_file.put_line(fnd_file.log,'=======================================================================');
        fnd_file.put_line(fnd_file.log, '');
      END LOOP; -- FOR r_sales_code_s IN c_sales_code_s LOOP
      IF utl_file.is_open(l_file) THEN
        utl_file.fclose(l_file);
        fnd_file.put_line(fnd_file.log, 'CLOSE FILE - OK');
      END IF;
    
      fnd_file.put_line(fnd_file.log,'=======================================================================');
      fnd_file.put_line(fnd_file.log,'FIM PROCESSAMENTO CURSOR QUE DEVE ATUALIZAR LINHAS ');
      fnd_file.put_line(fnd_file.log,'=======================================================================');
      fnd_file.put_line(fnd_file.log, '');
      --
      l_status := NULL; --todos pedidos / enviar email
      --
      fnd_file.put_line(fnd_file.log,'=======================================================================');
      fnd_file.put_line(fnd_file.log,'INICIO PROCESSAMENTO CURSOR QUE NAO DEVE ATUALIZAR LINHAS (NOTIFICACAO) ');
      fnd_file.put_line(fnd_file.log,'=======================================================================');
      fnd_file.put_line(fnd_file.log, '');
      FOR r_sales_code_s IN c_sales_code_s('NAO') LOOP
      
        fnd_file.put_line(fnd_file.log, 'Inicio Criacao de Novo Arquivo');
        l_file_name := 'Ordens_de_vendas_Retorno FCI_' ||r_sales_code_s.sales_channel_code || '.csv';
        l_file      := utl_file.fopen(p_directory_temp,l_file_name,'W',32767);
        utl_file.put_line(l_file
                         ,'CLIENTE' || p_separador || --A
                          'ORDEM DE VENDA' || p_separador || --B
                          'NUMERO LINHA ORDEM' || p_separador || --C
                          'QUANTIDADE PARA FATURAR' || p_separador || --D
                          'PRECO DE VENDA DA LINHA' || p_separador || --E
                          'STATUS FATURAMENTO' || p_separador || --F
                          'HEADER_ID' || p_separador || --G
                          'LINE_ID' || p_separador || --H
                          'NEW_PRICE' || p_separador || --I
                          'SALES CHANNEL CODE' || p_separador || --J
                          'MSG'); --K
        --
        fnd_file.put_line(fnd_file.log,'l_file_name ............. : ' || l_file_name);
        fnd_file.put_line(fnd_file.log, '');
        l_reg := 0;
        fnd_file.put_line(fnd_file.log,'Inicio processo r_cancel_line - sales_channel_code: ' ||r_sales_code_s.sales_channel_code ||' - l_status: ' || l_status);
        fnd_file.put_line(fnd_file.log, '');
      
        FOR r_cancel_line IN c_cancel_line(r_sales_code_s.sales_channel_code,l_status) LOOP
          BEGIN
            --
            fnd_file.put_line(fnd_file.log,'sales_channel_code ....... : ' ||r_sales_code_s.sales_channel_code);
            fnd_file.put_line(fnd_file.log,'flow_status_code ......... : ' ||r_cancel_line.flow_status_code);
            fnd_file.put_line(fnd_file.log,'party_name ............... : ' ||r_cancel_line.party_name);
            fnd_file.put_line(fnd_file.log,'order_number ............. : ' ||r_cancel_line.order_number);
            fnd_file.put_line(fnd_file.log,'line ..................... : ' ||r_cancel_line.line);
            l_reg := l_reg + 1;
            --
            utl_file.put_line(l_file
                             ,r_cancel_line.party_name || p_separador || --A
                              r_cancel_line.order_number || p_separador || --B
                              r_cancel_line.line || p_separador || --C
                              r_cancel_line.ordered_quantity ||
                              p_separador || --D
                              r_cancel_line.unit_selling_price ||
                              p_separador || --E
                              r_cancel_line.status_linha || p_separador || --F
                              r_cancel_line.header_id || p_separador || --G
                              r_cancel_line.line_id || p_separador || --H
                              r_cancel_line.l_updt_price/*new_price*/ || p_separador || --I
                              r_sales_code_s.sales_channel_code ||
                              p_separador || --J
                              r_cancel_line.err_msg); --K  
          
            fnd_file.put_line(fnd_file.log,'Registro Inserido Arquivo ..... : ' ||l_reg);
            fnd_file.put_line(fnd_file.log, '');
          
          END;
        END LOOP;
        fnd_file.put_line(fnd_file.log, 'CLOSE FILE');
        IF utl_file.is_open(l_file) THEN
          utl_file.fclose(l_file);
          fnd_file.put_line(fnd_file.log, 'CLOSE FILE - OK');
        END IF;
        fnd_file.put_line(fnd_file.log, 'END LOOP cursor r_cancel_line');
        fnd_file.put_line(fnd_file.log, '');
        fnd_file.put_line(fnd_file.log,'l_reg .................... : ' || l_reg);
        fnd_file.put_line(fnd_file.log, '');
        --
        IF l_reg > 0 THEN
          BEGIN
            fnd_file.put_line(fnd_file.log, 'inicio p_send_email');
            fnd_file.put_line(fnd_file.log,'p_from_email.............. : ' ||r_sales_code_s.from_email);
            fnd_file.put_line(fnd_file.log,'p_to_email................ : ' ||r_sales_code_s.to_email);
            fnd_file.put_line(fnd_file.log,'p_subject ................ : ' ||r_sales_code_s.subject);
            fnd_file.put_line(fnd_file.log,'p_message................. : ' ||r_sales_code_s.message);
            fnd_file.put_line(fnd_file.log,'p_directory .............. : ' ||p_directory_temp);
            fnd_file.put_line(fnd_file.log,'p_filename ............... : ' ||l_file_name);
            fnd_file.put_line(fnd_file.log, '');
            --
            p_send_email(p_from_email => r_sales_code_s.from_email
                        ,p_to_email   => r_sales_code_s.to_email
                        ,p_subject    => r_sales_code_s.subject
                        ,p_message    => r_sales_code_s.message
                        ,p_directory  => p_directory_temp
                        ,p_filename   => l_file_name);
            utl_file.fremove(p_directory_temp, l_file_name);
            fnd_file.put_line(fnd_file.log,'Arquivo : ' || l_file_name ||' Removido de : ' || p_directory_temp);
          EXCEPTION
            WHEN OTHERS THEN
              fnd_file.put_line(fnd_file.log,' Erro ao Enviar Email - ' || SQLERRM);
              utl_file.fcopy(p_directory_temp,l_file_name,g_dir_name_out,l_file_name);
              utl_file.fremove(p_directory_temp, l_file_name);
          END;
        ELSE
          fnd_file.put_line(fnd_file.log,'Sem Dados para atualizacao para BU : ' ||r_sales_code_s.sales_channel_code || ' - ' ||l_code_status);
        END IF;
      END LOOP;
      fnd_file.put_line(fnd_file.log,'=======================================================================');
      fnd_file.put_line(fnd_file.log,'FIM PROCESSAMENTO CURSOR QUE NAO DEVE ATUALIZAR LINHAS (NOTIFICACAO)');
      fnd_file.put_line(fnd_file.log,'=======================================================================');
      fnd_file.put_line(fnd_file.log, '');
    
    ELSE
      --p_file_name IS NULL (Atualizacao em massa)
      fnd_file.put_line(fnd_file.log,'=======================================================================');
      fnd_file.put_line(fnd_file.log,'INICIO PROCESSAMENTO ATUALIZACAO EM MASSA ');
      fnd_file.put_line(fnd_file.log,'=======================================================================');
      fnd_file.put_line(fnd_file.log, '');
    
      FOR r_mass_update_sales IN c_mass_update_sales LOOP
        l_file_name := 'MASS_UPDATE_Ordens_de_vendas_Retorno FCI_' ||r_mass_update_sales.sales_channel_code || '.csv';
        l_file      := utl_file.fopen(p_directory_temp,l_file_name,'W',32767);
        utl_file.put_line(l_file
                         ,'CLIENTE' || p_separador || --A
                          'ORDEM DE VENDA' || p_separador || --B
                          'LINHA CANCELADA' || p_separador || --C
                          'QTD LINHA CANCELADA' || p_separador || --D
                          'LINHA CRIADA' || p_separador || --E
                          'QTD LINHA CRIADA' || p_separador || --F
                          'PRECO DE VENDA DA LINHA'); --G
        --                  
        fnd_file.put_line(fnd_file.log,'file_name ................... : ' ||l_file_name);
        FOR r_mass_update IN c_mass_update(r_mass_update_sales.sales_channel_code) LOOP
          IF l_body_msg IS NULL THEN
          
            l_body_msg := r_mass_update.message;
            fnd_file.put_line(fnd_file.log,'l_body_msg ................. : ' ||l_body_msg);
            fnd_file.put_line(fnd_file.log,'l_file_name ................ : ' ||l_file_name);
          END IF;
          --
          IF l_to_email IS NULL THEN
            l_to_email := r_mass_update.to_email;
            fnd_file.put_line(fnd_file.log,'l_to_email ................. : ' ||l_to_email);
          END IF;
          --
          IF l_subject IS NULL THEN
            l_subject := r_mass_update.subject;
            fnd_file.put_line(fnd_file.log,'l_subject .................. : ' ||l_subject);
          END IF;
        
          fnd_file.put_line(fnd_file.log, '');
          oe_line_util.query_row(p_line_id  => r_mass_update.line_id,x_line_rec => l_line_rec);
        
          fnd_file.put_line(fnd_file.log,'INICIO PROCESSAMENTO LINE_ID: ' ||r_mass_update.line_id);
          fnd_file.put_line(fnd_file.log,'header_id ............... : ' ||r_mass_update.header_id);
          fnd_file.put_line(fnd_file.log,'r_mass_update.qtd ....... : ' ||r_mass_update.ordered_quantity);
          fnd_file.put_line(fnd_file.log,'l_line_rec.qtd .......... : ' ||l_line_rec.ordered_quantity);
          fnd_file.put_line(fnd_file.log, '');
          --
          BEGIN
              UPDATE oe_order_lines_all
              SET    calculate_price_flag = 'N'
              WHERE  line_id = r_mass_update.line_id;
            EXCEPTION
              WHEN OTHERS THEN
                fnd_file.put_line(fnd_file.log, 'Erro atualizar calculate_price_flag : '||SQLERRM); 
                fnd_file.put_line(fnd_file.log, 'line_id .......... : '||r_mass_update.line_id); 
            END;
          
          --
          IF l_line_rec.flow_status_code = 'ENTERED' THEN
            fnd_file.put_line(fnd_file.log,'Inicio processo deletar linha ');
            --
            p_delete_sales_line(p_header_id     => r_mass_update.header_id
                               ,p_line_id       => r_mass_update.line_id
                               ,x_return_status => l_return_status
                               ,x_message       => l_message);
            fnd_file.put_line(fnd_file.log,'p_delete_sales_line ...... : ' ||l_return_status);
            --
            IF l_return_status = 'S' THEN
              fnd_file.put_line(fnd_file.log, '');
              fnd_file.put_line(fnd_file.log,'Linha ENTERED apagada com sucesso - LINE_ID : ' ||r_mass_update.line_id);
            ELSE
              fnd_file.put_line(fnd_file.log, '');
              fnd_file.put_line(fnd_file.log,'Falha ao Apagar Linha ENTERED - LINE_ID : ' ||r_mass_update.line_id);
            END IF;
          ELSE
            fnd_file.put_line(fnd_file.log,'Inicio Processo Cancelar Linha ');
            fnd_file.put_line(fnd_file.log, '');
            fnd_file.put_line(fnd_file.log,'line_id ........... : ' ||r_mass_update.line_id);
            fnd_file.put_line(fnd_file.log,'p_reason ......... : ' || p_reason);
            fnd_file.put_line(fnd_file.log,'p_comment ........ : ' || p_comment);
            fnd_file.put_line(fnd_file.log,'l_return_status ...: ' || l_return_status);
            fnd_file.put_line(fnd_file.log,'l_message .........: ' || l_message);
            fnd_file.put_line(fnd_file.log, '');
            --
            fnd_file.put_line(fnd_file.log, 'Chamada p_man_cancel_lines');
            p_man_cancel_lines(p_line_id       => r_mass_update.line_id
                              ,p_motivo        => p_reason
                              ,p_obs           => p_comment
                              ,x_return_status => l_return_status
                              ,x_message       => l_message);
            --                  
            fnd_file.put_line(fnd_file.log,'p_man_cancel_lines ..... : ' ||l_return_status);
            IF l_return_status = 'S' THEN
              fnd_file.put_line(fnd_file.log, '');
              fnd_file.put_line(fnd_file.log,'Linha Cancelada com sucesso - LINE_ID : ' ||r_mass_update.line_id);
              fnd_file.put_line(fnd_file.log,'r_mass_update.qtd ....... : ' ||r_mass_update.ordered_quantity);
              fnd_file.put_line(fnd_file.log,'l_line_rec.qtd .......... : ' ||l_line_rec.ordered_quantity);
            ELSE
              fnd_file.put_line(fnd_file.log, '');
              fnd_file.put_line(fnd_file.log,'Falha ao Cancelar Linha - LINE_ID : ' ||r_mass_update.line_id);
              fnd_file.put_line(fnd_file.log,'r_mass_update.qtd ....... : ' ||r_mass_update.ordered_quantity);
              fnd_file.put_line(fnd_file.log,'l_line_rec.qtd .......... : ' ||l_line_rec.ordered_quantity);
            END IF;
          
          END IF;
          IF l_return_status = 'S' THEN
            --Criar nova linha
            p_add_lines(p_header_id            => r_mass_update.header_id
                       ,p_inventory_item_id    => l_line_rec.inventory_item_id
                       ,p_shipping_method_code => l_line_rec.shipping_method_code
                       ,p_unit_list_price      => r_mass_update.l_unit_selling_price --new_price
                       ,p_unit_selling_price   => r_mass_update.l_unit_selling_price --new_price
                       ,p_line_type_id         => l_line_rec.line_type_id
                       ,p_ordered_quantity     => r_mass_update.ordered_quantity
                       ,p_ship_from_org_id     => l_line_rec.ship_from_org_id
                       ,p_order_quantity_uom   => l_line_rec.order_quantity_uom
                       ,p_schedule_ship_date   => l_line_rec.schedule_ship_date
                       ,p_line_id              => x_line_id
                       ,x_return_status        => l_return_status
                       ,x_message              => l_message);
            fnd_file.put_line(fnd_file.log,'p_add_lines .............. : ' ||l_return_status);
            IF l_return_status = 'S' THEN
              fnd_file.put_line(fnd_file.log, '');
              fnd_file.put_line(fnd_file.log,'Nova Linha Criada com Sucesso - LINE_ID : ' ||x_line_id);
            ELSE
              fnd_file.put_line(fnd_file.log, '');
              fnd_file.put_line(fnd_file.log,'Falha na Criacao da Nova Linha - ');
              fnd_file.put_line(fnd_file.log, l_message);
            END IF;
            --
            IF l_return_status = 'S' THEN
              oe_line_util.query_row(p_line_id  => x_line_id,x_line_rec => l_line_rec);
            
              fnd_file.put_line(fnd_file.log,'r_mass_update.qtd ....... : ' ||r_mass_update.ordered_quantity);
              fnd_file.put_line(fnd_file.log,'l_line_rec.qtd .......... : ' ||l_line_rec.ordered_quantity);
              --
              utl_file.put_line(l_file
                               ,r_mass_update.party_name || p_separador || --A
                                r_mass_update.order_number || p_separador || --B
                                r_mass_update.line_number || p_separador || --C
                                l_line_rec.ordered_quantity || p_separador || --D
                                l_line_rec.line_number || '.' ||
                                l_line_rec.shipment_number || p_separador || --E
                                l_line_rec.ordered_quantity || p_separador || --F
                                l_line_rec.unit_selling_price); --G
              l_reg := l_reg + 1;
              fnd_file.put_line(fnd_file.log,'Linha Inserida no Arquivo..... : ' ||l_reg);
              fnd_file.put_line(fnd_file.log, '');
            END IF;
          
          END IF;
        END LOOP;
        fnd_file.put_line(fnd_file.log, 'CLOSE FILE');
        IF utl_file.is_open(l_file) THEN
          utl_file.fclose(l_file);
          fnd_file.put_line(fnd_file.log, 'CLOSE FILE - OK');
        END IF;
        --
        BEGIN
          BEGIN
            SELECT directory_path
            INTO   g_dir_path_out
            FROM   all_directories
            WHERE  directory_name = p_directory_temp
            AND    rownum = 1;
          EXCEPTION
            WHEN no_data_found THEN
              fnd_file.put_line(fnd_file.log,'   Directory ' || g_dir_name_out ||' does not exists');
          END;
        
          IF l_reg > 0 THEN
            BEGIN
              fnd_file.put_line(fnd_file.log, 'inicio p_send_email');
              fnd_file.put_line(fnd_file.log,'p_from_email.............. : ' ||l_from_email);
              fnd_file.put_line(fnd_file.log,'p_to_email................ : ' ||l_to_email);
              fnd_file.put_line(fnd_file.log,'p_subject ................ : ' ||l_subject);
              fnd_file.put_line(fnd_file.log,'p_message................. : ' ||l_body_msg);
              fnd_file.put_line(fnd_file.log,'p_directory .............. : ' ||p_directory_temp);
              fnd_file.put_line(fnd_file.log,'g_dir_path_out ........... : ' ||g_dir_path_out);
              fnd_file.put_line(fnd_file.log,'g_dir_name_out ........... : ' ||g_dir_name_out);
              fnd_file.put_line(fnd_file.log,'p_filename ............... : ' ||l_file_name);
              fnd_file.put_line(fnd_file.log, '');
              --
              BEGIN
                p_send_email(p_from_email => l_from_email
                            ,p_to_email   => l_to_email
                            ,p_subject    => l_subject
                            ,p_message    => l_body_msg
                            ,p_directory  => p_directory_temp
                            ,p_filename   => l_file_name);
              EXCEPTION
                WHEN OTHERS THEN
                  fnd_file.put_line(fnd_file.log, 'Erro Envio Email');
                  fnd_file.put_line(fnd_file.log, SQLERRM);
              END;
              --            
              BEGIN
                utl_file.fremove(p_directory_temp, l_file_name);
                fnd_file.put_line(fnd_file.log,'Arquivo : ' || l_file_name ||' Removido de : ' || p_directory_temp || '(' ||g_dir_path_out || ')');
                utl_file.fremove(g_dir_name_in, p_file_name);
                fnd_file.put_line(fnd_file.log,'Arquivo : ' || p_file_name ||' Removido de : ' || g_dir_name_in || '(' ||g_dir_path_in || ')');
              
              EXCEPTION
                WHEN OTHERS THEN
                  fnd_file.put_line(fnd_file.log,'Erro na Remocao dos Arquivos');
                  fnd_file.put_line(fnd_file.log, SQLERRM);
              END;
            EXCEPTION
              WHEN OTHERS THEN
                fnd_file.put_line(fnd_file.log
                                 ,' Erro ao Enviar Email - ' || SQLERRM);
                utl_file.fcopy(p_directory_temp,l_file_name,g_dir_name_out,l_file_name);
                utl_file.fremove(p_directory_temp, l_file_name);
            END;
          ELSE
            fnd_file.put_line(fnd_file.log,'Sem Dados para atualizacao para BU : ' ||r_mass_update_sales.sales_channel_code);
          
            BEGIN
              utl_file.fremove(p_directory_temp, l_file_name);
              fnd_file.put_line(fnd_file.log,'Arquivo : ' || l_file_name ||' Removido de : ' || p_directory_temp || '(' ||g_dir_path_out || ')');
            EXCEPTION
              WHEN OTHERS THEN
                fnd_file.put_line(fnd_file.log,'Erro Removacao do arquivo: ' ||l_file_name || ' em : ' ||p_directory_temp);
                fnd_file.put_line(fnd_file.log, SQLERRM);
            END;
            --
            BEGIN
              utl_file.fremove(g_dir_name_in, p_file_name);
              fnd_file.put_line(fnd_file.log,'Arquivo : ' || p_file_name ||' Removido de : ' || g_dir_name_in || '(' ||g_dir_path_in || ')');
            EXCEPTION
              WHEN OTHERS THEN
                fnd_file.put_line(fnd_file.log,'Erro Removacao do arquivo: ' ||p_file_name || ' em : ' || g_dir_name_in);
                fnd_file.put_line(fnd_file.log, SQLERRM);
            END;
          END IF;
        END;
      END LOOP;
      fnd_file.put_line(fnd_file.log,'=======================================================================');
      fnd_file.put_line(fnd_file.log,'FIM PROCESSAMENTO ATUALIZACAO EM MASSA ');
      fnd_file.put_line(fnd_file.log,'=======================================================================');
      fnd_file.put_line(fnd_file.log, '');
      --
      BEGIN
        utl_file.fremove(g_dir_name_in, p_file_name);
        fnd_file.put_line(fnd_file.log,'Arquivo : ' || p_file_name || ' Removido de : ' ||g_dir_name_in || '(' || g_dir_path_in || ')');
      EXCEPTION
        WHEN OTHERS THEN
          fnd_file.put_line(fnd_file.log,'Erro Removacao do arquivo: ' || p_file_name ||' em : ' || g_dir_name_in);
          fnd_file.put_line(fnd_file.log, SQLERRM);
      END;
    END IF;
  END p_net_price_fci;
  --
  --
  PROCEDURE p_add_lines(p_header_id            IN NUMBER
                       ,p_inventory_item_id    IN NUMBER
                       ,p_shipping_method_code IN VARCHAR2
                       ,p_unit_list_price      IN NUMBER
                       ,p_unit_selling_price   IN NUMBER
                       ,p_line_type_id         IN NUMBER
                       ,p_ordered_quantity     IN NUMBER
                       ,p_ship_from_org_id     IN NUMBER
                       ,p_order_quantity_uom   IN VARCHAR2
                       ,p_schedule_ship_date   IN DATE
                       ,p_line_id              OUT NUMBER
                       ,x_return_status        OUT VARCHAR2
                       ,x_message              OUT VARCHAR2) IS
    --
    i               NUMBER := 0;
    l_count         NUMBER;
    l_msg_index_out NUMBER;
    l_msg_data      VARCHAR2(4000);
    l_msg_return    VARCHAR2(4000);
    v_error         VARCHAR2(4000);
    l_return_status VARCHAR2(1);
    l_msg_count     NUMBER;
  
    --IN Variables API oe_order_pub.process_order --
    l_header_rec         oe_order_pub.header_rec_type;
    l_line_tbl           oe_order_pub.line_tbl_type;
    l_action_request_tbl oe_order_pub.request_tbl_type;
    -- OUT Variables API oe_order_pub.process_order --
    l_header_rec_out             oe_order_pub.header_rec_type;
    l_header_val_rec_out         oe_order_pub.header_val_rec_type;
    l_header_adj_tbl_out         oe_order_pub.header_adj_tbl_type;
    l_header_adj_val_tbl_out     oe_order_pub.header_adj_val_tbl_type;
    l_header_price_att_tbl_out   oe_order_pub.header_price_att_tbl_type;
    l_header_adj_att_tbl_out     oe_order_pub.header_adj_att_tbl_type;
    l_header_adj_assoc_tbl_out   oe_order_pub.header_adj_assoc_tbl_type;
    l_header_scredit_tbl_out     oe_order_pub.header_scredit_tbl_type;
    l_header_scredit_val_tbl_out oe_order_pub.header_scredit_val_tbl_type;
    l_line_tbl_out               oe_order_pub.line_tbl_type;
    l_line_val_tbl_out           oe_order_pub.line_val_tbl_type;
    l_line_adj_tbl_out           oe_order_pub.line_adj_tbl_type;
    l_line_adj_val_tbl_out       oe_order_pub.line_adj_val_tbl_type;
    l_line_price_att_tbl_out     oe_order_pub.line_price_att_tbl_type;
    l_line_adj_att_tbl_out       oe_order_pub.line_adj_att_tbl_type;
    l_line_adj_assoc_tbl_out     oe_order_pub.line_adj_assoc_tbl_type;
    l_line_scredit_tbl_out       oe_order_pub.line_scredit_tbl_type;
    l_line_scredit_val_tbl_out   oe_order_pub.line_scredit_val_tbl_type;
    l_lot_serial_tbl_out         oe_order_pub.lot_serial_tbl_type;
    l_lot_serial_val_tbl_out     oe_order_pub.lot_serial_val_tbl_type;
    l_action_request_tbl_out     oe_order_pub.request_tbl_type;
    --
  BEGIN
    --
    x_return_status := 'S';
    x_message       := NULL;
    --
    p_initialize_globals;
    mo_global.init('ONT');
    l_count := 0;
    l_header_rec := oe_order_pub.g_miss_header_rec;
    l_action_request_tbl(1) := oe_order_pub.g_miss_request_rec;
    l_count := l_count + 1;
    l_line_tbl(l_count) := oe_order_pub.g_miss_line_rec;
    -- Line Record --
    --REGISTROS DE LINHA
    l_line_tbl(l_count).operation := oe_globals.g_opr_create;
    l_line_tbl(l_count).header_id := p_header_id;
    l_line_tbl(l_count).inventory_item_id := p_inventory_item_id;
    l_line_tbl(l_count).ordered_quantity := p_ordered_quantity;
    l_line_tbl(l_count).unit_selling_price := p_unit_list_price;--p_unit_selling_price;
    l_line_tbl(l_count).unit_list_price := p_unit_list_price;
    
    l_line_tbl(l_count).ship_from_org_id := p_ship_from_org_id;
    l_line_tbl(l_count).order_quantity_uom := p_order_quantity_uom; ------New
    l_line_tbl(l_count).schedule_ship_date := p_schedule_ship_date; ----- New
    l_line_tbl(l_count).shipping_method_code := p_shipping_method_code;
    l_line_tbl(l_count).line_type_id := p_line_type_id;
    --
    fnd_file.put_line(fnd_file.log, ' ');
    fnd_file.put_line(fnd_file.log, 'oe_order_pub.process_order ANTES ');
    fnd_file.put_line(fnd_file.log,'operation ..................... : ' ||oe_globals.g_opr_create);
    fnd_file.put_line(fnd_file.log,'p_header_id ................... : ' || p_header_id);
    fnd_file.put_line(fnd_file.log,'p_inventory_item_id ........... : ' ||p_inventory_item_id);
    fnd_file.put_line(fnd_file.log,'p_ordered_quantity ............ : ' ||p_ordered_quantity);
    fnd_file.put_line(fnd_file.log,'p_unit_selling_price .......... : ' ||p_unit_list_price);
    fnd_file.put_line(fnd_file.log,'p_unit_list_price ............. : ' ||p_unit_list_price);
    fnd_file.put_line(fnd_file.log,'p_ship_from_org_id ............ : ' ||p_ship_from_org_id);
    fnd_file.put_line(fnd_file.log,'p_shipping_method_code ........ : ' ||p_shipping_method_code);
    fnd_file.put_line(fnd_file.log,'p_line_type_id ................ : ' ||p_line_type_id);
    fnd_file.put_line(fnd_file.log, '');
    fnd_file.put_line(fnd_file.log, '');
    --
    oe_order_pub.process_order(p_api_version_number => 1.0
                              ,p_init_msg_list      => fnd_api.g_false
                              ,p_return_values      => fnd_api.g_false
                              ,p_action_commit      => fnd_api.g_false
                              ,x_return_status      => l_return_status
                              ,x_msg_count          => l_msg_count
                              ,x_msg_data           => l_msg_data
                              ,p_header_rec         => l_header_rec
                              ,p_line_tbl           => l_line_tbl
                              ,p_action_request_tbl => l_action_request_tbl
                               -- OUT PARAMETERS ,
                              ,x_header_rec             => l_header_rec_out
                              ,x_header_val_rec         => l_header_val_rec_out
                              ,x_header_adj_tbl         => l_header_adj_tbl_out
                              ,x_header_adj_val_tbl     => l_header_adj_val_tbl_out
                              ,x_header_price_att_tbl   => l_header_price_att_tbl_out
                              ,x_header_adj_att_tbl     => l_header_adj_att_tbl_out
                              ,x_header_adj_assoc_tbl   => l_header_adj_assoc_tbl_out
                              ,x_header_scredit_tbl     => l_header_scredit_tbl_out
                              ,x_header_scredit_val_tbl => l_header_scredit_val_tbl_out
                              ,x_line_tbl               => l_line_tbl_out
                              ,x_line_val_tbl           => l_line_val_tbl_out
                              ,x_line_adj_tbl           => l_line_adj_tbl_out
                              ,x_line_adj_val_tbl       => l_line_adj_val_tbl_out
                              ,x_line_price_att_tbl     => l_line_price_att_tbl_out
                              ,x_line_adj_att_tbl       => l_line_adj_att_tbl_out
                              ,x_line_adj_assoc_tbl     => l_line_adj_assoc_tbl_out
                              ,x_line_scredit_tbl       => l_line_scredit_tbl_out
                              ,x_line_scredit_val_tbl   => l_line_scredit_val_tbl_out
                              ,x_lot_serial_tbl         => l_lot_serial_tbl_out
                              ,x_lot_serial_val_tbl     => l_lot_serial_val_tbl_out
                              ,x_action_request_tbl     => l_action_request_tbl_out);
    --
    fnd_file.put_line(fnd_file.log, ' ');
    fnd_file.put_line(fnd_file.log, 'l_line_tbl(l_count).unit_list_price ......... : ' || l_line_tbl_out(1).unit_list_price);
    fnd_file.put_line(fnd_file.log, ' ');
    FOR i IN 1 .. l_msg_count LOOP
      --
      oe_msg_pub.get(p_msg_index     => i
                    ,p_encoded       => fnd_api.g_false
                    ,p_data          => l_msg_data
                    ,p_msg_index_out => l_msg_index_out);
    END LOOP;
    -- Check the return status
    IF l_return_status = fnd_api.g_ret_sts_success THEN
      --
      x_return_status := 'S';
      p_line_id       := l_line_tbl_out(1).line_id;
      x_message       := NULL;
      --
      COMMIT;
    ELSE
      --
      IF l_msg_count > 0 THEN
        l_msg_return := 'OE_ORDER_PUB.PROCESS_ORDER ';
        FOR l_index IN 1 .. l_msg_count LOOP
          --
          l_msg_return := l_msg_return || ' - ' ||oe_msg_pub.get(p_msg_index => l_index,p_encoded   => 'F');
        END LOOP;
        --
      ELSE
        l_msg_return := l_msg_data;
      END IF;
      --
      x_message       := l_msg_return;
      x_return_status := 'E';
      --
    END IF;
    --
  EXCEPTION
    WHEN OTHERS THEN
      x_return_status := 'E';
      x_message       := '   Erro ao criar o pedido para a Ordem: ' ||p_header_id || ' | ' || l_msg_return || '-' ||SQLERRM;
  END p_add_lines;
  --
  FUNCTION f_email_get_address(addr_list IN OUT VARCHAR2) RETURN VARCHAR2
  
   IS
    addr VARCHAR2(256);
    i    PLS_INTEGER;
  
    FUNCTION lookup_unquoted_char(str  IN VARCHAR2
                                 ,chrs IN VARCHAR2) RETURN PLS_INTEGER AS
      c            VARCHAR2(5);
      i            PLS_INTEGER;
      len          PLS_INTEGER;
      inside_quote BOOLEAN;
    BEGIN
      inside_quote := FALSE;
      i            := 1;
      len          := length(str);
    
      WHILE (i <= len) LOOP
        c := substr(str, i, 1);
        IF (inside_quote) THEN
          IF (c = '"') THEN
            inside_quote := FALSE;
          ELSIF (c = '\') THEN
            i := i + 1; -- Skip the quote character
          END IF;
        END IF;
        IF (c = '"') THEN
          inside_quote := TRUE;
        END IF;
        IF (instr(chrs, c) >= 1) THEN
          RETURN i;
        END IF;
        i := i + 1;
      END LOOP;
      RETURN 0;
    END lookup_unquoted_char;
  
  BEGIN
    addr_list := ltrim(addr_list);
    dbms_output.put_line(addr_list);
    i := lookup_unquoted_char(addr_list, ',;');
  
    IF (i >= 1) THEN
      addr      := substr(addr_list, 1, i - 1);
      addr_list := substr(addr_list, i + 1);
    ELSE
      addr      := addr_list;
      addr_list := '';
    END IF;
  
    i := lookup_unquoted_char(addr, '<');
  
    IF (i >= 1) THEN
      addr := substr(addr, i + 1);
      i    := instr(addr, '>');
    
      IF (i >= 1) THEN
        addr := substr(addr, 1, i - 1);
      END IF;
    END IF;
  
    dbms_output.put_line(addr);
    RETURN addr;
  END f_email_get_address;
  --
  --
  PROCEDURE p_send_email(p_from_email       IN VARCHAR2
                        ,p_to_email         IN VARCHAR2
                        ,p_subject          IN VARCHAR2
                        ,p_message          IN VARCHAR2
                        ,p_directory        IN VARCHAR2 DEFAULT NULL
                        ,p_filename         IN VARCHAR2 DEFAULT NULL
                        ,p_smtp_server_port IN NUMBER DEFAULT '25') IS
    ----
    v_msg         VARCHAR2(32000);
    src_file      BFILE;
    i             INTEGER := 1;
    v_raw         RAW(57);
    v_length      INTEGER := 0;
    v_buffer_size INTEGER := 57;
    v_mailconn    utl_smtp.connection;
    gc_crlf       VARCHAR2(4) := chr(13) || chr(10);
    gc_lf         VARCHAR2(4) := chr(10);
    v_smtp_server VARCHAR2(30);
  
    boundary            CONSTANT VARCHAR2(256) := '7D81B75CCC90D2974F7A1CBD';
    first_boundary      CONSTANT VARCHAR2(256) := '--' || boundary ||utl_tcp.crlf;
    last_boundary       CONSTANT VARCHAR2(256) := '--' || boundary || '--' ||utl_tcp.crlf;
    multipart_mime_type CONSTANT VARCHAR2(256) := 'multipart/mixed; boundary="' ||boundary || '"';
    l_to_email VARCHAR2(500) := p_to_email;
    ----
  BEGIN
    BEGIN
      SELECT a.parameter_value
      INTO   v_smtp_server
      FROM   apps.fnd_svc_comp_param_vals a
            ,apps.fnd_svc_components      b
            ,apps.fnd_svc_comp_params_b   c
      WHERE  b.component_id = a.component_id
      AND    b.component_type = c.component_type
      AND    c.parameter_id = a.parameter_id
      AND    b.component_name LIKE '%Mailer%'
      AND    c.parameter_name = 'OUTBOUND_SERVER'
      AND    c.encrypted_flag = 'N';
    EXCEPTION
      WHEN no_data_found THEN
        NULL;
      WHEN OTHERS THEN
        NULL;
    END;
    ---
    v_mailconn := utl_smtp.open_connection(v_smtp_server,p_smtp_server_port);
    utl_smtp.helo(v_mailconn, v_smtp_server);
    utl_smtp.mail(v_mailconn, p_from_email);
    --
    WHILE (l_to_email IS NOT NULL) LOOP
      utl_smtp.rcpt(v_mailconn, f_email_get_address(l_to_email));
    END LOOP;
    --
    utl_smtp.open_data(v_mailconn);
    utl_smtp.write_data(v_mailconn,'From: ' || p_from_email || utl_tcp.crlf);
    utl_smtp.write_data(v_mailconn, 'To: ' || l_to_email || utl_tcp.crlf);
    utl_smtp.write_data(v_mailconn,'Subject: ' || p_subject || utl_tcp.crlf);
    --
    utl_smtp.write_data(v_mailconn, 'MIME-Version: 1.0' || utl_tcp.crlf);
    utl_smtp.write_data(v_mailconn,'Content-Type: multipart/mixed; boundary="' ||boundary || '"' || utl_tcp.crlf);
    utl_smtp.write_data(v_mailconn, utl_tcp.crlf);
  
    utl_smtp.write_data(v_mailconn, first_boundary);
    utl_smtp.write_data(v_mailconn,'Content-Type: text/plain;' || utl_tcp.crlf);
    utl_smtp.write_data(v_mailconn, ' charset=US-ASCII' || utl_tcp.crlf);
    utl_smtp.write_data(v_mailconn, utl_tcp.crlf);
    utl_smtp.write_data(v_mailconn, p_message || utl_tcp.crlf);
  
    IF p_directory IS NOT NULL AND p_filename IS NOT NULL THEN
      utl_smtp.write_data(v_mailconn, first_boundary);
      utl_smtp.write_data(v_mailconn,'Content-Type' || ': ' || 'application/pdf' ||utl_tcp.crlf);
      utl_smtp.write_data(v_mailconn,'Content-Disposition: attachment; ' ||utl_tcp.crlf);
      utl_smtp.write_data(v_mailconn,' filename="' || p_filename || '"' ||utl_tcp.crlf);
      utl_smtp.write_data(v_mailconn,'Content-Transfer-Encoding: base64' ||utl_tcp.crlf);
      utl_smtp.write_data(v_mailconn, utl_tcp.crlf);
      src_file := bfilename(p_directory, p_filename);
      dbms_lob.fileopen(src_file, dbms_lob.file_readonly);
      v_length := dbms_lob.getlength(src_file);
      -- 
      WHILE i < v_length LOOP
        dbms_lob.read(src_file, v_buffer_size, i, v_raw);
        utl_smtp.write_raw_data(v_mailconn
                               ,utl_encode.base64_encode(v_raw));
        i := i + v_buffer_size;
      END LOOP;
      --
    END IF;
    --
    utl_smtp.write_data(v_mailconn, utl_tcp.crlf);
    utl_smtp.write_data(v_mailconn, last_boundary);
    utl_smtp.write_data(v_mailconn, utl_tcp.crlf);
    IF p_directory IS NOT NULL AND p_filename IS NOT NULL THEN
      dbms_lob.fileclose(src_file);
    END IF;
    utl_smtp.close_data(v_mailconn);
    utl_smtp.quit(v_mailconn);
  EXCEPTION
    WHEN OTHERS THEN
      utl_smtp.quit(v_mailconn);
      fnd_file.put_line(fnd_file.log, SQLERRM);
  END p_send_email;
  --
  --
  FUNCTION format_br_mask_f(p_value IN NUMBER
                           ,p_mask  IN VARCHAR2) RETURN VARCHAR2 IS
    l_vreturn      VARCHAR2(20);
    l_ndecimal_qty NUMBER;
    l_nmask_qty    NUMBER;
    l_vmask        VARCHAR2(100);
  BEGIN
    l_vmask     := p_mask;
    l_nmask_qty := length(substr(l_vmask, instr(l_vmask, '.') + 1));
  
    IF l_nmask_qty > 3 THEN
      IF instr(to_char(translate(p_value, ',', '.')), '.') = 0 THEN
        l_ndecimal_qty := 0;
      ELSE
        l_ndecimal_qty := length(substr(to_char(translate(p_value, ',', '.')),instr(to_char(translate(p_value,',','.')),'.') + 1));
      END IF;
      IF l_ndecimal_qty <= 2 THEN
        l_ndecimal_qty := 2;
      END IF;
      l_vmask := substr(l_vmask, 1, instr(l_vmask, '.')) ||
                 rpad('0', l_ndecimal_qty, '0');
    END IF;
    --
    l_vreturn := lpad(to_char(p_value, l_vmask), 20, ' ');
    l_vreturn := REPLACE(l_vreturn, ',', '@');
    l_vreturn := REPLACE(l_vreturn, '.', ',');
    l_vreturn := REPLACE(l_vreturn, '@', '.');
    --
    RETURN(TRIM(l_vreturn));
    --
  END format_br_mask_f;
  --
  --
  FUNCTION conv_spc_chr(p_char IN VARCHAR2) RETURN VARCHAR2 IS
    l_vchar VARCHAR2(4000) := NULL;
  BEGIN
    --
    l_vchar := p_char;
    --
    l_vchar := REPLACE(l_vchar, '', ' ');
    l_vchar := REPLACE(l_vchar, '<', ' ');
    l_vchar := REPLACE(l_vchar, '>', ' ');
    l_vchar := REPLACE(l_vchar, '"', ' ');
    l_vchar := REPLACE(l_vchar, '”', ' ');
    l_vchar := REPLACE(l_vchar, '½', '1/2');
    l_vchar := REPLACE(l_vchar, '²', '2');
    l_vchar := REPLACE(l_vchar, '’’', ' ');
    l_vchar := REPLACE(l_vchar, '''', ' ');
    l_vchar := REPLACE(l_vchar, 'º', 'o');
    l_vchar := REPLACE(l_vchar, 'Ø', 'o');
    l_vchar := REPLACE(l_vchar, '%', ' ');
    l_vchar := REPLACE(l_vchar, '#', ' ');
    l_vchar := REPLACE(l_vchar, 'Ç', 'C');
    l_vchar := REPLACE(l_vchar, 'ç', 'c');
    l_vchar := REPLACE(l_vchar, 'Ý', 'Y');
    l_vchar := translate(l_vchar, ' áàãâÁÀÃÂ', ' aaaaAAAA');
    l_vchar := translate(l_vchar, ' éèêÉÈÊ', ' eeeEEE');
    l_vchar := translate(l_vchar, ' íìÍÌ', ' iiII');
    l_vchar := translate(l_vchar, ' óôõÓÔÕ', ' oooOOO');
    l_vchar := translate(l_vchar, ' úùÚÙ', ' uuUU');
    l_vchar := translate(l_vchar, ' ñÑ', ' nN');
    l_vchar := REPLACE(l_vchar, chr(170), 'a');
    l_vchar := REPLACE(l_vchar, chr(186), 'o');
    l_vchar := REPLACE(l_vchar, chr(49834), 'a');
    l_vchar := REPLACE(l_vchar, chr(14844051), '-');
    l_vchar := REPLACE(l_vchar, chr(39), ' '); -- 
    l_vchar := REPLACE(l_vchar, chr(38), ' '); --
    l_vchar := REPLACE(l_vchar, chr(13), ' ');
    l_vchar := REPLACE(l_vchar, chr(10), ' ');
    --
    RETURN(l_vchar);
  END conv_spc_chr;
  --
--
END xxppg_1081_net_price_pkg;
----Indicativo de Final de Arquivo. Nao deve ser removido.
/
EXIT
