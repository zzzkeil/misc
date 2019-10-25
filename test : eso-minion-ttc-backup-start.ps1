#Verzeichnisse eintragen / setup paths


# default eso installfolder =  "C:\Program Files (x86)\Zenimax Online\Launcher\Bethesda.net_Launcher.exe"
$esolauncher = "E:\ESO\Launcher\Bethesda.net_Launcher.exe"
# default eso addons userfiles folders 
$esottcaddon = "$env:userprofile\Documents\Elder Scrolls Online\live\AddOns\TamrielTradeCentre"
$esoconfig = "$env:userprofile\Documents\Elder Scrolls Online\live\UserSettings.txt"
# config backupfolder
$esoconfigbak = "$env:userprofile\Documents\Elder Scrolls Online\live\UserSettings.bakup"
# default minion folder
$minion = "$env:userprofile\AppData\Local\Minion\Minion.exe"
# downloadfolder for TamrielTradeCentre data
$ttczip = "$env:userprofile\Documents\TTC.zip"



#funktionen / funtions

function checkttczip {

if (Test-Path $ttczip) {
  "ok is here :)"
} else {
  "no ttc.zip found - download file now"
  Invoke-WebRequest -Uri https://eu.tamrieltradecentre.com/download/PriceTable -OutFile $ttczip
}

}


function datettczip {
$lastWrite = (get-item $ttczip).LastWriteTime
$timespan = new-timespan -days 1

if (((get-date) - $lastWrite) -gt $timespan) {
  "file older than 1 Day - download update now"
  Invoke-WebRequest -Uri https://eu.tamrieltradecentre.com/download/PriceTable -OutFile $ttczip
} else {
  "no update needed"    
}

}


function unzipttczip {

Get-ChildItem $ttczip | % {& "C:\Program Files\7-Zip\7z.exe" "x" $_.fullname "-o$esottcaddon" -y}

}


function startesominion {

start $minion
start $esolauncher

}



function backupconfig {

if (Test-Path $esoconfigbak) {
 "is da"
} else {
"nicht da"
  Copy-Item $esoconfig -Destination $esoconfigbak
}

$lastWrite2 = (get-item $esoconfigbak ).LastWriteTime
$timespan2 = new-timespan -days 3

if (((get-date) - $lastWrite2) -gt $timespan2) {
"zu alt"
  Copy-Item $esoconfig -Destination $esoconfigbak -Recurse -force
 
} else {
 "ok"
}

}

function timetoexit {

Start-Sleep -s 15
exit

}


function ttcuploadreminder {

$datetime=[datetime]::Today
if($datetime.DayOfWeek -match 'Wednesday|Friday|Sunday'){
   start https://eu.tamrieltradecentre.com/pc/Trade/WebClient
}else{
}

}



checkttczip
datettczip
unzipttczip
startesominion
#backupconfig
#timetoexit
#ttcuploadreminder
