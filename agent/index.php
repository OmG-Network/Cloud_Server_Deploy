<?php

if(!isset($_POST['key'])){
    die("<h1>Hier gibts nix zu sehen, bitte gehen sie weiter.</h1>");
}

if ($_POST['key'] != "AUTHKEY"){
    die("ERROR: Falscher Key !");
}
// Get Load
if(isset($_POST['status'])){
    switch ($_POST['status']){
        case "cpu":
        $exec_loads = sys_getloadavg();
        $exec_cores = trim(shell_exec("grep -P '^processor' /proc/cpuinfo|wc -l"));
        echo round($exec_loads[1]/($exec_cores + 1)*100, 0) . '%';
        exit();
        
        case "ram":
        $exec_free = explode("\n", trim(shell_exec('free')));
        $get_mem = preg_split("/[\s]+/", $exec_free[1]);
        echo number_format(round($get_mem[2]/1024/1024, 2), 2) . '/' . number_format(round($get_mem[1]/1024/1024, 2), 2);
        exit();
    }
}
// Start, Stop & Restart Game Server
if(isset($_POST['power'])){
    switch ($_POST['game']){
        case "csgo":
            switch($_POST['gtype']){
                case "1vs1":
                    switch($_POST['power']){
                        case "start":
                            exec('/opt/server/srcds_run -game csgo -console -usercon -tickrate 128 -maxplayers 10 -nobots -ip 0.0.0.0 -pingboost 3 +game_type 0 +game_mode 0 +map aim_redline +exec server.cfg >/dev/null 2>&1 &');
                            exit();
                        case "stop":
                            exec('killall -TERM srcds_linux >/dev/null 2>&1 &');
                            exit();
                        case "restart":
                            exec('killall -TERM srcds_linux >/dev/null 2>&1 &');
                            sleep(3);
                            exec('/opt/server/srcds_run -game csgo -console -usercon -tickrate 128 -maxplayers 10 -nobots -ip 0.0.0.0 -pingboost 3 +game_type 0 +game_mode 0 +map aim_redline +exec server.cfg >/dev/null 2>&1 &');
                            exit();
                        case "update":
                            exec('killall -TERM srcds_linux >/dev/null 2>&1 &');
                            sleep(3);
                            exec('/opt/steamcmd/steamcmd.sh +@sSteamCmdForcePlatformType linux +login anonymous +force_install_dir /opt/server +app_update 740 validate +quit >/dev/null 2>&1 && /opt/server/srcds_run -game csgo -console -usercon -tickrate 128 -maxplayers 10 -nobots -ip 0.0.0.0 -pingboost 3 +game_type 0 +game_mode 0 +map aim_redline +exec server.cfg >/dev/null 2>&1 &');
                            exit();
                        default:
                            die("ERROR: On 1vs1 Power Switch");
                    }
                case "Diegle":
                    switch($_POST['power']){
                        case "start":
                            exec('/opt/server/srcds_run -game csgo -console -usercon -tickrate 128 -maxplayers 10 -nobots -ip 0.0.0.0 -pingboost 3 +game_type 0 +game_mode 1 +map aim_deagle7k +exec server.cfg >/dev/null 2>&1 &');
                            exit();
                        case "stop":
                            exec('killall -TERM srcds_linux >/dev/null 2>&1 &');
                            exit();
                        case "restart":
                            exec('killall -TERM srcds_linux >/dev/null 2>&1 &');
                            sleep(3);
                            exec('/opt/server/srcds_run -game csgo -console -usercon -tickrate 128 -maxplayers 10 -nobots -ip 0.0.0.0 -pingboost 3 +game_type 0 +game_mode 1 +map aim_deagle7k +exec server.cfg >/dev/null 2>&1 &');
                            exit();
                        case "update":
                            exec('killall -TERM srcds_linux >/dev/null 2>&1 &');
                            sleep(3);
                            exec('/opt/steamcmd/steamcmd.sh +@sSteamCmdForcePlatformType linux +login anonymous +force_install_dir /opt/server +app_update 740 validate +quit >/dev/null 2>&1 && /opt/server/srcds_run -game csgo -console -usercon -tickrate 128 -maxplayers 10 -nobots -ip 0.0.0.0 -pingboost 3 +game_type 0 +game_mode 1 +map aim_deagle7k +exec server.cfg >/dev/null 2>&1 &');
                            exit();
                        default:
                            die("ERROR: On Deagle Power Switch");
                    }
                case "MM":
                    switch($_POST['power']){
                        case "start":
                            exec('/opt/server/srcds_run -game csgo -console -usercon -tickrate 128 -maxplayers 10 -nobots -ip 0.0.0.0 -pingboost 3 +game_type 0 +game_mode 1 +map de_cbble +exec server.cfg >/dev/null 2>&1 &');
                            exit();
                        case "stop":
                            exec('killall -TERM srcds_linux >/dev/null 2>&1 &');
                            exit();
                        case "restart":
                            exec('killall -TERM srcds_linux >/dev/null 2>&1 &');
                            sleep(3);
                            exec('/opt/server/srcds_run -game csgo -console -usercon -tickrate 128 -maxplayers 10 -nobots -ip 0.0.0.0 -pingboost 3 +game_type 0 +game_mode 1 +map de_cbble +exec server.cfg >/dev/null 2>&1 &');
                            exit();
                        case "update":
                            exec('killall -TERM srcds_linux >/dev/null 2>&1 &');
                            sleep(3);
                            exec('/opt/steamcmd/steamcmd.sh +@sSteamCmdForcePlatformType linux +login anonymous +force_install_dir /opt/server +app_update 740 validate +quit >/dev/null 2>&1 && /opt/server/srcds_run -game csgo -console -usercon -tickrate 128 -maxplayers 10 -nobots -ip 0.0.0.0 -pingboost 3 +game_type 0 +game_mode 1 +map de_cbble +exec server.cfg >/dev/null 2>&1 &');
                            exit();
                        default:
                            die("ERROR: On Deagle Power Switch");
                    }
                    
            }
        case "gm":
            break;
        case "l4d2":
            break;
        default:
            die("ERROR: In Power Game Switch");
    }
}
// Game Installaion
if(isset($_POST['install']) && $_POST['install'] == 1){
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
}
?>