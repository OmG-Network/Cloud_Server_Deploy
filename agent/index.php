<?php

if(!isset($_POST['key'])){
    die("<h1>Hier gibts nix zu sehen, bitte gehen sie weiter.</h1>");
}

if ($_POST['key'] != "AUTHKEY"){
    die("ERROR: Falscher Key !");
}

function liveExecuteCommand($cmd)
{

    while (@ ob_end_flush()); // end all output buffers if any

    $proc = popen("$cmd 2>&1 ; echo Exit status : $?", 'r');

    $live_output     = "";
    $complete_output = "";

    while (!feof($proc))
    {
        $live_output     = fread($proc, 4096);
        $complete_output = $complete_output . $live_output;
        echo "$live_output";
        @ flush();
    }

    pclose($proc);

    // POST exit status
    preg_match('/[0-9]+$/', $complete_output, $matches);

    // return exit status and intended output
    return array (
                    'exit_status'  => intval($matches[0]),
                    'output'       => str_replace("Exit status : " . $matches[0], '', $complete_output)
                 );
}

switch ($_POST['GAME']){
    case "CSGO":
    // Game Settings
    $gtype = $_POST['game_type'];
    $ghostname = $_POST['hostname'];
    $gsvpass = $_POST['sv_password'];
    $grcon = $_POST['rcon_password'];
    $gtoken = $_POST['sv_setsteamaccount'];
    
    // Start Download
    liveExecuteCommand('/opt/install_csgo.sh -a '.$gtype.' -b '.$ghostname.' -c '.$gsvpass.' -d '.$grcon.' -e '.$gtoken.'');

}

?>