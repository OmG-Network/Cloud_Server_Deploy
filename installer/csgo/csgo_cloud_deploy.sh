#!/bin/bash

## Server Deploy Tool installer
## Silent CSGO Server
## 2018-05-08


if [ $# == 0 ] ; then echo "Failed parsing options." >&2 ; exit 1 ; fi

# Set Default Settings
# FastDL Upload Portal Settings
fastdl_user=fastdl
fastdl_passwd=fastdl
php_max_upload=2048
# Download options
metamod="https://mms.alliedmods.net/mmsdrop/1.10/mmsource-1.10.7-git961-linux.tar.gz"
sourcemod="https://sm.alliedmods.net/smdrop/1.8/sourcemod-1.8.0-git6040-linux.tar.gz"
esl_cfg="http://fastdl.omg-network.de/csgo/esl.tar"
# Install options
steamCMD=/opt/steamcmd
server_inst_dir=/opt/server
install_user_name=csgo
retry=5
LSB=$($(which lsb_release) -si)
WAN_IP=$(curl ipinfo.io/ip)

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
#  metamod = i
#  sourcemod = j
#  esl_cfg = k
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
       i) metamod=$OPTARG;;
       j) sourcemod=$OPTARG;;
       k) esl_cfg=$OPTARG;;
       l) steamCMD=$OPTARG;;
       m) server_inst_dir=$OPTARG;;
       n) install_user_name=$OPTARG;;
       o) retry=$OPTARG;;
       p) LSB=$OPTARG;;
       q) WAN_IP=$OPTARG;;

   esac
done


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

function inst_vanilla_cs_srv ()
{
    tmp_dir="$(su $install_user_name --shell /bin/sh -c "mktemp -d")"
    # Download CSGO Server
    echo "### DOWNLOADING CSGO Server ###"
    su $install_user_name --shell /bin/sh -c "$steamCMD/steamcmd.sh +@sSteamCmdForcePlatformType linux +login anonymous +force_install_dir $tmp_dir/ +app_update 740 validate +quit" > $tmp_dir/log
    # Check install status
    if [[ $(cat $tmp_dir/log) = *"Success! App '740' fully installed."* ]] ; then
        echo "CSGO Download success"
    else
        rm -rf $tmp_dir
        echo "CSGO Download failed retry..."
         COUNTER=$((COUNTER +1))
             if [ $retry == $COUNTER ]; then
               echo "CSGO Download failed after $retry attempts exiting..."
            exit 1
             fi 
       inst_vanilla_cs_srv
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
    wget -P /var/www/fastdl/upload/ "https://raw.githubusercontent.com/OmG-Network/Bash-Archiv/master/cloud_deploy/csgo_deploy/dependencies/index.php"
    sed -i "s/{MAP_FOLDER_PATH}/${server_inst_dir//\//\\/}\/csgo\/maps\//g" /var/www/fastdl/upload/index.php

    # Link Map folder
    if [ ! -d /var/www/fastdl/csgo ]; then
        mkdir /var/www/fastdl/csgo
    fi    
    ln -s $server_inst_dir/csgo/maps/ /var/www/fastdl/csgo/maps
    ln -s $server_inst_dir/csgo/materials/ /var/www/fastdl/csgo/materials
    ln -s $server_inst_dir/csgo/models/ /var/www/fastdl/csgo/models
    ln -s $server_inst_dir/csgo/sound/ /var/www/fastdl/csgo/sound   
}

function csgo_srv_init ()
{
# Inst Metamod & Sourcemod
# Metamod
echo "### INST Metamod ###"
curl -sqL $metamod | tar zxvf - -C $server_inst_dir/csgo/
# Sourcemod
echo "### INST Sourcemod ###"
curl -sqL $sourcemod | tar zxvf - -C $server_inst_dir/csgo/
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
echo sv_downloadurl '"'"http://$WAN_IP/csgo/"'"' >> $server_inst_dir/csgo/cfg/server.cfg
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
curl -sqL $esl_cfg | tar xf - -C $server_inst_dir/csgo/cfg/
}

function srv_permission ()
{
    # Set permissions
    echo "### SET Permissions for $install_user_name"
    chown -cR $install_user_name:www-data $server_inst_dir && chmod -cR 775 $server_inst_dir    
    chmod +x $server_inst_dir/srcds_run
}

function csgo_1vs1 ()
{
# Download Maps
echo "### DOWNLOADING CSGO Maps ###"
wget -P $server_inst_dir/csgo/maps "http://fastdl.omg-network.de/csgo/csgo/maps/aim_redline.bsp"
wget -P $server_inst_dir/csgo/maps "http://fastdl.omg-network.de/csgo/csgo/maps/aim_dust2.bsp"
wget -P $server_inst_dir/csgo/maps "http://fastdl.omg-network.de/csgo/csgo/maps/aim_map_classic.bsp"
wget -P $server_inst_dir/csgo/maps "http://fastdl.omg-network.de/csgo/csgo/maps/aim_dust_go.bsp"
wget -P $server_inst_dir/csgo/maps "http://fastdl.omg-network.de/csgo/csgo/maps/aim_map.bsp"
wget -P $server_inst_dir/csgo/maps "http://fastdl.omg-network.de/csgo/csgo/maps/aim_prac_ak47.bsp"
#Set permissions
srv_permission
# Starting CSGO Server
echo "### STARTING CSGO Server ###"
screen -dmS CS_1vs1 su $install_user_name --shell /bin/sh -c "$server_inst_dir/srcds_run -game csgo -console -usercon -tickrate 128 -maxplayers 10 -nobots -ip 0.0.0.0 -pingboost 3 +game_type 0 +game_mode 0 +map aim_redline +exec server.cfg"
}

function csgo_diegel ()
{
# Downloading aim_deagle7k
wget -P $server_inst_dir/csgo/maps "http://fastdl.omg-network.de/csgo/csgo/maps/aim_deagle7k.bsp"
# Downloading only HS Plugin
wget -P $server_inst_dir/csgo/addons/sourcemod/plugins "https://raw.githubusercontent.com/Bara/OnlyHS/master/addons/sourcemod/plugins/onlyhs.smx"
#Set permissions
srv_permission
# Starting CSGO Server
echo "### STARTING CSGO Server ###"
screen -dmS CS_Diegle su $install_user_name --shell /bin/sh -c "$server_inst_dir/srcds_run -game csgo -console -usercon -tickrate 128 -maxplayers 10 -nobots -ip 0.0.0.0 -pingboost 3 +game_type 0 +game_mode 1 +map aim_deagle7k +exec server.cfg"

}

function csgo_mm ()
{
#Set permissions
srv_permission
# Starting CSGO Server
echo "### STARTING CSGO Server ###"
screen -dmS CS_MM su $install_user_name --shell /bin/sh -c "$server_inst_dir/srcds_run -game csgo -console -usercon -tickrate 128 -maxplayers 10 -nobots -ip 0.0.0.0 -pingboost 3 +game_type 0 +game_mode 1 +map de_cbble +exec server.cfg"
}
############################################## End of Functions ##############################################

# Main Starts here....
# Call Functions
check_root
check_distro
inst_req
inst_vanilla_cs_srv
init_fastdl
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
