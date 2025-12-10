#!/bin/bash

################################################################################
# NVIDIA Driver Troubleshooting Script
# Diagnoses and fixes common nvidia-smi communication errors
################################################################################

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Global variables
ISSUE_FOUND=false
FIXES_APPLIED=0

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
    ISSUE_FOUND=true
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
    ISSUE_FOUND=true
}

print_info() {
    echo -e "${CYAN}ℹ $1${NC}"
}

print_fix() {
    echo -e "${PURPLE}🔧 $1${NC}"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root (use sudo)"
        exit 1
    fi
}

# Check if nvidia-smi command exists
check_nvidia_smi_exists() {
    print_info "Checking if nvidia-smi command exists..."
    if command -v nvidia-smi &> /dev/null; then
        print_success "nvidia-smi command found"
        return 0
    else
        print_error "nvidia-smi command not found"
        print_fix "Run the NVIDIA driver installer to install drivers"
        return 1
    fi
}

# Check if NVIDIA hardware is detected
check_hardware_detection() {
    print_header "Step 1: Hardware Detection"
    
    print_info "Checking for NVIDIA hardware..."
    if lspci | grep -i nvidia > /dev/null; then
        print_success "NVIDIA hardware detected:"
        lspci | grep -i nvidia | while read -r line; do
            echo -e "  ${GREEN}•${NC} $line"
        done
        return 0
    else
        print_error "No NVIDIA hardware detected by system"
        print_fix "Possible solutions:"
        echo "  1. Verify GPU is properly seated in PCIe slot"
        echo "  2. Check GPU power connections"
        echo "  3. Try different PCIe slot"
        echo "  4. Check BIOS/UEFI settings for PCIe devices"
        echo "  5. Try GPU in another system to verify it's working"
        return 1
    fi
}

# Check kernel module status
check_kernel_module() {
    print_header "Step 2: Kernel Module Status"
    
    print_info "Checking if NVIDIA kernel module is loaded..."
    if lsmod | grep -q nvidia; then
        print_success "NVIDIA kernel module is loaded"
        echo -e "  ${GREEN}Loaded modules:${NC}"
        lsmod | grep nvidia | while read -r line; do
            echo -e "  • $line"
        done
        return 0
    else
        print_warning "NVIDIA kernel module is NOT loaded"
        print_fix "Attempting to load NVIDIA kernel module..."
        if modprobe nvidia 2>/dev/null; then
            print_success "NVIDIA kernel module loaded successfully"
            ((FIXES_APPLIED++))
            return 0
        else
            print_error "Failed to load NVIDIA kernel module"
            return 1
        fi
    fi
}

# Check for Nouveau driver conflict
check_nouveau_conflict() {
    print_header "Step 3: Nouveau Driver Conflict Check"
    
    print_info "Checking for Nouveau driver..."
    if lsmod | grep -q nouveau; then
        print_warning "Nouveau driver is loaded (conflicts with NVIDIA)"
        print_fix "Blacklisting Nouveau driver..."
        
        # Create comprehensive blacklist configuration
        cat > /etc/modprobe.d/blacklist-nvidia-nouveau.conf << 'EOF'
# Blacklist Nouveau driver to prevent conflicts with NVIDIA
blacklist nouveau
blacklist lbm-nouveau
options nouveau modeset=0
install nouveau /bin/false
EOF
        print_success "Comprehensive Nouveau blacklist created"
        ((FIXES_APPLIED++))
        
        # Check if X.org or display manager is running
        if systemctl is-active --quiet lightdm 2>/dev/null; then
            print_warning "LightDM is running with Nouveau driver"
            print_info "Display manager restart will be needed to apply blacklist"
            return 2  # Special return code for X.org conflict
        elif [[ -n "$DISPLAY" ]] && pgrep -x "Xorg" > /dev/null; then
            print_warning "X.org is running with Nouveau driver"
            print_info "Display manager restart will be needed to apply blacklist"
            return 2  # Special return code for X.org conflict
        else
            # Try to unload nouveau if no X session
            if lsmod | grep -q nouveau; then
                rmmod nouveau 2>/dev/null && print_success "Nouveau driver unloaded" || print_warning "Could not unload Nouveau driver"
            fi
            return 1
        fi
    else
        print_success "No Nouveau driver detected"
        return 0
    fi
}

# Check for running display managers
check_display_manager() {
    print_header "Display Manager Check"
    
    print_info "Checking for active display managers..."
    
    # Check for common display managers
    if systemctl is-active --quiet lightdm 2>/dev/null; then
        print_info "LightDM is active"
        LIGHTDM_ACTIVE=true
    else
        LIGHTDM_ACTIVE=false
    fi
    
    if systemctl is-active --quiet gdm3 2>/dev/null; then
        print_info "GDM3 is active"
        GDM3_ACTIVE=true
    else
        GDM3_ACTIVE=false
    fi
    
    if systemctl is-active --quiet sddm 2>/dev/null; then
        print_info "SDDM is active"
        SDDM_ACTIVE=true
    else
        SDDM_ACTIVE=false
    fi
    
    # Check if X.org is running
    if pgrep -x "Xorg" > /dev/null; then
        print_info "X.org is running"
        XORG_ACTIVE=true
    else
        XORG_ACTIVE=false
    fi
    
    # Return true if any display manager is active
    if [[ "$LIGHTDM_ACTIVE" == true ]] || [[ "$GDM3_ACTIVE" == true ]] || [[ "$SDDM_ACTIVE" == true ]] || [[ "$XORG_ACTIVE" == true ]]; then
        return 0
    else
        print_info "No active display manager detected"
        return 1
    fi
}

# Restart display manager to apply driver changes
restart_display_manager() {
    print_header "Restarting Display Manager"
    
    print_info "Restarting display manager to apply blacklist changes..."
    
    # Determine which display manager to restart
    if systemctl is-active --quiet lightdm 2>/dev/null; then
        print_info "Restarting LightDM..."
        if systemctl restart lightdm 2>/dev/null; then
            print_success "LightDM restarted successfully"
            ((FIXES_APPLIED++))
            return 0
        else
            print_error "Failed to restart LightDM"
            return 1
        fi
    elif systemctl is-active --quiet gdm3 2>/dev/null; then
        print_info "Restarting GDM3..."
        if systemctl restart gdm3 2>/dev/null; then
            print_success "GDM3 restarted successfully"
            ((FIXES_APPLIED++))
            return 0
        else
            print_error "Failed to restart GDM3"
            return 1
        fi
    elif systemctl is-active --quiet sddm 2>/dev/null; then
        print_info "Restarting SDDM..."
        if systemctl restart sddm 2>/dev/null; then
            print_success "SDDM restarted successfully"
            ((FIXES_APPLIED++))
            return 0
        else
            print_error "Failed to restart SDDM"
            return 1
        fi
    else
        print_info "No supported display manager found to restart"
        return 1
    fi
}

# Check Secure Boot status
check_secure_boot() {
    print_header "Step 4: Secure Boot Check"
    
    if command -v mokutil &> /dev/null; then
        print_info "Checking Secure Boot status..."
        if mokutil --sb-state 2>/dev/null | grep -q "Secure Boot enabled"; then
            print_warning "Secure Boot is ENABLED"
            print_fix "Secure Boot can prevent proprietary drivers from loading"
            echo ""
            echo "Solutions:"
            echo "  1. Disable Secure Boot in BIOS/UEFI settings"
            echo "  2. Sign NVIDIA kernel modules (advanced)"
            echo "  3. Use shim-signed with MOK (Ubuntu, more complex)"
            return 1
        else
            print_success "Secure Boot is disabled or not active"
            return 0
        fi
    else
        print_info "mokutil not available, skipping Secure Boot check"
        return 0
    fi
}

# Check kernel headers
check_kernel_headers() {
    print_header "Step 5: Kernel Headers Check"
    
    print_info "Checking for kernel headers..."
    KERNEL_VERSION=$(uname -r)
    
    if [[ -d "/usr/src/linux-headers-${KERNEL_VERSION}" ]]; then
        print_success "Kernel headers found for version $KERNEL_VERSION"
        return 0
    else
        print_warning "Kernel headers not found for version $KERNEL_VERSION"
        print_fix "Installing kernel headers..."
        
        # Try to install kernel headers
        if apt update && apt install -y linux-headers-$(uname -r) 2>/dev/null; then
            print_success "Kernel headers installed"
            ((FIXES_APPLIED++))
            return 0
        else
            print_error "Failed to install kernel headers"
            print_fix "Try: apt install linux-headers-\$(uname -r)"
            return 1
        fi
    fi
}

# Check NVIDIA driver package installation
check_driver_package() {
    print_header "Step 6: Driver Package Check"
    
    print_info "Checking installed NVIDIA packages..."
    if dpkg -l | grep -q "nvidia-driver"; then
        DRIVER_VERSION=$(dpkg -l | grep nvidia-driver | awk '{print $3}' | head -1)
        print_success "NVIDIA driver package installed: version $DRIVER_VERSION"
        
        # Check if driver version matches current kernel
        print_info "Checking driver/kernel compatibility..."
        if nvidia-smi --query-gpu=driver_version --format=csv,noheader,nounits 2>/dev/null | head -1 >/dev/null; then
            print_success "Driver appears to be working"
            return 0
        else
            print_warning "Driver installed but not functioning properly"
            return 1
        fi
    else
        print_error "NVIDIA driver package not found"
        print_fix "Run the NVIDIA driver installer script"
        return 1
    fi
}

# Check system reboot requirement
check_reboot_requirement() {
    print_header "Step 7: Reboot Check"
    
    print_info "Checking if system needs reboot..."
    
    # Check if nvidia modules are in initramfs
    if lsinitramfs /boot/initrd.img-$(uname -r) 2>/dev/null | grep -q nvidia; then
        print_success "NVIDIA modules are in initramfs"
    else
        print_warning "NVIDIA modules may not be in initramfs"
        print_fix "Update initramfs..."
        if update-initramfs -u 2>/dev/null; then
            print_success "Initramfs updated"
            ((FIXES_APPLIED++))
        else
            print_error "Failed to update initramfs"
        fi
    fi
    
    # Check if system recently installed drivers
    if [[ -f /var/log/dpkg.log ]]; then
        RECENT_NVIDIA=$(grep -i "nvidia-driver" /var/log/dpkg.log | tail -1)
        if [[ -n "$RECENT_NVIDIA" ]]; then
            print_warning "NVIDIA drivers were recently installed"
            print_fix "A system reboot is RECOMMENDED"
            echo "Recent installation: $RECENT_NVIDIA"
            return 1
        fi
    fi
    
    return 0
}

# Try to run nvidia-smi and analyze output
test_nvidia_smi() {
    print_header "Step 8: nvidia-smi Test"
    
    print_info "Testing nvidia-smi command..."
    if nvidia-smi &> /tmp/nvidia_smi_test.log; then
        print_success "nvidia-smi is working!"
        echo -e "${GREEN}Output:${NC}"
        cat /tmp/nvidia_smi_test.log
        return 0
    else
        print_error "nvidia-smi failed"
        echo -e "${RED}Error output:${NC}"
        cat /tmp/nvidia_smi_test.log
        return 1
    fi
}

# Apply automatic fixes
apply_automatic_fixes() {
    print_header "Applying Automatic Fixes"
    
    # Try to reload kernel modules
    print_fix "Reloading NVIDIA kernel modules..."
    if lsmod | grep -q nvidia; then
        rmmod nvidia 2>/dev/null || true
        rmmod nvidia_drm 2>/dev/null || true
        rmmod nvidia_modeset 2>/dev/null || true
    fi
    
    if modprobe nvidia 2>/dev/null; then
        print_success "NVIDIA modules reloaded"
        ((FIXES_APPLIED++))
    fi
    
    # Try to load additional modules
    print_fix "Loading additional NVIDIA modules..."
    modprobe nvidia_drm 2>/dev/null && print_success "nvidia_drm loaded" || true
    modprobe nvidia_modeset 2>/dev/null && print_success "nvidia_modeset loaded" || true
    
    # Update module dependencies
    print_fix "Updating module dependencies..."
    depmod -a 2>/dev/null && print_success "Module dependencies updated" || true
    
    # Update initramfs if drivers were loaded
    if lsmod | grep -q nvidia; then
        print_fix "Updating initramfs..."
        update-initramfs -u 2>/dev/null && print_success "Initramfs updated" || print_warning "Could not update initramfs"
        ((FIXES_APPLIED++))
    fi
}

# Provide manual fix suggestions
provide_manual_fixes() {
    print_header "Manual Fix Suggestions"
    
    echo -e "${YELLOW}If automatic fixes didn't work, try these manual steps:${NC}"
    echo ""
    
    echo -e "${CYAN}1. Complete Driver Reinstallation:${NC}"
    echo "   sudo apt remove --purge ^nvidia-"
    echo "   sudo apt autoremove"
    echo "   sudo reboot"
    echo "   # Then run the NVIDIA driver installer again"
    echo ""
    
    echo -e "${CYAN}2. Check for Conflicting Packages:${NC}"
    echo "   sudo apt list --installed | grep nvidia"
    echo "   sudo apt remove --purge conflicting-packages"
    echo ""
    
    echo -e "${CYAN}3. Rebuild Kernel Modules:${NC}"
    echo "   sudo apt install --reinstall nvidia-driver"
    echo "   sudo reboot"
    echo ""
    
    echo -e "${CYAN}4. Check System Logs:${NC}"
    echo "   sudo dmesg | grep nvidia"
    echo "   sudo journalctl -xe | grep nvidia"
    echo ""
    
    echo -e "${CYAN}5. Verify Hardware:${NC}"
    echo "   sudo lspci -v | grep -i nvidia"
    echo "   sudo dmidecode -t baseboard | grep -i nvidia"
    echo ""
}

# Main diagnostic function
run_diagnostics() {
    clear
    print_header "NVIDIA Driver Troubleshooting"
    echo -e "${WHITE}Diagnosing nvidia-smi communication issues...${NC}"
    echo ""
    
    # Run all checks
    check_hardware_detection
    echo ""
    
    if ! check_nvidia_smi_exists; then
        echo ""
        provide_manual_fixes
        return 1
    fi
    
    echo ""
    check_kernel_module
    echo ""
    
    # Check for Nouveau conflict with special handling for X.org
    NOUVEAU_STATUS=$(check_nouveau_conflict)
    echo ""
    
    check_display_manager
    echo ""
    
    check_secure_boot
    echo ""
    
    check_kernel_headers
    echo ""
    
    check_driver_package
    echo ""
    
    check_reboot_requirement
    echo ""
    
    # Handle Nouveau/X.org conflict specifically
    if [[ $NOUVEAU_STATUS -eq 2 ]]; then
        print_header "Special Handling: X.org/Nouveau Conflict"
        print_warning "Nouveau driver conflict detected with active display manager"
        print_fix "Applying comprehensive fix..."
        
        # Update initramfs with blacklist
        if update-initramfs -u -k all 2>/dev/null; then
            print_success "Initramfs rebuilt with Nouveau blacklist"
            ((FIXES_APPLIED++))
        else
            print_warning "Failed to update initramfs"
        fi
        
        # Restart display manager to apply changes
        if restart_display_manager; then
            print_success "Display manager restarted - NVIDIA drivers should now be active"
            print_info "Waiting 5 seconds for display manager to fully restart..."
            sleep 5
            
            # Test if nvidia-smi works now
            if nvidia-smi &> /tmp/nvidia_smi_after_restart.log; then
                print_success "🎉 SUCCESS! nvidia-smi is now working!"
                echo -e "${GREEN}Output:${NC}"
                cat /tmp/nvidia_smi_after_restart.log
                return 0
            else
                print_warning "nvidia-smi still not working after restart"
                echo -e "${YELLOW}This may require a full system reboot to take effect${NC}"
            fi
        else
            print_error "Failed to restart display manager"
            print_info "Manual restart may be required or system reboot"
        fi
        echo ""
    fi
    
    # Try automatic fixes
    apply_automatic_fixes
    echo ""
    
    # Test nvidia-smi again
    if test_nvidia_smi; then
        print_success "Problem appears to be resolved!"
        return 0
    else
        echo ""
        provide_manual_fixes
        return 1
    fi
}

# Interactive fix menu
show_fix_menu() {
    while true; do
        clear
        print_header "NVIDIA Driver Fix Menu"
        
        echo -e "${WHITE}Select a fix option:${NC}"
        echo ""
        echo -e "${CYAN}1.${NC} Run full diagnostics"
        echo -e "${CYAN}2.${NC} Force reload NVIDIA modules"
        echo -e "${CYAN}3.${NC} Blacklist Nouveau driver"
        echo -e "${CYAN}4.${NC} Restart display manager (FIXES Nouveau conflict)"
        echo -e "${CYAN}5.${NC} Install kernel headers"
        echo -e "${CYAN}6.${NC} Update initramfs"
        echo -e "${CYAN}7.${NC} Complete driver reinstall (DESTRUCTIVE)"
        echo -e "${CYAN}8.${NC} Show system logs"
        echo -e "${CYAN}9.${NC} Exit"
        echo ""
        echo -n "Select option [1-9]: "
        
        read -r choice
        case $choice in
            1)
                run_diagnostics
                echo ""
                read -p "Press Enter to continue..."
                ;;
            2)
                print_fix "Reloading NVIDIA modules..."
                rmmod nvidia 2>/dev/null || true
                rmmod nvidia_drm 2>/dev/null || true
                rmmod nvidia_modeset 2>/dev/null || true
                modprobe nvidia
                modprobe nvidia_drm 2>/dev/null || true
                modprobe nvidia_modeset 2>/dev/null || true
                print_success "Modules reloaded"
                sleep 2
                ;;
            3)
                print_fix "Blacklisting Nouveau..."
                echo "blacklist nouveau" > /etc/modprobe.d/nvidia-nouveau.conf
                echo "options nouveau modeset=0" >> /etc/modprobe.d/nvidia-nouveau.conf
                print_success "Nouveau blacklisted"
                sleep 2
                ;;
            4)
                print_header "Display Manager Restart"
                print_fix "Restarting display manager to apply driver changes..."
                if restart_display_manager; then
                    print_success "Display manager restarted successfully"
                    print_info "NVIDIA drivers should now be active"
                    sleep 3
                else
                    print_error "Failed to restart display manager"
                    sleep 2
                fi
                ;;
            5)
                print_fix "Installing kernel headers..."
                apt update && apt install -y linux-headers-$(uname -r)
                print_success "Kernel headers installation attempted"
                sleep 2
                ;;
            6)
                print_fix "Updating initramfs..."
                update-initramfs -u
                print_success "Initramfs updated"
                sleep 2
                ;;
            7)
                print_warning "This will remove all NVIDIA drivers!"
                read -p "Are you sure? (y/N): " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    print_fix "Removing NVIDIA drivers..."
                    apt remove --purge -y ^nvidia-*
                    apt autoremove -y
                    print_success "NVIDIA drivers removed. Reboot and reinstall."
                    sleep 3
                fi
                ;;
            8)
                print_header "Recent NVIDIA kernel messages"
                dmesg | grep -i nvidia | tail -20
                echo ""
                read -p "Press Enter to continue..."
                ;;
            9)
                exit 0
                ;;
            *)
                print_error "Invalid option"
                sleep 1
                ;;
        esac
    done
}

# Main function
main() {
    check_root
    
    if [[ $# -eq 0 ]]; then
        show_fix_menu
    else
        case $1 in
            --diagnose|--test)
                run_diagnostics
                ;;
            --fix)
                apply_automatic_fixes
                ;;
            --help|-h)
                echo "Usage: sudo $0 [option]"
                echo "Options:"
                echo "  (no option)  Interactive fix menu"
                echo "  --diagnose   Run diagnostics only"
                echo "  --fix        Apply automatic fixes only"
                echo "  --help       Show this help"
                ;;
            *)
                echo "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    fi
}

# Trap Ctrl+C
trap 'echo -e "\n${YELLOW}Script interrupted by user${NC}"; exit 1' INT

main "$@"