# NVIDIA Driver Manager for Debian

A comprehensive bash script for managing NVIDIA drivers and related tools on Debian OS versions 10-13.

## Features

- **Universal Compatibility**: Supports Debian versions 10 (Buster), 11 (Bullseye), 12 (Bookworm), and 13 (Trixie)
- **Interactive Menu System**: Easy-to-use console interface with color-coded output
- **Driver Management**: Install, check status, and uninstall NVIDIA drivers
- **CUDA Toolkit Support**: Install and manage CUDA development environment
- **Additional Tools**: Install development tools, Docker with NVIDIA support, and Python packages
- **System Information**: Display detailed system and GPU information
- **Safety Features**: Validation checks and confirmation prompts
- **Comprehensive Troubleshooting**: Dedicated script for diagnosing and fixing common issues
- **Pre-Installation Checks**: System readiness verification before driver installation
- **Automatic Fixes**: Script can automatically resolve most common driver problems

## Requirements

- Debian 10, 11, 12, or 13
- Root privileges (sudo access)
- Internet connection
- x86_64 architecture

## Installation

1. Download the scripts:
```bash
wget https://raw.githubusercontent.com/your-repo/nvidia-driver-manager.sh
wget https://raw.githubusercontent.com/your-repo/nvidia_troubleshoot.sh
wget https://raw.githubusercontent.com/your-repo/nvidia_precheck.sh
```

2. Make them executable:
```bash
chmod +x nvidia_driver_manager.sh nvidia_troubleshoot.sh nvidia_precheck.sh
```

3. Optional: Run pre-check before installation:
```bash
sudo ./nvidia_precheck.sh
```

4. Run the main script as root:
```bash
sudo ./nvidia_driver_manager.sh
```

## 🚨 Quick Fix for Common Error

If you get the error: **"NVIDIA-SMI has failed because it couldn't communicate with the NVIDIA driver"**

**Immediate solution:**
```bash
sudo ./nvidia_troubleshoot.sh
```

This comprehensive troubleshooting script will diagnose and fix the issue automatically.

## Usage

### Main Menu Options

1. **Check NVIDIA driver status**
   - Verify if drivers are installed
   - Display current driver version
   - Show CUDA version if available
   - List installed NVIDIA packages

2. **Install NVIDIA drivers**
   - Automatic driver installation for your Debian version
   - Handles dependencies and firmware
   - Prompts for system reboot

3. **Install CUDA toolkit**
   - Sets up NVIDIA CUDA repository
   - Installs CUDA toolkit 12.0
   - Configures environment variables

4. **Uninstall NVIDIA drivers**
   - Complete removal of all NVIDIA packages
   - Cleans configuration files
   - Prompts for confirmation

5. **Install additional NVIDIA tools**
   - Development tools (nvcc, profiler, visual profiler)
   - Docker with NVIDIA container support
   - Python packages for GPU computing

6. **Show system information**
   - OS and kernel information
   - Detected NVIDIA hardware
   - GPU specifications
   - Memory information

7. **Update system packages**
   - Refresh package lists
   - Update installed packages

8. **Exit**

### Available Scripts

- **nvidia_driver_manager.sh**: Main installation and management script
- **nvidia_troubleshoot.sh**: Comprehensive troubleshooting and repair tool
- **nvidia_precheck.sh**: Pre-installation system readiness check

### Safety Features

- **Root Check**: Ensures script runs with proper privileges
- **Version Validation**: Warns if running unsupported Debian version
- **Internet Check**: Verifies connectivity before proceeding
- **Confirmation Prompts**: Asks for user confirmation before destructive operations
- **Error Handling**: Graceful error handling and informative messages

## What the Script Does

### Driver Installation Process

1. **System Detection**: Identifies Debian version and validates compatibility
2. **Dependency Check**: Installs required packages (wget, gnupg2, software-properties-common)
3. **Repository Setup**: Configures appropriate repositories for your Debian version
4. **Driver Installation**: Installs `nvidia-driver` package with firmware support
5. **Verification**: Checks installation status using `nvidia-smi`

### CUDA Installation Process

1. **Repository Setup**: Adds NVIDIA GPG keys and CUDA repository
2. **Package Installation**: Installs `cuda-toolkit-12-0`
3. **Environment Configuration**: Sets up PATH and LD_LIBRARY_PATH variables
4. **Validation**: Verifies installation with `nvcc --version`

### Additional Tools Installation

1. **Development Tools**: Installs CUDA development packages
2. **Docker Setup**: Installs Docker with NVIDIA Container Toolkit
3. **Python Support**: Installs PyTorch, TensorFlow, and JupyterLab with GPU support
4. **System Integration**: Configures services and permissions

## Troubleshooting

### 🚨 Critical Issue: "NVIDIA-SMI has failed because it couldn't communicate with the NVIDIA driver"

This is the most common error after driver installation. The NVIDIA drivers appear to be installed but `nvidia-smi` can't communicate with them.

#### Quick Fix (Run this first):
```bash
sudo ./nvidia_troubleshoot.sh
```

#### Manual Diagnostic Steps:

1. **Check if kernel module is loaded:**
   ```bash
   lsmod | grep nvidia
   ```

2. **Try to load the module manually:**
   ```bash
   sudo modprobe nvidia
   ```

3. **Check for Nouveau conflict:**
   ```bash
   lsmod | grep nouveau
   ```

4. **Check Secure Boot status:**
   ```bash
   sudo mokutil --sb-state
   ```

5. **Check kernel headers:**
   ```bash
   ls /usr/src/linux-headers-$(uname -r)
   ```

### Common Issues and Solutions

**"No NVIDIA hardware detected"**
- Ensure your system has an NVIDIA GPU
- Check if GPU is properly seated in PCIe slot
- Verify BIOS/UEFI settings
- Try: `sudo lspci | grep -i nvidia`

**"NVIDIA-SMI has failed because it couldn't communicate with the NVIDIA driver"**
- **Most common cause**: NVIDIA kernel module not loaded
- **Solution**: Run the troubleshooting script: `sudo ./nvidia_troubleshoot.sh`
- **Manual fix**:
  ```bash
  sudo modprobe nvidia
  sudo update-initramfs -u
  sudo reboot
  ```

**"Nouveau driver conflict"**
- **Symptom**: `lsmod | grep nouveau` shows Nouveau is loaded
- **Solution**: Blacklist Nouveau driver:
  ```bash
  echo "blacklist nouveau" | sudo tee /etc/modprobe.d/nvidia-nouveau.conf
  echo "options nouveau modeset=0" | sudo tee -a /etc/modprobe.d/nvidia-nouveau.conf
  sudo update-initramfs -u
  sudo reboot
  ```

**"Secure Boot enabled"**
- **Symptom**: Drivers install but won't load
- **Solution**: Disable Secure Boot in BIOS/UEFI settings

**"Kernel headers not found"**
- **Solution**: Install kernel headers:
  ```bash
  sudo apt install linux-headers-$(uname -r)
  ```

**"Internet connection required"**
- Check network connectivity
- Verify DNS resolution
- Check firewall/proxy settings

**"Permission denied"**
- Run script with `sudo`
- Ensure you have root access

**"Package installation failed"**
- Update system packages first (option 7)
- Check available disk space
- Verify package repository accessibility

### Using the Troubleshooting Script

The `nvidia_troubleshoot.sh` script provides comprehensive diagnostics and automatic fixes:

```bash
# Interactive troubleshooting menu
sudo ./nvidia_troubleshoot.sh

# Run diagnostics only
sudo ./nvidia_troubleshoot.sh --diagnose

# Apply automatic fixes only
sudo ./nvidia_troubleshoot.sh --fix

# Show help
sudo ./nvidia_troubleshoot.sh --help
```

The script will check:
- ✅ Hardware detection
- ✅ Kernel module loading
- ✅ Nouveau driver conflicts
- ✅ Secure Boot status
- ✅ Kernel headers installation
- ✅ Driver package integrity
- ✅ Initramfs configuration

### Log Files

The script provides real-time output for troubleshooting. For detailed logs:
```bash
sudo ./nvidia_driver_manager.sh 2>&1 | tee installation.log
```

## Advanced Usage

### Command Line Options

While the script is primarily interactive, you can examine specific sections:
```bash
# Check driver status only
sudo bash -c 'source ./nvidia_driver_manager.sh; check_nvidia_drivers'

# Show system info only
sudo bash -c 'source ./nvidia_driver_manager.sh; show_system_info'
```

### Custom CUDA Version

To install a different CUDA version, modify the `install_cuda_toolkit()` function:
```bash
apt install -y cuda-toolkit-11-8  # For CUDA 11.8
```

## Compatibility

### Supported Debian Versions

| Debian Version | Code Name    | Status       |
|----------------|--------------|--------------|
| 10             | Buster       | ✅ Supported |
| 11             | Bullseye     | ✅ Supported |
| 12             | Bookworm     | ✅ Supported |
| 13             | Trixie       | ✅ Supported |

### NVIDIA Hardware Support

The script works with all modern NVIDIA GPUs:
- GeForce ( GTX/RTX series)
- Quadro (Professional series)
- Tesla (Data center series)
- A100, H100, V100
- And other CUDA-capable NVIDIA hardware

## Security Considerations

- Script requires root privileges for system modifications
- Downloads packages from official NVIDIA and Debian repositories
- Uses secure HTTPS connections for repository access
- No malicious code or unauthorized modifications

## Contributing

To improve this script:

1. Test on different Debian versions
2. Add support for newer CUDA versions
3. Improve error handling
4. Add more NVIDIA tools
5. Enhance hardware detection

## License

This script is provided as-is for educational and practical use. Please review and understand what the script does before running it on your system.

## Support

For issues or questions:
1. Check the troubleshooting section
2. Review system logs
3. Ensure all prerequisites are met
4. Test with a fresh Debian installation in a VM first

---

**Warning**: Installing graphics drivers can potentially cause display issues if something goes wrong. Always ensure you have a way to access the system (SSH, console) if the GUI fails to load after driver installation.