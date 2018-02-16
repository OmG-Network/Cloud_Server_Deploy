#!/bin/bash

## Cloud Deploy Tool CSGO Server INST
## 2018-02-16


############################################## Start of Script ##############################################
function check_root ()
{
 if [ ! $(whoami) == "root" ]; then
        echo "Start as root an try again"
        exit 1
fi
}

function check_distro ()
{
    if [ -x /usr/bin/lsb_release ]; then
        if [ !$DEPLOY_LSB == "Ubuntu" ] || [ !$DEPLOY_LSB == "Debian" ]; then
          echo "Your distro isn´t supported"
         exit 1
        fi
    else
        echo "Your distro isn´t supported."
        exit 1
    fi
}

function inst_req ()
{
    # System Update
apt update && apt upgrade -y
    # Install Req via APT
apt install -y curl debconf libc6 lib32gcc1 curl screen wget
    # Create User
    if [ ! -d $DEPLOY_server_inst_dir ]; then
        mkdir $DEPLOY_server_inst_dir
    fi
    if [[ ! $(getent passwd $DEPLOY_install_user_name) = *"$DEPLOY_install_user_name"* ]]; then
        useradd $DEPLOY_install_user_name -d $DEPLOY_server_inst_dir --shell /usr/sbin/nologin
    fi
    # Download SteamCMD
 if [ -d $DEPLOY_steamCMD ]; then
         curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf - -C $DEPLOY_steamCMD >/dev/null 2>&1
    else
        mkdir $DEPLOY_steamCMD
        curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf - -C $DEPLOY_steamCMD >/dev/null 2>&1
 fi
    # Set User rights
    chown -cR $DEPLOY_install_user_name $DEPLOY_steamCMD && chmod -cR 770 $DEPLOY_install_user_name $DEPLOY_steamCMD
    # Clean up
apt-get autoclean -y

}

function inst_vanilla_cs_srv ()
{
    tmp_dir="$(su $DEPLOY_install_user_name --shell /bin/sh -c "mktemp -d")"
    # Download CSGO Server
    echo "### DOWNLOADING CSGO Server ###"
    su $DEPLOY_install_user_name --shell /bin/sh -c "$DEPLOY_steamCMD/steamcmd.sh +@sSteamCmdForcePlatformType linux +login anonymous +force_install_dir $tmp_dir/ +app_update 740 validate +quit" > $tmp_dir/log
    # Check install status
    if [[ $(cat $tmp_dir/log) = *"Success! App '740' fully installed."* ]] ; then
        echo "CSGO Download success"
    else
        rm -rf $tmp_dir
        echo "CSGO Download failed retry..."
         COUNTER=$((COUNTER +1))
             if [ $DEPLOY_retry == $COUNTER ]; then
               echo "CSGO Download failed after $DEPLOY_retry attempts exiting..."
            exit 1
             fi 
       inst_vanilla_cs_srv
    fi
    # Move Folder
    mv $tmp_dir/* $DEPLOY_server_inst_dir
    # Clean up
    rm -rf $tmp_dir
}

function csgo_srv_init ()
{
# Inst Metamod & Sourcemod
# Metamod
echo "### INST Metamod ###"
curl -sqL $DEPLOY_metamod | tar zxvf - -C $DEPLOY_server_inst_dir/csgo/
# Sourcemod
echo "### INST Sourcemod ###"
curl -sqL $DEPLOY_sourcemod | tar zxvf - -C $DEPLOY_server_inst_dir/csgo/
# Update Config
# Create Server CFG
echo "### UPDATE Server CFG ###"
if [ -a $DEPLOY_server_inst_dir/csgo/cfg/server.cfg ]; then
    rm $DEPLOY_server_inst_dir/csgo/cfg/server.cfg
fi
echo // Base Configuration >> $DEPLOY_server_inst_dir/csgo/cfg/server.cfg
echo hostname $DEPLOY_hostname >> $DEPLOY_server_inst_dir/csgo/cfg/server.cfg
echo sv_password $DEPLOY_sv_password >> $DEPLOY_server_inst_dir/csgo/cfg/server.cfg
echo rcon_password "$DEPLOY_rcon_password" >> $DEPLOY_server_inst_dir/csgo/cfg/server.cfg
echo  >> $DEPLOY_server_inst_dir/csgo/cfg/server.cfg
echo // Network Configuration >> $DEPLOY_server_inst_dir/csgo/cfg/server.cfg
echo sv_loadingurl "https://aimb0t.husos.wtf" >> $DEPLOY_server_inst_dir/csgo/cfg/server.cfg
echo sv_downloadurl '"http://fastdl.omg-network.de/csgo/csgo/"' >> $DEPLOY_server_inst_dir/csgo/cfg/server.cfg
echo sv_allowdownload 0 >> $DEPLOY_server_inst_dir/csgo/cfg/server.cfg
echo sv_allowupload 0 >> $DEPLOY_server_inst_dir/csgo/cfg/server.cfg
echo net_maxfilesize 64 >> $DEPLOY_server_inst_dir/csgo/cfg/server.cfg
echo sv_setsteamaccount $DEPLOY_sv_setsteamaccount >> $DEPLOY_server_inst_dir/csgo/cfg/server.cfg
echo  >> $DEPLOY_server_inst_dir/csgo/cfg/server.cfg
echo sv_maxrate 0 >> $DEPLOY_server_inst_dir/csgo/cfg/server.cfg
echo sv_minrate 196608 >> $DEPLOY_server_inst_dir/csgo/cfg/server.cfg
echo sv_maxcmdrate 128 >> $DEPLOY_server_inst_dir/csgo/cfg/server.cfg
echo sv_mincmdrate 128 >> $DEPLOY_server_inst_dir/csgo/cfg/server.cfg
echo sv_maxupdaterate 128 >> $DEPLOY_server_inst_dir/csgo/cfg/server.cfg
echo sv_minupdaterate 128 >> $DEPLOY_server_inst_dir/csgo/cfg/server.cfg
echo  >> $DEPLOY_server_inst_dir/csgo/cfg/server.cfg
echo // Logging Configuration >> $DEPLOY_server_inst_dir/csgo/cfg/server.cfg
echo log on >> $DEPLOY_server_inst_dir/csgo/cfg/server.cfg
echo sv_logbans 0 >> $DEPLOY_server_inst_dir/csgo/cfg/server.cfg
echo sv_logecho 0 >> $DEPLOY_server_inst_dir/csgo/cfg/server.cfg
echo sv_logfile 1 >> $DEPLOY_server_inst_dir/csgo/cfg/server.cfg
echo sv_log_onefile 0 >> $DEPLOY_server_inst_dir/csgo/cfg/server.cfg
echo  >> $DEPLOY_server_inst_dir/csgo/cfg/server.cfg
echo mp_match_end_restart 1 >> $DEPLOY_server_inst_dir/csgo/cfg/server.cfg

# Add ESL Config files
echo "### ADD ESL Config ###"
curl -sqL $DEPLOY_esl_cfg | tar xf - -C $DEPLOY_server_inst_dir/csgo/cfg/
}

function csgo_1vs1 ()
{
# Download Maps
echo "### DOWNLOADING CSGO Maps ###"
wget -P $DEPLOY_server_inst_dir/csgo/maps "http://fastdl.omg-network.de/csgo/csgo/maps/aim_redline.bsp"
wget -P $DEPLOY_server_inst_dir/csgo/maps "http://fastdl.omg-network.de/csgo/csgo/maps/aim_dust2.bsp"
wget -P $DEPLOY_server_inst_dir/csgo/maps "http://fastdl.omg-network.de/csgo/csgo/maps/aim_map_classic.bsp"
wget -P $DEPLOY_server_inst_dir/csgo/maps "http://fastdl.omg-network.de/csgo/csgo/maps/aim_dust_go.bsp"
wget -P $DEPLOY_server_inst_dir/csgo/maps "http://fastdl.omg-network.de/csgo/csgo/maps/aim_map.bsp"
wget -P $DEPLOY_server_inst_dir/csgo/maps "http://fastdl.omg-network.de/csgo/csgo/maps/aim_prac_ak47.bsp"
# Set permissions
echo "### SET Permissions for $DEPLOY_install_user_name"
chown -cR $DEPLOY_install_user_name $DEPLOY_server_inst_dir && chmod -cR 770 $DEPLOY_server_inst_dir
chmod +x $DEPLOY_server_inst_dir/srcds_run
# Starting CSGO Server
echo "### STARTING CSGO Server ###"
screen -dmS CS_1vs1 su $DEPLOY_install_user_name --shell /bin/sh -c "$DEPLOY_server_inst_dir/srcds_run -game csgo -console -autoupdate -usercon -tickrate 128 -maxplayers 10 -nobots -pingboost 3 -ip 0.0.0.0 +game_type 0 +game_mode 0 +map aim_redline +exec server.cfg"
}

function csgo_diegel ()
{
# Downloading aim_deagle7k
wget -P $DEPLOY_server_inst_dir/csgo/maps "http://fastdl.omg-network.de/csgo/csgo/maps/aim_deagle7k.bsp"
# Downloading only HS Plugin
wget -P $DEPLOY_server_inst_dir/csgo/addons/sourcemod/plugins "https://raw.githubusercontent.com/Bara/OnlyHS/master/addons/sourcemod/plugins/onlyhs.smx"
# Set permissions
echo "### SET Permissions for $DEPLOY_install_user_name"
chown -cR $DEPLOY_install_user_name $DEPLOY_server_inst_dir && chmod -cR 770 $DEPLOY_server_inst_dir
chmod +x $DEPLOY_server_inst_dir/srcds_run
# Starting CSGO Server
echo "### STARTING CSGO Server ###"
screen -dmS CS_Diegle su $DEPLOY_install_user_name --shell /bin/sh -c "$DEPLOY_server_inst_dir/srcds_run -game csgo -console -autoupdate -usercon -tickrate 128 -maxplayers 10 -nobots -pingboost 3 -ip 0.0.0.0 +game_type 0 +game_mode 1 +map aim_deagle7k +exec server.cfg"

}

function csgo_mm ()
{
# Set permissions
echo "### SET Permissions for $DEPLOY_install_user_name"
chown -cR $DEPLOY_install_user_name $DEPLOY_server_inst_dir && chmod -cR 770 $DEPLOY_server_inst_dir
chmod +x $DEPLOY_server_inst_dir/srcds_run
# Starting CSGO Server
echo "### STARTING CSGO Server ###"
screen -dmS CS_MM su $DEPLOY_install_user_name --shell /bin/sh -c "$DEPLOY_server_inst_dir/srcds_run -game csgo -console -autoupdate -usercon -tickrate 128 -maxplayers 10 -nobots -pingboost 3 -ip 0.0.0.0 +game_type 0 +game_mode 1 +map de_cbble +exec server.cfg"
}
############################################## End of Functions ##############################################

# Main Starts here....
# Call Functions
check_root
check_distro
inst_req
inst_vanilla_cs_srv
csgo_srv_init

case "$DEPLOY_GAME_TYPE" in
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