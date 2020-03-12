
select *
from   wf_item_attribute_values                            wiav
,    ( select sqaux.*
       from   wf_item_attribute_values                     sqaux
       where  sqaux.item_type                              =  'XX_RCAWF'
       and    sqaux.name                                   =  'ID_COMPUESTO'
       and    sqaux.text_value                            in( 'ALC8362846', 'ALC9392903', 'ALC2904'   , 'ALC5532909', 'ALC2910'
                                                            , 'ALC8112911', 'ALC2912'   , 'ALC9392901', 'ALC2902'   , 'ALC7102913'
                                                            , 'ALC2914'   , 'ALC9432907', 'ALC2908'   , 'ALC7892905', 'ALC2906'
                                                            , 'ALC8752915', 'ALC2916'   , 'ALC8862917', 'ALC2918'   , 'ALC8842919'
                                                            , 'ALC2920'   , 'ALC8782921', 'ALC2922'   , 'ALC8772923', 'ALC2924'
                                                            , 'ALC8902925', 'ALC2926'   , 'ALC8762927', 'ALC8932928', 'ALC2929'
                                                            , 'ALC9322930', 'ALC2931'   , 'ALC7092932', 'ALC9432933', 'ALC7102934'
                                                            , 'ALC9082935', 'RLC3383'   , 'RLC3382'
                                                            )
     )                                                     swiav
where  wiav.item_type                                      =  swiav.item_type
and    wiav.item_key                                       =  swiav.item_key
;



 
