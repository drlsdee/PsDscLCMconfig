function Set-DSCEndpointURL {
    [CmdletBinding()]
    param (
        # DNS domain
        [Parameter()]
        [ValidatePattern('^([a-z0-9-]+\.)+([a-z0-9-]+)$')]
        [string]
        $DomainName,

        # Host name
        [Parameter(
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [ValidatePattern('^([a-z0-9-]+)(\.[a-z0-9-]+)*$')]
        [string]
        $HostName,

        # Protocol (HTTP or HTTPS)
        [Parameter(
            ValueFromPipelineByPropertyName = $true
        )]
        [ValidateSet('HTTP', 'HTTPS')]
        [string]
        $Protocol = 'HTTPS',

        # Port
        [Parameter(
            ValueFromPipelineByPropertyName = $true
        )]
        [ValidateRange(1,65535)]
        [int]
        $Port = 443,

        # Endpoint of URL
        [Parameter(
            ValueFromPipelineByPropertyName = $true
        )]
        [string]
        $EndpointName = 'PSDSCPullServer.svc'
    )

    if (-not $DomainName) {
        Write-Warning -Message "Domain DNS name is not set! Get current domain from class `"Win32_ComputerSystem`"..."
        $DomainName = (Get-WmiObject -Class Win32_ComputerSystem).Domain
    }
    Write-Verbose -Message "Domain DNS name selected: `"$DomainName`". Continue..."

    if ($HostName -match '^([a-z0-9-]+\.)+([a-z0-9-]+)$') {
        [string[]]$hostNameSplitted = $HostName -split '\.'
        [string]$domainInHostName = $hostNameSplitted[1..($hostNameSplitted.Count - 1)] -join '.'
        Write-Warning -Message "Selected hostname `"$HostName`" probably already contains DNS name of domain `"$domainInHostName`"!"
        if ($domainInHostName -notmatch "$DomainName$") {
            Write-Warning -Message "DNS name `"$domainInHostName`" is not a part of current DNS domain `"$DomainName`"!"
        } else {
            Write-Verbose -Message "DNS name `"$domainInHostName`" is probably a subdomain of current DNS domain `"$DomainName`"."
        }
        [string]$dscEndpointFQDN = $HostName.ToLower()
    } else {
        Write-Verbose -Message "Host name `"$HostName`" is not an FQDN. Joining to current DNS domain name `"$DomainName`"."
        [string]$dscEndpointFQDN = "$HostName.$DomainName".ToLower()
    }
    Write-Verbose -Message "FQDN of selected host is `"$dscEndpointFQDN`". Continue..."

    if ((($Protocol -eq 'HTTP') -and ($Port -eq 80)) -or (($Protocol -eq 'HTTPS') -and ($Port -eq 443))) {
        Write-Verbose -Message "Selected port `"$Port`" is standard port for protocol `"$Protocol`" and will be omitted in URL."
        [string]$DSCEndpointURL = "$($Protocol.ToLower())://$dscEndpointFQDN/$EndpointName"
    } else {
        Write-Verbose -Message "Selected port `"$Port`" is NON-STANDARD port for protocol `"$Protocol`" and will be INCLUDED in URL."
        [string]$DSCEndpointURL = "$($Protocol.ToLower())`://$dscEndpointFQDN`:$Port/$EndpointName"
    }

    Write-Verbose -Message "Resulting URL is: `"$DSCEndpointURL`". Returning result."
    return $DSCEndpointURL
}
