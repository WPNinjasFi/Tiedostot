### REST
$body = @{
    client_id     = ""
    client_secret = ""
    scope         = "https://graph.microsoft.com/.default"
    grant_type    = "client_credentials"
}

# URL:ssa on tenantin ID, joka pitää vaihtaa
$url = "https://login.microsoftonline.com/ccef0ddc-6ee0-43c4-809e-2dbdd3703af2/oauth2/v2.0/token"

$token = (Invoke-RestMethod -Uri $url -Method POST -Body $body).access_token

$headers = @{
    Authorization = "Bearer $token"
}

$users = (Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/users" -Headers $headers).value

### Mg-Graph
Connect-MgGraph -Scopes "Directory.Read.All"
$users = Get-MgUser -All


### Azure Automation Account / Azure Function APp
Connect-MgGraph -Identity
$users = Get-MgUser -All

