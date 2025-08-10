# ESPTool v5 Automator

**ESPTool v5 Automator** is an interactive PowerShell 7 script for managing ESP32 devices, including **ESP32-WROOM-32E** and **ESP32-S3**.
It wraps **esptool v5** and **espefuse** with a colorful ASCII menu for easy flashing, eFuse management, MAC address operations, and more.

---

## 📋 Features

- Interactive **ASCII-based menu** in PowerShell
- Support for **ESP32-WROOM-32E** and **ESP32-S3**
- Works with **esptool v5** and **espefuse**
- High-speed flashing with default baud rate **460800**
- Organized into Main, Advanced, and Utility actions

---

## 🛠 Prerequisites

1. **PowerShell 7+** (Windows, macOS, Linux)
2. **Python 3.8+**
3. **esptool** and **espefuse** installed:
   ```sh
   pip install esptool
   ```
4. USB drivers for your ESP32 board
5. Add `esptool.exe` and `espefuse.exe` to your PATH or keep them in the same folder as the script.

---

## 📂 Repository Structure

```
.
├── ESPAutomator.ps1     # Main automation script
├── README.md            # Documentation
└── .gitignore           # Ignore unnecessary files
```

---

## 🚀 Installation

Clone the repository:
```sh
git clone https://github.com/your-username/ESPAutomator.git
cd ESPAutomator
```

Make sure PowerShell execution policy allows running scripts:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

---

## ▶️ Usage

Run the script:
```powershell
.\ESPAutomator.ps1
```

You will see a **menu interface** with actions:

### Main Actions
| Key | Action          |
|-----|----------------|
| 1   | Read Chip ID   |
| 2   | Read Flash ID  |
| 3   | Erase Flash    |
| 4   | Flash Firmware |
| 5   | Dump Flash     |
| 6   | Read MAC       |

### Advanced Actions
| Key | Action           |
|-----|-----------------|
| 7   | Write MAC       |
| 8   | Read eFuses     |
| 9   | Burn eFuse      |
| 10  | Read Memory     |
| 11  | Write Memory    |
| 12  | Load+Exec Stub  |

### Utility Actions
| Key | Action             |
|-----|-------------------|
| 13  | Reset Chip         |
| 14  | esptool Version    |
| R   | Select Serial Port |
| 0   | Exit               |

---

## 📜 Example

```
──────────────────────────────────────────────
           ESPTool V5 Automator
                Ver. 1.1.2
──────────────────────────────────────────────
  Port: COM3    Chip: ESP32-S3    Baud: 460800
──────────────────────────────────────────────

  Main Actions
[1] Read Chip ID     [2] Read Flash ID   
[3] Erase Flash      [4] Flash Firmware  
[5] Dump Flash       [6] Read MAC        

  Advanced Actions
[7] Write MAC        [8] Read eFuses     
[9] Burn eFuse       [10] Read Memory    
[11] Write Memory    [12] Load+Exec Stub 

  Utility Actions
[13] Reset Chip      [14] esptool Version
[R] Select Serial Port [0] Exit
```

---

## 🐞 Troubleshooting

**Problem:** Script blocked by execution policy  
**Solution:**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**Problem:** `esptool.exe` not found  
**Solution:** Install esptool and ensure it’s in PATH:
```sh
pip install esptool
```

**Problem:** No COM ports detected  
**Solution:** Connect device and press any key to refresh, or install required USB drivers.

---

## 🤝 Contributing

1. Fork the repository
2. Create a branch (`feature/my-feature`)
3. Commit your changes
4. Push to GitHub
5. Open a Pull Request

---

## 📄 License

This project is licensed under the **MIT License**.

-AnAnarchist
