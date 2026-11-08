# Turns an issue from the "Submit a mod" form into a pull request, so sharing a mod doesn't need git. Lachy still
# reads every one before it merges. Everything in the issue is untrusted: it's read from the event file here and
# never reaches a shell line, only GitHub's own attachment links are downloaded, and nothing from a submission is
# run, imported or unpacked to disk.
#
#   check OUT     reads the issue and downloads its files into OUT. Runs with a read-only token.
#   open-pr OUT   puts OUT's files in mods/<id>/ on branch submit/<issue>, opens or updates its pull request and
#                 comments on the issue with the link.
#   explain OUT   comments on the issue with what to fix.
#   --dry-run     open-pr and explain write the mod folder into this repo and the pull request text into OUT,
#                 without calling GitHub.
import hashlib, io, json, os, re, stat, struct, subprocess, sys, unicodedata, urllib.error, urllib.parse, urllib.request, zipfile

here = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
mb = 1024 * 1024
marker = '<!-- capri-submit-mod -->'
bot_name = 'github-actions[bot]'
bot_email = '41898282+github-actions[bot]@users.noreply.github.com'

# The form's headings, in order. .github/ISSUE_TEMPLATE/submit-mod.yml uses the same labels.
fields = (('name', 'Mod name'), ('id', 'Mod id'), ('description', 'Short description'), ('kind', 'Kind'),
          ('file', 'Mod file'), ('preview', 'Preview picture'), ('more', 'More about it'), ('permission', 'Permission'))

# Each of the form's kinds: its mod file, the README's Kind words, the uploads GitHub takes for it, and a size cap.
kinds = {'Settings mod (.capri-mod)': ('.capri-mod', 'settings mod', ('.zip', '.json', '.txt'), 2 * mb),
         'Code mod (.capri-code)': ('.capri-code', 'code mod', ('.zip', '.cs', '.txt'), 2 * mb),
         'Skin (.capri-skin)': ('.capri-skin', 'skin', ('.zip',), 96 * mb),
         'Skill (.capri-skill)': ('.capri-skill', 'skill', ('.zip', '.txt', '.md'), 2 * mb)}
mod_types = tuple(kind[0] for kind in kinds.values())
kind_words = {kind[1] for kind in kinds.values()}
upload_cap = 25 * mb   # GitHub's own limit for a dragged-in file
preview_cap = 2 * mb   # the same as tools/check-mods.py

slug = re.compile(r'[a-z0-9](?:[a-z0-9-]{0,48}[a-z0-9])?')
reserved = {'con', 'prn', 'aux', 'nul'} | {'com' + str(n) for n in range(10)} | {'lpt' + str(n) for n in range(10)}
login_shape = re.compile(r'[A-Za-z0-9][A-Za-z0-9-]{0,38}')
name_shape = re.compile(r"[^\W_][\w .,:&!?'+()-]{0,59}")
not_plain = re.compile(r'[-#>|*+=!\[<`~_]|\d+\.')
when_shape = re.compile(r'\d{4}-\d\d-\d\dT\d\d:\d\d:\d\dZ')

# Only what GitHub writes when a file is dragged into a box: the user-attachments links and the older repo and
# user-images forms. Every hop of a download has to stay on these hosts, over HTTPS.
any_link = re.compile(r'https?://[^\s<>()\[\]"\'`]+', re.I)
attachment = re.compile(r'https://(?:github\.com/user-attachments/(?:files/\d+/[^/?#]+|assets/[0-9a-fA-F-]{36})'
                        r'|github\.com/[\w.-]+/[\w.-]+/(?:files/\d+/[^/?#]+|assets/\d+/[0-9a-fA-F-]{36})'
                        r'|user-images\.githubusercontent\.com/\d+/[^/?#]+)')
hosts = {'github.com', 'objects.githubusercontent.com', 'user-images.githubusercontent.com',
         'private-user-images.githubusercontent.com', 'github-production-user-asset-6210df.s3.amazonaws.com',
         'github-production-repository-file-5c1aeb.s3.amazonaws.com'}


class Problem(Exception):
    pass


class Stay(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, *args):
        return None  # download() checks every hop itself


opener = urllib.request.build_opener(Stay)


def open_url(url):
    return opener.open(urllib.request.Request(url, headers={'User-Agent': 'capri-mods-submit'}), timeout=30)


def download(url, cap):
    for _ in range(5):
        try:
            parts = urllib.parse.urlsplit(url)
            safe = (parts.scheme == 'https' and parts.hostname in hosts and parts.port in (None, 443)
                    and not parts.username and not parts.password)
        except ValueError:
            safe = False
        if not safe:
            raise Problem("tried to come from somewhere that isn't GitHub, so it wasn't downloaded.")
        try:
            response = open_url(url)
        except urllib.error.HTTPError as error:
            where = error.headers.get('Location')
            if error.code in (301, 302, 303, 307, 308) and where:
                url = urllib.parse.urljoin(url, where)
                continue
            raise Problem("couldn't be downloaded (GitHub said {}). Drag it in again.".format(error.code))
        except (OSError, ValueError):
            raise Problem("couldn't be downloaded. Drag it in again.")
        with response:
            size = response.headers.get('Content-Length', '')
            if size.isdigit() and int(size) > cap:
                raise Problem('is over {}.'.format(size_words(cap)))
            data = response.read(cap + 1)
        if len(data) > cap:
            raise Problem('is over {}.'.format(size_words(cap)))
        return data
    raise Problem("couldn't be downloaded. Drag it in again.")


def size_words(size):
    return '{:.1f} MB'.format(size / mb).replace('.0 MB', ' MB') if size >= mb else '{} KB'.format(max(1, round(size / 1024)))


def shown(text, limit=60):
    # Text from the issue goes back out in a code span, with nothing that can close it or start a new line.
    text = ' '.join(''.join(c if c.isprintable() and c != '`' else ' ' for c in text).split())
    return '`' + (text[:limit] + '...' if len(text) > limit else text or '(blank)') + '`'


def listed(names):
    return ', '.join(shown(name) for name in names[:3]) + (' and {} more'.format(len(names) - 3) if len(names) > 3 else '')


def log(text):
    # Only plain ASCII reaches the log, and nothing the runner would read as a command.
    print(''.join(c if ' ' <= c <= '~' else '?' for c in str(text)).replace('::', ': :').replace('##[', '# #['))


def output(name, value):
    if os.environ.get('GITHUB_OUTPUT'):
        with open(os.environ['GITHUB_OUTPUT'], 'a', encoding='utf-8') as out:
            out.write(name + '=' + value + '\n')


def git(*args, env=None, data=None):
    return subprocess.run(('git',) + args, cwd=here, env=env, input=data, capture_output=True,
                          check=True).stdout.decode('utf-8', 'surrogateescape')


def tree(spec):
    rows = {}
    for row in git('ls-tree', '-z', spec).split('\0'):
        if row:
            info, name = row.split('\t', 1)
            mode, kind, sha = info.split()
            rows[name] = (mode, kind, sha)
    return rows


def mktree(rows):
    text = ''.join('{} {} {}\t{}\0'.format(mode, kind, sha, name) for name, (mode, kind, sha) in rows.items())
    return git('mktree', '-z', '--missing', data=text.encode('utf-8', 'surrogateescape')).strip()


class GitHub:
    def __init__(self):
        self.repo = os.environ['GITHUB_REPOSITORY']
        self.base = os.environ.get('GITHUB_API_URL', 'https://api.github.com').rstrip('/') + '/repos/' + self.repo
        self.token = os.environ.get('GITHUB_TOKEN', '')

    def call(self, method, path, body=None):
        request = urllib.request.Request(self.base + path, method=method,
                                         data=None if body is None else json.dumps(body).encode('utf-8'))
        request.add_header('Accept', 'application/vnd.github+json')
        request.add_header('X-GitHub-Api-Version', '2022-11-28')
        request.add_header('User-Agent', 'capri-mods-submit')
        if body is not None:
            request.add_header('Content-Type', 'application/json')
        if self.token:
            request.add_header('Authorization', 'Bearer ' + self.token)
        with urllib.request.urlopen(request, timeout=30) as response:
            text = response.read()
        return json.loads(text) if text.strip() else None


def read_event():
    with open(os.environ['GITHUB_EVENT_PATH'], encoding='utf-8') as event:
        return json.load(event)


def read_form(body):
    # Each heading has to be there once and in order, so text inside one box can't pose as another box.
    lines = body.replace('\r\n', '\n').replace('\r', '\n').split('\n')
    spots = []
    for _, label in fields:
        found = [number for number, line in enumerate(lines) if line.strip() == '### ' + label]
        if len(found) != 1:
            return None
        spots.append(found[0])
    if spots != sorted(spots):
        return None
    form = {}
    for at, (key, _) in enumerate(fields):
        text = '\n'.join(lines[spots[at] + 1:spots[at + 1] if at + 1 < len(spots) else len(lines)]).strip()
        form[key] = '' if text == '_No response_' else text
    return form


def made_by(mod_id):
    try:
        text = git('cat-file', 'blob', 'HEAD:mods/' + mod_id + '/README.md')
    except subprocess.CalledProcessError:
        return ''
    found = re.search(r'^- Made by: (.+)$', text.replace('\r\n', '\n'), re.M)
    return found.group(1).strip() if found else ''


def first_opener(mod_id):
    # Who opened the pull request that first added the folder, the same way tools/make-index.py credits a mod.
    if not os.environ.get('GITHUB_TOKEN'):
        return ''
    try:
        github = GitHub()
        commits = github.call('GET', '/commits?per_page=100&path=' + urllib.parse.quote('mods/' + mod_id))
        if not commits:
            return ''
        pulls = github.call('GET', '/commits/' + commits[-1]['sha'] + '/pulls')
        return pulls[0]['user']['login'] if pulls else (commits[-1].get('author') or {}).get('login') or ''
    except Exception:
        return ''


def attached(text, label, cap, problems, required):
    links = list(dict.fromkeys(any_link.findall(text)))
    if not links:
        if required:
            problems.append('**{}** is empty. Drag your file into that box, wait for it to upload, then save.'.format(label))
        return None
    if len(links) > 1:
        problems.append('**{}** has more than one file or link in it, so keep just one.'.format(label))
        return None
    if not attachment.fullmatch(links[0]):
        problems.append("**{}** has to be a file dragged into the box. Links to other sites don't work.".format(label))
        return None
    path = urllib.parse.urlsplit(links[0]).path
    ext = os.path.splitext(urllib.parse.unquote(path.rsplit('/', 1)[1]))[1].lower() if '/assets/' not in path else ''
    try:
        return download(links[0], cap), ext
    except Problem as problem:
        problems.append('**{}** {}'.format(label, problem))
        return None


def unzip(data, want, cap, problems):
    # Read in memory with a cap, never extracted, so a name like ../x or a zip bomb goes nowhere.
    try:
        with zipfile.ZipFile(io.BytesIO(data)) as box:
            entries = [entry for entry in box.infolist() if not entry.is_dir()
                       and not entry.filename.startswith('__MACOSX/') and entry.filename.rsplit('/', 1)[-1] != '.DS_Store']
            names = [entry.filename for entry in entries]
            if want == '.capri-skin' and 'skin.json' in names and not any(n.lower().endswith(want) for n in names):
                return data  # a renamed .capri-skin is already the skin, so it's kept byte for byte
            if len(entries) != 1 or not names[0].lower().endswith(want):
                problems.append('**Mod file** has to be a zip with just your one `{}` file in it, but it holds {}.'.format(
                    want, listed(names) if names else 'nothing'))
                return None
            if stat.S_ISLNK(entries[0].external_attr >> 16):
                problems.append("**Mod file** holds a link, not a file, so zip the file itself.")
                return None
            too_big = entries[0].file_size > cap
            if not too_big:
                with box.open(entries[0]) as read:
                    inner = read.read(cap + 1)
                too_big = len(inner) > cap
    except Exception:
        problems.append("**Mod file** isn't a zip that can be opened.")
        return None
    if too_big:
        problems.append('**Mod file** is over {} once unzipped.'.format(size_words(cap)))
        return None
    return inner


def content_problem(data, want):
    if want == '.capri-skin':
        try:
            with zipfile.ZipFile(io.BytesIO(data)) as skin:
                names = skin.namelist()
        except Exception:
            return "isn't a skin. A skin is a zip of her pictures and a `skin.json`."
        return None if data[:4] == b'PK\x03\x04' and 'skin.json' in names else "has no `skin.json` at the top, so it isn't a skin."
    try:
        text = data.decode('utf-8')
    except ValueError:
        return "isn't plain UTF-8 text."
    if '\0' in text:
        return "isn't plain text."
    if want == '.capri-mod':
        try:
            value = json.loads(text)
        except (ValueError, RecursionError):
            return "isn't valid JSON."
        if not isinstance(value, dict):
            return 'has to be a JSON object, with { } around it.'
    return None


def png_problem(data):
    if data[:8] != b'\x89PNG\r\n\x1a\n' or data[12:16] != b'IHDR':
        return 'has to be a PNG.'
    width, height = struct.unpack('>II', data[16:24])
    if not 0 < width <= 4096 or not 0 < height <= 4096:
        return 'has to be 4096 pixels across or smaller.'
    return None


def readme(plan, description, more):
    text = '# {}\n\n{}\n\n- Kind: {}\n- Made by: {}\n'.format(plan['name'], description, plan['kind'], plan['login'])
    return text + ('\n' + more + '\n' if more else '')


def gather(issue, plan, out):
    problems = plan['problems']
    form = read_form(issue.get('body') or '')
    if form is None:
        problems.append("This doesn't look like the Submit a mod form any more: each of its headings, like "
                        "`### Mod name`, has to be there once. Open a new issue with New issue > Submit a mod.")
        return
    name = ' '.join(form['name'].split())
    if not name_shape.fullmatch(name):
        problems.append("**Mod name** {} has to be up to 60 letters, numbers, spaces and simple marks like : & ' ( ), "
                        'starting with a letter or number.'.format(shown(name)))
    mod_id = form['id'].strip()
    if not slug.fullmatch(mod_id) or mod_id in reserved:
        problems.append('**Mod id** {} has to be up to 50 lower-case letters, numbers and dashes, like `neon-hearts`, '
                        'without a dash at either end.'.format(shown(mod_id)))
        mod_id = None
    description = ' '.join(form['description'].split())
    if not description or len(description) > 300 or not description.isprintable() or not_plain.match(description):
        problems.append('**Short description** has to be one plain line, up to 300 characters, that starts with a '
                        'word rather than a mark like `-`, `#` or `>`.')
    kind = kinds.get(form['kind'].strip())
    if not kind:
        problems.append("**Kind** has to be one of the form's choices.")
    more = '\n'.join(line.rstrip() for line in form['more'].split('\n')).strip()
    if len(more) > 5000 or any((unicodedata.category(c) == 'Cc' and c not in '\n\t') or '\u202a' <= c <= '\u202e'
                               or '\u2066' <= c <= '\u2069' for c in more):
        problems.append('**More about it** has to be plain text, up to 5000 characters.')
    if not re.search(r'^- \[[xX]\] ', form['permission'], re.M):
        problems.append('Tick the box to say this is your own work, or that you have permission to share it.')

    if mod_id:
        folders = {folder.lower(): folder for folder, (_, kind_of, _) in tree('HEAD:mods').items() if kind_of == 'tree'}
        taken = folders.get(mod_id)
        if taken and taken != mod_id:
            problems.append('**Mod id** {} is too close to the mod {}, so pick another one.'.format(shown(mod_id), shown(taken)))
        elif taken:
            owner = made_by(mod_id)
            if owner.lower() == plan['login'].lower() or first_opener(mod_id).lower() == plan['login'].lower():
                plan['update'] = True
            else:
                problems.append("**Mod id** {} is already used by {}'s mod, so pick another id. If that mod is yours, "
                                'say so in a comment here and Lachy will sort it out.'.format(shown(mod_id), shown(owner or 'someone')))

    mod = None
    if kind:
        want, words, types, cap = kind
        found = attached(form['file'], 'Mod file', upload_cap, problems, True)
        if found:
            data, ext = found
            if ext not in types + (want,):
                problems.append('**Mod file** for a {} has to be a {} file, but this one is {}.'.format(
                    words, ' or '.join('`' + t + '`' for t in types), shown(ext or 'a picture')))
            else:
                mod = unzip(data, want, cap, problems) if ext == '.zip' else data
                if mod is not None and want == '.capri-mod' and mod.startswith(b'\xef\xbb\xbf'):
                    mod = mod[3:]  # tools/make-index.py can't read a settings mod with a BOM
                problem = content_problem(mod, want) if mod is not None else None
                if problem:
                    problems.append('**Mod file** ' + problem)
                    mod = None
    preview = attached(form['preview'], 'Preview picture', preview_cap, problems, False)
    if preview:
        problem = png_problem(preview[0])
        if problem:
            problems.append('**Preview picture** ' + problem)
    if problems:
        return

    plan.update(id=mod_id, name=name, kind=kind[1], ext=kind[0])
    files = {mod_id + kind[0]: mod, 'README.md': readme(plan, description, more).encode('utf-8')}
    if preview:
        files['preview.png'] = preview[0]
    for file, data in files.items():
        with open(os.path.join(out, 'files', file), 'xb') as write:
            write.write(data)
    plan['files'] = sorted(files)
    if os.path.isfile(os.path.join(here, 'tools', 'check-mods.py')):
        plan['checks'], plan['to_fix'] = run_checks(plan, out)


def run_checks(plan, out):
    # The same checklist a normal pull request gets, on the exact commit open-pr will push. A pull request opened
    # by GITHUB_TOKEN doesn't start the Mod checks workflow, so it runs here instead.
    parent = git('rev-parse', 'HEAD').strip()
    commit = build_commit(plan, os.path.join(out, 'files'), parent)
    env = {key: value for key, value in os.environ.items() if key != 'GITHUB_STEP_SUMMARY'}
    env['OWN_BRANCH'] = 'false'
    try:
        result = subprocess.run([sys.executable, '-I', os.path.join(here, 'tools', 'check-mods.py'), parent, commit],
                                cwd=here, env=env, capture_output=True, timeout=300)
    except subprocess.TimeoutExpired:
        result = None
    if result is None or result.returncode not in (0, 1):
        return "The automatic checks didn't finish, so read this one by hand.", 0
    report = result.stdout.decode('utf-8', 'replace').strip()
    to_fix = re.search(r'Mod checks: (\d+) to fix', report)
    return report, int(to_fix.group(1)) if to_fix else 0


def build_commit(plan, files, parent):
    # Built from git objects alone, so it works in a sparse checkout, and the same plan always gives the same commit.
    folder = 'mods/' + plan['id']
    rows = {}
    if plan.get('update'):
        for file, row in tree(parent + ':' + folder).items():
            if not file.endswith(mod_types) and file != 'README.md':
                rows[file] = row  # an update without a new picture keeps the old one
    for file in plan['files']:
        rows[file] = ('100644', 'blob', git('hash-object', '-w', '--no-filters', '--', os.path.join(files, file)).strip())
    mods = tree(parent + ':mods')
    mods[plan['id']] = ('040000', 'tree', mktree(rows))
    root = tree(parent + '^{tree}')
    root['mods'] = ('040000', 'tree', mktree(mods))
    when = plan['created'] if when_shape.fullmatch(plan.get('created', '')) else '2026-01-01T00:00:00Z'
    env = dict(os.environ, GIT_AUTHOR_NAME=plan['login'], GIT_AUTHOR_DATE=when,
               GIT_AUTHOR_EMAIL='{}+{}@users.noreply.github.com'.format(plan['user_id'], plan['login']),
               GIT_COMMITTER_NAME=bot_name, GIT_COMMITTER_EMAIL=bot_email, GIT_COMMITTER_DATE=when)
    message = '{}, sent with the mod form in #{}'.format(title(plan), plan['issue'])
    return git('commit-tree', mktree(root), '-p', parent, '-m', message, env=env).strip()


def title(plan):
    login = plan['login'].lower()
    return '{}{} {} {}{}'.format(login, "'" if login.endswith('s') else "'s", plan['name'].lower(), plan['kind'],
                                 ', updated' if plan.get('update') else '')


def pr_body(plan, files):
    lines = ['Sent in by @{} with the Submit a mod form in #{}.'.format(plan['login'], plan['issue']), '',
             '- Kind: ' + plan['kind'], '- Made by: {}, their GitHub username'.format(plan['login']),
             '- ' + ('An update to their mod' if plan.get('update') else 'A new mod')]
    for file in plan['files']:
        with open(os.path.join(files, file), 'rb') as read:
            data = read.read()
        lines.append('- `mods/{}/{}`: {}, sha256 `{}`'.format(plan['id'], file, size_words(len(data)), hashlib.sha256(data).hexdigest()))
    lines += ['', 'Read every file before merging, like any mod. Editing #{} updates this pull request, and '
              '`tools/make-index.py` runs after merging as usual.'.format(plan['issue']), '']
    if plan.get('checks'):
        lines += [plan['checks'], '']
    return '\n'.join(lines + ['Closes #{}'.format(plan['issue'])]) + '\n'


def load_plan(out, ok):
    # The check job handled the untrusted bytes, so its plan is checked again before anything is written.
    with open(os.path.join(out, 'plan.json'), encoding='utf-8') as read:
        plan = json.load(read)
    good = (plan.get('ok') is ok and isinstance(plan.get('issue'), int) and plan['issue'] > 0
            and login_shape.fullmatch(str(plan.get('login'))) and isinstance(plan.get('user_id'), int))
    if good and ok:
        mod_id = str(plan.get('id'))
        allowed = {mod_id + str(plan.get('ext')), 'README.md', 'preview.png'}
        files = plan.get('files') or []
        good = (slug.fullmatch(mod_id) and mod_id not in reserved and plan.get('ext') in mod_types
                and plan.get('kind') in kind_words and name_shape.fullmatch(str(plan.get('name')))
                and isinstance(files, list) and set(files) <= allowed and {mod_id + plan['ext'], 'README.md'} <= set(files))
        for file in files if good else []:
            info = os.lstat(os.path.join(out, 'files', file))
            good = good and stat.S_ISREG(info.st_mode) and info.st_size <= (preview_cap if file == 'preview.png' else 96 * mb)
    if not good:
        raise SystemExit("The check job's plan doesn't look right, so nothing was changed.")
    return plan


def say(github, plan, text, dry, out):
    # One comment from the workflow, edited in place, so the issue always shows where things stand.
    body = marker + '\n' + text
    if dry:
        with open(os.path.join(out, 'dry-run', 'comment.md'), 'w', encoding='utf-8', newline='\n') as write:
            write.write(body)
        return
    issue = str(plan['issue'])
    mine = [c for c in github.call('GET', '/issues/' + issue + '/comments?per_page=100')
            if c['user']['login'] == bot_name and c['body'].startswith(marker)]
    if mine:
        github.call('PATCH', '/issues/comments/' + str(mine[0]['id']), {'body': body})
    else:
        github.call('POST', '/issues/' + issue + '/comments', {'body': body})


def find_pull(github, plan):
    head = github.repo.split('/')[0] + ':submit/' + str(plan['issue'])
    pulls = github.call('GET', '/pulls?state=all&head=' + urllib.parse.quote(head))
    return pulls[0] if pulls else None


def check(out, dry):
    event = read_event()
    issue = event['issue']
    user = issue.get('user') or {}
    if user.get('type') == 'Bot' or (event.get('sender') or {}).get('type') == 'Bot':
        log('Skipped: sent by a bot.')
        output('ok', 'skip')
        return 0
    plan = {'ok': False, 'issue': int(issue['number']), 'login': str(user.get('login', '')),
            'user_id': int(user.get('id') or 0), 'created': str(issue.get('created_at') or ''), 'problems': []}
    os.makedirs(os.path.join(out, 'files'))
    try:
        if not login_shape.fullmatch(plan['login']) or plan['user_id'] <= 0:
            raise ValueError('odd user')
        gather(issue, plan, out)
    except Exception as error:
        plan['problems'] = ['Something went wrong reading this, so Lachy will take a look.']
        plan['broken'] = True
        log('Check failed: ' + type(error).__name__)
    plan['ok'] = not plan['problems']
    with open(os.path.join(out, 'plan.json'), 'w', encoding='utf-8', newline='\n') as write:
        json.dump(plan, write, indent=2)
    log('Issue {}: {}'.format(plan['issue'], 'ready for a pull request' if plan['ok'] else
                              '{} things to fix'.format(len(plan['problems']))))
    output('ok', 'true' if plan['ok'] else 'false')
    return 0


def open_pr(out, dry):
    plan = load_plan(out, True)
    files = os.path.join(out, 'files')
    branch = 'submit/' + str(plan['issue'])
    commit = build_commit(plan, files, git('rev-parse', 'HEAD').strip())
    body = pr_body(plan, files)
    if dry:
        folder = os.path.join(here, 'mods', plan['id'])
        os.makedirs(folder, exist_ok=True)
        for file in os.listdir(folder):
            if file.endswith(mod_types) or file == 'README.md':
                os.remove(os.path.join(folder, file))
        for file in plan['files']:
            with open(os.path.join(files, file), 'rb') as read, open(os.path.join(folder, file), 'wb') as write:
                write.write(read.read())
        os.makedirs(os.path.join(out, 'dry-run'), exist_ok=True)
        for file, text in (('pr-title.txt', title(plan) + '\n'), ('pr-body.md', body), ('commit.txt', commit + '\n')):
            with open(os.path.join(out, 'dry-run', file), 'w', encoding='utf-8', newline='\n') as write:
                write.write(text)
        say(None, plan, opened_words(plan, 'NUMBER'), True, out)
        log('Dry run: wrote mods/{} and the pull request text.'.format(plan['id']))
        return 0

    github = GitHub()
    try:
        pull = find_pull(github, plan)
        if pull and pull['state'] != 'open':
            if pull.get('merged_at'):
                text = ('Your mod is in! Pull request #{} was merged. To send an update, fill in the form again with '
                        'the same id.'.format(pull['number']))
            else:
                text = ("Pull request #{} is closed, so edits here don't change it any more. To send a new version, "
                        'fill in the form again.'.format(pull['number']))
            say(github, plan, text, False, out)
            return 0
        current = git('ls-remote', 'origin', 'refs/heads/' + branch).split('\t')[0].strip() or None
        if current and current != commit:
            # A force push here would undo anything Lachy changed on the branch himself.
            last = github.call('GET', '/commits/' + current)
            if last['commit']['committer']['email'] != bot_email:
                say(github, plan, "This pull request's branch was changed by hand, so edits here don't update it any "
                    'more. Ask in the pull request instead.', False, out)
                return 0
        if current != commit:
            git('push', '--quiet', '--force-with-lease=refs/heads/{}:{}'.format(branch, current or ''), 'origin',
                commit + ':refs/heads/' + branch)
            log('Pushed {} to {}.'.format(commit, branch))
        if pull:
            github.call('PATCH', '/pulls/' + str(pull['number']), {'title': title(plan), 'body': body})
        else:
            base = read_event()['repository']['default_branch']
            pull = github.call('POST', '/pulls', {'title': title(plan), 'head': branch, 'base': base, 'body': body})
        say(github, plan, opened_words(plan, pull['number']), False, out)
        log('Pull request #{} is up to date.'.format(pull['number']))
    except Exception as error:
        log('Opening the pull request failed: ' + type(error).__name__)
        try:
            say(github, plan, "Your mod passed its checks, but the pull request couldn't be opened, so Lachy will "
                'take a look.', False, out)
        except Exception:
            pass
        return 1
    return 0


def opened_words(plan, number):
    text = ("Thanks! Your mod is in pull request #{0}. Lachy reads every mod before it goes up, and it shows in Capri's "
            'mods window once he merges it.\n\nTo change anything, edit this issue, like dragging in a new file, and '
            'the pull request follows.'.format(number))
    if plan.get('to_fix'):
        text += ('\n\nThe automatic checks found {} {} to fix, listed in #{}. Fix your file, then drag the new one in '
                 'here.'.format(plan['to_fix'], 'thing' if plan['to_fix'] == 1 else 'things', number))
    return text


def explain(out, dry):
    plan = load_plan(out, False)
    problems = plan.get('problems') or ['Something went wrong reading this, so Lachy will take a look.']
    text = "Thanks! This can't become a pull request yet:\n\n" + '\n'.join('- ' + p for p in problems)
    text += '\n\nEdit this issue to fix ' + ('it' if len(problems) == 1 else 'them') + ', and it gets checked again.'
    github = None if dry else GitHub()
    if dry:
        os.makedirs(os.path.join(out, 'dry-run'), exist_ok=True)
    else:
        pull = find_pull(github, plan)
        if pull and pull['state'] == 'open':
            text += ' Until then, pull request #{} keeps the last version that worked.'.format(pull['number'])
    say(github, plan, text, dry, out)
    log('Commented on issue {}.'.format(plan['issue']))
    return 1 if plan.get('broken') else 0


def main(argv):
    dry = '--dry-run' in argv
    args = [arg for arg in argv if arg != '--dry-run']
    steps = {'check': check, 'open-pr': open_pr, 'explain': explain}
    if len(args) != 2 or args[0] not in steps:
        raise SystemExit('usage: submit-mod.py check|open-pr|explain OUT [--dry-run]')
    return steps[args[0]](args[1], dry)


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
