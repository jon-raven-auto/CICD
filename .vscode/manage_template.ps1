param(
    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path $_ -PathType Leaf })]
    [string]$TargetFile
)

function Export-Template {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateScript({ Test-Path $_ -PathType Leaf })]
        [string]$TargetFile,
        [Parameter(Mandatory = $true)]
        [string]$Webhook,        
        [Parameter(Mandatory = $true)]
        [string]$Secret,        
        [Parameter(Mandatory = $true)]
        [string]$PS,
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    $guidPattern = '(\w{8}-\w{4}-\w{4}-\w{4}-\w{12})'

    # Find all GUID matches
    $guidMatches = [regex]::Matches($firstLine, $guidPattern)

    #return if no match 
    if ($guidMatches.Count -eq 0) {
    Write-Output "No GUIDs found in first line. Exiting"
    return
    }



    $templateGuid = $guidMatches[0].Value


    # Read file content
    $fileContent = Get-Content -Path $TargetFile -Raw


    #base64 the content and send a post request to the api
    $base64Content = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($fileContent))

    #create params object for invoke rest method
    $body = @{
        "method" = "export"
        "template_name" = $Name
        "template" = $base64Content
        "template_guid" = $templateGuid
        "ps" = $PS
    } | ConvertTo-Json -Depth 10

    Write-Output $body

    #create splat for invoke rest method

    $params = @{
        Method = "Post"
        Uri = $Webhook
        ContentType = "application/json"
        Body = $body
        Headers = @{
            "x-rewst-secret" = $Secret
        }
    }

    #invoke the request 
    Invoke-RestMethod @params

}

function Create-Template {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateScript({ Test-Path $_ -PathType Leaf })]
        [string]$TargetFile,
        [Parameter(Mandatory = $true)]
        [string]$Webhook,        
        [Parameter(Mandatory = $true)]
        [string]$Secret,        
        [Parameter(Mandatory = $true)]
        [string]$PS,
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    try {
    # Read file content
    $fileContent = Get-Content -Path $TargetFile -Raw

    #base64 the content and send a post request to the api
    $base64Content = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($fileContent))

    #create params object for invoke rest method
    $body = @{
        "method" = "create"
        "template_name" = $Name
        "template" = $base64Content
        "ps" = $PS
    } | ConvertTo-Json -Depth 10

    Write-Output $body

    #create splat for invoke rest method

    $params = @{
        Method = "Post"
        Uri = $Webhook
        ContentType = "application/json"
        Body = $body
        Headers = @{
            "x-rewst-secret" = $Secret
        }
    }

    #invoke the request 
    $res = Invoke-RestMethod @params
    Write-Output $res
    if($res.result.success) {
            $template_guid = $res.result.template_guid
            [regex]$pattern = "create template"
            $new_content = $pattern.replace($fileContent, "export $template_guid", 1) 
            Set-Content -Path $TargetFile -Value $new_content
        }
    }
    catch {
        
    }

}


get-content "./.vscode/.ENV" | foreach {
    if(![String]::IsNullOrWhiteSpace($_)){
        $Name, $value = $_.split('=')
        set-content env:\$Name $value
    }
}

$parts = $TargetFile -split "\\"
$dict = @{}
for($i = 1; $i -lt $parts.length; $i++) {
    $dict[$parts[$i-1]] = $parts[$i]
}

$company_name = $dict['templates']

$customer_secret_name = "$($company_name)_secret"
$customer_webhook_name = "$($company_name)_webhook"
$customer_ps_name = "$($company_name)_ps"

$Webhook = get-content env:\$customer_webhook_name
$Secret = get-content env:\$customer_secret_name
$PS = get-content env:\$customer_ps_name
$Name = $parts[-2..-1] -join "/"

if([String]::IsNullOrWhiteSpace($Webhook) `
    -or [String]::IsNullOrWhiteSpace($Secret) `
    -or [String]::IsNullOrWhiteSpace($PS)`
    ) {
    Write-Output "company not setup in .env EXITING"
    return
}

$firstLine = Get-Content -Path $TargetFile -TotalCount 1

if ($firstLine -match 'export') {
    Export-Template -TargetFile $TargetFile -Webhook $Webhook -Secret $Secret -PS $PS -Name $Name
    return
}

if ($firstLine -match 'create template') {
    Create-Template -TargetFile $TargetFile -Webhook $Webhook -Secret $Secret -PS $PS -Name $Name
    return
}



