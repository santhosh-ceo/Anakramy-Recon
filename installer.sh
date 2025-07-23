#!/bin/bash

# Anakramy Recon CLI Installer
# Version: 1.0
# Author: Anakramy

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variables
INSTALL_DIR="/opt/anakramy-recon"
BIN_DIR="/usr/local/bin"
TOOLS_DIR="$HOME/tools"
WORDLISTS_DIR="$HOME/wordlists"
SHELL_CONFIG="$HOME/.bashrc"
VENV_DIR="$HOME/anakramy-venv"

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
echo -e "${YELLOW}Anakramy Recon Installation Script${NC}"
echo -e "${BLUE}---------------------------------${NC}"
echo ""

# Check dependencies
check_dependencies() {
    echo -e "${YELLOW}[*] Checking system dependencies...${NC}"
    
    # Check for Go
    if ! command -v go &> /dev/null; then
        echo -e "${RED}[ERROR] Go is not installed. Installing Go 1.24...${NC}"
        sudo apt install -y golang-1.24
        sudo rm -f /usr/bin/go
        sudo ln -s /usr/lib/go-1.24/bin/go /usr/bin/go
        echo 'export PATH=$PATH:/usr/lib/go-1.24/bin' >> "$SHELL_CONFIG"
        source "$SHELL_CONFIG"
    fi
    
    echo -e "${GREEN}[+] Found Go $(go version)${NC}"
    
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
    
    # Check for pip
    if ! command -v pip3 &> /dev/null; then
        echo -e "${RED}[ERROR] pip3 is not installed.${NC}"
        exit 1
    else
        echo -e "${GREEN}[+] Found pip $(pip3 --version)${NC}"
    fi
}

# Install required tools
install_tools() {
    echo -e "${YELLOW}[*] Installing required tools...${NC}"
    
    # Create directories
    mkdir -p "$TOOLS_DIR" "$WORDLISTS_DIR"
    
    # Setup Python virtual environment
    echo -e "${BLUE}[+] Setting up Python virtual environment...${NC}"
    python3 -m venv "$VENV_DIR"
    source "$VENV_DIR/bin/activate"
    
    # Install Python tools
    echo -e "${BLUE}[+] Installing Python tools...${NC}"
    pip install corsy || echo -e "${YELLOW}[!] Failed to install corsy, continuing anyway...${NC}"
    deactivate
    
    # Install Go tools
    echo -e "${BLUE}[+] Installing Go tools...${NC}"
    declare -a go_tools=(
        "github.com/projectdiscovery/subfinder/v2/cmd/subfinder"
        "github.com/tomnomnom/assetfinder"
        "github.com/owasp-amass/amass/v3/..."
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
        GO111MODULE=on go install -v "$tool@latest" || echo -e "${YELLOW}[!] Failed to install $tool, continuing...${NC}"
    done
    
    # Download wordlists
    echo -e "${BLUE}[+] Downloading wordlists...${NC}"
    wget -q --timeout=10 --tries=2 https://gist.githubusercontent.com/jhaddix/86a06c5dc309d08580a018c66354a056/raw/96f4e51d96b2203f19f6381c8c545b278eaa0837/all.txt -O "$WORDLISTS_DIR/dns_wordlist.txt" || echo -e "${YELLOW}[!] Failed to download dns_wordlist.txt${NC}"
    wget -q --timeout=10 --tries=2 https://raw.githubusercontent.com/kh4sh3i/Fresh-Resolvers/master/resolvers.txt -O "$TOOLS_DIR/resolvers.txt" || echo -e "${YELLOW}[!] Failed to download resolvers.txt${NC}"
}

# Install Anakramy Recon
install_anakam() {
    echo -e "${YELLOW}[*] Installing Anakramy Recon...${NC}"
    
    # Create installation directory
    mkdir -p "$INSTALL_DIR"
    
    # Copy files
    echo -e "${BLUE}[+] Copying files to $INSTALL_DIR...${NC}"
    
    # Check if main script exists
    if [[ -f "anakam_recon.sh" ]]; then
        cp anakam_recon.sh "$INSTALL_DIR/"
        chmod +x "$INSTALL_DIR/anakam_recon.sh"
        
        # Create symlink with correct name
        echo -e "${BLUE}[+] Creating symlink in $BIN_DIR...${NC}"
        ln -sf "$INSTALL_DIR/anakam_recon.sh" "$BIN_DIR/anakramy-recon"
    else
        echo -e "${RED}[ERROR] Main script anakam_recon.sh not found!${NC}"
        exit 1
    fi
    
    # Copy templates if they exist
    if [[ -d "templates" ]]; then
        cp -r templates "$INSTALL_DIR/"
    else
        echo -e "${YELLOW}[!] No templates directory found${NC}"
        mkdir -p "$INSTALL_DIR/templates"
    fi
    
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
    echo -e "2. Start using Anakramy Recon: ${BLUE}anakramy-recon -d example.com${NC}"
    echo ""
    echo -e "${GREEN}Anakramy Recon has been installed to:${NC} $INSTALL_DIR"
    echo -e "${GREEN}Tools and wordlists are in:${NC} $TOOLS_DIR and $WORDLISTS_DIR"
    echo -e "${GREEN}Python virtual environment:${NC} $VENV_DIR"
    echo ""
    echo -e "${YELLOW}To update:${NC} Just run this installer again"
    echo -e "${YELLOW}To uninstall:${NC} Run ${BLUE}rm -rf $INSTALL_DIR $BIN_DIR/anakramy-recon $VENV_DIR${NC}"
    echo -e "${YELLOW}Note:${NC} To use Python tools, activate the virtual environment with:"
    echo -e "${BLUE}source $VENV_DIR/bin/activate${NC}"
}

# Main installation flow
check_dependencies
install_tools
install_anakam
post_install
