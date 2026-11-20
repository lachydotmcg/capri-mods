"""Checks mods/<folder>/ against the safety rules Capri enforces, so nothing that trips a hard rule gets listed.

    python3 tools/check-mods.py [--all | --changed BASE_SHA | folder ...]
    python3 tools/check-mods.py PARENT COMMIT

The last form reads the mods changed between two git revisions straight from git, without a checkout.

Prints a Markdown report (also appended to $GITHUB_STEP_SUMMARY when set). Exits 1 if any hard failure, else 0.
"""
import io, json, os, posixpath, re, subprocess, sys, zipfile

here = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
root = os.path.join(here, 'mods')
kinds = ('.capri-mod', '.capri-code', '.capri-skin', '.capri-skill', '.capri-plugin', '.capri-companion')
mb = 1024 * 1024

packs = re.compile(r"FromBase64String|Aes\.|AesManaged|Rijndael|TripleDES|DESCryptoServiceProvider|GZipStream|DeflateStream|BrotliStream")
loads = re.compile(r"Assembly\.Load|AssemblyLoadContext|AppDomain\.CreateDomain|ExecuteAssembly|CreateInstanceAndUnwrap|Reflection\.Emit|DynamicMethod|CompileAssembly|CodeDomProvider|CSharpCodeProvider|CSharpCompilation")

secret = re.compile(r"sk-(?:ant|proj|or-v1|svcacct|admin)-[A-Za-z0-9_-]{16,}|\bgh[pousr]_[A-Za-z0-9]{20,}|\bgithub_pat_[A-Za-z0-9_]{20,}|\bxox[abprse]-[A-Za-z0-9-]{10,}|\bAKIA[0-9A-Z]{16}\b|\bAIza[0-9A-Za-z_-]{30,}|\bglpat-[A-Za-z0-9_-]{16,}|\bhf_[A-Za-z0-9]{20,}\b|\bnpm_[A-Za-z0-9]{20,}\b|\bnvapi-[A-Za-z0-9_-]{16,}|\bgsk_[A-Za-z0-9]{16,}|\bxai-[A-Za-z0-9]{16,}")

fetches = re.compile(r"\b(?:curl|wget|iwr|irm|invoke-webrequest|invoke-restmethod|bitsadmin|start-bitstransfer|certutil|downloadstring|downloadfile|downloaddata|urlopen|urlretrieve)\b|\bnet\.webclient\b|\burllib\.request\b|\brequests\.get\b|\bfetch\s*\(|\bhttps?\.get\s*\(", re.I)
runs = re.compile(r"\|\s*(?:sudo\s+)?(?:sh|bash|zsh|dash|ksh|fish|python[0-9.]*|py|node|perl|ruby|php|iex|pwsh|powershell)\b|\b(?:iex|invoke-expression)\b|\beval\b|\bexec\s*\(|<\(\s*(?:curl|wget)\b|\bchmod\s+[+0-7ugoa]*x\b|\bstart-process\b|&&\s*\.{0,2}[\\/]", re.I)
unpacks = re.compile(r"\bb64decode\b|\bfrombase64string\b|\bbase64\s+(?:-d|--decode)\b|\batob\s*\(|['\"]base64['\"]\s*\)", re.I)
shell_name = re.compile(r"powershell|pwsh", re.I)
runner_name = re.compile(r"^(npx|bunx|pnpx|uvx)(\.cmd|\.exe)?$", re.I)
version_tail = re.compile(r"^\d+(\.\d+)*([-+][0-9A-Za-z.-]+)?$")
secret_env_name = re.compile(r"(?:^|_)(?:API_?KEYS?|KEYS?|TOKENS?|SECRETS?|PASSWORDS?|PASSWD|PASS|PAT|CREDENTIALS?|COOKIES?)(?:_|$)", re.I)
env_use = re.compile(r"\$\{([A-Za-z_][A-Za-z0-9_]*)\}")

capri_folder = re.compile(r"(?:AppData|Application Support|\.config)[\\/]+(?:(?:Local|Roaming)[\\/]+)?Capri\b|(?:LOCALAPPDATA|ApplicationData|APPDATA)[^\r\n]{0,40}?[\"'\\/]Capri\b|\bCapriAI_[A-Za-z0-9]+", re.I)
capri_folder_words = "reaches into Capri's own settings folder, where her keys are saved"

code_warnings = (
    ("loads code while it runs", loads),
    ("unpacks hidden text", packs),
    ("unlocks saved secrets", re.compile(r"ProtectedData|CryptUnprotectData|\.dpapi\b")),
    ("calls Windows directly", re.compile(r"DllImport|LibraryImport|Marshal\.|GetProcAddress|VirtualAlloc")),
    ("starts programs", re.compile(r"Process\.Start|ProcessStartInfo|cmd\.exe|powershell")),
    ("uses the network", re.compile(r"HttpClient|WebClient|WebRequest|TcpClient|UdpClient|Socket\(|ClientWebSocket")),
    ("reaches outside her folder", re.compile(r"SpecialFolder|Registry|DriveInfo|GetTempPath|GetEnvironmentVariable")),
    ("reads the keyboard", re.compile(r"GetAsyncKeyState|SetWindowsHookEx|keybd_event|SendKeys")),
    ("changes what her brain is told", re.compile(r"ICapriBrain|ICapriChat|AddContext|AddTool|\.Sending\b|\.Replying\b|ToolUsing|Personality\.(?:Add|Remove|Clear)\b|(?i:system prompt)")),
)

url = re.compile(r"\b(?:https?|wss?|ftp)://([^\s/\\?#\"'<>]+)", re.I)
skipped_hosts = ('localhost', '0.0.0.0', 'schemas.microsoft.com', 'www.w3.org', 'schemas.openxmlformats.org')
base64_run = re.compile(r"[A-Za-z0-9+/=]{800,}")


class Result:
    def __init__(self, folder):
        self.folder = folder
        self.fails = []
        self.warns = []

    def fail(self, rule, why):
        self.fails.append((rule, why))

    def warn(self, text):
        if text not in self.warns:
            self.warns.append(text)


def text_of(data):
    return data.decode('utf-8', 'replace')


def host_list(text):
    found = []
    for match in url.finditer(text):
        host = match.group(1).rsplit('@', 1)[-1]
        host = re.sub(r":\d*$", "", host).lower()
        if host and host not in found and not host.startswith('127.') and host not in skipped_hosts:
            found.append(host)
    return found


def unreadable(text):
    lines = text.splitlines()
    longest = max((len(line) for line in lines), default=0)
    if base64_run.search(text) or longest > 600:
        return True
    if len(text) > 4000:
        return len(lines) <= 1 or longest * 10 >= len(text) * 9 or text.count(' ') * 20 < len(text)
    return False


def check_secrets(result, name, data):
    if secret.search(data.decode('latin-1')):
        result.fail("a key is written into the mod", "secret-shaped text in `" + name + "`")


def check_settings_folder(result, text):
    if capri_folder.search(text):
        result.warn(capri_folder_words)


def check_code(result, name, data):
    if len(data) > mb:
        result.fail("code mod too big", "`" + name + "` is " + str(len(data)) + " bytes, over 1 MB")
    text = text_of(data)
    has_packs, has_loads = packs.search(text), loads.search(text)
    if has_packs and has_loads:
        result.fail("the code you can read isn't the code that would run", "`" + name + "` unpacks text and also loads code")
    for label, pattern in code_warnings:
        if pattern.search(text):
            result.warn(label)
    check_settings_folder(result, text)
    hosts = host_list(text)
    if hosts:
        result.warn("contacts " + ", ".join(hosts))
    if unreadable(text):
        result.warn("code that is hard to read")


def zip_problem(zf, size):
    infos = zf.infolist()
    if size > mb:
        return "zip is over 1 MB"
    if len(infos) > 400:
        return "more than 400 entries"
    if sum(i.file_size for i in infos) > 8 * mb:
        return "unpacks to over 8 MB"
    for i in infos:
        if i.file_size > 4 * mb:
            return "`" + i.filename + "` is over 4 MB"
        parts = i.filename.replace('\\', '/').split('/')
        if i.filename.startswith('/') or ':' in i.filename or '..' in parts:
            return "unsafe entry name `" + i.filename + "`"
    return None


def pinned(runner, package):
    if runner.lower().startswith('uvx'):
        return re.search(r"==\d", package) is not None
    at = package.rfind('@')
    return at > 0 and version_tail.match(package[at + 1:]) is not None


def package_of(args):
    for i, arg in enumerate(args):
        if arg in ('--from', '-p', '--package') and i + 1 < len(args):
            return args[i + 1]
        for flag in ('--from=', '--package='):
            if arg.startswith(flag):
                return arg[len(flag):]
    for arg in args:
        if not arg.startswith('-'):
            return arg
    return None


def encoded_powershell(command, line, args):
    if not (re.match(r"^(powershell|pwsh)(\.exe)?$", posixpath.basename(command.replace('\\', '/')), re.I) or shell_name.search(line)):
        return False
    for arg in args:
        arg = arg.lower()
        if len(arg) < 2 or arg[0] not in '-/':
            continue
        word = arg.lstrip('-/')
        if word in ('e', 'ec') or (len(word) >= 2 and 'encodedcommand'.startswith(word)):
            return True
    return False


def check_server(result, name, server):
    if not isinstance(server, dict) or not isinstance(server.get('command'), str):
        return
    command = server['command']
    args = [a if isinstance(a, str) else str(a) for a in server.get('args') or [] if not isinstance(a, (dict, list))]
    line = command + " " + " ".join(args)
    where = "server `" + name + "`"
    if encoded_powershell(command, line, args):
        result.fail("encoded PowerShell", where + " starts PowerShell with an encoded command")
    if fetches.search(line) and runs.search(line):
        result.fail("downloads and runs", where + " downloads something and runs it")
    if unpacks.search(line) and runs.search(line):
        result.fail("unpacks and runs", where + " decodes something hidden and runs it")
    base = posixpath.basename(command.replace('\\', '/'))
    if runner_name.match(base):
        package = package_of(args)
        if package and not pinned(base, package):
            result.fail("unpinned package", where + " runs `" + package + "` without a pinned version, so what runs could change after review")
    values = [command] + args + [server.get('cwd')] + list((server.get('env') or {}).values() if isinstance(server.get('env'), dict) else [])
    for value in values:
        for var in env_use.findall(value if isinstance(value, str) else ''):
            if secret_env_name.search(var):
                result.warn("server `" + name + "` passes `${" + var + "}` from the environment")


def check_plugin(result, name, data):
    size = len(data)
    try:
        zf = zipfile.ZipFile(io.BytesIO(data))
    except zipfile.BadZipFile:
        result.fail("plug-in isn't a valid zip", "`" + name + "` can't be opened as a zip")
        return
    with zf:
        problem = zip_problem(zf, size)
        if problem:
            result.fail("plug-in zip limits", "`" + name + "`: " + problem)
            return
        servers = {}
        try:
            for info in zf.infolist():
                if info.is_dir():
                    continue
                data = zf.read(info)
                check_secrets(result, name + ":" + info.filename, data)
                if b'\0' not in data:
                    text = text_of(data)
                    check_settings_folder(result, text)
                    if info.filename.endswith(('.mcp.json', 'plugin.json')):
                        servers.update(read_servers(info.filename, text))
        except (zipfile.BadZipFile, RuntimeError, NotImplementedError, EOFError, OSError):
            result.fail("plug-in isn't a valid zip", "`" + name + "` has an unreadable entry")
            return
    for server_name, server in servers.items():
        check_server(result, server_name, server)


def read_servers(filename, text):
    try:
        data = json.loads(text)
    except ValueError:
        return {}
    if not isinstance(data, dict):
        return {}
    found = data.get('mcpServers')
    if found is None and filename.endswith('.mcp.json'):
        found = data
    return found if isinstance(found, dict) else {}


class DiskSource:
    def folders(self):
        return sorted(f for f in os.listdir(root) if os.path.isdir(os.path.join(root, f)))

    def exists(self, folder):
        return os.path.isdir(os.path.join(root, folder))

    def files(self, folder):
        path = os.path.join(root, folder)
        return sorted(f for f in os.listdir(path) if os.path.isfile(os.path.join(path, f)))

    def read(self, folder, file):
        with open(os.path.join(root, folder, file), 'rb') as f:
            return f.read()


class GitSource:
    def __init__(self, commit):
        self.commit = commit

    def git(self, *args):
        return subprocess.run(['git', '-C', here] + list(args), capture_output=True, check=True).stdout

    def exists(self, folder):
        return bool(self.git('ls-tree', self.commit, 'mods/' + folder).strip())

    def files(self, folder):
        out = self.git('ls-tree', '-z', self.commit, 'mods/' + folder + '/').decode('utf-8', 'replace')
        names = []
        for record in out.split('\0'):
            if record:
                meta, path = record.split('\t', 1)
                if meta.split()[1] == 'blob':
                    names.append(path.split('/', 2)[2])
        return sorted(names)

    def read(self, folder, file):
        return self.git('cat-file', 'blob', self.commit + ':mods/' + folder + '/' + file)

    def changed(self, base):
        out = self.git('diff', '--name-only', '--no-renames', '-z', base, self.commit, '--', 'mods/').decode('utf-8', 'replace')
        folders = {p.split('/')[1] for p in out.split('\0') if p.count('/') >= 2}
        return sorted(f for f in folders if self.exists(f))


def check_folder(folder, source=None):
    source = source or DiskSource()
    result = Result(folder)
    for file in source.files(folder):
        if file == 'preview.png':
            if len(source.read(folder, file)) > 2 * mb:
                result.fail("preview picture too big", "`preview.png` is over 2 MB")
            continue
        if not file.endswith(kinds):
            continue
        data = source.read(folder, file)
        if file.endswith('.capri-code'):
            check_secrets(result, file, data)
            check_code(result, file, data)
        elif file.endswith('.capri-plugin'):
            check_plugin(result, file, data)
        elif file.endswith(('.capri-skin', '.capri-skill', '.capri-companion')) and zipfile.is_zipfile(io.BytesIO(data)):
            try:
                with zipfile.ZipFile(io.BytesIO(data)) as zf:
                    for info in zf.infolist():
                        if not info.is_dir() and info.file_size <= 8 * mb:
                            check_secrets(result, file + ":" + info.filename, zf.read(info))
            except (zipfile.BadZipFile, RuntimeError, NotImplementedError, EOFError, OSError):
                check_secrets(result, file, data)
        else:
            check_secrets(result, file, data)
            check_settings_folder(result, text_of(data))
    return result


def report(results):
    failing = [r for r in results if r.fails]
    warned = [r for r in results if r.warns and not r.fails]
    lines = ["## Mod checks", "", "Mod checks: " + str(len(failing)) + " to fix", "",
             "Checked " + str(len(results)) + " mod folder" + ("" if len(results) == 1 else "s") + ": "
             + str(len(failing)) + " with hard failures, " + str(sum(1 for r in results if r.warns)) + " with warnings.", ""]
    for r in results:
        if not r.fails and not r.warns:
            continue
        lines.append("### `" + r.folder + "`")
        for rule, why in r.fails:
            lines.append("- **FAIL** " + rule + ": " + why)
        for text in r.warns:
            lines.append("- warning: " + text)
        lines.append("")
    if not failing and not warned:
        lines.append("Nothing to flag.")
    return "\n".join(lines).rstrip() + "\n"


def main(argv):
    args = argv[1:]
    source = DiskSource()
    if args and args[0] == '--changed':
        if len(args) != 2:
            raise SystemExit("usage: check-mods.py [--all | --changed BASE_SHA | folder ...] | PARENT COMMIT")
        source = GitSource('HEAD')
        folders = source.changed(args[1])
    elif len(args) == 2 and not os.path.isdir(os.path.join(root, args[0])):
        source = GitSource(args[1])
        folders = source.changed(args[0])
    elif args == ['--all'] or not args:
        folders = source.folders()
    else:
        folders = [os.path.basename(a.rstrip('/\\')) for a in args]
        missing = [f for f in folders if not source.exists(f)]
        if missing:
            raise SystemExit("no such mod folder: " + ", ".join(missing))
    results = [check_folder(f, source) for f in folders]
    text = report(results)
    sys.stdout.write(text)
    summary = os.environ.get('GITHUB_STEP_SUMMARY')
    if summary:
        with open(summary, 'a', encoding='utf-8') as f:
            f.write(text)
    return 1 if any(r.fails for r in results) else 0


if __name__ == '__main__':
    sys.exit(main(sys.argv))
