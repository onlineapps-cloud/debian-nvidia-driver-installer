#!/bin/bash

################################################################################
# NVIDIA Driver Manager for Debian OS (versions 10-13)
# Universal bash script for managing NVIDIA drivers and related tools
# 
# Usage: sudo ./nvidia_driver_manager.sh
################################################################################

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Global variables
SCRIPT_NAME="NVIDIA Driver Manager"
DEBIAN_VERSION=""
NVIDIA_DRIVER_PACKAGE="nvidia-driver"
CUDA_REPO_SETUP=false

################################################################################
# Utility Functions
################################################################################

print_banner() {
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${WHITE}               NVIDIA Driver Manager for Debian               ${CYAN}║${NC}"
    echo -e "${CYAN}║${WHITE}                    Version 1.0                                ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_header() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}$1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${CYAN}ℹ $1${NC}"
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root (use sudo)"
        exit 1
    fi
}

# Detect Debian version
detect_debian_version() {
    if [[ -f /etc/debian_version ]]; then
        DEBIAN_VERSION=$(cat /etc/debian_version | cut -d. -f1)
        print_info "Detected Debian version: $DEBIAN_VERSION"
        
        # Validate version (10-13)
        if [[ $DEBIAN_VERSION -lt 10 || $DEBIAN_VERSION -gt 13 ]]; then
            print_warning "Debian version $DEBIAN_VERSION may not be fully supported"
            read -p "Continue anyway? (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                exit 1
            fi
        fi
    else
        print_error "Unable to detect Debian version"
        exit 1
    fi
}

# Check internet connectivity
check_internet() {
    print_info "Checking internet connectivity..."
    if ! ping -c 1 google.com &> /dev/null; then
        print_error "No internet connection detected"
        exit 1
    fi
    print_success "Internet connection verified"
}

# Update package lists
update_system() {
    print_info "Updating package lists..."
    apt update
    print_success "Package lists updated"
}

# Install required dependencies
install_dependencies() {
    print_info "Installing required dependencies..."
    apt install -y wget gnupg2 software-properties-common apt-transport-https ca-certificates curl build-essential
    print_success "Dependencies installed"
}

################################################################################
# NVIDIA Driver Functions
################################################################################

# Check NVIDIA driver installation status
check_nvidia_drivers() {
    print_header "NVIDIA Driver Status Check"
    
    # Check if nvidia-smi is available
    if command -v nvidia-smi &> /dev/null; then
        print_success "NVIDIA drivers appear to be installed"
        echo ""
        print_info "NVIDIA System Management Interface (nvidia-smi) output:"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        nvidia-smi
        echo ""
        
        # Check driver version
        DRIVER_VERSION=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader,nounits | head -1)
        print_info "Current driver version: $DRIVER_VERSION"
        
        # Check CUDA version if available
        if command -v nvcc &> /dev/null; then
            CUDA_VERSION=$(nvcc --version | grep "release" | sed 's/.*release \([0-9]\+\.[0-9]\+\).*/\1/')
            print_info "CUDA version: $CUDA_VERSION"
        else
            print_warning "CUDA toolkit not detected"
        fi
        
    else
        print_warning "NVIDIA drivers not detected or not installed"
        echo ""
        print_info "Checking for other NVIDIA-related packages..."
        
        # Check for installed NVIDIA packages
        if dpkg -l | grep -q nvidia; then
            print_info "Some NVIDIA packages are installed:"
            dpkg -l | grep nvidia
        else
            print_info "No NVIDIA packages found"
        fi
    fi
    
    echo ""
    read -p "Press Enter to continue..."
}

# Install NVIDIA drivers
install_nvidia_drivers() {
    print_header "NVIDIA Driver Installation"
    
    # Check if drivers are already installed
    if command -v nvidia-smi &> /dev/null; then
        print_warning "NVIDIA drivers are already installed"
        read -p "Do you want to reinstall them? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            return
        fi
    fi
    
    print_info "Installing NVIDIA drivers for Debian $DEBIAN_VERSION..."
    
    # Update system first
    update_system
    
    # Install drivers based on Debian version
    case $DEBIAN_VERSION in
        10|11)
            print_info "Installing NVIDIA drivers using apt..."
            apt install -y $NVIDIA_DRIVER_PACKAGE
            ;;
        12|13)
            print_info "Installing NVIDIA drivers using apt..."
            apt install -y $NVIDIA_DRIVER_PACKAGE firmware-misc-nonfree
            ;;
        *)
            print_info "Installing NVIDIA drivers using apt..."
            apt install -y $NVIDIA_DRIVER_PACKAGE
            ;;
    esac
    
    print_success "NVIDIA drivers installation completed"
    print_warning "A system reboot is required for the drivers to take effect"
    
    read -p "Reboot now? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        reboot
    fi
}

# Uninstall NVIDIA drivers
uninstall_nvidia_drivers() {
    print_header "NVIDIA Driver Uninstallation"
    
    print_warning "This will remove all NVIDIA drivers and related packages"
    read -p "Are you sure you want to continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        return
    fi
    
    print_info "Removing NVIDIA packages..."
    
    # Remove NVIDIA packages
    apt remove --purge -y ^nvidia-*
    apt autoremove -y
    
    # Remove NVIDIA configuration files
    rm -rf /etc/X11/xorg.conf
    rm -rf /etc/X11/xorg.conf.backup
    
    print_success "NVIDIA drivers uninstalled"
    print_warning "A system reboot is recommended"
    
    read -p "Reboot now? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        reboot
    fi
}

################################################################################
# CUDA Toolkit Functions
################################################################################

# Setup CUDA repository
setup_cuda_repository() {
    if [[ $CUDA_REPO_SETUP == true ]]; then
        return
    fi
    
    print_info "Setting up CUDA repository..."
    
    # Add NVIDIA GPG key
    wget -qO - https://developer.download.nvidia.com/compute/cuda/repos/debian$(lsb_release -rs)/x86_64/3bf863cc.pub | apt-key add -
    
    # Add CUDA repository
    echo "deb https://developer.download.nvidia.com/compute/cuda/repos/debian$(lsb_release -rs)/x86_64 /" > /etc/apt/sources.list.d/cuda.list
    
    apt update
    CUDA_REPO_SETUP=true
    print_success "CUDA repository setup completed"
}

# Install CUDA toolkit
install_cuda_toolkit() {
    print_header "CUDA Toolkit Installation"
    
    # Check if CUDA is already installed
    if command -v nvcc &> /dev/null; then
        print_info "CUDA toolkit is already installed"
        CUDA_VERSION=$(nvcc --version | grep "release" | sed 's/.*release \([0-9]\+\.[0-9]\+\).*/\1/')
        print_info "Current CUDA version: $CUDA_VERSION"
        read -p "Do you want to update/install a different version? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            return
        fi
    fi
    
    print_info "Installing CUDA toolkit..."
    
    # Setup repository
    setup_cuda_repository
    
    # Check available CUDA toolkit versions
    print_info "Checking available CUDA toolkit versions..."
    apt-cache search cuda-toolkit | grep -E "^cuda-toolkit-1[0-9]" | sort
    
    # Ask user to select version
    echo ""
    echo -e "${CYAN}Available CUDA toolkit versions:${NC}"
    echo -e "${CYAN}1.${NC} cuda-toolkit-12 (latest 12.x)"
    echo -e "${CYAN}2.${NC} cuda-toolkit-13 (latest 13.x)"
    echo -e "${CYAN}3.${NC} cuda-toolkit (meta-package for latest)"
    echo -e "${CYAN}4.${NC} Exit"
    echo ""
    read -p "Select version [1-4]: " cuda_choice
    
    case $cuda_choice in
        1)
            CUDA_PACKAGE="cuda-toolkit-12"
            CUDA_VERSION="12"
            ;;
        2)
            CUDA_PACKAGE="cuda-toolkit-13"
            CUDA_VERSION="13"
            ;;
        3)
            CUDA_PACKAGE="cuda-toolkit"
            CUDA_VERSION="latest"
            ;;
        4)
            print_info "Installation cancelled"
            return
            ;;
        *)
            print_error "Invalid choice. Using cuda-toolkit (latest version)"
            CUDA_PACKAGE="cuda-toolkit"
            CUDA_VERSION="latest"
            ;;
    esac
    
    print_info "Installing $CUDA_PACKAGE..."
    
    # Install CUDA toolkit
    if apt install -y $CUDA_PACKAGE; then
        print_success "CUDA toolkit installation completed"
        
        # Find CUDA installation path
        CUDA_PATH=$(find /usr/local -name "cuda*" -type d 2>/dev/null | head -1)
        if [[ -z "$CUDA_PATH" ]]; then
            CUDA_PATH="/usr/local/cuda"
        fi
        
        # Add CUDA to PATH
        echo 'export PATH=/usr/local/cuda/bin:$PATH' >> /etc/profile.d/cuda.sh
        echo 'export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH' >> /etc/profile.d/cuda.sh
        
        print_info "CUDA added to PATH (will take effect after reboot or sourcing)"
        
        # Verify installation
        if command -v nvcc &> /dev/null; then
            print_success "CUDA installation verified"
            nvcc --version
        else
            print_warning "nvcc not found in PATH, but installation completed"
        fi
        
    else
        print_error "CUDA toolkit installation failed"
        print_info "Trying to install meta-package instead..."
        apt install -y cuda-toolkit
    fi
    
    read -p "Reboot now to complete CUDA setup? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        reboot
    fi
}

################################################################################
# Additional Tools Functions
################################################################################

# Install additional NVIDIA tools
install_nvidia_tools() {
    print_header "NVIDIA Additional Tools Installation"
    
    print_info "Installing additional NVIDIA development tools..."
    
    # Install useful NVIDIA packages
    apt install -y \
        nvidia-cuda-dev \
        nvidia-cuda-toolkit \
        nvidia-profiler \
        nvidia-visual-profiler \
        nvidia-settings
    
    print_success "NVIDIA development tools installed"
    
    # Install Docker with NVIDIA container support
    print_info "Setting up Docker with NVIDIA container support..."
    
    # Add Docker repository
    curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    apt update
    apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    
    # Install NVIDIA Container Toolkit
    distribution=$(. /etc/os-release;echo $ID$VERSION_ID) \
        && curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | apt-key add - \
        && curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | tee /etc/apt/sources.list.d/nvidia-docker.list
    
    apt update
    apt install -y nvidia-container-toolkit
    
    systemctl restart docker
    
    print_success "Docker with NVIDIA support installed"
    
    # Install useful Python packages for NVIDIA development
    if command -v pip3 &> /dev/null; then
        print_info "Installing Python packages for NVIDIA development..."
        pip3 install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121
        pip3 install tensorflow-gpu
        pip3 install jupyterlab
        print_success "Python NVIDIA development packages installed"
    fi
    
    print_success "All additional NVIDIA tools installed"
    read -p "Press Enter to continue..."
}

################################################################################
# System Information Functions
################################################################################

# Display system information
show_system_info() {
    print_header "System Information"
    
    print_info "Operating System: $(lsb_release -d | cut -f2)"
    print_info "Kernel: $(uname -r)"
    print_info "Architecture: $(uname -m)"
    
    # Check for NVIDIA hardware
    if lspci | grep -i nvidia > /dev/null; then
        print_success "NVIDIA hardware detected:"
        lspci | grep -i nvidia
    else
        print_warning "No NVIDIA hardware detected"
    fi
    
    # Display memory information
    print_info "Memory: $(free -h | awk '/^Mem:/{print $2}')"
    
    # Display GPU information if drivers are installed
    if command -v nvidia-smi &> /dev/null; then
        echo ""
        print_info "GPU Information:"
        nvidia-smi --query-gpu=name,memory.total,driver_version --format=csv,noheader
    fi
    
    echo ""
    read -p "Press Enter to continue..."
}

################################################################################
# Menu Functions
################################################################################

# Main menu
show_main_menu() {
    clear
    print_banner
    
    echo -e "${WHITE}Main Menu:${NC}"
    echo ""
    echo -e "${CYAN}1.${NC} Check NVIDIA driver status"
    echo -e "${CYAN}2.${NC} Install NVIDIA drivers"
    echo -e "${CYAN}3.${NC} Install CUDA toolkit"
    echo -e "${CYAN}4.${NC} Uninstall NVIDIA drivers"
    echo -e "${CYAN}5.${NC} Install additional NVIDIA tools"
    echo -e "${CYAN}6.${NC} Show system information"
    echo -e "${CYAN}7.${NC} Update system packages"
    echo -e "${CYAN}8.${NC} Exit"
    echo ""
    echo -n "Select an option [1-8]: "
}

# Handle menu selection
handle_menu_selection() {
    case $1 in
        1)
            check_nvidia_drivers
            ;;
        2)
            install_nvidia_drivers
            ;;
        3)
            install_cuda_toolkit
            ;;
        4)
            uninstall_nvidia_drivers
            ;;
        5)
            install_nvidia_tools
            ;;
        6)
            show_system_info
            ;;
        7)
            update_system
            read -p "Press Enter to continue..."
            ;;
        8)
            print_info "Thank you for using $SCRIPT_NAME"
            exit 0
            ;;
        *)
            print_error "Invalid option. Please select a number between 1-8."
            sleep 2
            ;;
    esac
}

################################################################################
# Main Script
################################################################################

main() {
    # Initial checks
    check_root
    detect_debian_version
    check_internet
    install_dependencies
    
    # Main menu loop
    while true; do
        show_main_menu
        read -r choice
        handle_menu_selection $choice
    done
}

# Trap Ctrl+C
trap 'echo -e "\n${YELLOW}Script interrupted by user${NC}"; exit 1' INT

# Run main function
main "$@"