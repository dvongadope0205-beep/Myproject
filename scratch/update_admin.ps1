$path = "AspireApp1.Web\Pages\AdminDashboard.cshtml"
$content = [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)

# Locate the exact target string
$target = @"
                                                <button class="btn-icon btn-edit" title="Edit"
                                                         data-id="@p.ProductId"
                                                         data-name="@p.Name"
                                                         data-info="@p.ProductInformation"
                                                         data-detail="@p.ProductDetail"
                                                         data-care="@p.MaterialAndCare"
                                                         data-price="@p.Price"
                                                         data-stock="@p.StockQuantity"
                                                         data-category="@p.CategoryName"
                                                         data-image="@p.ImagePath"
                                                         data-images="@p.AdditionalImages"
                                                         onclick="openProductModal(this)">
"@

$replacement = @"
                                                <button class="btn-icon btn-edit" title="Edit"
                                                         data-id="@p.ProductId"
                                                         data-name="@p.Name"
                                                         data-info="@p.ProductInformation"
                                                         data-detail="@p.ProductDetail"
                                                         data-care="@p.MaterialAndCare"
                                                         data-price="@p.Price"
                                                         data-stock="@p.StockQuantity"
                                                         data-category="@p.CategoryName"
                                                         data-image="@p.ImagePath"
                                                         data-images="@p.AdditionalImages"
                                                         data-size-enabled="@(p.IsSizeEnabled ? "1" : "0")"
                                                         data-size-chart-enabled="@(p.IsSizeChartEnabled ? "1" : "0")"
                                                         data-featured="@(p.IsFeatured ? "1" : "0")"
                                                         data-new="@(p.IsNew ? "1" : "0")"
                                                         onclick="openProductModal(this)">
"@

# Normalize CRLF and replace
$contentNorm = $content.Replace("`r`n", "`n")
$targetNorm = $target.Replace("`r`n", "`n")
$replacementNorm = $replacement.Replace("`r`n", "`n")

if ($contentNorm.Contains($targetNorm)) {
    $newContentNorm = $contentNorm.Replace($targetNorm, $replacementNorm)
    $newContent = $newContentNorm.Replace("`n", "`r`n")
    [System.IO.File]::WriteAllText($path, $newContent, [System.Text.Encoding]::UTF8)
    Write-Output "✅ AdminDashboard.cshtml successfully updated!"
} else {
    # If indentation differs, let's try a simpler regex
    $pattern = "(?s)<button class=`"btn-icon btn-edit`" title=`"Edit`"\s+data-id=`"@p\.ProductId`"\s+data-name=`"@p\.Name`"\s+data-info=`"@p\.ProductInformation`"\s+data-detail=`"@p\.ProductDetail`"\s+data-care=`"@p\.MaterialAndCare`"\s+data-price=`"@p\.Price`"\s+data-stock=`"@p\.StockQuantity`"\s+data-category=`"@p\.CategoryName`"\s+data-image=`"@p\.ImagePath`"\s+data-images=`"@p\.AdditionalImages`"\s+onclick=`"openProductModal\(this\)`">"
    if ($content -match $pattern) {
        $newContent = [System.Text.RegularExpressions.Regex]::Replace($content, $pattern, $replacement)
        [System.IO.File]::WriteAllText($path, $newContent, [System.Text.Encoding]::UTF8)
        Write-Output "✅ AdminDashboard.cshtml successfully updated via RegEx!"
    } else {
        Write-Error "❌ Target string not found in AdminDashboard.cshtml"
    }
}
