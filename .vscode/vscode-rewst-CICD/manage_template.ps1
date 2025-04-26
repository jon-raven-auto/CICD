param(
    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path $_ -PathType Leaf })]
    [string]$TargetFile

)

$script:TargetFile = $TargetFile
$script:Name = $TargetFile.replace('\','/')


function Get-Config {
    $content_json = Get-Content "./.vscode/vscode-rewst-CICD/config.json"
    return $content_json | ConvertFrom-Json -Depth 10
}

function Export-Template {

    $guidPattern = '(\w{8}-\w{4}-\w{4}-\w{4}-\w{12})'

    # Find all GUID matches
    $guidMatches = [regex]::Matches($script:firstLine, $guidPattern)

    #return if no match 
    if ($guidMatches.Count -eq 0) {
    Write-Output "No GUIDs found in first line. Exiting"
    return
    }



    $templateGuid = $guidMatches[0].Value


    # Read file content
    $fileContent = Get-Content -Path $script:TargetFile -Raw


    #base64 the content and send a post request to the api
    $base64Content = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($fileContent))

    #create params object for invoke rest method
    $body = @{
        "method" = "export"
        "template_name" = $script:Name
        "template" = $base64Content
        "template_guid" = $templateGuid
        "ps" = $script:company_config.PS
    } | ConvertTo-Json -Depth 10

    #create splat for invoke rest method

    $params = @{
        Method = "Post"
        Uri = $script:company_config.Webhook
        ContentType = "application/json"
        Body = $body
        Headers = @{
            "x-rewst-secret" = $script:company_config.Secret
        }
    }

    #invoke the request 
    Write-Output Invoke-RestMethod @params

}

function Create-Template {

    try {
    # Read file content
    $fileContent = Get-Content -Path $script:TargetFile -Raw

    #base64 the content and send a post request to the api
    $base64Content = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($fileContent))

    #create params object for invoke rest method
    $body = @{
        "method" = "create"
        "template_name" = $script:Name
        "template" = $base64Content
        "ps" = $script:company_config.PS
    } | ConvertTo-Json -Depth 10

    #create splat for invoke rest method

    $params = @{
        Method = "Post"
        Uri = $script:company_config.Webhook
        ContentType = "application/json"
        Body = $body
        Headers = @{
            "x-rewst-secret" = $script:company_config.Secret
        }
    }

    #invoke the request 
    $res = Invoke-RestMethod @params
    Write-Output $res
    if($res.result.success) {
            $template_guid = $res.result.template_guid
            [regex]$pattern = "create template"
            $new_content = $pattern.replace($fileContent, "export $template_guid", 1) 
            Set-Content -Path $script:TargetFile -Value $new_content
        }
    }
    catch {
        
    }

}


try {

    $config = Get-Config

    $parts = $script:TargetFile -split "\\"
    $root = $parts[0]

    $script:company_config = $config.RewstInstances.$root

    if ([String]::IsNullOrEmpty($script:company_config)) {
        throw "Failed to load company config for '$root'. Setup config.json in '.vscode\vscode-rewst-CICD\config.json'"
    }
}
catch {
    Write-Output $_.Exception.Message
    return
}

try {
    $script:firstLine = Get-Content -Path $script:TargetFile -TotalCount 1

    if ($script:firstLine -match 'export') {
        Export-Template
        return
    }

    if ($script:firstLine -match 'create template') {
        Create-Template
        return
    }

    throw "No Command found"
    
}
catch {
    Write-Output $_.Exception.Message
}



