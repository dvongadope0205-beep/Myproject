import os
import re

search_dir = r"c:\WEBDEV\AspireApp1\AspireApp1.Web\Pages"

print("--- Searching for nested div in label ---")
label_div_pat = re.compile(r"<label\b[^>]*>[\s\S]*?<div\b[\s\S]*?</label>", re.IGNORECASE)
for root, dirs, files in os.walk(search_dir):
    for f in files:
        if f.endswith(".cshtml"):
            path = os.path.join(root, f)
            try:
                with open(path, "r", encoding="utf-8") as file:
                    content = file.read()
                if label_div_pat.search(content):
                    print(f"Nested div in label found in: {path}")
            except Exception as e:
                pass

print("\n--- Searching for h3 tag issues ---")
# Let's search for h3 tags that don't have a matching </h3>, or contain <p> or <div> inside them.
h3_pat = re.compile(r"<h3\b[^>]*>([\s\S]*?)(</h3>|<h3\b)", re.IGNORECASE)
for root, dirs, files in os.walk(search_dir):
    for f in files:
        if f.endswith(".cshtml"):
            path = os.path.join(root, f)
            try:
                with open(path, "r", encoding="utf-8") as file:
                    content = file.read()
                # Find all h3 blocks
                for match in re.finditer(r"<h3\b[^>]*>([\s\S]*?)(</h3>)", re.IGNORECASE):
                    h3_content = match.group(1)
                    if "<div" in h3_content.lower() or "<p" in h3_content.lower():
                        print(f"h3 with nested div/p in: {path}")
                        print(f"Content: {match.group(0)}")
            except Exception as e:
                pass

print("\n--- Done ---")
