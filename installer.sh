#!/bin/bash

# Anakamy Recon CLI Installer
# Version: 1.0
# Author: Anakramy

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variables
INSTALL_DIR="/opt/anakamy-recon"
BIN_DIR="/usr/local/bin"
TOOLS_DIR="$HOME/tools"
WORDLISTS_DIR="$HOME/wordlists"
SHELL_CONFIG="$HOME/.bashrc"

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}[ERROR] This script must be run as root${NC}" 
   exit 1
fi

# Banner
echo -e "${GREEN}"
cat << "EOF"
   ___   _   __   _  ______  ___   __ __ 
  / _ \ / | / /  / |/ / __ \/   | / //_/
 / /_\//  |/ /  /   / /_/ / /| |/ ,<   
 / _,  / /|  /  /   / _, _/ ___ / /| |  
/_/ |_/_/ |_/  /_//_/_/ |_/_/  /_/_/|_|  
EOF
echo -e "${NC}"
echo -e "${YELLOW}Anakamy Recon Installation Script${NC}"
echo -e "${BLUE}---------------------------------${NC}"
echo ""

# Check dependencies
check_dependencies() {
    echo -e "${YELLOW}[*] Checking system dependencies...${NC}"
    
    # Check for Go
    if ! command -v go &> /dev/null; then
        echo -e "${RED}[ERROR] Go is not installed. Please install Go 1.17+ first.${NC}"
        exit 1
    else
        echo -e "${GREEN}[+] Found Go $(go version)${NC}"
    fi
    
    # Check for Python
    if ! command -v python3 &> /dev/null; then
        echo -e "${RED}[ERROR] Python 3 is not installed.${NC}"
        exit 1
    else
        echo -e "${GREEN}[+] Found Python $(python3 --version)${NC}"
    fi
    
    # Check for git
    if ! command -v git &> /dev/null; then
        echo -e "${RED}[ERROR] git is not installed.${NC}"
        exit 1
    else
        echo -e "${GREEN}[+] Found git $(git --version)${NC}"
    fi
}

# Install required tools
install_tools() {
    echo -e "${YELLOW}[*] Installing required tools...${NC}"
    
    # Create directories
    mkdir -p "$TOOLS_DIR" "$WORDLISTS_DIR"
    
    # Install Go tools
    echo -e "${BLUE}[+] Installing Go tools...${NC}"
    declare -a go_tools=(
        "github.com/projectdiscovery/subfinder/v2/cmd/subfinder"
        "github.com/tomnomnom/assetfinder"
        "github.com/OWASP/Amass/v3/..."
        "github.com/projectdiscovery/httpx/cmd/httpx"
        "github.com/projectdiscovery/nuclei/v2/cmd/nuclei"
        "github.com/sensepost/gowitness"
        "github.com/lc/gau/v2/cmd/gau"
        "github.com/tomnomnom/qsreplace"
        "github.com/hahwul/dalfox/v2"
        "github.com/jaeles-project/gospider"
    )
    
    for tool in "${go_tools[@]}"; do
        echo -e "${YELLOW}[*] Installing $tool...${NC}"
        GO111MODULE=on go install -v $tool@latest
    done
    
    # Install Python tools
    echo -e "${BLUE}[+] Installing Python tools...${NC}"
    pip3 install corsy
    
    # Download wordlists
    echo -e "${BLUE}[+] Downloading wordlists...${NC}"
    wget -q https://gist.githubusercontent.com/jhaddix/86a06c5dc309d08580a018c66354a056/raw/96f4e51d96b2203f19f6381c8c545b278eaa0837/all.txt -O "$WORDLISTS_DIR/dns_wordlist.txt"
    wget -q https://raw.githubusercontent.com/kh4sh3i/Fresh-Resolvers/master/resolvers.txt -O "$TOOLS_DIR/resolvers.txt"
}

# Install Anakam Recon
install_anakam() {
    echo -e "${YELLOW}[*] Installing Anakamy Recon...${NC}"
    
    # Create installation directory
    mkdir -p "$INSTALL_DIR"
    
    # Copy files
    echo -e "${BLUE}[+] Copying files to $INSTALL_DIR...${NC}"
    cp anakam_recony.sh "$INSTALL_DIR"
    cp -r templates "$INSTALL_DIR"
    chmod +x "$INSTALL_DIR/anakamy_recon.sh"
    
    # Create symlink
    echo -e "${BLUE}[+] Creating symlink in $BIN_DIR...${NC}"
    ln -sf "$INSTALL_DIR/anakamy_recon.sh" "$BIN_DIR/anakamy-recon"
    
    # Update PATH if needed
    if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
        echo -e "${YELLOW}[!] Adding $BIN_DIR to PATH in $SHELL_CONFIG${NC}"
        echo "export PATH=\$PATH:$BIN_DIR" >> "$SHELL_CONFIG"
        source "$SHELL_CONFIG"
    fi
}

# Post-installation
post_install() {
    echo -e "${GREEN}"
    cat << "EOF"
 ___ _   _  ___ ___ ___  ___ ___ 
|_ _| \ | |/ _ \_ _/ _ \| _ \ __|
 | ||  \| | | | | | | | |  _/ _| 
|___|_|\_|_| |_|___\___/|_| |___|
                                  
EOF
    echo -e "${NC}"
    echo -e "${GREEN}[+] Installation complete!${NC}"
    echo ""
    echo -e "${YELLOW}What to do next:${NC}"
    echo -e "1. Run ${BLUE}source $SHELL_CONFIG${NC} or open a new terminal"
    echo -e "2. Start using Anakamy Recon: ${BLUE}anakamy-recon -d example.com${NC}"
    echo ""
    echo -e "${GREEN}Anakamy Recon has been installed to:${NC} $INSTALL_DIR"
    echo -e "${GREEN}Tools and wordlists are in:${NC} $TOOLS_DIR and $WORDLISTS_DIR"
    echo ""
    echo -e "${YELLOW}To update:${NC} Just run this installer again"
    echo -e "${YELLOW}To uninstall:${NC} Run ${BLUE}rm -rf $INSTALL_DIR $BIN_DIR/anakamy-recon${NC}"
}

# Main installation flow
check_dependencies
install_tools
install_anakam
post_install
