$pages = @{
    "index.cshtml"       = "featured"
    "new.cshtml"         = "new"
    "apparel.cshtml"     = "Apparel"
    "accessories.cshtml" = "Accessories"
    "plush.cshtml"       = "Plush"
    "bundles.cshtml"     = "Bundles"
    "stationery.cshtml"  = "Stationery"
    "game.cshtml"        = "Games"
    "shop-all.cshtml"    = "all"
}

foreach ($filename in $pages.Keys) {
    $path = "AspireApp1.Web\Pages\Shop2\$filename"
    if (Test-Path $path) {
        $content = [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)
        
        # 1. Clear the hardcoded product list items (non-greedy regex matching <ul ... id="Slider-template" ...> ... </ul>)
        # We handle quotes and exact format.
        $gridPattern = "(?s)<ul class=`"product-grid`" id=`"Slider-template`" role=`"list`">.*?</ul>"
        $replacementGrid = "<ul class=`"product-grid`" id=`"Slider-template`" role=`"list`"></ul>"
        
        # If the quotes are single quotes in some files, let's handle that as well
        if ($content -notmatch $gridPattern) {
            $gridPattern = "(?s)<ul class='product-grid' id='Slider-template' role='list'>.*?</ul>"
            $replacementGrid = "<ul class='product-grid' id='Slider-template' role='list'></ul>"
        }
        
        $content = [System.Text.RegularExpressions.Regex]::Replace($content, $gridPattern, $replacementGrid)

        # 2. Inject renderShopProducts('{filter}') before initCartEffects();
        $filter = $pages[$filename]
        $scriptPattern = "(?s)initCartEffects\(\);\s*initFeatures\(\);"
        $replacementScript = "renderShopProducts('$filter');`r`n        initCartEffects();`r`n        initFeatures();"
        
        if ($content -match $scriptPattern) {
            $content = [System.Text.RegularExpressions.Regex]::Replace($content, $scriptPattern, $replacementScript)
            [System.IO.File]::WriteAllText($path, $content, [System.Text.Encoding]::UTF8)
            Write-Output "✅ $filename successfully updated!"
        } else {
            Write-Warning "⚠️ Script block not matched in $filename"
        }
    } else {
        Write-Warning "⚠️ File not found: $filename"
    }
}
