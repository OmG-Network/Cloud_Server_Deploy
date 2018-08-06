<?php

if(!isset($_POST['key'])){
    die("<h1>Hier gibts nix zu sehen, bitte gehen sie weiter.</h1>");
}

if ($_POST['key'] != "AUTHKEY"){
    die("ERROR: Falscher Key !");
}

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