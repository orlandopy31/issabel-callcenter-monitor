<?php
/**
 * Configuración de ejemplo segura.
 * Para una instalación nueva ejecute: sudo bash install.sh
 */
return array(
    'app' => array('name'=>'Panel Ejecutivo Issabel Call Center','company'=>'Call Center','timezone'=>'America/Asuncion','debug'=>false,'records_per_page'=>30,'max_export_rows'=>30000,'brand_color'=>'#0f766e'),
    'db' => array('host'=>'localhost','port'=>3306,'user'=>'ccpanel','pass'=>'CAMBIAR','charset'=>'utf8mb4','call_center'=>'call_center','cdr'=>'asteriskcdrdb','asterisk'=>'asterisk','panel'=>'callcenter_panel'),
    'recordings' => array('dirs'=>array('/var/spool/asterisk/monitor','/var/spool/asterisk/monitoring'),'allowed_extensions'=>array('wav','WAV','wav49','WAV49','gsm','mp3','ogg','sln','ulaw','alaw'),'search_depth'=>6,'max_scan_files'=>50000),
    'ami' => array('enabled'=>true,'host'=>'127.0.0.1','port'=>5038,'username'=>'ccpanel_monitor','secret'=>'CAMBIAR','timeout'=>1.5,'cache_ttl'=>8,'allowed_commands'=>array('core show channels concise')),
    'supervision' => array('enabled'=>true,'allowed_supervisor_techs'=>array('PJSIP','SIP','IAX2','LOCAL'),'default_supervisor_tech'=>'PJSIP','originate_timeout_ms'=>7000,'refresh_seconds'=>15,'quiet'=>true,'spy_options_listen'=>'q','spy_options_whisper'=>'qw','spy_options_barge'=>'qB','local_context'=>'from-internal','target_strategy'=>'extension','audit_file'=>__DIR__.'/cache/supervision_audit.log'),
    'auth' => array('username'=>'','password'=>'','session_name'=>'ISSABEL_CC_PANEL_PRO','public_devoluciones'=>false),
    'reports' => array('callback_search_days'=>30,'phone_match_last_digits'=>8,'extension_match_max_digits'=>6,'sla_seconds'=>20,'service_level_target_pct'=>80),
    'after_hours' => array('business_days'=>array(1,2,3,4,5),'start_time'=>'06:00:00','end_time'=>'20:00:00','guard_number'=>'','match_last_digits'=>8),
);
