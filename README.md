# Windows Startup Diagnostic Toolkit 🖥️

[![PowerShell](https://img.shields.io/badge/PowerShell-5%2F7-blue?logo=powershell)](https://learn.microsoft.com/powershell/)
[![Windows](https://img.shields.io/badge/Windows-10%2F11-lightgrey?logo=windows)](https://learn.microsoft.com/windows/)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)

A PowerShell toolkit that inventories Windows startup programs, classifies them into **Valid**, **Suspicious**, and **Broken**, and exports recruiter‑ready reports in **CSV**, **Markdown**, and **HTML**.  
The HTML dashboard includes color‑coded tables and DuckDuckGo search links for quick reputation checks.

---

## 📊 Executive Summary

- **Purpose:** Provide a clear snapshot of what auto‑starts on a Windows PC, highlight risk patterns, and surface misconfigurations that impact reliability or security.
- **Outputs:**
  - CSV for automation and ingestion
  - Markdown for documentation and GitHub
  - HTML dashboard with color‑coded tables and summary
- **Categories:**
  - ✔ **Valid** — Executable exists in trusted locations (Program Files, System32).
  - ⚠ **Suspicious** — Executable exists but runs from user‑scoped or transient locations (AppData, Temp).
  - ✖ **Broken** — Registry entry exists but executable is missing or path is empty.
- **Value:** Presents a “health snapshot” of startup behavior—useful for IT directors, SOC analysts, and endpoint engineering teams to prioritize cleanup and reduce boot‑time bloat, instability, and attack surface.

---

## ⚙️ Technical Details

### What the script scans

- Registry Run keys:
  - `HKLM:\Software\Microsoft\Windows\CurrentVersion\Run`
  - `HKCU:\Software\Microsoft\Windows\CurrentVersion\Run`
- Extracts executable paths, verifies existence, and flags suspicious locations.

### Classification logic

- **Valid:** Executable exists in system/vendor directories.
- **Suspicious:** Executable exists but runs from AppData, Roaming, Temp, or user profile.
- **Broken:** Registry entry exists but executable is missing or path is empty.

### Why these signals matter

- **User‑scoped locations** (AppData/Temp) are mutable, harder to govern, and often abused by malware or auto‑updaters.
- **Stale entries** add diagnostic noise and slow login.
- **System‑scoped installs** improve reliability, update governance, and inventory accuracy.

---

## 📚 References

- [Autoruns – Sysinternals (Microsoft Learn)](https://learn.microsoft.com/en-us/sysinternals/downloads/autoruns)  
- [Run and RunOnce Registry Keys (Microsoft Learn)](https://learn.microsoft.com/en-us/windows/win32/setupapi/run-and-runonce-registry-keys)  
- [Startup Apps – Win32 Guidance (Microsoft Learn)](https://learn.microsoft.com/en-us/windows/win32/w8cookbook/startup-apps)

---

## 🚀 Usage

```powershell
# Clone repo
git clone https://github.com/ChrisMunnPS/windows-startup-toolkit.git
cd windows-startup-toolkit

# Run script
.\StartupToolkit.ps1
```

Reports will be saved to configurable paths (default: `C:\temp`):
- `StartupPrograms.csv`
- `StartupPrograms.md`
- `StartupPrograms.html`

Open the HTML report for a color‑coded dashboard and quick DuckDuckGo links.

---

## 🗂️ Example Report

### Summary

- ✔ Valid: 18  
- ⚠ Suspicious: 9  
- ✖ Broken: 4  
- **Total: 31** (Local Machine: 7, Current User: 24)

### Valid Startup Programs

| Hive           | Name           | Path                                      |
|----------------|----------------|-------------------------------------------|
| Local Machine  | SecurityHealth | C:\Windows\System32\SecurityHealthSystray.exe |
| Current User   | OneDrive       | C:\Program Files\Microsoft OneDrive\OneDrive.exe |
| Current User   | Steam          | C:\Program Files (x86)\Steam\steam.exe -silent |

### Suspicious Startup Programs

| Hive         | Name    | Path                                                   | Reason                          |
|--------------|---------|--------------------------------------------------------|---------------------------------|
| Current User | Slack   | C:\Users\Alice\AppData\Local\slack\slack.exe           | Runs from AppData (user profile)|
| Current User | Discord | C:\Users\Alice\AppData\Local\Discord\Update.exe        | Runs from AppData (user profile)|
| Current User | Spotify | C:\Users\Alice\AppData\Roaming\Spotify\Spotify.exe     | Runs from Roaming profile       |
| Current User | Teams   | C:\Users\Alice\AppData\Local\Microsoft\Teams\current\Teams.exe | Runs from AppData (user profile)|

### Broken Startup Programs

| Hive           | Name                  | Path |
|----------------|-----------------------|------|
| Local Machine  | OldVendor Updater     | C:\Program Files\OldVendor\Updater\Update.exe |
| Current User   | ExampleApp Updater    | (missing) |
| Current User   | GameClient            | (empty) |

---

## 🛡️ Remediation Guidance

- **Valid:** No action needed; ensure updates are governed by enterprise policy.  
- **Suspicious:** Confirm publisher reputation, consider system‑scoped installs, monitor auto‑updaters.  
- **Broken:** Remove stale registry values or reinstall apps cleanly.  

---

## 📌 Notes for Enterprise

- Audit startup via endpoint management baselines.  
- Prefer MSI/MSIX or vendor installers that support system‑scoped deployment.  
- Integrate this report into onboarding/offboarding checks to catch leftovers.  

---

## 📝 License

MIT License. See [LICENSE](LICENSE) for details.
```

---
