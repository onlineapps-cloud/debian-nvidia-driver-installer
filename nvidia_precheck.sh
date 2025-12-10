#!/bin/bash

################################################################################
# NVIDIA System Pre-Check Script
# Verifies system readiness for NVIDIA driver installation
################################################################################

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║${WHITE}          NVIDIA Driver Pre-Installation Check          ${BLUE}║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if running as root
echo -n "Checking root privileges... "
if [[ $EUID -eq 0 ]]; then
    echo -e "${GREEN}✓ Running as root${NC}"
else
    echo -e "${YELLOW}⚠ Not running as root (some checks may be limited)${NC}"
fi

# Check OS version
echo -n "Checking Debian version... "
if [[ -f /etc/debian_version ]]; then
    DEBIAN_VERSION=$(cat /etc/debian_version | cut -d. -f1)
    echo -e "${GREEN}✓ Debian $DEBIAN_VERSION detected${NC}"
    
    if [[ $DEBIAN_VERSION -ge 10 && $DEBIAN_VERSION -le 13 ]]; then
        echo -e "${GREEN}✓ Version supported${NC}"
    else
        echo -e "${YELLOW}⚠ Version may not be fully supported${NC}"
    fi
else
    echo -e "${RED}✗ Unable to detect Debian version${NC}"
fi

# Check internet connectivity
echo -n "Checking internet connectivity... "
if ping -c 1 google.com &> /dev/null; then
    echo -e "${GREEN}✓ Internet connection available${NC}"
else
    echo -e "${RED}✗ No internet connection${NC}"
fi

# Check for existing NVIDIA hardware
echo -n "Checking for NVIDIA hardware... "
if lspci | grep -i nvidia > /dev/null; then
    echo -e "${GREEN}✓ NVIDIA hardware detected${NC}"
    echo "Detected NVIDIA devices:"
    lspci | grep -i nvidia | sed 's/^/  /'
else
    echo -e "${YELLOW}⚠ No NVIDIA hardware detected${NC}"
fi

# Check available disk space
echo -n "Checking disk space... "
DISK_SPACE=$(df / | awk 'NR==2 {print $4}')
if [[ $DISK_SPACE -gt 5000000 ]]; then  # 5GB in KB
    echo -e "${GREEN}✓ Sufficient disk space (${DISK_SPACE}KB available)${NC}"
else
    echo -e "${YELLOW}⚠ Low disk space (${DISK_SPACE}KB available)${NC}"
fi

# Check for conflicting drivers
echo -n "Checking for conflicting drivers... "
if lsmod | grep -q nouveau; then
    echo -e "${YELLOW}⚠ Nouveau driver detected (will be replaced)${NC}"
else
    echo -e "${GREEN}✓ No conflicting drivers detected${NC}"
fi

# Check system architecture
echo -n "Checking system architecture... "
ARCH=$(uname -m)
if [[ $ARCH == "x86_64" ]]; then
    echo -e "${GREEN}✓ x86_64 architecture supported${NC}"
else
    echo -e "${YELLOW}⚠ Architecture $ARCH may not be fully supported${NC}"
fi

# Check memory
echo -n "Checking system memory... "
MEMORY=$(free -m | awk '/^Mem:/{print $2}')
if [[ $MEMORY -gt 4000 ]]; then
    echo -e "${GREEN}✓ Sufficient memory (${MEMORY}MB)${NC}"
else
    echo -e "${YELLOW}⚠ Low memory (${MEMORY}MB)${NC}"
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${WHITE}Pre-check completed. Review any warnings above.${NC}"
echo -e "${WHITE}If all checks passed, you can proceed with driver installation.${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"