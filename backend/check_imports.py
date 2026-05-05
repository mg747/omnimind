import ast
import os
import sys

def get_imports(path):
    with open(path, 'r', encoding='utf-8') as f:
        try:
            tree = ast.parse(f.read())
        except Exception as e:
            return set()
    imports = set()
    for node in ast.walk(tree):
        if isinstance(node, ast.Import):
            for n in node.names:
                imports.add(n.name.split('.')[0])
        elif isinstance(node, ast.ImportFrom):
            if node.module:
                imports.add(node.module.split('.')[0])
    return imports

all_imports = set()
for root, dirs, files in os.walk('.'):
    if 'venv' in root or 'test_env' in root:
        continue
    for file in files:
        if file.endswith('.py'):
            all_imports.update(get_imports(os.path.join(root, file)))

stdlib = set(sys.builtin_module_names) | {'os', 'sys', 'time', 'json', 're', 'hashlib', 'typing', 'uuid', 'random', 'asyncio'}
missing = sorted(list(all_imports - stdlib))
print("Found imports:", missing)
