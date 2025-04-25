# VSCode Rewst Template CI/CD  
**Automated Template Management for Rewst Workflows**  

---

## 📋 Table of Contents  
- [Features](#-key-features)  
- [Installation](#-installation-guide)  
- [Usage](#-usage-patterns) 

---

## ✨ Key Features  
- **Instant Sync**: Auto-push templates to Rewst on file save  
- **ID Auto-Update**: `create template` → `export [UUID]` conversion for seemless creation
- **Multi-Org Support**: Manage multiple Rewst organizations via `.ENV` sections  
- **Filetype Agnostic**: Works with `<!-- -->`, `{# #}`, or `/* */` syntax  

---

## 🚀 Quick Start  

### Requirements  
```powershell
# Verify PowerShell 7.4+
$PSVersionTable.PSVersion
```
## 🛠️ Installation Guide  

### Clone this repo to get supporting files
   ```bash
   git clone https://github.com/jon-raven-auto/vscode-rewst-CICD.git
   ```  
### Setup Trigger Task on Save
Install VSCode extension [Gruntfuggly.triggertaskonsave](https://github.com/Gruntfuggly/triggertaskonsave)

After installation go to the extension's settings

VSCode > Gear Icon > Settings > triggerTaskOnSave.tasks > "Edit in settings.json"

- Copy in this configuration
```json
{
    "git.autofetch": true,
    "editor.formatOnSave": true,
    "triggerTaskOnSave.tasks": {
        "manage_template": [
            "templates/**"
        ]
    }
}
```

### Rewst Import Workflow

- Import "\[RAVEN] Template CICD*.json" workflow into Rewst

- Ensure Webhook Trigger is
    - Enabled
    - POST method is allowed
    - YOUR OWN "Secret Key" is seleted (will be used later)

- Take note of webhook URL

### Configure ENV
***!CAUTION***
Please add .ENV to your .gitignore if using git before proceeding 

- Navigate to ```.vscode/.ENV```

- Replace `yourcompany` in the variable names
```
yourcompany_secret=1234567890
yourcompany_webhook=https://engine.rewst.io/webhooks/custom/trigger/*/*
yourcompany_ps=true
```


- Replace values
    - _secret with the secret you selected on the webhook trigger
    - _webhook with the webhook from your trigger
    - _ps with true or false that you have the Rewst Powershell Interpretter
 
---

## 🧩 Usage Patterns  

This setup will only target files nested under `/templates/yourcompany`. Any other files will not trigger the script on save. You can have layers of folders under this.

After setup everything revolves around keywords in the first line of the file:

`create template` or `export`

It does not matter if these are commented out, the script will still process then. If both are present then preference is given to `export`.

To create a new template simply put the `create template` keyword in the first line of the file and save. You should see the script running at the bottom of your VSCode. On completion `create template` will be replaced with `export 00000000-0000-0000-0000-000000000000`. Any further changes will then be exported to the proper template.

The template name will be updated in Rewst to the default of `project_folder/file.html`.

### Folder Structure  
```  
📁 .vscode/
└── 📄 .ENV
└── 📄 manage_template.ps1
└── 📄 tasks.json
📁 templates/
└── 📁 yourcompany/  
    ├── 📁 project1/  
    │   └── 📄 dashboard.html → Rewst: "project1/dashboard.html"  
    └── 📁 project2/  
        └── 📁 shared/  
            └── 📄 base_layout.html → Rewst: "shared/base_layout.html"  
```

### Template Lifecycle  
1. **Creation**:  
   ```html
   <!-- create template -->
   <div>New Template</div>
   ```  

    ```powershell
   # create template
   # powershell example
   Write-Host "Hi"
   ```  
   *Saves → Pushes to Rewst and updates file with template guid*  

2. **Updates**:  
   ```powershell
   # export 00000000-0000-0000-0000-000000000000 
   Write-Host "Hi"
   ```  
   *Saves → Pushes to Rewst*  


---

## 📜 License  
MIT License