#!/usr/bin/env python3
"""
Script to convert Objective-C (.m) keymap files to C (.c) files
"""

import re
import sys
import os

def convert_objc_to_c(input_file, output_file):
    """Convert Objective-C file to C file"""
    
    with open(input_file, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Remove #import statements for Objective-C headers
    content = re.sub(r'#import\s+"[^"]*\.h"', '', content)
    
    # Add C includes
    c_includes = """#include "IndicNotesIMEngine.h"
#include <ctype.h>
"""
    
    # Find the first non-comment line and insert includes
    lines = content.split('\n')
    insert_pos = 0
    for i, line in enumerate(lines):
        line = line.strip()
        if line and not line.startswith('/*') and not line.startswith('//') and not line.startswith('*'):
            insert_pos = i
            break
    
    lines.insert(insert_pos, c_includes)
    
    # Make all arrays static
    content = '\n'.join(lines)
    content = re.sub(r'^UniChar\s+(\w+)\[\]', r'static UniChar \1[]', content, flags=re.MULTILINE)
    
    # Convert Objective-C specific functions
    # Replace NSLog with simple comment (or printf if needed)
    content = re.sub(r'NSLog\(@"([^"]*)"[^;]*\);', r'// Debug: \1', content)
    
    # Replace isnumber with isdigit
    content = re.sub(r'isnumber\(', r'isdigit(', content)
    
    # Fix boolean values
    content = re.sub(r'\btrue\b', 'true', content)
    content = re.sub(r'\bfalse\b', 'false', content)
    content = re.sub(r'\bTRUE\b', 'true', content)
    content = re.sub(r'\bFALSE\b', 'false', content)
    
    # Write output file
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print(f"Converted {input_file} -> {output_file}")

def main():
    if len(sys.argv) < 2:
        print("Usage: python convert_objc_to_c.py <input_directory> [output_directory]")
        sys.exit(1)
    
    input_dir = sys.argv[1]
    output_dir = sys.argv[2] if len(sys.argv) > 2 else input_dir
    
    # List of files to convert
    files_to_convert = [
        'IndicDevanagariAnjalIMKeymap.m',
        'IndicMalayalamAnjalIMKeymap.m', 
        'IndicKannadaAnjalIMKeymap.m',
        'IndicTeluguAnjalIMKeymap.m',
        'IndicGurmukhiAnjalIMKeymap.m',
        'IndicNotesIMEngine.m'
    ]
    
    for filename in files_to_convert:
        input_path = os.path.join(input_dir, filename)
        output_filename = filename.replace('.m', '.c')
        output_path = os.path.join(output_dir, output_filename)
        
        if os.path.exists(input_path):
            try:
                convert_objc_to_c(input_path, output_path)
            except Exception as e:
                print(f"Error converting {filename}: {e}")
        else:
            print(f"File not found: {input_path}")

if __name__ == "__main__":
    main()