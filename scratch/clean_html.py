import os

file_path = r"c:\WEBDEV\AspireApp1\AspireApp1.Web\Pages\AdminDashboard.cshtml"

with open(file_path, "r", encoding="utf-8") as f:
    lines = f.readlines()

# We want to remove lines 1003 to 1016 (inclusive, 1-indexed)
# In 0-indexed lists, these are indices 1002 to 1015 (inclusive)
del lines[1002:1016]

with open(file_path, "w", encoding="utf-8") as f:
    f.writelines(lines)

print("Successfully cleaned AdminDashboard.cshtml")
