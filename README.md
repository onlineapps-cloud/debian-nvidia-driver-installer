# 🚀 NVIDIA Driver Manager for Debian

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Debian](https://img.shields.io/badge/Debian-10--13-blue.svg)](https://www.debian.org/)
[![Bash](https://img.shields.io/badge/Bash-4.0+-green.svg)](https://www.gnu.org/software/bash/)
[![NVIDIA](https://img.shields.io/badge/NVIDIA-Driver%20Support-red.svg)](https://www.nvidia.com/)

A comprehensive suite of bash scripts for **universal NVIDIA driver management** on Debian OS versions 10-13. These scripts automate driver installation, CUDA toolkit setup, troubleshooting, and system pre-checks.

## 📋 **Features**

### 🎯 **Main Capabilities**
- **Universal Compatibility**: Works with Debian 10 (Buster) through 13 (Trixie)
- **Driver Management**: Install, update, and uninstall NVIDIA drivers
- **CUDA Toolkit**: Interactive CUDA installation with version selection
- **Automatic Troubleshooting**: Diagnose and fix common NVIDIA driver issues
- **System Pre-checks**: Verify system readiness before driver installation
- **Additional Tools**: Install NVIDIA development tools and Docker support

### 🔧 **Included Scripts**

| Script | Purpose | Description |
|--------|---------|-------------|
| `nvidia_driver_manager.sh` | **Main Manager** | Interactive menu for all NVIDIA operations |
| `nvidia_troubleshoot.sh` | **Troubleshooting** | Diagnose and fix driver issues |
| `nvidia_precheck.sh` | **System Check** | Verify system readiness |
| `README_nvidia_driver_manager.md` | **Documentation** | Detailed usage guide |

## 🚀 **Quick Start**

### Prerequisites
- **Debian 10-13** operating system
- **Internet connection**
- **Administrative privileges** (sudo access)
- **NVIDIA GPU** (recommended)

### Installation
```bash
# Clone the repository
git clone https://github.com/yourusername/nvidia-driver-manager.git
cd nvidia-driver-manager

# Make scripts executable
chmod +x *.sh

# Run the main manager (requires sudo)
sudo ./nvidia_driver_manager.sh
```

## 📖 **Usage Guide**

### 1. **Main Driver Manager** (`nvidia_driver_manager.sh`)
Interactive menu-driven interface for all NVIDIA operations:

```bash
sudo ./nvidia_driver_manager.sh
```

**Main Menu Options:**
```
1. Check NVIDIA driver status
2. Install NVIDIA drivers  
3. Install CUDA toolkit
4. Uninstall NVIDIA drivers
5. Install additional NVIDIA tools
6. Show system information
7. Update system packages
8. Exit
```

### 2. **Troubleshooting Script** (`nvidia_troubleshoot.sh`)
Comprehensive diagnostic and repair tool:

```bash
sudo ./nvidia_troubleshoot.sh
```

**Key Features:**
- **Automatic Diagnostics**: Full system analysis
- **Module Management**: Force reload NVIDIA modules
- **Nouveau Conflict Resolution**: Handle open-source driver conflicts
- **Display Manager Restart**: Fix X.org/display manager issues
- **Log Analysis**: Display system logs for troubleshooting

### 3. **System Pre-check** (`nvidia_precheck.sh`)
Verify system readiness before driver installation:

```bash
sudo ./nvidia_precheck.sh
```

**Checks Performed:**
- Hardware compatibility verification
- System requirements validation
- Driver conflict detection
- Repository accessibility test

## 🛠️ **CUDA Toolkit Installation**

The main manager includes an enhanced CUDA toolkit installer with:

- **Version Selection**: Choose between CUDA 12.x, 13.x, or latest
- **Automatic Repository Setup**: Adds NVIDIA CUDA repository
- **Package Verification**: Ensures correct package installation
- **PATH Configuration**: Automatically configures CUDA environment
- **Installation Verification**: Tests with `nvcc --version`

### Example CUDA Installation:
```bash
# Select option 3 from main menu
Select an option [1-8]: 3

Available CUDA toolkit versions:
1. cuda-toolkit-12 (latest 12.x)
2. cuda-toolkit-13 (latest 13.x)
3. cuda-toolkit (meta-package for latest)
4. Exit

Select version [1-4]: 1
```

## 🔧 **Common Troubleshooting**

### "NVIDIA-SMI has failed because it couldn't communicate with the NVIDIA driver"
This common issue is automatically resolved by the troubleshooting script:

```bash
sudo ./nvidia_troubleshoot.sh --diagnose
```

The script will:
1. **Detect** Nouveau driver conflicts
2. **Create** comprehensive blacklist
3. **Rebuild** initramfs
4. **Restart** display manager
5. **Verify** fix success

### Manual Nouveau Blacklist (if needed):
```bash
# Create blacklist file
echo "blacklist nouveau" | sudo tee /etc/modprobe.d/blacklist-nvidia-nouveau.conf
echo "options nouveau modeset=0" | sudo tee -a /etc/modprobe.d/blacklist-nvidia-nouveau.conf

# Rebuild initramfs
sudo update-initramfs -u -k all

# Restart display manager (example for LightDM)
sudo systemctl restart lightdm
```

### Additional Tools Installation
Install comprehensive NVIDIA development environment:

```bash
# From main menu, select option 5
sudo ./nvidia_driver_manager.sh
# Choose: 5. Install additional NVIDIA tools
```

Includes:
- NVIDIA development libraries
- Docker with NVIDIA container support
- Python packages for AI/ML development
- NVIDIA Container Toolkit

## 📋 **System Requirements**

### Minimum Requirements
- **OS**: Debian 10 (Buster) or later
- **RAM**: 4GB minimum, 8GB recommended
- **Storage**: 10GB free space for drivers + CUDA
- **Internet**: Stable connection for package downloads

### Hardware Support
- **NVIDIA GPUs**: GeForce, Quadro, Tesla, A100, RTX series
- **Architecture**: x86_64 (64-bit)
- **Driver Versions**: 470+ (recommended: latest stable)

## 🐛 **Troubleshooting Common Issues**

### Issue: "Unable to locate package cuda-toolkit-12-0"
**Fixed**: Enhanced script now uses correct package names with version selection menu.

### Issue: Nouveau driver conflicts
**Solution**: Run troubleshooting script with automatic resolution:
```bash
sudo ./nvidia_troubleshoot.sh
# Select option 4: Restart display manager
```

### Issue: Display manager doesn't restart
**Solution**: Manual restart:
```bash
# For LightDM
sudo systemctl restart lightdm

# For GDM3
sudo systemctl restart gdm3

# For SDDM
sudo systemctl restart sddm
```

### Issue: `nvidia-smi` not found after installation
**Solution**: Verify installation and check PATH:
```bash
# Check if drivers are loaded
lsmod | grep nvidia

# Check PATH configuration
echo $PATH | grep cuda

# Source CUDA environment
source /etc/profile.d/cuda.sh
```

## 📁 **File Structure**

```
nvidia-driver-manager/
├── README.md                           # This file
├── README_nvidia_driver_manager.md     # Detailed documentation
├── nvidia_driver_manager.sh            # Main driver manager
├── nvidia_troubleshoot.sh              # Troubleshooting script  
├── nvidia_precheck.sh                  # System pre-check tool
└── docs/                               # Additional documentation
```

## 🔧 **Advanced Configuration**

### Custom Driver Installation
For custom driver versions, modify the script variables:
```bash
# Edit nvidia_driver_manager.sh
NVIDIA_DRIVER_PACKAGE="nvidia-driver-525"  # Example: specific version
```

### Repository Mirrors
Change CUDA repository mirror by editing:
```bash
# In setup_cuda_repository() function
echo "deb [trusted=yes] https://your-mirror.com/cuda/repos/debian$(lsb_release -rs)/x86_64 /" > /etc/apt/sources.list.d/cuda.list
```

## 🤝 **Contributing**

Contributions are welcome! Please:

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/amazing-feature`)
3. **Commit** your changes (`git commit -m 'Add amazing feature'`)
4. **Push** to the branch (`git push origin feature/amazing-feature`)
5. **Open** a Pull Request

### Development Guidelines
- Follow bash best practices
- Add comprehensive error handling
- Include detailed comments
- Test on multiple Debian versions
- Update documentation

## 📄 **License**

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

## 🙏 **Acknowledgments**

- **NVIDIA Corporation** for driver and CUDA documentation
- **Debian Project** for excellent package management
- **Community contributors** for testing and feedback

## 📞 **Support**

For issues and support:

- **GitHub Issues**: [Create an issue](https://github.com/yourusername/nvidia-driver-manager/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/nvidia-driver-manager/discussions)
- **Documentation**: See `README_nvidia_driver_manager.md` for detailed guide

---

**Made with ❤️ for the Debian and NVIDIA community**

*Last updated: December 2024*
