# Créer un dossier pour sauvegarder les images
$downloadFolder = "C:\ImagesBing"
if (-Not (Test-Path -Path $downloadFolder)) {
    New-Item -ItemType Directory -Path $downloadFolder | Out-Null
}

# Initialiser les variables pour le rapport
$totalImages = 0
$totalSize = 0
$startTime = Get-Date

# Boucler sur les pages de 1 à 27
for ($page = 1; $page -le 27; $page++) {
    Write-Output "Téléchargement des images de la page $page..."
    
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
        $imgName = [System.IO.Path]::GetFileNameWithoutExtension($imgUrl)
        $imgExtension = [System.IO.Path]::GetExtension($imgUrl)
        $imgPath = Join-Path -Path $downloadFolder -ChildPath "$imgName$imgExtension"

        # Télécharger et sauvegarder l'image
        $webResponse = Invoke-WebRequest -Uri $imgUrl -OutFile $imgPath
        
        # Mettre à jour les statistiques
        $fileSize = (Get-Item $imgPath).Length
        $totalSize += $fileSize
        $totalImages++

        Write-Output "Téléchargé: $imgName$imgExtension - Taille: $([math]::Round($fileSize / 1MB, 2)) MB"
    }
}

# Calculer le temps écoulé
$endTime = Get-Date
$duration = $endTime - $startTime

# Afficher le rapport
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
