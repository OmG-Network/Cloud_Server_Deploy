<?php

if(!isset($_GET['key'])){
    die("<h1>Hier gibts nix zu sehen, bitte gehen sie weiter.</h1>");
}

if ($_GET['key'] != "1337"){
    die("ERROR: Falscher Key !");
}

function steamCMD(){
    shell_exec('mkdir /opt/steamcmd');
    shell_exec('curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf - -C /opt/steamcmd > /dev/null &');

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

    // get exit status
    preg_match('/[0-9]+$/', $complete_output, $matches);

    // return exit status and intended output
    return array (
                    'exit_status'  => intval($matches[0]),
                    'output'       => str_replace("Exit status : " . $matches[0], '', $complete_output)
                 );
}

switch ($_GET['GAME']){
    case "CSGO":
    // Game Settings
    $gtype = $_GET['game_type'];
    $ghostname = $_GET['hostname'];
    $gsvpass = $_GET['sv_password'];
    $grcon = $_GET['rcon_password'];
    $gtoken = $_GET['sv_setsteamaccount'];
    // FastDL Settings
    if (!isset($_GET['fastdl_user'])){
        $fuser = "fastdl";
    } else {
        $fuser = $_GET['fastdl_user'];
    }
    if (!isset($_GET['fastdl_passwd'])){
        $fpasswd = "fastdl";
    } else {
        $fpasswd = $_GET['fastdl_passwd'];
    }
    // Download Options
    if (!isset($_GET['metamod'])){
        $metamod = "https://mms.alliedmods.net/mmsdrop/1.10/mmsource-1.10.7-git961-linux.tar.gz";
    } else {
        $metamod = $_GET['metamod'];
    }
    if (!isset($_GET['sourcemod'])){
        $sourcemod = "https://sm.alliedmods.net/smdrop/1.8/sourcemod-1.8.0-git6040-linux.tar.gz";
    } else {
        $sourcemod = $_GET['sourcemod'];
    }
    if (!isset($_GET['esl_cfg'])){
        $esl_cfg = "http://fastdl.omg-network.de/csgo/esl.tar";
    } else {
        $esl_cfg = $_GET['esl_cfg'];
    }
    // Install Options
    $ipv4 = $_GET['ip'];

    // Start Download
    shell_exec('mkdir /opt/csgo');
    liveExecuteCommand('/opt/steamcmd/steamcmd.sh +@sSteamCmdForcePlatformType linux +login anonymous +force_install_dir /opt/csgo +app_update 740 validate +quit');

}

?>