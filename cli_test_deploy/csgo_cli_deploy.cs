using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using Renci.SshNet;

namespace ssh
{
   public class SSH_installer
    {

        // Init optional VARs with default values

        public String rcon_passwd = "";
        public String sv_passwd = "";
        public String metamod = "https://mms.alliedmods.net/mmsdrop/1.10/mmsource-1.10.7-git961-linux.tar.gz";
        public String sourcemod = "https://sm.alliedmods.net/smdrop/1.8/sourcemod-1.8.0-git6040-linux.tar.gz";
        public String esl_cfg = "http://fastdl.omg-network.de/csgo/esl.tar";
        public String steamCMD = "/opt/steamcmd";
        public String srv_inst_dir = "/opt/server";
        public String inst_user = "csgo";
        public int retry = 5;
        public String LSB = "$(/usr/bin/lsb_release -i | awk '{ print $3 }')";

        public String inst_csgo_srv(String IP, String sshPasswd, String GAME_TYPE, String ServerToken, String hostname)
        {

            SshClient client = new SshClient(IP, 22, "root", sshPasswd);

            client.Connect();

            // Remove Sys Vars
            client.RunCommand("sed -i -e '/^DEPLOY/d' /etc/environment");
            client.RunCommand("source /etc/environment");

            // Exporting Sys Vars

            // Game Settings
            client.RunCommand("echo DEPLOY_GAME_TYPE='\u0022'" + GAME_TYPE + "'\u0022' >> /etc/environment");
            client.RunCommand("echo DEPLOY_hostname='\u0022'" + hostname + "'\u0022' >> /etc/environment");
            client.RunCommand("echo DEPLOY_sv_password='\u0022'" + sv_passwd + "'\u0022' >> /etc/environment");
            client.RunCommand("echo DEPLOY_rcon_password='\u0022'" + rcon_passwd + "'\u0022' >> /etc/environment");
            client.RunCommand("echo DEPLOY_sv_setsteamaccount='\u0022'" + ServerToken + "'\u0022' >> /etc/environment");
            // Download Options
            client.RunCommand("echo DEPLOY_metamod='\u0022'" + metamod + "'\u0022' >> /etc/environment");
            client.RunCommand("echo DEPLOY_sourcemod='\u0022'" + sourcemod + "'\u0022' >> /etc/environment");
            client.RunCommand("echo DEPLOY_esl_cfg='\u0022'" + esl_cfg + "'\u0022' >> /etc/environment");
            // Install Options
            client.RunCommand("echo DEPLOY_steamCMD='\u0022'" + steamCMD + "'\u0022' >> /etc/environment");
            client.RunCommand("echo DEPLOY_server_inst_dir='\u0022'" + srv_inst_dir + "'\u0022' >> /etc/environment");
            client.RunCommand("echo DEPLOY_install_user_name='\u0022'" + inst_user + "'\u0022' >> /etc/environment");
            client.RunCommand("echo DEPLOY_retry='\u0022'" + retry + "'\u0022' >> /etc/environment");
            client.RunCommand("echo DEPLOY_LSB='\u0022'" + LSB + "'\u0022' >> /etc/environment");
            client.RunCommand("source /etc/environment");
            client.Disconnect();
            client.Connect();
    
            // Log watcher
            String test = client.CreateCommand("source /etc/environment && curl -sql https://raw.githubusercontent.com/OmG-Network/Cloud_Server_Deploy/DEV/installer/csgo/csgo_cloud_deploy.sh | bash").Execute();

            client.Disconnect();
            if (test.Contains("### ERROR: Start as root and try again ###"))
            {
                return "### ERROR: Start as root and try again ###";
            } else if (test.Contains("### ERROR: Your distro isn´t supported ###"))
            {
                return "### ERROR: Your distro isn´t supported ###";
            } else if (test.Contains("### ERROR: CSGO Download failed after "+retry+" attempts exiting... ###"))
            {
                return "### ERROR: CSGO Download failed after "+retry+" attempts exiting... ###";
            } else if (test.Contains("### ERROR: Wrong GAME_TYPE exiting... ###"))
            {
                return "### ERROR: Wrong GAME_TYPE exiting... ###";
            }
            return "Success";
        }

    }
}
