param (
    [Parameter(Mandatory=$true)]
    [ValidateScript({Test-Path $_ -PathType 'Container'})]
    [string]$targetDir,
    
    [ValidateScript({Test-Path $_ -PathType 'Leaf'})]
    [string]$exifToolPath = "D:\audri\Sofrtware\exiftool-12.97_64\exiftool.exe",

    [Parameter(Mandatory=$false)]
    [string[]]$fileExtensions = @('CR2', 'CR3', 'JPG', 'JPEG', 'PNG', 'TIF', 'TIFF')
)

# Vérifier si ExifTool est présent
if (-not (Test-Path $exifToolPath)) {
    Write-Error "ExifTool n'a pas été trouvé. Veuillez spécifier le bon chemin."
    exit 1
}

# Fonction pour extraire la date de capture avec ExifTool
function Get-DateTaken {
    param ([string]$filePath)
    
    $exifOutput = & $exifToolPath -DateTimeOriginal -T -d "%Y:%m:%d %H:%M:%S" $filePath
    if ($exifOutput) {
        try {
            return [datetime]::ParseExact($exifOutput, "yyyy:MM:dd HH:mm:ss", $null)
        } catch {
            Write-Warning "Erreur lors de l'extraction de la date pour $filePath"
            return $null
        }
    }
    return $null
}

# Fonction pour trier les fichiers par date
function Sort-FilesByDate {
    param (
        [string]$fileExtension
    )
    
    $files = Get-ChildItem -Path $targetDir -Filter *.$fileExtension -File
    $totalFiles = $files.Count
    $processedFiles = 0
    $startTime = Get-Date
    
    foreach ($file in $files) {
        $dateTaken = Get-DateTaken -filePath $file.FullName
        if ($dateTaken) {
            $folderName = $dateTaken.ToString('yyyy_MM_dd')
            $destDir = Join-Path $targetDir $folderName
            
            if (-not (Test-Path $destDir)) {
                New-Item -ItemType Directory -Path $destDir | Out-Null
            }
            
            try {
                Move-Item -Path $file.FullName -Destination $destDir -ErrorAction Stop
                $processedFiles++
                
                $elapsedTime = (Get-Date) - $startTime
                $averageTimePerFile = $elapsedTime.TotalSeconds / $processedFiles
                $remainingFiles = $totalFiles - $processedFiles
                $estimatedRemainingTime = [TimeSpan]::FromSeconds($averageTimePerFile * $remainingFiles)
                
                $status = "Progression : {0:N2}% - Temps restant estimé : {1:hh\:mm\:ss}" -f (($processedFiles / $totalFiles) * 100), $estimatedRemainingTime
                Write-Progress -Activity "Tri des fichiers $fileExtension" -Status $status -PercentComplete (($processedFiles / $totalFiles) * 100)
            } catch {
                Write-Warning "Impossible de déplacer $($file.FullName) : $_"
            }
        } else {
            Write-Warning "Impossible de récupérer la date de capture pour $($file.FullName)"
        }
    }
    
    Write-Host "Tous les fichiers $fileExtension ont été traités. $processedFiles sur $totalFiles ont été triés avec succès."
}

# Trier les fichiers selon les extensions spécifiées
$fileExtensions | ForEach-Object {
    Sort-FilesByDate -fileExtension $_
}

Write-Host "Opération terminée."

