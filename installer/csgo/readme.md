# CSGO Server installer

Als grundlage dient hier die aktuellste Version, aus dem Bash Cloud Deploy Projekt.
Die Varaiblen übergabe wurde von evn Vars auf übergabeparameter umgebaut.

Das Script besitzt 17 übergabeparameter, davon müssen mindestens 5 angegeben werden.
Hier die Liste der zuordnungen der einzelnen übergabeparametern zu den Variablen.

```
# Matching Table (alles Buchstaben)
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
```

__Eine ausführliche Liste von optionen für die Übergabeparabeter folgt...__

So könnte ein aufruf des Scripts aussehen:

```bash
./csgo_cloud_deploy.sh -a MM -b "[OmG] Network Diegel only HS" -c "aim" -d "lul" -e "(Game_Server_Token)" -f upload-user -g upload-passwd -h 4096 -i "(Link zur metamod .tar.gz)" -j "(Link zur Sourcemod .tar.gz)" -k "(Link zur esl CFG .tar)" -l /opt/steamCMD -m /opt/server -n CSGO -o 10 -p $($(which lsb_release) -si) -q 1.1.1.1
```
Die Parameter für LSB "p" und für WAN_IP "q" können wie in der "normalen" Version ignoriert werden und daher ohne einschränkungen entfallen.

# Garrys Mod Server installer

```
# Matching Table (alles Buchstaben)
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
```

__Eine ausführliche Liste von optionen für die Übergabeparabeter folgt...__

So könnte ein aufruf des Scripts aussehen:

```bash
./csgo_cloud_deploy.sh -a TTT -b "[OmG] Network TTT" -c "aim" -d "lul" -e "(Game_Server_Token)" -f upload-user -g upload-passwd -h 4096 -i "8045401" -j "5405684" -k "aw654d5a6w4d6aw46d5aw4d65ad6" -l /opt/steamCMD -m /opt/server -n GM -o 10 -p $($(which lsb_release) -si) -q 1.1.1.1
```
Die Parameter für LSB "p" und für WAN_IP "q" können wie in der "normalen" Version ignoriert werden und daher ohne einschränkungen entfallen.