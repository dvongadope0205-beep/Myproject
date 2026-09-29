$path = "c:\WEBDEV\AspireApp1\AspireApp1.Web\Pages\Join.cshtml"
$content = [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)

# 1. Remove the "Opening times" box button in "Do I still..." section
$oldAccordionRte = '                                                        <div class="accordion_rte">
                                                            <a class="faq_button" href="opening_time.html">
                                                                <span class="button-icon">
                                                                    <span class="button-text">Opening times</span>
                                                                </span>
                                                            </a>
                                                        </div>'
$content = $content.Replace($oldAccordionRte, "")

# 2. Format the <a> links: lowercase, no href (styled to look like regular text with no link style/behavior)
# Match links robustly using regex or direct string replacement. Since they might have different whitespace, regex is safer.
$content = $content -replace '<a\s+href="experiences\.html">Nation\s+Zoo\s+experiences</a>', '<a style="text-decoration: none; color: inherit; cursor: default;">national zoo experiences</a>'
$content = $content -replace '<a\s+href="activities\.html">Treetop\s+Challenge</a>', '<a style="text-decoration: none; color: inherit; cursor: default;">treetop challenge</a>'
$content = $content -replace '<a\s+href="activities\.html">Virtual\s+Reality</a>', '<a style="text-decoration: none; color: inherit; cursor: default;">virtual reality</a>'
$content = $content -replace '<a\s+href="activities\.html">Off-Road\s+Adventure</a>', '<a style="text-decoration: none; color: inherit; cursor: default;">off-road adventure</a>'

# Let's also do the direct replacement if they are slightly different in whitespace
$content = $content.Replace('<a href="experiences.html">Nation Zoo' + "`r`n" + '                                                                            experiences</a>', '<a style="text-decoration: none; color: inherit; cursor: default;">national zoo experiences</a>')
$content = $content.Replace('<a href="activities.html">Treetop Challenge</a>', '<a style="text-decoration: none; color: inherit; cursor: default;">treetop challenge</a>')
$content = $content.Replace('<a href="activities.html">Virtual Reality</a>', '<a style="text-decoration: none; color: inherit; cursor: default;">virtual reality</a>')
$content = $content.Replace('<a href="activities.html">Off-Road Adventure</a>', '<a style="text-decoration: none; color: inherit; cursor: default;">off-road adventure</a>')

# 3. Standardize text: Replace "Chester Zoo" and "Nation Zoo" with "National Zoo" (handling multiline/any whitespace)
$content = $content.Replace("ColNation Zoo", "Colchester Zoo")
$content = $content -replace 'Chester\s+Zoo', 'National Zoo'
$content = $content -replace 'Nation\s+Zoo', 'National Zoo'

# Fix typo "Subribe" to "Subscribe" in the benefits section
$content = $content.Replace("Subribe", "Subscribe")

[System.IO.File]::WriteAllText($path, $content, [System.Text.Encoding]::UTF8)
Write-Output "Join.cshtml updated successfully"
