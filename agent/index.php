<?php

if(!isset($_POST['key'])){
    die("<h1>Hier gibts nix zu sehen, bitte gehen sie weiter.</h1>");
}

if ($_POST['key'] != "AUTHKEY"){
    die("ERROR: Falscher Key !");
}

switch ($_POST['game']){
    case "csgo":
    // Game Settings
    $gtype = $_POST['game_type'];
    $ghostname = $_POST['hostname'];
    $gsvpass = $_POST['sv_password'];
    $grcon = $_POST['rcon_password'];
    $gtoken = $_POST['sv_setsteamaccount'];
    
    // Start Download
    exec('/opt/install_csgo.sh -a '.$gtype.' -b "'.$ghostname.'" -c "'.$gsvpass.'" -d "'.$grcon.'" -e "'.$gtoken.'" >/dev/null 2>&1 &');
    echo "Installation Started";

}

?>