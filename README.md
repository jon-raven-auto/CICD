
# VSCode Rewst Template CI/CD

**Automated Template Management for Rewst Workflows**

  

---

## ✨ Key Features

-  **Instant Sync**: Auto-push templates to Rewst on file save

-  **ID Auto-Update**: `create template` → `export [UUID]` conversion for seemless creation

-  **Multi-Org Support**: Manage multiple Rewst organizations via `.ENV` sections

-  **Filetype Agnostic**: Works with `<!-- -->`, `{# #}`, or `/* */` syntax
  

## Requirements

- [Powershell 7 latest](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-windows?view=powershell-7.5)

```powershell

# Verify PowerShell 7.4+

$PSVersionTable.PSVersion

```

- Rewst Powershell Beta Interpreter

- [VSCode](https://code.visualstudio.com/) with Extensions

  
  

## 🛠️ Installation Guide

  

### Clone this repo to get supporting files

```bash

git  clone  https://github.com/jon-raven-auto/vscode-rewst-CICD.git

```

### Setup Trigger Task on Save

- Install VSCode extension [Gruntfuggly.triggertaskonsave](https://github.com/Gruntfuggly/triggertaskonsave) 

- Go to the extension's settings

(VSCode > Gear Icon > Settings > triggerTaskOnSave.tasks > "Edit in settings.json")

- Copy in this configuration

```json
{
    "git.autofetch": true,
    "editor.formatOnSave": true,
    "triggerTaskOnSave.tasks": {
        "manage_template": [
            "**"
        ]
    }
}
```

  

### Rewst Import Workflow

- Import "\[RAVEN] Template CICD*.json" workflow into Rewst

- Ensure Webhook Trigger is
    - Enabled
    - POST method is allowed
    - YOUR OWN "Secret Key" is selected (will be used later)

- Take note of webhook URL

  

### Config

***!CAUTION***

Please ensure `.vscode/vscode-rewst-CICD/config.json` is in your .gitignore if using git before proceeding. [Git Ignore and .gitignore](https://www.w3schools.com/git/git_ignore.asp)

  

- Navigate to `.vscode\vscode-rewst-CICD\config.json.example`
- Rename `config.json.example` to `config.json`
- Replace Relevant Values in config file
	- rewst_instance1 with your company name (you will need a folder at the root level that matches this exactly)
    - Secret with the secret you selected on the webhook trigger
    - Webhook with the webhook from your trigger
    - PS with true or false that you have the Rewst Powershell Interpretter

```
{
    "RewstInstances": {
        "rewst_instance1": {
            "Webhook": "https://engine.rewst.io/webhooks/custom/trigger/00000000-0000-0000-0000-000000000000/00000000-0000-0000-0000-000000000000",
            "Secret": "123456789",
            "PS": true
        },
        "rewst_instance2": {
            "Webhook": "https://engine.rewst.io/webhooks/custom/trigger/00000000-0000-0000-0000-000000000000/00000000-0000-0000-0000-000000000000",
            "Secret": "123456789",
            "PS": false
        }
    }
}
```

---

  

## 🧩 Usage Patterns

  

### Folder Structure

```

📁 .vscode/
├── 📄 tasks.json
└── 📁 vscode-rewst-CICD/
    ├── 📄 config.json
    └── 📄 manage_template.ps1
📁 rewst_instance1/
├── 📁 project1/
|    └── 📄 dashboard.html → Rewst: "rewst_instance1/project1/dashboard.html"
└── 📁 project2/
     └── 📁 shared/
         └── 📄 base_layout.html
```

  

After saving a file, a script will run that looks for these keywords in the first line:

  

`create template` or `export`

  

It does not matter if these are commented out, the script will still process them. If both are present then preference is given to `export`.

  

To create a new template simply put the `create template` keyword in the first line of the file and save. You should see the script running at the bottom of your VSCode. On completion `create template` will be replaced with `export 00000000-0000-0000-0000-000000000000`. Any further saves will then be exported to the proper template.

  

If you don't want to export every save simply remove the `export` keyword from the first line.

  

The template name will be updated in Rewst to the default of the realtive path to the file.

  
  
  

### Template Lifecycle

1.  **Creation**:

    ```html

    <!-- create template -->

    <div>New Template</div>

    ```

    

    ```powershell

    # create template

    # powershell example

    Write-Host  "Hi"

    ```

*Saves → Pushes to Rewst and updates file with template guid*

  

2.  **Updates**:

```powershell

# export 00000000-0000-0000-0000-000000000000

Write-Host  "Hi"

```

*Saves → Pushes to Rewst*

  
  

---

  

## 📜 License

MIT License