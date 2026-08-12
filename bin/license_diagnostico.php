<?php
if (PHP_SAPI !== 'cli') { fwrite(STDERR, "Solo CLI\n"); exit(1); }
$config = require dirname(__DIR__).'/config.php';
require dirname(__DIR__).'/includes/LicenseManager.php';
LicenseManager::init($config);
function octmode($f){ $p=@fileperms($f); return $p===false?'?':substr(sprintf('%o',$p),-4); }
function own($f){
    $u=@fileowner($f); $g=@filegroup($f);
    $un=$u===false?'?':(function_exists('posix_getpwuid')?(posix_getpwuid($u)['name']??$u):$u);
    $gn=$g===false?'?':(function_exists('posix_getgrgid')?(posix_getgrgid($g)['name']??$g):$g);
    return $un.':'.$gn;
}
$state=LicenseManager::stateFile();
$client=LicenseManager::clientFile();
echo "Cybermatica Licence Diagnostic\n";
echo "Server URL: ".LicenseManager::serverUrl()."\n";
echo "OpenSSL PHP: ".(function_exists('openssl_verify')?'OK':'FALTA')."\n";
foreach (array('state'=>$state,'client'=>$client) as $n=>$f) {
    echo strtoupper($n).": $f\n";
    echo "  existe: ".(is_file($f)?'SI':'NO')."\n";
    if(is_file($f)){
        echo "  readable CLI: ".(is_readable($f)?'SI':'NO')."\n";
        echo "  owner: ".own($f)."\n";
        echo "  mode: ".octmode($f)."\n";
    }
}
$r=LicenseManager::loadState();
echo "Estado firmado válido: ".(!empty($r['valid'])?'SI':'NO')."\n";
echo "Status: ".($r['status']??'?')."\n";
echo "Error: ".($r['error']??'')."\n";
if (is_file($state)) {
    echo "SELinux:\n";
    passthru('ls -ldZ '.escapeshellarg(dirname($state)).' '.escapeshellarg($state).' 2>/dev/null');
}
