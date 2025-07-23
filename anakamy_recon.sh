#!/bin/bash

# Anakamy Recon - Automated Reconnaissance Tool
# By Anakramy

# Colors
red=`tput setaf 1`
green=`tput setaf 2`
yellow=`tput setaf 3`
reset=`tput sgr0`

# Global Variables
domain=""
output_dir=""
tools_dir="$HOME/tools"
wordlists_dir="$HOME/wordlists"
resolvers_file="$tools_dir/resolvers.txt"
http_ports="80,81,300,443,591,593,832,981,1010,1311,1099,2082,2095,2096,2480,3000,3128,3333,4243,4443,4444,4567,4711,4712,4993,5000,5104,5108,5280,5281,5601,5800,6543,7000,7001,7396,7474,8000,8001,8008,8014,8042,8060,8069,8080,8081,8083,8088,8090,8091,8095,8118,8123,8172,8181,8222,8243,8280,8281,8333,8337,8443,8444,8500,8800,8834,8880,8881,8888,8983,9000,9001,9043,9060,9080,9090,9091,9200,9443,9502,9800,9981,10000,10250,11371,12443,15672,16080,17778,18091,18092,20720,27201,32000,55440,55672"
server_ip=$(curl -s ifconfig.me)

# Functions
logo() {
  echo "${yellow}
   ___   _   __   _  ______  ___   __ __ 
  / _ \ / | / /  / |/ / __ \/   | / //_/
 / /_\//  |/ /  /   / /_/ / /| |/ ,<   
 / _,  / /|  /  /   / _, _/ ___ / /| |  
/_/ |_/_/ |_/  /_//_/_/ |_/_/  /_/_/|_|  ${reset}"
  echo "${green}Anakamy Recon - Automated Reconnaissance Tool${reset}"
  echo ""
}

usage() {
  echo "Usage: $0 -d domain.com [options]"
  echo ""
  echo "Options:"
  echo "  -d, --domain    Target domain (required)"
  echo "  -o, --output    Output directory (default: domain_<date>)"
  echo "  -a, --all       Run all checks (default)"
  echo "  -s, --subdomains Run subdomain enumeration only"
  echo "  -w, --web       Run web-related checks (screenshots, URLs)"
  echo "  -v, --vuln      Run vulnerability scans (XSS, SSRF, etc.)"
  echo "  -r, --report    Generate HTML report only"
  echo "  -h, --help      Show this help message"
  exit 1
}

check_dependencies() {
  declare -a tools=("subfinder" "assetfinder" "amass" "httpx" "nuclei" "gowitness" "gau" "qsreplace" "dalfox")
  
  for tool in "${tools[@]}"; do
    if ! command -v "$tool" &> /dev/null; then
      echo "${red}[ERROR] $tool is not installed or not in PATH${reset}"
      exit 1
    fi
  done
}

setup_directories() {
  if [ -z "$output_dir" ]; then
    output_dir="${domain}_$(date +%Y%m%d_%H%M%S)"
  fi
  
  mkdir -p "$output_dir" || { echo "${red}Failed to create output directory${reset}"; exit 1; }
  mkdir -p "$output_dir/subdomains"
  mkdir -p "$output_dir/screenshots"
  mkdir -p "$output_dir/reports"
  mkdir -p "$output_dir/vulnerabilities"
  
  echo "${green}[+] Output will be saved to: $output_dir${reset}"
}

download_resources() {
  echo "${green}[+] Downloading required resources...${reset}"
  
  # Download resolvers list if not exists
  if [ ! -f "$resolvers_file" ]; then
    wget -q https://raw.githubusercontent.com/kh4sh3i/Fresh-Resolvers/master/resolvers.txt -O "$resolvers_file"
  fi
  
  # Download wordlist if not exists
  if [ ! -f "$wordlists_dir/dns_wordlist.txt" ]; then
    wget -q https://gist.githubusercontent.com/jhaddix/86a06c5dc309d08580a018c66354a056/raw/96f4e51d96b2203f19f6381c8c545b278eaa0837/all.txt -O "$wordlists_dir/dns_wordlist.txt"
  fi
}

enumerate_subdomains() {
  echo "${green}[+] Starting subdomain enumeration...${reset}"
  
  # Subfinder
  echo "${yellow}[*] Running subfinder...${reset}"
  subfinder -d "$domain" -silent -o "$output_dir/subdomains/subfinder.txt"
  
  # Assetfinder
  echo "${yellow}[*] Running assetfinder...${reset}"
  assetfinder -subs-only "$domain" > "$output_dir/subdomains/assetfinder.txt"
  
  # Amass (passive)
  echo "${yellow}[*] Running amass (passive)...${reset}"
  amass enum -passive -d "$domain" -o "$output_dir/subdomains/amass.txt"
  
  # Combine and sort results
  cat "$output_dir/subdomains/"*.txt | sort -u > "$output_dir/subdomains/all_subdomains.txt"
  
  # Count results
  sub_count=$(wc -l < "$output_dir/subdomains/all_subdomains.txt")
  echo "${green}[+] Found $sub_count unique subdomains${reset}"
}

resolve_subdomains() {
  echo "${green}[+] Resolving live subdomains...${reset}"
  
  # Use httpx to find live hosts
  httpx -l "$output_dir/subdomains/all_subdomains.txt" -silent -ports "$http_ports" -o "$output_dir/subdomains/live_subdomains.txt"
  
  live_count=$(wc -l < "$output_dir/subdomains/live_subdomains.txt")
  echo "${green}[+] Found $live_count live subdomains${reset}"
}

takeover_checks() {
  echo "${green}[+] Checking for subdomain takeovers...${reset}"
  
  # Check for CNAME records that might be vulnerable
  while read -r sub; do
    host -t CNAME "$sub" | grep 'is an alias' >> "$output_dir/reports/takeover_check.txt"
  done < "$output_dir/subdomains/all_subdomains.txt"
  
  # Check for known vulnerable services
  nuclei -l "$output_dir/subdomains/live_subdomains.txt" -t "$tools_dir/nuclei-templates/takeovers/" -o "$output_dir/reports/takeover_results.txt"
}

capture_screenshots() {
  echo "${green}[+] Capturing screenshots of live subdomains...${reset}"
  gowitness file -f "$output_dir/subdomains/live_subdomains.txt" -P "$output_dir/screenshots" --delay 5
}

discover_urls() {
  echo "${green}[+] Discovering URLs from various sources...${reset}"
  
  # Wayback Machine
  echo "${yellow}[*] Checking Wayback Machine...${reset}"
  gau "$domain" --o "$output_dir/reports/wayback_urls.txt"
  
  # Common Crawl
  echo "${yellow}[*] Checking Common Crawl...${reset}"
  gospider -s "https://$domain" -o "$output_dir/reports" -t 2 -d 1 -c 5
  
  # Combine and filter URLs
  cat "$output_dir/reports/"*urls.txt | sort -u > "$output_dir/reports/all_urls.txt"
}

scan_vulnerabilities() {
  echo "${green}[+] Scanning for vulnerabilities...${reset}"
  
  # XSS Scanning
  echo "${yellow}[*] Checking for XSS vulnerabilities...${reset}"
  cat "$output_dir/reports/all_urls.txt" | gf xss | qsreplace -a | dalfox pipe -o "$output_dir/vulnerabilities/xss_results.txt"
  
  # SSRF Scanning
  echo "${yellow}[*] Checking for SSRF vulnerabilities...${reset}"
  cat "$output_dir/reports/all_urls.txt" | gf ssrf | qsreplace "http://$server_ip" | httpx -silent
  
  # CORS Scanning
  echo "${yellow}[*] Checking for CORS misconfigurations...${reset}"
  corsy -i "$output_dir/subdomains/live_subdomains.txt" -o "$output_dir/vulnerabilities/cors_results.txt"
  
  # Nuclei Scanning
  echo "${yellow}[*] Running Nuclei scans...${reset}"
  nuclei -l "$output_dir/subdomains/live_subdomains.txt" -t "$tools_dir/nuclei-templates/" -o "$output_dir/vulnerabilities/nuclei_results.txt"
}

generate_report() {
  echo "${green}[+] Generating HTML report...${reset}"
  
  # Create a simple HTML report
  cat << EOF > "$output_dir/report.html"
<!DOCTYPE html>
<html>
<head>
    <title>Anakamy Recon</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1 { color: #333; }
        h2 { color: #444; margin-top: 30px; }
        pre { background: #f4f4f4; padding: 10px; border-radius: 5px; }
        .summary { background: #e7f3fe; padding: 15px; border-radius: 5px; }
    </style>
</head>
<body>
    <h1>Anakamy Recon Report for $domain</h1>
    <p>Generated on $(date)</p>
    
    <div class="summary">
        <h2>Summary</h2>
        <p>Total subdomains found: $(wc -l < "$output_dir/subdomains/all_subdomains.txt")</p>
        <p>Live subdomains: $(wc -l < "$output_dir/subdomains/live_subdomains.txt")</p>
    </div>
    
    <h2>Subdomains</h2>
    <pre>$(cat "$output_dir/subdomains/all_subdomains.txt")</pre>
    
    <h2>Live Subdomains</h2>
    <pre>$(cat "$output_dir/subdomains/live_subdomains.txt")</pre>
    
    <h2>Screenshots</h2>
    <p>Screenshots saved in: $output_dir/screenshots</p>
    
    <h2>Vulnerability Scan Results</h2>
    <h3>XSS Findings</h3>
    <pre>$(head -n 20 "$output_dir/vulnerabilities/xss_results.txt")</pre>
    
    <h3>Nuclei Findings</h3>
    <pre>$(head -n 20 "$output_dir/vulnerabilities/nuclei_results.txt")</pre>
</body>
</html>
EOF

  echo "${green}[+] Report generated: $output_dir/report.html${reset}"
}

cleanup() {
  echo "${green}[+] Cleaning up temporary files...${reset}"
  rm -f "$output_dir/subdomains/subfinder.txt" "$output_dir/subdomains/assetfinder.txt" "$output_dir/subdomains/amass.txt"
}

main() {
  logo
  check_dependencies
  setup_directories
  download_resources
  
  # Run selected modules
  enumerate_subdomains
  resolve_subdomains
  takeover_checks
  capture_screenshots
  discover_urls
  scan_vulnerabilities
  generate_report
  cleanup
  
  echo "${green}[+] Anakamy Recon completed successfully!${reset}"
  echo "${green}[+] Results saved to: $output_dir${reset}"
}

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    -d|--domain)
      domain="$2"
      shift 2
      ;;
    -o|--output)
      output_dir="$2"
      shift 2
      ;;
    -a|--all)
      # All modules will run (default)
      shift
      ;;
    -s|--subdomains)
      # Only run subdomain enumeration
      MODE="subdomains"
      shift
      ;;
    -w|--web)
      # Only run web-related checks
      MODE="web"
      shift
      ;;
    -v|--vuln)
      # Only run vulnerability scans
      MODE="vuln"
      shift
      ;;
    -r|--report)
      # Only generate report
      MODE="report"
      shift
      ;;
    -h|--help)
      usage
      ;;
    *)
      echo "${red}[!] Unknown option: $1${reset}"
      usage
      ;;
  esac
done

# Validate domain
if [ -z "$domain" ]; then
  echo "${red}[!] Domain is required${reset}"
  usage
fi

# Run main function
main
