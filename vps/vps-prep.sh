#!/bin/bash +x

############################################################
#  Program: preperation for eXist-nginx install on a new ubuntu vps server
#  Author : Grant MacKenzie
#  gmack.nz
#  grantmacken@gmail.com
#  run as sudo
#
# git clone https://github.com/grantmacken/nginx-eXist-ubuntu
# cd nginx-eXist-ubuntu/vps
# chmod +x vps-prep.sh
############################################################
function aptInstall(){
aptName=$1
chk=$(
    dpkg -s ${aptName}  2>/dev/null |
    grep Status
    )
if [ -z "${chk}" ]; then
    echo "install ${aptName}"
    apt-get --assume-yes install ${aptName}
else
    echo "TICK! ${aptName}: ${chk}"
    ok=$(
        echo  ${chk} |
        grep -oP 'install ok \Kinstalled'  |
        head -1
        )
    if [ "${ok}" = "installed" ]; then
        echo "OK! Looks like ${aptName} ${ok} OK"
    else
        echo "upgrade ${aptName}"
        apt-get --assume-yes --only-upgrade install ${aptName}
    fi
fi
}

aptList=(cowsay curl expect net-tools ncurses-term )

aptList2=( build-essential software-properties-common \
python-dev python-pip python3-dev python3-pip \
zlib1g-dev \
git tmux)

echo '#UTILITY TOOLS#'
echo "TASK! Use apt-get to install some utility apps"
for i in ${!aptList[@]}
do
    echo '----------------------------------------------------------------------------------------'
    aptInstall "${aptList[${i}]}"
done
chkJavaVersion=$(
        java -version  2>&1 |
        grep -oP '\K[0-9]+\.[0-9]+\.[0-9_]+'  |
        head -1
        )

chkOracle8Installer=$(
        dpkg -s oracle-java8-installer  2>/dev/null |
        grep Status
        )

if [ -z "${chkJavaVersion}" ]; then
    echo "INFO! No Java version installed"
    while true; do
	read -p "Install oracle-java8 (Y/N)?" answer
	case $answer in
		[Yy]* )
		echo "YES"
		add-apt-repository ppa:webupd8team/java
		apt-get update
		apt-get install oracle-java8-installer
		apt-get install oracle-java8-set-default
		break;;
		[Nn]* ) echo "NO"; break;;
		* ) echo "Please answer yes or no.";;
	esac
    done
else
    echo "INFO! Current Java version installed: ${chkJavaVersion}"
    if [ -z "${chkOracle8Installer}" ]; then
        echo "TASK! install oracle-java8-installer"
    else
        echo "TICK! ORACLE-JAVA8-INSTALLER: ${chkOracle8Installer}"
        okOracle8Installer=$(
        echo  ${chkOracle8Installer} |
        grep -oP 'install ok \Kinstalled'  |
        head -1
        )
        if [ "${okOracle8Installer}" = "installed" ]; then
            echo "OK! Looks like oracle-java8-installer ${okOracle8Installer} OK"
        fi
    fi
fi
echo '#BUILD TOOLS#'
echo "TASK! Use apt-get to install some BUILD TOOLS"
for i in ${!aptList2[@]}
do
    echo '----------------------------------------------------------------------------------------'
    aptInstall "${aptList2[${i}]}"
done
