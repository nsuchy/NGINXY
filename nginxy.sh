#!/usr/bin/env bash
#===============================================================================================================================================
# (C) Copyright 2019 NGINXY a project under the Crypto World Foundation (https://cryptoworld.is).
#
# Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.gnu.org/licenses/gpl-3.0.en.html
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
#===============================================================================================================================================
# title            :NGINXY
# description      :This script will make it super easy to setup a Reverse Proxy with NGINX.
# author           :The Crypto World Foundation.
# contributors     :beard
# date             :03-26-2019
# version          :0.0.9 Alpha
# os               :Debian/Ubuntu
# usage            :bash nginxy.sh
# notes            :If you have any problems feel free to email the maintainer: beard [AT] cryptoworld [DOT] is
#===============================================================================================================================================

# Force check for root
  if ! [ $(id -u) = 0 ]; then
    echo "You need to be logged in as root!"
    exit 1
  fi

  # Setting up an update/upgrade global function
    function upkeep() {
      echo "Performing upkeep.."
        apt-get update -y
        apt-get dist-upgrade -y
        apt-get clean -y
    }

  # Setting up different NGINX branches to prep for install
    function stable(){
        echo deb http://nginx.org/packages/$system/ $flavor nginx > /etc/apt/sources.list.d/$flavor.nginx.stable.list
        echo deb-src http://nginx.org/packages/$system/ $flavor nginx >> /etc/apt/sources.list.d/$flavor.nginx.stable.list
          wget https://nginx.org/keys/nginx_signing.key
          apt-key add nginx_signing.key
      }

    function mainline(){
        echo deb http://nginx.org/packages/mainline/$system/ $flavor nginx > /etc/apt/sources.list.d/$flavor.nginx.mainline.list
        echo deb-src http://nginx.org/packages/mainline/$system/ $flavor nginx >> /etc/apt/sources.list.d/$flavor.nginx.mainline.list
          wget https://nginx.org/keys/nginx_signing.key
          apt-key add nginx_signing.key
      }

      # Attached func for NGINX branch prep.
        function nginx_default() {
          echo "Installing NGINX.."
            apt-get install nginx
            service nginx status
          echo "Raising limit of workers.."
            ulimit -n 65536
            ulimit -a
          echo "Setting up Security Limits.."
            wget -O /etc/security/limits.conf https://raw.githubusercontent.com/beardlyness/NGINXY/master/etc/security/limits.conf
          echo "Setting up background NGINX workers.."
            wget -O /etc/default/nginx https://raw.githubusercontent.com/beardlyness/NGINXY/master/etc/default/nginx
            echo "Setting up configuration file for NGINX main configuration.."
              wget -O /etc/nginx/nginx.conf https://raw.githubusercontent.com/beardlyness/NGINXY/master/etc/nginx/nginx.conf
          echo "Setting up configuration file for NGINX Proxy.."
            wget -O /etc/nginx/conf.d/nginx-proxy.conf https://raw.githubusercontent.com/beardlyness/NGINXY/master/etc/nginx/conf.d/nginx-proxy.conf
          echo "Setting up folders.."
            mkdir -p /etc/engine/ssl/live
            mkdir -p /var/www/html/pub/live

            read -r -p "Domain Name: (Leave { HTTPS:/// | HTTP:// | WWW. } out of the domain) " DOMAIN
              if [[ "${DOMAIN,,}" ]]
                then
                  echo "Changing 'server_name foobar' >> server_name '$DOMAIN' .."
                    sed -i 's/server_name foobar/server_name '$DOMAIN'/g' /etc/nginx/conf.d/nginx-proxy.conf
                  echo "Domain Name has been set to: '$DOMAIN' "
              fi
        }

        #Prep for SSL setup & install via ACME.SH script | Check it out here: https://github.com/Neilpang/acme.sh
          function ssldev() {
                echo "Preparing for SSL install.."
                  wget -O -  https://raw.githubusercontent.com/Neilpang/acme.sh/master/acme.sh | INSTALLONLINE=1  sh
                  reset
                  service nginx stop
                  openssl dhparam -out /etc/engine/ssl/live/dhparam.pem 2048
                  bash ~/.acme.sh/acme.sh --issue --standalone -d $DOMAIN -ak 4096 -k 4096 --force
                  bash ~/.acme.sh/acme.sh --install-cert -d $DOMAIN \
                    --key-file    /etc/engine/ssl/live/ssl.key \
                    --fullchain-file    /etc/engine/ssl/live/certificate.cert \
                    --reloadcmd   "service nginx restart"
          }

          # Grabbing info on active machine.
              flavor=`lsb_release -cs`
              system=`lsb_release -i | grep "Distributor ID:" | sed 's/Distributor ID://g' | sed 's/["]//g' | awk '{print tolower($1)}'`

#START

# Checking for multiple "required" pieces of software.
    if
      echo -e "\033[92mPerforming upkeep of system packages.. \e[0m"
        upkeep
      echo -e "\033[92mChecking software list..\e[0m"

      [ ! -x  /usr/bin/lsb_release ] || [ ! -x  /usr/bin/wget ] || [ ! -x  /usr/bin/apt-transport-https ] || [ ! -x  /usr/bin/dirmngr ] || [ ! -x  /usr/bin/ca-certificates ] || [ ! -x  /usr/bin/dialog ] ; then

        echo -e "\033[92mlsb_release: checking for software..\e[0m"
        echo -e "\033[34mInstalling lsb_release, Please Wait...\e[0m"
          apt-get install lsb-release

        echo -e "\033[92mwget: checking for software..\e[0m"
        echo -e "\033[34mInstalling wget, Please Wait...\e[0m"
          apt-get install wget

        echo -e "\033[92mapt-transport-https: checking for software..\e[0m"
        echo -e "\033[34mInstalling apt-transport-https, Please Wait...\e[0m"
          apt-get install apt-transport-https

        echo -e "\033[92mdirmngr: checking for software..\e[0m"
        echo -e "\033[34mInstalling dirmngr, Please Wait...\e[0m"
          apt-get install dirmngr

        echo -e "\033[92mca-certificates: checking for software..\e[0m"
        echo -e "\033[34mInstalling ca-certificates, Please Wait...\e[0m"
          apt-get install ca-certificates

        echo -e "\033[92mdialog: checking for software..\e[0m"
        echo -e "\033[34mInstalling dialog, Please Wait...\e[0m"
          apt-get install dialog
    fi

# NGINX Arg main
read -r -p "Do you want to setup NGINX as a Reverse Proxy? (Y/N) " REPLY
  case "${REPLY,,}" in
    [yY]|[yY][eE][sS])
      HEIGHT=20
      WIDTH=120
      CHOICE_HEIGHT=2
      BACKTITLE="NGINXY"
      TITLE="NGINX Branch Builds"
      MENU="Choose one of the following Build options:"

      OPTIONS=(1 "Stable"
               2 "Mainline")

      CHOICE=$(dialog --clear \
                      --backtitle "$BACKTITLE" \
                      --title "$TITLE" \
                      --menu "$MENU" \
                      $HEIGHT $WIDTH $CHOICE_HEIGHT \
                      "${OPTIONS[@]}" \
                      2>&1 >/dev/tty)


# Attached Arg for dialogs $CHOICE output
    case $CHOICE in
      1)
        echo "Grabbing Stable build dependencies.."
          stable
          upkeep
          nginx_default
          ssldev
          ;;
      2)
        echo "Grabbing Mainline build dependencies.."
          mainline
          upkeep
          nginx_default
          ssldev
          ;;
    esac
clear

# Close Arg for Main Statement.
      ;;
    [nN]|[nN][oO])
      echo "You have said no? We cannot work without your permission!"
      ;;
    *)
      echo "Invalid response. You okay?"
      ;;
esac

read -r -p "Would you like to setup the sysctl.conf to harden the security of the host box? (Y/N) " REPLY
  case "${REPLY,,}" in
    [yY]|[yY][eE][sS])
        echo "Setting up sysctl.conf rules. Hold tight.."
          wget -O /etc/sysctl.conf https://raw.githubusercontent.com/beardlyness/NGINXY/master/etc/sysctl.conf
          ;;
    [nN]|[nN][oO])
      echo "You have said no? We cannot work without your permission!"
      ;;
    *)
    echo "Invalid response. You okay?"
    ;;
  esac