using System;
using System.Collections.Generic;
using System.Linq;
using System.Reflection;
using System.Text;
using System.Threading.Tasks;
using Renci.SshNet;

namespace ssh_dev
{
    class csgo_cli_deploy
    {

        
        String csgoinit(String IP, String user, String passwd, String GameType, String Hostname, String sv_passwd, String rcon_passwd, String ServerToken, String Metamod = "https://mms.alliedmods.net/mmsdrop/1.10/mmsource-1.10.7-git961-linux.tar.gz", String Sourcemod = "https://sm.alliedmods.net/smdrop/1.8/sourcemod-1.8.0-git6040-linux.tar.gz", String esl_cfg = "http://fastdl.omg-network.de/csgo/esl.tar", String steamCMD = "/opt/steamcmd", String server_inst_dir= "/opt/server", String installUser = "csgo", int retry=5, String LSB= "$(/usr/bin/lsb_release -i | awk '{ print $3 }')")
        {

            SshClient client = new SshClient(IP, 22, user, passwd);
            
            client.Connect();

            // Remove Sys Vars
            client.RunCommand("sed -i -e '/^DEPLOY/d' /etc/environment").Execute();
            client.RunCommand("source /etc/environment").Execute();
            // Exporting Sys Vars

            // Game Settings
                 client.RunCommand("echo 'DEPLOY_GAME_TYPE="+GameType+"' >> /etc/environment").Execute();
                 client.RunCommand("echo DEPLOY_hostname="+Hostname+" >> /etc/environment").Execute();
                 client.RunCommand("echo DEPLOY_sv_password="+sv_passwd+" >> /etc/environment").Execute();
                 client.RunCommand("echo DEPLOY_rcon_password="+rcon_passwd+" >> /etc/environment").Execute();
                 client.RunCommand("echo DEPLOY_sv_setsteamaccount="+ServerToken+" >> /etc/environment").Execute();
                // Download Options
                 client.RunCommand("echo DEPLOY_metamod="+Metamod+" >> /etc/environment").Execute();
                 client.RunCommand("echo DEPLOY_sourcemod="+Sourcemod+" >> /etc/environment").Execute();
                 client.RunCommand("echo DEPLOY_esl_cfg="+esl_cfg+" >> /etc/environment").Execute();
                // Install Options
                 client.RunCommand("echo DEPLOY_steamCMD="+steamCMD+" >> /etc/environment").Execute(); 
                 client.RunCommand("echo DEPLOY_server_inst_dir="+server_inst_dir+ " >> /etc/environment").Execute();
                 client.RunCommand("echo DEPLOY_install_user_name="+installUser+" >> /etc/environment").Execute();
                 client.RunCommand("echo DEPLOY_retry="+retry+" >> /etc/environment").Execute();
                 client.RunCommand("echo DEPLOY_LSB="+LSB+" >> /etc/environment").Execute();

            client.RunCommand("source /etc/environment").Execute();
            client.Disconnect();
            client.Connect();
            // Log watcher
            String test = client.CreateCommand("source /etc/environment && curl -sql https://raw.githubusercontent.com/OmG-Network/Cloud_Server_Deploy/DEV/installer/csgo/csgo_cloud_deploy.sh | bash").Execute();

            client.Disconnect();
            return test;

        }

        static void Main(string[] args)
        {
            // SSH Objekt
            Program ssh = new Program();


            // Verbindung zu Server erhstellen
            //ssh.csgoinit(IP, User, Passwd, GameType, Hostname, sv_passwd, rcon_passwd, ServerToken);

            

            Console.WriteLine(ssh.csgoinit("IP", "root", "passwd", "1vs1", "[OmG]Test", "aim", "lul", "xx1337xx"));
            Console.ReadKey();

        }
    }
}
