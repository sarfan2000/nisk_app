$files = Get-ChildItem -Path lib\screens -Filter "*.dart" -Recurse

foreach ($file in $files) {
    if ($file.Name -match "main.dart") { continue }
    
    $content = Get-Content $file.FullName
    $modified = $false
    
    for ($i = 0; $i -lt $content.Length; $i++) {
        $line = $content[$i]
        
        # Matches: decoration: const InputDecoration(labelText: 'Some Text *', ...)
        # Wait, if there's const on the InputDecoration, we need to make sure we don't break it. If Text.rich is also const, it's fine.
        
        if ($line -match "labelText:\s*'([^']+?)\s*\*'?") {
            $text = $matches[1]
            $newLine = $line -replace "labelText:\s*'[^']+?\s*\*'?", "label: const Text.rich(TextSpan(text: '$text ', children: [TextSpan(text: '*', style: TextStyle(color: Colors.red))]))"
            $content[$i] = $newLine
            $modified = $true
        }
    }
    
    if ($modified) {
        Set-Content -Path $file.FullName -Value $content
        Write-Host "Modified $($file.Name)"
    }
}
