#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_color() { echo -e "${2}${1}${NC}"; }

check_file() {
    if [ ! -s "$1" ]; then
        print_color "✗ Failed: $1" $RED
        rm -f "$1"
        return 1
    else
        print_color "✓ $1" $GREEN
    fi
}

check_python() {
    if command -v python3 &> /dev/null; then
        PYTHON_CMD="python3"
    elif command -v python &> /dev/null; then
        PYTHON_CMD="python"
    else
        print_color "Error: Python is not installed!" $RED
        exit 1
    fi
    print_color "✓ Using $PYTHON_CMD" $GREEN
}

################################
# PEAS
################################
download_peas() {
    mkdir -p toolbox && cd toolbox || exit

    print_color "Downloading PEAS..." $YELLOW

    wget -q --show-progress https://github.com/carlospolop/PEASS-ng/releases/latest/download/winPEASx64.exe -O winpeas64.exe
    check_file winpeas64.exe

    wget -q --show-progress https://github.com/carlospolop/PEASS-ng/releases/latest/download/winPEASx86.exe -O winpeas86.exe
    check_file winpeas86.exe
    
    wget -q --show-progress https://github.com/carlospolop/PEASS-ng/releases/latest/download/winPEAS.bat -O winpeas.bat
    check_file winpeas.bat

    wget -q --show-progress https://github.com/carlospolop/PEASS-ng/releases/latest/download/linpeas.sh -O linpeas.sh
    check_file linpeas.sh && chmod +x linpeas.sh

    cd - >/dev/null
}

################################
# NETCAT (reliable sources)
################################
download_netcat() {
    mkdir -p toolbox && cd toolbox || exit

    print_color "Downloading Netcat..." $YELLOW

    # Windows
    wget -q --show-progress https://github.com/int0x33/nc.exe/raw/master/nc.exe -O nc.exe
    check_file nc.exe

    cd - >/dev/null
}

################################
# LIGOLO (dynamic latest release)
################################
download_ligolo() {
    mkdir -p toolbox && cd toolbox || exit

    print_color "Fetching latest Ligolo release..." $YELLOW
    API=$(curl -s https://api.github.com/repos/nicocha30/ligolo-ng/releases/latest)

    proxy_url=$(echo "$API" | grep browser_download_url | grep proxy | grep linux | cut -d '"' -f4 | head -n1)
    agent_linux_url=$(echo "$API" | grep browser_download_url | grep agent | grep linux | cut -d '"' -f4 | head -n1)
    agent_win_url=$(echo "$API" | grep browser_download_url | grep agent | grep windows | cut -d '"' -f4 | head -n1)

    print_color "Downloading Ligolo..." $YELLOW

    wget -q --show-progress "$proxy_url" -O proxy.tar.gz
    if check_file proxy.tar.gz; then
        tar -xzf proxy.tar.gz
        chmod +x proxy 2>/dev/null
    fi

    wget -q --show-progress "$agent_linux_url" -O agent.tar.gz
    if check_file agent.tar.gz; then
        tar -xzf agent.tar.gz
        chmod +x agent 2>/dev/null
    fi

    wget -q --show-progress "$agent_win_url" -O agent.zip
    if check_file agent.zip && command -v unzip &>/dev/null; then
        unzip -oq agent.zip < /dev/null
    fi

    cd - >/dev/null
}

################################
# SERVER
################################
start_server() {
    local port=8001
    cd toolbox || exit

    IP=$(hostname -I 2>/dev/null | awk '{print $1}')
    [ -z "$IP" ] && IP="YOUR-IP"

    print_color "Server: http://$IP:$port" $GREEN
    print_color "Press Ctrl+C to stop" $YELLOW

    $PYTHON_CMD -m http.server $port
}

################################
# SUMMARY
################################
summary(){
    print_color "\nFiles in toolbox:" $GREEN
    ls -lh toolbox 2>/dev/null
}


################################
# MAIN
################################
print_color "Toolbox downloader" $GREEN
check_python

echo ""
print_color "1) PEAS" $BLUE
print_color "2) Netcat" $BLUE
print_color "3) Ligolo" $BLUE
print_color "4) All" $BLUE
print_color "5) Start server" $BLUE
echo ""

read -p "Choice: " c

case $c in
1) download_peas ;;
2) download_netcat ;;
3) download_ligolo ;;
4)
   download_peas
   download_netcat
   download_ligolo
   ;;
5) start_server ;;
*) print_color "Invalid" $RED ;;
esac

summary

echo ""
read -p "Start server now? (y/n): " s
[[ $s =~ ^[Yy]$ ]] && start_server
