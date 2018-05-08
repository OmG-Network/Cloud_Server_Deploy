#!/bin/bash

# Server Deploy Tool installer
## Garrys Mod Server [DEV Channel]
## 2018-05-08

if [ $# == 0 ] ; then echo "Failed parsing options." >&2 ; exit 1 ; fi

# Matching Table
#
#  GAME_TYPE = a
#  Hostname = b
#  sv_password = c
#  rcon_password = d
#  sv_setsteamaccount = e
#  fastdl_user = f
#  fastdl_passwd = g
#  php_max_upload = h
#  workshop_map_id = i
#  workshop_collection_id = j
#  workshop_api_key = k
#  steamCMD = l
#  server_inst_dir = m
#  install_user_name = n
#  retry = o
#  LSB = p
#  WAN_IP = q
#

while getopts a:b:c:d:e:f:g:h:i:j:k:l:m:n:o:p:q: opt
do
   case $opt in
       a) GAME_TYPE=$OPTARG;;
       b) hostname=$OPTARG;;
       c) sv_password=$OPTARG;;
       d) rcon_password=$OPTARG;;
       e) sv_setsteamaccount=$OPTARG;;
       f) fastdl_user=$OPTARG;;
       g) fastdl_passwd=$OPTARG;;
       h) php_max_upload=$OPTARG;;
       i) workshop_map_id=$OPTARG;;
       j) workshop_collection_id=$OPTARG;;
       k) workshop_api_key=$OPTARG;;
       l) steamCMD=$OPTARG;;
       m) server_inst_dir=$OPTARG;;
       n) install_user_name=$OPTARG;;
       o) retry=$OPTARG;;
       p) LSB=$OPTARG;;
       q) WAN_IP=$OPTARG;;

   esac
done

# FastDL Upload Portal Settings
fastdl_user=fastdl
fastdl_passwd=fastdl
php_max_upload=2048
# Textures Download
CSS_txt="http://fastdl.omg-network.de/gm/textures/targz/css_content_addon_apr2016.tar.gz"
CSS_maps="http://fastdl.omg-network.de/gm/textures/targz/css_maps_addon_apr2016.tar.gz"
dod_txt="http://fastdl.omg-network.de/gm/textures/targz/dod_content_addon_apr2016.tar.gz"
dod_maps="http://fastdl.omg-network.de/gm/textures/targz/dod_maps_addon_apr2016.tar.gz"
hl1_txt="http://fastdl.omg-network.de/gm/textures/targz/hl1_content_addon_apr2016.tar.gz"
hl2e_txt="http://fastdl.omg-network.de/gm/textures/targz/hl2e_content_addon_apr2016.tar.gz"
hl2e_maps="http://fastdl.omg-network.de/gm/textures/targz/hl2e_maps_addon_apr2016.tar.gz"
hl2ep1_txt="http://fastdl.omg-network.de/gm/textures/targz/hl2ep1_content_addon_apr2016.tar.gz"
portal2_txt="http://fastdl.omg-network.de/gm/textures/targz/portal2_content_addon_apr2016.tar.gz"
portal_txt="http://fastdl.omg-network.de/gm/textures/targz/portal_content_addon_apr2016.tar.gz"
# Install options
steamCMD=/opt/steamcmd
server_inst_dir=/opt/server
install_user_name=gm
retry=5

LSB=$(/usr/bin/lsb_release -si)
WAN_IP=$(curl ipinfo.io/ip)

############################################## Start of Script ##############################################
function check_root ()
{
 if [ ! $(id -u) == "0" ]; then
        echo "Start as root an try again"
        exit 1
fi
}

function check_distro ()
{
    if [ -x /usr/bin/lsb_release ]; then
        if [ !$LSB == "Ubuntu" ] || [ !$LSB == "Debian" ]; then
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
apt install -y curl debconf libc6 lib32gcc1 lib32stdc++6 screen curl wget apache2 php libapache2-mod-php
    # Create User
    if [ ! -d $server_inst_dir ]; then
        mkdir $server_inst_dir
    fi
    if [[ ! $(getent passwd $install_user_name) = *"$install_user_name"* ]]; then
        useradd $install_user_name -d $server_inst_dir --shell /usr/sbin/nologin
    fi
    # Download SteamCMD
 if [ -d $steamCMD ]; then
         curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf - -C $steamCMD >/dev/null 2>&1
    else
        mkdir $steamCMD
        curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf - -C $steamCMD >/dev/null 2>&1
 fi
    # Set User rights
    chown -cR $install_user_name $steamCMD && chmod -cR 770 $install_user_name $steamCMD
    # Clean up
apt-get autoclean -y

}

function inst_vanilla_gm_srv ()
{
    tmp_dir="$(su $install_user_name --shell /bin/sh -c "mktemp -d")"
    # Download GM Server
    echo "### DOWNLOADING GM Server ###"
    su $install_user_name --shell /bin/sh -c "$steamCMD/steamcmd.sh +@sSteamCmdForcePlatformType linux +login anonymous +force_install_dir $tmp_dir/ +app_update 4020 validate +quit" > $tmp_dir/log
    # Check install status
    if [[ $(cat $tmp_dir/log) = *"Success! App '4020' fully installed."* ]] ; then
        echo "GM Download success"
    else
        rm -rf $tmp_dir
        echo "GM Download failed retry..."
         COUNTER=$((COUNTER +1))
             if [ $retry == $COUNTER ]; then
               echo "GM Download failed after $retry attempts exiting..."
            exit 1
             fi 
       inst_vanilla_gm_srv
    fi
    # Move Folder
    mv $tmp_dir/* $server_inst_dir
    # Clean up
    rm -rf $tmp_dir
}

function init_fastdl ()
{
    # Create fastdl dir
    if [ ! -d /var/www/fastdl ]; then
        mkdir /var/www/fastdl
    fi
    if [ ! -d /var/www/fastdl/upload ]; then
        mkdir /var/www/fastdl/upload
    fi
    # Create fastdl apache2 config file
    if [ -a /etc/apache2/sites-available/fastdl.conf ]; then
        a2dissite fastdl.conf
        rm /etc/apache2/sites-available/fastdl.conf
    fi
    echo "<VirtualHost *:80>" >> /etc/apache2/sites-available/fastdl.conf
    echo "        ServerAdmin webmaster@localhost" >> /etc/apache2/sites-available/fastdl.conf
    echo "        DocumentRoot /var/www/fastdl" >> /etc/apache2/sites-available/fastdl.conf
    echo "        LogLevel info" >> /etc/apache2/sites-available/fastdl.conf
    echo "        <Directory /var/www/fastdl>" >> /etc/apache2/sites-available/fastdl.conf
    echo "                Options Indexes FollowSymLinks MultiViews" >> /etc/apache2/sites-available/fastdl.conf
    echo "                AllowOverride All" >> /etc/apache2/sites-available/fastdl.conf
    echo "                Order allow,deny" >> /etc/apache2/sites-available/fastdl.conf
    echo "                allow from all" >> /etc/apache2/sites-available/fastdl.conf
    echo "        </Directory>" >> /etc/apache2/sites-available/fastdl.conf
    echo "        ErrorLog "'${APACHE_LOG_DIR}'"/fastdl_error.log" >> /etc/apache2/sites-available/fastdl.conf
    echo "        CustomLog "'${APACHE_LOG_DIR}'"/fastdl_access.log combined" >> /etc/apache2/sites-available/fastdl.conf
    echo "</VirtualHost>" >> /etc/apache2/sites-available/fastdl.conf
    # Create .htaccess file
    echo "AuthType Basic" >> /var/www/fastdl/upload/.htaccess
    echo "AuthUserFile /etc/apache2/.passwd" >> /var/www/fastdl/upload/.htaccess
    echo "AuthName "fastdl"" >> /var/www/fastdl/upload/.htaccess
    echo "order deny,allow" >> /var/www/fastdl/upload/.htaccess
    echo "allow from all" >> /var/www/fastdl/upload/.htaccess
    echo "require valid-user" >> /var/www/fastdl/upload/.htaccess
    echo "" >> /var/www/fastdl/upload/.htaccess
    echo "php_value  upload_max_filesize ${php_max_upload}M" >> /var/www/fastdl/upload/.htaccess
    echo "php_value post_max_size ${php_max_upload}M" >> /var/www/fastdl/upload/.htaccess

    # Deactivate Default apache2 conf
    a2dissite 000-default.conf
    # Activate fastdl apache2 conf
    a2ensite fastdl
    # Restart apache2 server
    /etc/init.d/apache2 restart
    # Create fastdl user with password
    htpasswd -cbB /etc/apache2/.passwd $fastdl_user $fastdl_passwd

    # Create Upload PHP
    wget -P /var/www/fastdl/upload/ "https://raw.githubusercontent.com/OmG-Network/Bash-Archiv/DEV/cloud_deploy/csgo_deploy/dependencies/index.php"
    sed -i "s/{MAP_FOLDER_PATH}/${server_inst_dir//\//\\/}\/gm\/maps\//g" /var/www/fastdl/upload/index.php

    # Link Map folder
    if [ ! -d /var/www/fastdl/gm ]; then
        mkdir /var/www/fastdl/gm
    fi    
    ln -s $server_inst_dir/garrysmod/maps/ /var/www/fastdl/gm/maps
    ln -s $server_inst_dir/garrysmod/materials/ /var/www/fastdl/gm/materials
    ln -s $server_inst_dir/garrysmod/models/ /var/www/fastdl/gm/models
    ln -s $server_inst_dir/garrysmod/sound/ /var/www/fastdl/gm/sound
    ln -s $server_inst_dir/garrysmod/particles/ /var/www/fastdl/gm/particles
    ln -s $server_inst_dir/garrysmod/scripts/ /var/www/fastdl/gm/scripts
    ln -s $server_inst_dir/garrysmod/addons /var/www/fastdl/gm/addons
}

function ttt_srv_init ()
{

# Create Server CFG
echo "### UPDATE Server CFG ###"
if [ -a $server_inst_dir/garrysmod/cfg/server.cfg ]; then
    rm $server_inst_dir/garrysmod/cfg/server.cfg
fi

# Base Config
echo // Base Configuration >> $server_inst_dir/garrysmod/cfg/server.cfg
echo hostname $hostname >> $server_inst_dir/garrysmod/cfg/server.cfg
echo sv_password $sv_password >> $server_inst_dir/garrysmod/cfg/server.cfg
echo rcon_password "$rcon_password" >> $server_inst_dir/garrysmod/cfg/server.cfg
echo  >> $server_inst_dir/garrysmod/cfg/server.cfg
echo // Network Configuration >> $server_inst_dir/garrysmod/cfg/server.cfg
echo sv_downloadurl '"'"http://$WAN_IP/gm/"'"' >> $server_inst_dir/garrysmod/cfg/server.cfg
echo sv_allowdownload 0 >> $server_inst_dir/garrysmod/cfg/server.cfg
echo sv_allowupload 0 >> $server_inst_dir/garrysmod/cfg/server.cfg
echo net_maxfilesize 64 >> $server_inst_dir/garrysmod/cfg/server.cfg
echo sv_setsteamaccount $sv_setsteamaccount >> $server_inst_dir/garrysmod/cfg/server.cfg

# TTT Game Settings
echo //Prepare >> $server_inst_dir/garrysmod/cfg/server.cfg
echo ttt_preptime_seconds "10" >> $server_inst_dir/garrysmod/cfg/server.cfg
echo ttt_firstpreptime "30" >> $server_inst_dir/garrysmod/cfg/server.cfg

echo //Roundlength >> $server_inst_dir/garrysmod/cfg/server.cfg
echo ttt_roundtime_minutes "5" >> $server_inst_dir/garrysmod/cfg/server.cfg

echo //Switching >> $server_inst_dir/garrysmod/cfg/server.cfg
echo ttt_round_limit "99" >> $server_inst_dir/garrysmod/cfg/server.cfg
echo //Traitor & Detectives >> $server_inst_dir/garrysmod/cfg/server.cfg
echo ttt_detective_karma_min "800" >> $server_inst_dir/garrysmod/cfg/server.cfg
echo ttt_detective_min_players "4" >> $server_inst_dir/garrysmod/cfg/server.cfg
echo ttt_traitor_pct "0.25" >> $server_inst_dir/garrysmod/cfg/server.cfg
echo ttt_traitor_max "2" >> $server_inst_dir/garrysmod/cfg/server.cfg
echo ttt_detective_max "1" >> $server_inst_dir/garrysmod/cfg/server.cfg
echo //Voicechat >> $server_inst_dir/garrysmod/cfg/server.cfg
echo ttt_voice_drain "1" >> $server_inst_dir/garrysmod/cfg/server.cfg

echo //Gameplay >> $server_inst_dir/garrysmod/cfg/server.cfg
echo ttt_minimum_players "1" >> $server_inst_dir/garrysmod/cfg/server.cfg
echo ttt_postround_dm "1" >> $server_inst_dir/garrysmod/cfg/server.cfg
echo ttt_ragdoll_pinning "1" >> $server_inst_dir/garrysmod/cfg/server.cfg
echo ttt_ragdoll_pinning_innocents "0" >> $server_inst_dir/garrysmod/cfg/server.cfg

echo //Maps >> $server_inst_dir/garrysmod/cfg/server.cfg
echo ttt_use_weapon_spawn_scripts "1" >> $server_inst_dir/garrysmod/cfg/server.cfg

echo //Credits >> $server_inst_dir/garrysmod/cfg/server.cfg
echo ttt_credits_starting "2" >> $server_inst_dir/garrysmod/cfg/server.cfg
echo ttt_credits_award_size "1" >> $server_inst_dir/garrysmod/cfg/server.cfg
echo ttt_credits_detectivekill "2" >> $server_inst_dir/garrysmod/cfg/server.cfg
echo ttt_det_credits_starting "1" >> $server_inst_dir/garrysmod/cfg/server.cfg
echo ttt_det_credits_traitorkill "1" >> $server_inst_dir/garrysmod/cfg/server.cfg
echo ttt_det_credits_traitordead "1" >> $server_inst_dir/garrysmod/cfg/server.cfg

echo // Props >> $server_inst_dir/garrysmod/cfg/server.cfg
echo ttt_spec_prop_control "1" >> $server_inst_dir/garrysmod/cfg/server.cfg
echo ttt_spec_prop_base "15" >> $server_inst_dir/garrysmod/cfg/server.cfg

echo //Admin >> $server_inst_dir/garrysmod/cfg/server.cfg
echo ttt_idle_limit "1800" >> $server_inst_dir/garrysmod/cfg/server.cfg
echo ttt_detective_hats "1" >> $server_inst_dir/garrysmod/cfg/server.cfg

# Download Models & Textures & Maps
curl -sqL $CSS_txt | tar xfvz - -C $server_inst_dir/garrysmod/
curl -sqL $CSS_maps | tar xfvz - -C $server_inst_dir/garrysmod/
curl -sqL $dod_txt | tar xfvz - -C $server_inst_dir/garrysmod/
curl -sqL $dod_maps | tar xfvz - -C $server_inst_dir/garrysmod/
curl -sqL $hl1_txt | tar xfvz - -C $server_inst_dir/garrysmod/
curl -sqL $hl2ep1_txt | tar xfvz - -C $server_inst_dir/garrysmod/
curl -sqL $hl2e_maps | tar xfvz - -C $server_inst_dir/garrysmod/
curl -sqL $hl2e_txt | tar xfvz - -C $server_inst_dir/garrysmod/
curl -sqL $portal2_txt | tar xfvz - -C $server_inst_dir/garrysmod/
curl -sqL $portal_txt | tar xfvz - -C $server_inst_dir/garrysmod/

}

function srv_permission ()
{
    # Set permissions
    echo "### SET Permissions for $install_user_name"
    chown -cR $install_user_name:www-data $server_inst_dir && chmod -cR 775 $server_inst_dir    
    chmod +x $server_inst_dir/srcds_run
}



function gm_ttt ()
{
#Set permissions
srv_permission
# Create Crontab
if [ -a /tmp/ttt_crontab ]; then
     rm /tmp/ttt_crontab
fi
echo @reboot screen -dmS CS_MM su $install_user_name --shell /bin/sh -c "$server_inst_dir/srcds_run -game garrysmod -console -maxplayers 16 -ip 0.0.0.0 -pingboost 3 -authkey $workshop_api_key +gamemode terrortown +host_workshop_collection $workshop_collection_id +host_workshop_map $workshop_map_id +exec server.cfg" >> /tmp/ttt_crontab
crontab /tmp/ttt_crontab
# Starting TTT Server
echo "### STARTING TTT Server ###"
screen -dmS CS_MM su $install_user_name --shell /bin/sh -c "$server_inst_dir/srcds_run -game garrysmod -console -maxplayers 16 -ip 0.0.0.0 -pingboost 3 -authkey $workshop_api_key +gamemode terrortown +host_workshop_collection $workshop_collection_id +host_workshop_map $workshop_map_id +exec server.cfg"
}
############################################## End of Functions ##############################################

# Main Starts here....
# Call Functions
check_root
check_distro
inst_req
inst_vanilla_gm_srv
init_fastdl

case "$GAME_TYPE" in
    Murder)
     echo "ERROR: NO Murder function !"
    ;;

    Pedo)
     echo "ERROR: NO Murder function !"
    ;;

    TTT)
     ttt_srv_init
     gm_ttt
    ;;

    *)
     echo "ERROR: Wrong GAME_TYPE exiting..."
    exit 1
esac

exit 0
