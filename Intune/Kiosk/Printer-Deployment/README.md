# Deploy Local IP Printers with Microsoft Intune and PowerShell

Deploy local IP printers to Microsoft Entra joined Windows 11 devices using:

- Microsoft Intune
- PowerShell
- PrintBRM
- Win32 Applications

## Architecture

text
Windows 11 Device
        │
        ▼
Microsoft Intune
        │
        ▼
Install-Printers.ps1
        │
        ▼
PrintBRM
        │
        ▼
Network Printer
