# Función para establecer el fondo de pantalla
function Set-Wallpaper($imagePath) {
    Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public class Wallpaper {
    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
    
    public static void SetWallpaper(string path) {
        SystemParametersInfo(0x0014, 0, path, 0x0001 | 0x0002);
    }
}
"@
    [Wallpaper]::SetWallpaper($imagePath)
}

# URL de la imagen a descargar
$imageUrl = "https://listodelacompra.com/wp-content/uploads/2016/09/fary-2.jpg"

# Obtener el nombre del archivo de la URL
$imageFileName = [System.IO.Path]::GetFileName($imageUrl)

# Ruta temporal para guardar la imagen
$tempPath = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), $imageFileName)

# Descargar la imagen
Invoke-WebRequest -Uri $imageUrl -OutFile $tempPath

# Verificar si la descarga fue exitosa
if (Test-Path $tempPath) {
    # Establecer la imagen como fondo de pantalla
    Set-Wallpaper $tempPath
    Write-Host "Fondo de pantalla establecido con la imagen descargada: $($imageFileName)"
} else {
    Write-Host "No se pudo descargar la imagen desde la URL: $imageUrl"
}
