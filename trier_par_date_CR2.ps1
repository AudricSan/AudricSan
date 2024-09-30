param (
    [string]$targetDir,  # Dossier où se trouvent les fichiers à trier
    [string]$exifToolPath = "D:\audri\Sofrtware\exiftool-12.97_64\exiftool.exe"  # Chemin vers exiftool
)

# Vérifier si le dossier cible existe
if (-not (Test-Path $targetDir)) {
    Write-Host "Veuillez spécifier un chemin valide."
    exit
}

# Vérifier si ExifTool est présent
if (-not (Test-Path $exifToolPath)) {
    Write-Host "ExifTool n'a pas été trouvé. Veuillez spécifier le bon chemin."
    exit
}

# Fonction pour extraire la date de capture avec ExifTool
function Get-DateTaken {
    param (
        [string]$filePath
    )

    # Utiliser ExifTool pour extraire la date de capture (DateTimeOriginal)
    $exifOutput = & $exifToolPath -DateTimeOriginal -T $filePath

    if ($exifOutput) {
        try {
            # Convertir la sortie de ExifTool en format DateTime
            return [datetime]::ParseExact($exifOutput, "yyyy:MM:dd HH:mm:ss", $null)
        } catch {
            Write-Host "Erreur lors de l'extraction de la date pour $filePath"
            return $null
        }
    } else {
        return $null
    }
}

# Récupérer tous les fichiers CR2 dans le dossier cible
Get-ChildItem -Path $targetDir -Filter *.CR2 | ForEach-Object {
    $file = $_

    if (-not $file.PSIsContainer) {
        # Extraire la date de capture via ExifTool
        $dateTaken = Get-DateTaken -filePath $file.FullName

        if ($dateTaken) {
            # Formater la date en AAAA_MM_JJ
            $folderName = $dateTaken.ToString('yyyy_MM_dd')

            # Créer le dossier si nécessaire
            $destDir = Join-Path $targetDir $folderName
            if (-not (Test-Path $destDir)) {
                New-Item -ItemType Directory -Path $destDir
            }

            # Déplacer le fichier dans le dossier correspondant
            Move-Item -Path $file.FullName -Destination $destDir
        } else {
            Write-Host "Impossible de récupérer la date de capture pour $($file.FullName)"
        }
    }
}
Write-Host "Tous les fichiers CR2 ont été triés par date de capture."

# Récupérer tous les fichiers CR2 dans le dossier cible
Get-ChildItem -Path $targetDir -Filter *.CR3 | ForEach-Object {
    $file = $_

    if (-not $file.PSIsContainer) {
        # Extraire la date de capture via ExifTool
        $dateTaken = Get-DateTaken -filePath $file.FullName

        if ($dateTaken) {
            # Formater la date en AAAA_MM_JJ
            $folderName = $dateTaken.ToString('yyyy_MM_dd')

            # Créer le dossier si nécessaire
            $destDir = Join-Path $targetDir $folderName
            if (-not (Test-Path $destDir)) {
                New-Item -ItemType Directory -Path $destDir
            }

            # Déplacer le fichier dans le dossier correspondant
            Move-Item -Path $file.FullName -Destination $destDir
        } else {
            Write-Host "Impossible de récupérer la date de capture pour $($file.FullName)"
        }
    }
}

Write-Host "Tous les fichiers CR3 ont été triés par date de capture."
