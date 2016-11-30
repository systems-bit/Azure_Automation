#################################################################
workflow Invoke-RunbookUsingAlerts
{
    param (     
        [object]$WebhookData 
    ) 
 
    # If runbook was called from Webhook, WebhookData will not be null.
    if ($WebhookData -ne $null) {   
        # Collect properties of WebhookData. 
        $WebhookName    =   $WebhookData.WebhookName 
        $WebhookBody    =   $WebhookData.RequestBody 
        $WebhookHeaders =   $WebhookData.RequestHeader 
 
        # Outputs information on the webhook name that called This 
        Write-Output "This runbook was started from webhook $WebhookName." 
 
 
        # Obtain the WebhookBody containing the AlertContext 
        $WebhookBody = (ConvertFrom-Json -InputObject $WebhookBody) 
        Write-Output "`nWEBHOOK BODY" 
        Write-Output "=============" 
        Write-Output $WebhookBody 
 
        # Obtain the AlertContext     
        $AlertContext = [object]$WebhookBody.context
 
        # Some selected AlertContext information 
        Write-Output "`nALERT CONTEXT DATA" 
        Write-Output "===================" 
        Write-Output $AlertContext.name 
        Write-Output $AlertContext.subscriptionId 
        Write-Output $AlertContext.resourceGroupName 
        Write-Output $AlertContext.resourceName 
        Write-Output $AlertContext.resourceType 
        Write-Output $AlertContext.resourceId 
        Write-Output $AlertContext.timestamp 
 
        # Act on the AlertContext data, in our case restarting the VM. 
        # Authenticate to your Azure subscription to be able to restart that Virtual Machine. 
        $connectionName = "AzureRunAsConnection"
        try
        {
            # Get the connection "AzureRunAsConnection "
            $servicePrincipalConnection=Get-AutomationConnection -Name $connectionName         

            "Logging in to Azure..."
            Add-AzureRmAccount `
                -ServicePrincipal `
                -TenantId $servicePrincipalConnection.TenantId `
                -ApplicationId $servicePrincipalConnection.ApplicationId `
                -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint 
        }
        catch {
            if (!$servicePrincipalConnection)
            {
                $ErrorMessage = "Connection $connectionName not found."
                throw $ErrorMessage
            } else {
                Write-Error -Message $_.Exception
                throw $_.Exception
            }
        }
 
        #Check the status property of the VM
        Write-Output "Status of VM before taking action"
        Get-AzureRmVM -Name $AlertContext.resourceName -ResourceGroupName $AlertContext.resourceGroupName
        Write-Output "Restarting VM"
 
        # Restart the VM by passing VM name and Service name which are same in this case
        Restart-AzureRmVM -Name $AlertContext.resourceName -ResourceGroupName $AlertContext.resourceGroupName 
        Write-Output "Status of VM after alert is active and takes action"
        Get-AzureRmVM -Name $AlertContext.resourceName -ResourceGroupName $AlertContext.resourceGroupName
    } 
    else  
    { 
        Write-Error "This runbook is meant to only be started from a webhook."  
    }  
}
########################################################################