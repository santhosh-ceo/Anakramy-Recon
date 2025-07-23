# Anakam Recon

<img width="50" height="50" alt="logo" src="https://github.com/user-attachments/assets/f8ce1e7e-7feb-479f-a805-4cb7b5f3806c" />

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)



Anakam Recon is an automated reconnaissance tool that performs comprehensive scanning of target domains to identify subdomains, web applications, and potential vulnerabilities.

## Features

- Subdomain enumeration using multiple tools
- Live host detection
- Screenshot capture of web applications
- URL discovery from various sources
- Vulnerability scanning (XSS, SSRF, CORS, etc.)
- HTML report generation
- Modular design for flexible scanning

## Installation

### Prerequisites

- Linux or macOS (Windows support via WSL)
- Go (v1.17+)
- Python (v3.6+)
- Basic build tools (make, gcc, etc.)

### One-Command Installation (Recommended)

Simply run this command to install Anakam Recon system-wide:

```
curl -sSL https://raw.githubusercontent.com/yourusername/anakam-recon/main/installer.sh | sudo bash
```

### Manual Installation

Clone the repository:
```
git clone https://github.com/santhosh-ceo/Anakamy-recon.git
cd anakamy-recon
```
Run the installer:
```
chmod +x installer.sh
sudo ./installer.sh
```
Update your shell:
```
source ~/.bashrc  # or source ~/.zshrc for Zsh users
```

## Usage
### Basic Scan

```
anakam-recon -d example.com
```
### Full Scan with Custom Output
```
anakam-recon -d example.com -o /path/to/output_directory
```
### Selective Scanning

```
# Subdomain enumeration only
anakam-recon -d example.com -s

# Web-related checks (screenshots, URLs)
anakam-recon -d example.com -w

# Vulnerability scanning only
anakam-recon -d example.com -v

# Generate HTML report from existing data
anakam-recon -d example.com -r
```

### Advanced Options
```
# Use custom resolvers
anakam-recon -d example.com -r custom_resolvers.txt

# Specify custom ports
anakam-recon -d example.com -p 80,443,8080,8443

# Set custom concurrency level
anakam-recon -d example.com -t 50
```
