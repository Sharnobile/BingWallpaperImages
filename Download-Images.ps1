function Get-UserInput {
    param (
        [string]$message,
        [string[]]$validResponses,
        [bool]$isCaseSensitive = $false
    )
    do {
        $response = Read-Host $message
        if (-not $isCaseSensitive) {
            $response = $response.ToLower()
            $validResponses = $validResponses.ForEach({ $_.ToLower() })
        }
    } until ($validResponses -contains $response)
    return $response
}

# Demander à l'utilisateur l'emplacement de téléchargement des fichiers
$downloadFolder = Read-Host "Entrez l'emplacement de téléchargement des fichiers (ou appuyez sur Entrée pour utiliser C:\ImagesBing par défaut)"
if (-not $downloadFolder) {
    $downloadFolder = "C:\ImagesBing"
}

# Demander si l'utilisateur souhaite limiter le nombre de fichiers
$limitFilesResponse = Get-UserInput -message "Voulez-vous limiter le nombre de fichiers à télécharger? (Oui/Non)" -validResponses @("O", "Y", "Yes", "Oui", "N", "NO")
$limitFiles = $limitFilesResponse -match "^(O|Y|Yes|Oui)$"
if ($limitFiles) {
    $maxFiles = [int](Read-Host "Entrez le nombre maximum de fichiers à télécharger")
} else {
    $maxFiles = [int]::MaxValue
}

# Demander si l'utilisateur souhaite spécifier des pages spécifiques
$limitPagesResponse = Get-UserInput -message "Voulez-vous spécifier des pages spécifiques à télécharger? (Oui/Non)" -validResponses @("O", "Y", "Yes", "Oui", "N", "NO")
$limitPages = $limitPagesResponse -match "^(O|Y|Yes|Oui)$"
if ($limitPages) {
    $pages = Read-Host "Entrez les numéros de pages séparés par des virgules (ex: 1,3,5)"
    $pages = $pages -split "," | ForEach-Object { [int]$_ }
} else {
    $pages = 1..27
}

# Demander si l'utilisateur souhaite un mode verbose
$verboseModeResponse = Get-UserInput -message "Voulez-vous activer le mode verbose? (Oui/Non)" -validResponses @("O", "Y", "Yes", "Oui", "N", "NO")
$verboseMode = $verboseModeResponse -match "^(O|Y|Yes|Oui)$"
if ($verboseMode) {
    $VerbosePreference = "Continue"
} else {
    $VerbosePreference = "SilentlyContinue"
}

# Demander si l'utilisateur souhaite un rapport à la fin
$generateReportResponse = Get-UserInput -message "Voulez-vous générer un rapport à la fin? (Oui/Non)" -validResponses @("O", "Y", "Yes", "Oui", "N", "NO")
$generateReport = $generateReportResponse -match "^(O|Y|Yes|Oui)$"

# Créer un dossier pour sauvegarder les images si nécessaire
if (-Not (Test-Path -Path $downloadFolder)) {
    New-Item -ItemType Directory -Path $downloadFolder | Out-Null
}

# Initialiser les variables pour le rapport
$totalImages = 0
$totalSize = 0
$startTime = Get-Date

# Boucler sur les pages spécifiées
foreach ($page in $pages) {
    Write-Verbose "Téléchargement des images de la page $page..."
    
    # Définir l'URL de la page web
    $url = "https://bing.gifposter.com/fr/list/new/desc/classic.html?p=$page"

    # Télécharger le contenu de la page
    $pageContent = Invoke-WebRequest -Uri $url -UseBasicParsing

    # Extraire les URLs des images en utilisant une regex
    $imageUrls = Select-String -InputObject $pageContent.Content -Pattern '(https:\/\/h2.gifposter.com\/bingImages\/[^"]+)' -AllMatches | ForEach-Object { $_.Matches.Value }

    # Filtrer les URLs pour obtenir des images en haute qualité
    $imageUrls = $imageUrls | ForEach-Object { $_ -replace '_sm', '' }

    # Télécharger chaque image et maintenir le nom
    foreach ($imgUrl in $imageUrls) {
        if ($totalImages -ge $maxFiles) {
            break
        }

        $imgName = [System.IO.Path]::GetFileNameWithoutExtension($imgUrl)
        $imgExtension = [System.IO.Path]::GetExtension($imgUrl)
        $imgPath = Join-Path -Path $downloadFolder -ChildPath "$imgName$imgExtension"

        # Télécharger et sauvegarder l'image
        Invoke-WebRequest -Uri $imgUrl -OutFile $imgPath
        
        # Mettre à jour les statistiques
        $fileSize = (Get-Item $imgPath).Length
        $totalSize += $fileSize
        $totalImages++

        Write-Verbose "Téléchargé: $imgName$imgExtension - Taille: $([math]::Round($fileSize / 1MB, 2)) MB"
    }

    if ($totalImages -ge $maxFiles) {
        break
    }
}

# Calculer le temps écoulé
$endTime = Get-Date
$duration = $endTime - $startTime

# Afficher le rapport si demandé
if ($generateReport) {
    Write-Output "Téléchargement terminé!"
    Write-Output "Nombre total d'images: $totalImages"
    Write-Output "Taille totale: $([math]::Round($totalSize / 1MB, 2)) MB"
    Write-Output "Durée totale: $duration"

    # Sauvegarder le rapport dans un fichier texte
    $reportPath = Join-Path -Path $downloadFolder -ChildPath "rapport_telechargement.txt"
    @"
Téléchargement terminé!
Nombre total d'images: $totalImages
Taille totale: $([math]::Round($totalSize / 1MB, 2)) MB
Durée totale: $duration
"@ | Out-File -FilePath $reportPath -Encoding UTF8

    Write-Output "Le rapport a été sauvegardé dans $reportPath"
}
