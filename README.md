# ESPTool v5 Automator

A comprehensive PowerShell 7 script for ESP32-WROOM-32E and ESP32-S3 device management, featuring an interactive console UI with ASCII interface for flashing, eFuse management, MAC operations, memory operations, and more.

## 🚀 Features

### Core Functionality
- **Interactive Console UI** with ASCII art interface
- **Automatic Device Detection** for ESP32-WROOM-32E and ESP32-S3
- **Serial Port Management** with auto-detection and selection
- **Firmware Flashing** with automatic file detection
- **eFuse Management** (read, burn, summary)
- **MAC Address Operations** (read, write)
- **Memory Operations** (read, write, dump)
- **Flash Operations** (erase, dump, ID reading)

### Supported Operations
1. **Read Chip ID** - Get ESP32 chip identification
2. **Read Flash ID** - Retrieve flash memory ID
3. **Erase Flash** - Completely erase flash memory
4. **Flash Firmware** - Flash bootloader, partition table, and firmware
5. **Dump Flash** - Extract flash memory contents
6. **Read MAC** - Read device MAC address
7. **Write MAC** - Write new MAC address
8. **Read eFuses** - Display eFuse summary
9. **Burn eFuse** - Burn specific eFuses
10. **Read Memory** - Read from device memory
11. **Write Memory** - Write to device memory
12. **Load+Exec Stub** - Load and execute stub code
13. **Reset Chip** - Reset the ESP32 device
14. **esptool Version** - Check esptool version

## 📋 Prerequisites

### Required Software
- **PowerShell 7** or later
- **Python 3.7+** (for esptool)
- **esptool v5** (`pip install esptool`)
- **espefuse** (included with esptool)

### Hardware Requirements
- **ESP32-WROOM-32E** or **ESP32-S3** device
- **USB-to-Serial cable** (CP210x, CH340, FTDI, etc.)
- **Windows 10/11** (tested on Windows 10.0.22631)

### Installation Steps

1. **Install Python 3.7+**
   ```bash
   # Download from https://www.python.org/downloads/
   # Ensure "Add Python to PATH" is checked during installation
   ```

2. **Install esptool v5**
   ```bash
   pip install esptool
   ```

3. **Verify Installation**
   ```bash
   esptool.exe version
   espefuse.exe version
   ```

4. **Download ESPAutomator.ps1**
   ```bash
   # Place the script in your desired directory
   ```

## 🎯 Quick Start

### Basic Usage

1. **Navigate to your firmware directory**
   ```powershell
   cd "C:\path\to\your\firmware\folder"
   ```

2. **Run the script**
   ```powershell
   .\ESPAutomator.ps1
   ```

3. **Follow the interactive prompts**
   - Select your serial port
   - Choose your chip type
   - Select desired operation

### Firmware Flashing Workflow

1. **Prepare your firmware files** in the current directory:
   ```
   firmware_folder/
   ├── bootloader.bin
   ├── partition-table.bin
   └── firmware.bin
   ```

2. **Run the script and select option 4** (Flash Firmware)

3. **When prompted for firmware folder**, press **Enter** to use current directory

4. **The script will automatically detect**:
   - `boot*.bin` files as bootloader
   - `part*.bin` files as partition table
   - `firm*.bin` or `app*.bin` files as firmware

## 📁 File Structure

### Expected Firmware Files
The script automatically detects firmware files with these patterns:
- **Bootloader**: `boot*.bin` (e.g., `bootloader.bin`)
- **Partition Table**: `part*.bin` (e.g., `partition-table.bin`)
- **Firmware**: `firm*.bin` or `app*.bin` (e.g., `firmware.bin`, `app.bin`)

### Script Location
```
Your_Project/
├── ESPAutomator.ps1
├── bootloader.bin
├── partition-table.bin
├── firmware.bin
└── README.md
```

## 🔧 Configuration

### Baud Rate
Default baud rate is set to **460800**. To modify:
```powershell
# Line 18 in ESPAutomator.ps1
$script:baud = 460800  # Change this value
```

### UI Colors
Customize the interface colors by modifying the `$script:UIColors` hash:
```powershell
$script:UIColors = @{
    Title     = 'DarkCyan'
    Section   = 'Magenta'
    MenuItem  = 'White'
    Highlight = 'Black'
    Warning   = 'Yellow'
    Error     = 'Red'
}
```

## 🎮 Usage Examples

### Example 1: Flash New Firmware
```powershell
# Navigate to firmware directory
cd "C:\ESP32_Projects\MyProject\build"

# Run script
.\ESPAutomator.ps1

# Select option 4 (Flash Firmware)
# Press Enter for current directory
# Script auto-detects firmware files
```

### Example 2: Read Device Information
```powershell
.\ESPAutomator.ps1

# Select option 1 (Read Chip ID)
# Select option 6 (Read MAC)
# Select option 8 (Read eFuses)
```

### Example 3: Backup Flash Memory
```powershell
.\ESPAutomator.ps1

# Select option 5 (Dump Flash)
# Enter: Start offset: 0x00000
# Enter: Length: 4194304 (4MB)
# Enter: Output filename: backup.bin
```

## ⚠️ Important Notes

### Safety Warnings
- **eFuse burning is irreversible** - Use with extreme caution
- **Flash erasing removes all data** - Ensure you have backups
- **MAC address changes** may affect device identification
- **Test on development boards** before production use

### Troubleshooting

#### Common Issues

1. **"esptool.exe not found"**
   ```bash
   # Solution: Install esptool
   pip install esptool
   ```

2. **"No COM ports found"**
   - Check USB connection
   - Install correct USB-to-Serial drivers
   - Try different USB cable

3. **"Failed to connect"**
   - Put ESP32 in download mode (hold BOOT button)
   - Check baud rate compatibility
   - Verify chip type selection

4. **"Permission denied"**
   ```powershell
   # Run PowerShell as Administrator
   # Or modify execution policy
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

#### Debug Mode
To see detailed esptool output, the script displays all commands being executed.

## 🔄 Version History

### v1.2.0 (Current)
- Added current directory support for firmware flashing
- Enhanced error handling
- Improved UI responsiveness
- Added automatic file detection

### v1.1.0
- Added eFuse management features
- Enhanced memory operations
- Improved serial port detection

### v1.0.0
- Initial release
- Basic ESP32 operations
- Interactive console UI

## 🤝 Contributing

### Development Setup
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

### Code Style
- Follow PowerShell best practices
- Use consistent indentation (4 spaces)
- Add comments for complex logic
- Maintain error handling

## 📄 License

This project is open source and available under the [MIT License](LICENSE).

## 🆘 Support

### Getting Help
- Check the troubleshooting section above
- Review esptool documentation: https://docs.espressif.com/projects/esptool/
- Search existing issues before creating new ones

### Reporting Issues
When reporting issues, please include:
- PowerShell version (`$PSVersionTable.PSVersion`)
- esptool version (`esptool.exe version`)
- ESP32 chip type
- Operating system version
- Error messages and logs

## 🙏 Acknowledgments

- **Espressif Systems** for ESP32 and esptool
- **PowerShell Community** for best practices
- **Open Source Contributors** for inspiration

---

**Note**: This script is designed for development and testing purposes. Always verify operations on development boards before using in production environments.
