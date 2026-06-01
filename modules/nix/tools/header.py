# modules/nix/tools/header.py
################################################################################
# Writes and repairs the file-path + separator header block at the top of each
# source file. Run automatically by treefmt via the `header` formatter.
################################################################################
import sys
import os

SEP = '#' * 80


def find_root(filepath):
    path = os.path.realpath(os.path.dirname(os.path.abspath(filepath)))
    while True:
        if os.path.exists(os.path.join(path, 'flake.nix')):
            return path
        parent = os.path.dirname(path)
        if parent == path:
            return None
        path = parent


def is_path_line(line):
    if not line.startswith('# '):
        return False
    return ' ' not in line[2:] and len(line) > 2


def repair_header(lines, path_line):
    result = list(lines)
    result[0] = path_line

    if len(result) < 2 or result[1] != SEP:
        comment_end = 1
        while comment_end < len(result) and result[comment_end].startswith('#') and result[comment_end] != SEP:
            comment_end += 1
        result.insert(1, SEP)
        comment_end += 1
        if comment_end == 2:
            result.insert(2, '# ')
            comment_end = 3
        if comment_end >= len(result) or result[comment_end] != SEP:
            result.insert(comment_end, SEP)
        return result

    i = 2
    while i < len(result) and result[i].startswith('#') and result[i] != SEP:
        i += 1

    if i < len(result) and result[i] == SEP:
        if i == 2:
            result.insert(2, '# ')
        return result

    if i == 2:
        result.insert(2, '# ')
        i = 3
    result.insert(i, SEP)
    return result


def process_file(filepath):
    root = find_root(filepath)
    if root is None:
        print(f"Warning: could not find project root for {filepath}", file=sys.stderr)
        return

    rel_path = os.path.relpath(os.path.realpath(os.path.abspath(filepath)), root)
    path_line = f"# {rel_path}"

    with open(filepath, 'r') as f:
        content = f.read()

    lines = content.splitlines()

    if lines and is_path_line(lines[0]):
        repaired = repair_header(lines, path_line)
        new_content = '\n'.join(repaired) + '\n'
        if new_content != content:
            with open(filepath, 'w') as f:
                f.write(new_content)
    else:
        header = f"{path_line}\n{SEP}\n# \n{SEP}\n"
        with open(filepath, 'w') as f:
            f.write(header + content)


for filepath in sys.argv[1:]:
    process_file(filepath)
