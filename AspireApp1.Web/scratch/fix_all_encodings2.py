import os

dir_path = r"c:\WEBDEV\AspireApp1\AspireApp1.Web\Pages\Shopnew"

replacements = {
    "£": "$",
    "Â£": "$",
    "₫": "$",
    "âˆ’": "−",
    "âœ•": "✕",
    "âœ\"": "✓",
    "â€¢": "•",
    "â€¹": "‹",
    "â€º": "›",
    "Ã—": "✕",
    "â€™": "'"
}

for root, dirs, files in os.walk(dir_path):
    for file in files:
        if file.endswith(".cshtml"):
            file_path = os.path.join(root, file)
            try:
                with open(file_path, "r", encoding="utf-8-sig") as f:
                    content = f.read()
                
                modified = False
                for key, val in replacements.items():
                    if key in content:
                        content = content.replace(key, val)
                        modified = True
                
                if modified:
                    with open(file_path, "w", encoding="utf-8-sig") as f:
                        f.write(content)
                    print(f"Updated: {file}")
            except Exception as e:
                print(f"Error reading {file}: {e}")

print("Done!")
