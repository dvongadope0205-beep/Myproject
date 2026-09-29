import os
import re

def check_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # 1. Search for <h3> containing <p> or <div> or <span>?
    # Actually, let's use regex to find <h3...>(.*?)</h3> with nested tags
    # Or just search for raw patterns
    
    # Find all h3 tags
    h3_matches = re.findall(r'<h3[^>]*>.*?</h3>', content, re.DOTALL)
    for m in h3_matches:
        if '<p' in m or '<div' in m:
            print(f"[{filepath}] Found h3 with nested p or div: {m[:100]}...")

    # Find all label tags
    label_matches = re.findall(r'<label[^>]*>.*?</label>', content, re.DOTALL)
    for m in label_matches:
        if '<div' in m:
            print(f"[{filepath}] Found label with nested div: {m[:100]}...")

    # Find unclosed tags or syntax issues
    # Let's count open/close tags
    for tag in ['div', 'p', 'h3', 'label']:
        opens = len(re.findall(rf'<{tag}\b', content, re.IGNORECASE))
        closes = len(re.findall(rf'</{tag}>', content, re.IGNORECASE))
        if opens != closes:
            print(f"[{filepath}] Mismatch for <{tag}>: opens={opens}, closes={closes}")

# Check all CSHTML files
pages_dir = r"c:\WEBDEV\AspireApp1\AspireApp1.Web\Pages"
for root, dirs, files in os.walk(pages_dir):
    for file in files:
        if file.endswith('.cshtml'):
            check_file(os.path.join(root, file))
