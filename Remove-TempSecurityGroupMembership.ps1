###This script requires Quest ActiveRoles##
###Author: Dean Pollaro###

##Loads Quest ActiveRoles snapin##
Add-PSSnapin Quest.ActiveRoles.ADManagement -ErrorAction SilentlyContinue

#Variables#

#Get's todays date##
$date = Get-Date -f "dd-MMM-yyyy"
#Enter Root Directory for CSV File#
$root = 'Enter Folder Path'
#Enter CSV Filename#
$csvfile = $($root + '\EnterFileName.csv')
#Enter Group to monitor#
$groupname  = "GroupName"

#Checks if CSV file exists and imports the data, if not sets empty array##
if (Test-Path $csvfile) {
	$DataIN = Import-Csv $csvfile
} else {
	$DataIN = @()
}

#Enter group name that you want to monitor/remove from. The below line gets the list#
#of members in the group and selects their name, user guid, and the date it found it in the group#
$members = Get-QADGroupMember $groupname | select name, guid, @{n='date'; e={$date}}

##sets empty array##
$DataOut = @()

##iterates through each member in the group that it found## 
foreach ($member in $members) {

##sets a new variable to false##
	$found = $false
    ##iterates through each line in the csv file and checks if the member guid matches any line in the csv##
	foreach ($RecordIn in $DataIN) {
		if ($member.guid -eq $RecordIn.guid) {
            ##checks the date for the user it matched and removes it from group if in there for 7 days##
			if ($(Get-Date $RecordIn.date) -lt $(Get-Date).AddDays(-7)) {
                ##removes user from group##
				Remove-QADGroupMember $groupname -member $($member.guid)

                ##if less than 7 days it adds to the $DataOut array##
			} else {

				$DataOut += $RecordIn
			}
            ##sets found variable to true for users it found regardless if 7 days or not##
			$found = $true
			Break
		}
	}
    ##if the user is not found, it adds it to the $DataOut array##
	if ($found -eq $false) {
		$DataOut += $member
	}
}
##Exports the $DataOut array to the csv file.  The array will contain##
##existing users found but haven't been removed as well as new users##
$DataOut | Export-Csv -Path $csvfile -NoTypeInformation