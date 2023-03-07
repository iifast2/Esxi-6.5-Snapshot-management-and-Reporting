############### Snapshot Management Script for Vsphere Esxi 6.5 ################
################################################################################


#################  Esxi 6.5 ################
$esxi="192.168.1.50"
$user="root"
$pass="your-password"

#################################
$vm = "vm_name"
$date = Get-Date -format "dd-MMM-yyyy HH:mm:ss"
$dateonly = Get-Date -format "dd-MMM-yyyy"
Write-Host "$date" 
Write-Host "$dateonly" 
############### Mailgun SMTP #####################
$Username = "postmaster@sandbox.mailgun.org";
$Password = "mailgun_password";
$email="mohamedamine.bentaieb@theteam.com.tn"
$port="587" 
$SMTPserver="smtp.mailgun.org"
###########
$mailsubject="VMware reporting Snapshots Creation"
$mailbody="This email is for today's snapshot $date :"
#$sendto="email-address@gmail.com"
$path = "C:\powercli-exports\Snapshots-$dateonly-Log.csv";

###########
#$mailsubjectdelete="VMware reporting Snapshots Deletion"
#$mailbodydelete="This email is for the Deleted snapshots $date :"
$deletepath = "C:\powercli-exports\Snapshot-AfterRemove.csv"

##########################  Esxi Connection  #######################
  

try {

  Connect-VIServer -Server $esxi -User $user -Password $pass -ErrorAction SilentlyContinue

}

catch{

  $Error[0]

}


####################  CREATE SNAPSHOTS FUNCTION ###############################

function createSnapshot($vm){

     try{
          Write-Host "Creating new snapshot for $vm"
          Get-VM $vm | New-Snapshot -name "$vm Snapshot $dateonly (script)" -description "created by powerCli script _ $date " -memory:$false -quiesce:$false -confirm:$false
          Write-Host -foregroundcolor "Green" "`nDone, Creating your Snapshot, Now Proceeding to sending an Email."
     }
     catch{
          $Error[1]
          Write-Host -foregroundcolor RED -backgroundcolor BLACK "Error creating new snapshot. See Esxi log for details."
     }
}
####################### REMOVE SNAPSHOTS FUNCTION ( 7 old) ###########################

function removeSnapshot($vm){
     try{

#  Write-Host "Previous snapshot detected, removing first..."
#  Get-VM $vm | Get-Snapshot -name $snapshot | Remove-Snapshot -confirm:$false
#  Write-Host -foregroundcolor "YELLOW" "`nDone Removing your Snapshots ( without specific date ) "
             
          Get-Snapshot -VM $vm | FL | Export-Csv C:\powercli-exports\Snapshot-BeforeRemove.csv -Append
    
          Get-VM $vm | `
            Get-Snapshot |  `
            Where-Object { $_.Created -lt (Get-Date).AddDays(-7) } | `
            Remove-Snapshot -Confirm:$false
           #-Confirm:$falsec
          Write-Host -foregroundcolor "Red" "`nRemoving snapshots that are 7 days old..." 

          Get-Snapshot -VM $vm | FL | Out-File C:\powercli-exports\Snapshot-AfterRemove.csv -Append


     }
     catch {
       Write-Host -foregroundcolor RED -backgroundcolor BLACK "Error deleting old snapshot. See Esxi log for details."
     break
     }
}


####################### MAILER TO SEND REPORTS ( config with free SMTP mailgun ) ############################

function Send-ToEmail([string]$email, [string]$attachmentpath){


    $message = new-object Net.Mail.MailMessage;
    $message.From = "mohamedamine.bentaieb@theteam.com.tn";
    $message.To.Add($email);
    $message.Subject = $mailsubject;
    $message.Body = $mailbody;
    $attachment = New-Object Net.Mail.Attachment($attachmentpath);
    $message.Attachments.Add($attachment);
    $smtp = new-object Net.Mail.SmtpClient($SMTPserver, $port);
    $smtp.EnableSSL = $true;
    $smtp.Credentials = New-Object System.Net.NetworkCredential($Username, $Password);
    $smtp.send($message);
    write-host "Mail Sent";
    $attachment.Dispose();

}


############################## EXEC ####################################

Write-Host -foregroundcolor "Red" "` your Error is : "  $Error[0]    
createSnapshot($vm) 
Get-Snapshot -VM $vm | Export-Csv -Path C:\powercli-exports\Snapshots-$dateonly-Log.csv -Force -Append
Write-Host -foregroundcolor "Yellow" "`nPlease wait for 10 Seconds, processing now...."
Start-Sleep -Seconds 10
Write-Host -foregroundcolor "Yellow" "`nPlease wait for few minutes (this may take a while), processing Deletion now...."
removeSnapshot($vm)
Write-Host -foregroundcolor "Magenta" "`nSending Your Email now !."
Send-ToEmail  -email $email -attachmentpath $path;
Send-ToEmail  -email $email -attachmentpath $deletepath;


############################## Other ~ biblio ##################################

<#

https://i.imgur.com/KIphoxW.png   -- Issue with Run Script (F5) 
Execute this on commmand Line :  
Powershell.exe -executionpolicy remotesigned -File C:\VmwareScripts\mailGun.ps1
https://stackoverflow.com/questions/36355271/how-to-send-email-with-powershell
https://app.mailgun.com/app/sending/domains/sandbox813a5ab763194fc4b3ba7d1ebb23884b.mailgun.org

#>

<#

#Start-Sleep -Seconds 5

#Get-Date | Out-File C:\VmwareScripts\Snapshots-Log.csv -Force -Append
#New-Snapshot -VM $vm -Name Daily-Snapshot  
createSnapshot($vm) 
Get-Snapshot -VM $vm | Export-Csv -Path C:\VmwareScripts\Snapshots-$dateonly-Log.csv -Force -Append
this script to create VM snapshots. 
Get-Date | Out-File C:\VmwareScripts\Snapshots-Log.txt -Append
Connect-VIServer 192.168.75.128 -User root -Password azerty123% 
Get-Snapshot -VM odoo15-vm | FL | Out-File C:\VmwareScripts\Snapshots-Log.txt -Append

#>

