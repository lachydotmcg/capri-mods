import json, os, re, shutil, subprocess

here = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
root = os.path.join(here, 'mods')
repo = 'lachydotmcg/capri-mods'
fallback = os.path.join(here, 'tools', 'default-preview.png')
kinds = {'.capri-mod': 'settings', '.capri-code': 'code', '.capri-skin': 'skin', '.capri-skill': 'skill', '.capri-companion': 'companion'}
about_mod = {'format', 'id', 'name', 'version', 'author', 'description'}

def kind(path, file):
    # A settings mod that only sets her colours is a look, so Capri's directory lists it with the skins.
    if file.endswith('.capri-mod') and set(json.load(open(os.path.join(path, file), encoding='utf-8'))) - about_mod == {'colors'}:
        return 'skin'
    return kinds[os.path.splitext(file)[1]]

def github(path):
    return json.loads(subprocess.run(['gh', 'api', path], capture_output=True, check=True, encoding='utf-8').stdout)

def maker(folder):
    # The pull request's opener wins, since a commit can sit under another of their accounts.
    commits = github('repos/' + repo + '/commits?per_page=100&path=mods/' + folder)
    if not commits:
        raise SystemExit(folder + ': no Made by line and no commit on GitHub yet, so merge it first')
    first = commits[-1]
    pulls = github('repos/' + repo + '/commits/' + first['sha'] + '/pulls')
    login = pulls[0]['user']['login'] if pulls else (first['author'] or {}).get('login')
    if not login:
        raise SystemExit(folder + ': no Made by line and no GitHub account on its first commit')
    return login

def plain(line):
    # Capri's directory shows the description as plain words: a banner picture is skipped, a link keeps its words,
    # and bold, italic and code marks come off.
    line = re.sub(r'!\[[^\]]*\]\([^)]*\)', '', line)
    line = re.sub(r'\[([^\]]+)\]\([^)]*\)', r'\1', line)
    line = re.sub(r'\*\*|__|`', '', line)
    line = re.sub(r'(?<![\w*])[*_](\S(?:.*?\S)?)[*_](?![\w*])', r'\1', line)
    return ' '.join(line.split())

def sign(path, login):
    # The line goes under Kind like every other README, so the next run doesn't need GitHub.
    with open(path, encoding='utf-8', newline='') as f:
        text = f.read()
    eol = '\r\n' if '\r\n' in text else '\n'
    under = re.search(r'^- Kind:.*\n', text, re.M)
    if not under:
        text = text.rstrip() + eol + eol
    at = under.end() if under else len(text)
    with open(path, 'w', encoding='utf-8', newline='') as f:
        f.write(text[:at] + '- Made by: ' + login + eol + text[at:])

mods = []
for folder in sorted(os.listdir(root)):
    path = os.path.join(root, folder)
    if not os.path.isdir(path):
        continue
    files = [f for f in os.listdir(path) if os.path.splitext(f)[1] in kinds]
    if len(files) != 1:
        raise SystemExit(folder + ': expected one mod file, found ' + str(files))
    readme_path = os.path.join(path, 'README.md')
    readme = open(readme_path, encoding='utf-8').read().replace('\r\n', '\n')
    lines = readme.split('\n')
    name = lines[0].lstrip('# ').strip()
    about = next(text for text in (plain(l) for l in lines[1:] if not l.startswith('-') and not l.startswith('#')) if text)
    made = re.search(r'^- Made by: (.+)$', readme, re.M)
    author = made.group(1).strip() if made else ''
    if not author:
        author = maker(folder)
        sign(readme_path, author)
        print(folder + ': no name in its README, so it gets the GitHub username ' + author)
    if not os.path.exists(os.path.join(path, 'preview.png')):
        shutil.copyfile(fallback, os.path.join(path, 'preview.png'))
        print(folder + ': no preview.png, so it gets the default picture')
    mods.append({'folder': folder, 'file': files[0], 'name': name, 'kind': kind(path, files[0]), 'author': author, 'about': about})
out = {'format': 1, 'mods': mods}
with open(os.path.join(here, 'index.json'), 'w', encoding='utf-8', newline='\n') as f:
    json.dump(out, f, ensure_ascii=False, indent=2)
    f.write('\n')
print(len(mods), 'mods:', ', '.join(m['name'] + ' (' + m['author'] + ')' for m in mods))
