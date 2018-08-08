#!/bin/bash

#
## Server Web Deploy Tool
## Silent CSGO Server
## 2018-07-27
#

if [ $# == 0 ] ; then echo "Failed parsing options." >&2 ; exit 1 ; fi

# Set Default Settings
# Download options
metamod="https://mms.alliedmods.net/mmsdrop/1.10/mmsource-1.10.7-git961-linux.tar.gz"
sourcemod="https://sm.alliedmods.net/smdrop/1.8/sourcemod-1.8.0-git6040-linux.tar.gz"
esl_cfg="http://fastdl.omg-network.de/csgo/esl.tar"
# Install options
steamCMD=/opt/steamcmd
server_inst_dir=/opt/server
retry=5
LSB=$($(which lsb_release) -si)
WAN_IP=$($(which curl) ipinfo.io/ip >/dev/null 2>&1)

# Matching Table
#
#  GAME_TYPE = a
#  Hostname = b
#  sv_password = c
#  rcon_password = d
#  sv_setsteamaccount = e
#

while getopts a:b:c:d:e: opt
do
   case $opt in
       a) GAME_TYPE=$OPTARG;;
       b) hostname="$OPTARG";;
       c) sv_password="$OPTARG";;
       d) rcon_password="$OPTARG";;
       e) sv_setsteamaccount="$OPTARG";;
   esac
done


############################################## Start of Script ##############################################

function inst_req ()
{
    # Download SteamCMD
    if [ -d $steamCMD ]; then
         curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf - -C $steamCMD >/dev/null 2>&1
    else
        mkdir $steamCMD
        curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf - -C $steamCMD >/dev/null 2>&1
 fi
}

function inst_vanilla_cs_srv ()
{
    if [ ! -d $server_inst_dir ]; then
        mkdir $server_inst_dir
    fi
    # Download CSGO Server
    echo "### DOWNLOADING CSGO Server ###"
    #curl -sqL "http://fastdl.omg-network.de/csgo/csgo.tar.gz" | tar zxvf - -C $server_inst_dir >/dev/null 2>&1
    $steamCMD/steamcmd.sh +@sSteamCmdForcePlatformType linux +login anonymous +force_install_dir $server_inst_dir/ +app_update 740 validate +quit > $server_inst_dir/log
    # Check install status
    if [[ $(cat $server_inst_dir/log) = *"Success! App '740' fully installed."* ]] ; then
        echo "CSGO Download success"
    else
        rm -rf $server_inst_dir
        echo "CSGO Download failed retry..."
         COUNTER=$((COUNTER +1))
             if [ $retry == $COUNTER ]; then
               echo "CSGO Download failed after $retry attempts exiting..."
            exit 1
             fi 
       inst_vanilla_cs_srv
    fi
}

function csgo_srv_init ()
{
# Inst Metamod & Sourcemod
# Metamod
echo "### INST Metamod ###"
curl -sqL $metamod | tar zxvf - -C $server_inst_dir/csgo/ >/dev/null 2>&1
# Sourcemod
echo "### INST Sourcemod ###"
curl -sqL $sourcemod | tar zxvf - -C $server_inst_dir/csgo/ >/dev/null 2>&1
# Update Config
# Create Server CFG
echo "### UPDATE Server CFG ###"
if [ -a $server_inst_dir/csgo/cfg/server.cfg ]; then
    rm $server_inst_dir/csgo/cfg/server.cfg
fi
echo // Base Configuration >> $server_inst_dir/csgo/cfg/server.cfg
echo hostname $hostname >> $server_inst_dir/csgo/cfg/server.cfg
echo sv_password $sv_password >> $server_inst_dir/csgo/cfg/server.cfg
echo rcon_password "$rcon_password" >> $server_inst_dir/csgo/cfg/server.cfg
echo  >> $server_inst_dir/csgo/cfg/server.cfg
echo // Network Configuration >> $server_inst_dir/csgo/cfg/server.cfg
echo sv_downloadurl "http://fastdl.omg-network.de/csgo/" >> $server_inst_dir/csgo/cfg/server.cfg
echo sv_allowdownload 0 >> $server_inst_dir/csgo/cfg/server.cfg
echo sv_allowupload 0 >> $server_inst_dir/csgo/cfg/server.cfg
echo net_maxfilesize 64 >> $server_inst_dir/csgo/cfg/server.cfg
echo sv_setsteamaccount $sv_setsteamaccount >> $server_inst_dir/csgo/cfg/server.cfg
echo  >> $server_inst_dir/csgo/cfg/server.cfg
echo sv_maxrate 0 >> $server_inst_dir/csgo/cfg/server.cfg
echo sv_minrate 196608 >> $server_inst_dir/csgo/cfg/server.cfg
echo sv_maxcmdrate 128 >> $server_inst_dir/csgo/cfg/server.cfg
echo sv_mincmdrate 128 >> $server_inst_dir/csgo/cfg/server.cfg
echo sv_maxupdaterate 128 >> $server_inst_dir/csgo/cfg/server.cfg
echo sv_minupdaterate 128 >> $server_inst_dir/csgo/cfg/server.cfg
echo  >> $server_inst_dir/csgo/cfg/server.cfg
echo // Logging Configuration >> $server_inst_dir/csgo/cfg/server.cfg
echo log on >> $server_inst_dir/csgo/cfg/server.cfg
echo sv_logbans 0 >> $server_inst_dir/csgo/cfg/server.cfg
echo sv_logecho 0 >> $server_inst_dir/csgo/cfg/server.cfg
echo sv_logfile 1 >> $server_inst_dir/csgo/cfg/server.cfg
echo sv_log_onefile 0 >> $server_inst_dir/csgo/cfg/server.cfg
echo  >> $server_inst_dir/csgo/cfg/server.cfg
echo mp_match_end_restart 1 >> $server_inst_dir/csgo/cfg/server.cfg

# Add ESL Config files
echo "### ADD ESL Config ###"
curl -sqL $esl_cfg | tar xf - -C $server_inst_dir/csgo/cfg/ >/dev/null 2>&1
}

function csgo_1vs1 ()
{
# Download Maps
echo "### DOWNLOADING CSGO Maps ###"
wget -P $server_inst_dir/csgo/maps "http://fastdl.omg-network.de/csgo/csgo/maps/aim_redline.bsp" >/dev/null 2>&1
wget -P $server_inst_dir/csgo/maps "http://fastdl.omg-network.de/csgo/csgo/maps/aim_dust2.bsp" >/dev/null 2>&1
wget -P $server_inst_dir/csgo/maps "http://fastdl.omg-network.de/csgo/csgo/maps/aim_map_classic.bsp" >/dev/null 2>&1
wget -P $server_inst_dir/csgo/maps "http://fastdl.omg-network.de/csgo/csgo/maps/aim_dust_go.bsp" >/dev/null 2>&1
wget -P $server_inst_dir/csgo/maps "http://fastdl.omg-network.de/csgo/csgo/maps/aim_map.bsp" >/dev/null 2>&1
wget -P $server_inst_dir/csgo/maps "http://fastdl.omg-network.de/csgo/csgo/maps/aim_prac_ak47.bsp" >/dev/null 2>&1
# Starting CSGO Server
echo "### STARTING CSGO Server ###"
$server_inst_dir/srcds_run -game csgo -console -usercon -tickrate 128 -maxplayers 10 -nobots -ip 0.0.0.0 -pingboost 3 +game_type 0 +game_mode 0 +map aim_redline +exec server.cfg &
}

function csgo_diegel ()
{
# Downloading aim_deagle7k
wget -P $server_inst_dir/csgo/maps "http://fastdl.omg-network.de/csgo/csgo/maps/aim_deagle7k.bsp" >/dev/null 2>&1
# Downloading only HS Plugin
wget -P $server_inst_dir/csgo/addons/sourcemod/plugins "https://raw.githubusercontent.com/Bara/OnlyHS/master/addons/sourcemod/plugins/onlyhs.smx" >/dev/null 2>&1
# Starting CSGO Server
echo "### STARTING CSGO Server ###"
$server_inst_dir/srcds_run -game csgo -console -usercon -tickrate 128 -maxplayers 10 -nobots -ip 0.0.0.0 -pingboost 3 +game_type 0 +game_mode 1 +map aim_deagle7k +exec server.cfg &

}

function csgo_mm ()
{
# Starting CSGO Server
echo "### STARTING CSGO Server ###"
$server_inst_dir/srcds_run -game csgo -console -usercon -tickrate 128 -maxplayers 10 -nobots -ip 0.0.0.0 -pingboost 3 +game_type 0 +game_mode 1 +map de_cbble +exec server.cfg &
}
############################################## End of Functions ##############################################

# Main Starts here....
# Call Functions
inst_req
inst_vanilla_cs_srv
csgo_srv_init

case "$GAME_TYPE" in
    1vs1)
     csgo_1vs1
    ;;

    Diegel)
     csgo_diegel
    ;;

    MM)
     csgo_mm
    ;;

    *)
     echo "ERROR: Wrong GAME_TYPE exiting..."
    exit 1
esac

exit 0
