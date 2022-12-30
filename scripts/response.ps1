$responsePath = $args[0]
$filename = $args[1]
$url = $args[2]
$duration = $args[3]

$response = Invoke-WebRequest -SkipHeaderValidation -SkipHttpErrorCheck $url -TimeoutSec $duration
$url = $url.Replace('?raw=true', '')

# Flags for Accept-Ranges & Content-Disposition...
$arFlag = $false
$cdFlag = $false
$ctFlag = $false

if (($response.Headers.'Accept-Ranges'.Length -gt 0) -and !($response.Headers.'Accept-Ranges'.Contains('none'))) {
    $arFlag = $true
}

if (($response.Headers.'Content-Type'.Length -gt 0) -and !($response.Headers.'Content-Type'.Contains('text'))) {
    $ctFlag = $true
}

if ($response.Headers.'Content-Disposition'.Length -ne 0) {
    $cdFlag = $true
}

# Response Log Generation...
$jsonfile = "$responsePath\$filename.json"
$response | Select-Object -Property StatusCode, StatusDescription, RawContent, Headers | ConvertTo-Json | Out-File $jsonfile
$response = Get-Content $jsonfile | Out-String | ConvertFrom-Json

if ($null -ne $response) {
    $response | Add-Member -Type NoteProperty -Name 'url' -Value $url

    # Flags Check for Downloadable-Status...
    if ($arFlag -or $cdFlag -or $ctFlag) {
        $response | Add-Member -Type NoteProperty -Name 'Downloadable' -Value 'True'
    }
    else {
        $response | Add-Member -Type NoteProperty -Name 'Downloadable' -Value 'False'
    }

    $response | ConvertTo-Json | Set-Content $jsonfile
}
else {
    "{'url': $url,'status': 'No Response'}" > $jsonfile
}