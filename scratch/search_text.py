import os

search_dir = r"c:\WEBDEV\AspireApp1"
query = "card-heading-h5"

for root, dirs, files in os.walk(search_dir):
    if ".vs" in root or "obj" in root or "bin" in root or ".git" in root:
        continue
    for file in files:
        if file.endswith((".css", ".cshtml", ".cs", ".js")):
            path = os.path.join(root, file)
            try:
                with open(path, "r", encoding="utf-8") as f:
                    for line_num, line in enumerate(f, 1):
                        if query in line:
                            print(f"{path}:{line_num}: {line.strip()}")
            except Exception:
                pass
