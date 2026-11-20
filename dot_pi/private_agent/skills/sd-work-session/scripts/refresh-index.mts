// Run with Node 22.18+ (native TypeScript, no packages or compilation).
import * as fs from 'node:fs';
import * as path from 'node:path';

const nodes = {
  sessions: ['Time-bound session notes, drafts and evidence', 'session', 'sessions'],
  data: ['Reusable references and tool configuration', 'category', 'categories'],
  logs: ['Application and server logs by date and source', 'log collection', 'log collections'],
};

function workRoot(): string {
  const root = process.env.SD_WORK_DIR;
  if (!root) {
    const mise = (process.env.PATH ?? '').split(path.delimiter).some(dir => {
      try { fs.accessSync(path.join(dir, 'mise'), fs.constants.X_OK); return true; } catch { return false; }
    });
    throw Error('Please configure SD_WORK_DIR. ' + (mise
      ? 'Set SD_WORK_DIR = "/absolute/path/to/work-area" under [env] in mise.toml, then run mise exec -- pi.'
      : 'Run export SD_WORK_DIR="/absolute/path/to/work-area" before launching Pi.'));
  }
  if (!path.isAbsolute(root) || !fs.statSync(root, {throwIfNoEntry:false})?.isDirectory())
    throw Error('Please set SD_WORK_DIR to an existing absolute directory.');
  for (const name of Object.keys(nodes))
    if (!fs.lstatSync(path.join(root, name), {throwIfNoEntry:false})?.isDirectory())
      throw Error(`Missing or unsafe ${name}/; initialize the work area first.`);
  return fs.realpathSync(root);
}

type Entry = {name:string; file:string; kids?:Entry[]; count:number; size:number; newest:number};
const generated = (name:string) => name === 'README.md' || name === 'INDEX.md';
function scan(file:string): Entry {
  const name = path.basename(file);
  const stat = fs.lstatSync(file);
  if (!stat.isDirectory()) return {name, file, count:1, size:generated(name) ? 0 : stat.size,
    newest:generated(name) ? 0 : stat.mtimeMs};
  const kids = fs.readdirSync(file, {withFileTypes:true})
    .filter(x => x.name !== '.DS_Store' && (x.isDirectory() || x.isFile())) // no symlinks or devices
    .sort((a,b) => Number(b.isDirectory()) - Number(a.isDirectory()) || a.name.localeCompare(b.name, 'en'))
    .map(x => scan(path.join(file, x.name)));
  const entry = {name, file, kids, count:0, size:0, newest:0};
  for (const k of kids) { entry.count += k.count; entry.size += k.size; entry.newest = Math.max(entry.newest, k.newest); }
  return entry;
}
function human(n:number) {
  for (const unit of ['B','KB','MB','GB','TB']) {
    if (n < 1024 || unit === 'TB') return `${n.toFixed(unit === 'B' ? 0 : 1)} ${unit}`;
    n /= 1024;
  }
}
function date(ms:number) {
  const d = new Date(ms);
  return ms ? [d.getFullYear(), d.getMonth()+1, d.getDate()].map(x=>String(x).padStart(2,'0')).join('-') : '-';
}
function tree(folder:Entry, depth:number) {
  const label = (k:Entry) => k.kids ? `📁 ${k.name}/  (${k.count} file${k.count === 1 ? '' : 's'}, ${human(k.size)})`
    : `${k.name}${generated(k.name) ? '' : `  (${human(k.size)})`}`;
  const lines = ['```', label(folder)];
  function descend(e:Entry, prefix:string, left:number) {
    if (!left) return;
    e.kids?.forEach((k,i,all) => {
      const last = i === all.length-1;
      lines.push(prefix + (last ? '└── ' : '├── ') + label(k));
      descend(k, prefix + (last ? '    ' : '│   '), left-1);
    });
  }
  descend(folder, '', depth);
  return [...lines,'```'].join('\n');
}
const child = (e:Entry,n:string) => e.kids?.find(k=>k.name===n);
const dirs = (e:Entry) => e.kids?.filter(k=>k.kids) ?? [];
function description(e:Entry, topic:boolean) {
  const readme = child(e,'README.md');
  if (!readme || readme.kids || e.name === 'config') return '(no README)';
  const lines = fs.readFileSync(readme.file,'utf8').split(/\r?\n/);
  const h = lines.findIndex(l=>l.startsWith('# '));
  if (h < 0) return '(untitled)';
  return topic ? lines[h].slice(2).trim().replace(/^[^\p{L}\p{N}]+/u,'').replace(/^\d{4}-\d\d-\d\d\s*[:-]\s*/,'')
    : lines.slice(h+1).map(l=>l.trim()).find(l=>l && !/^(?:#|<!--|\||```|\[)/.test(l))?.replace(/^>\s*/,'') ?? '(no description)';
}
function table(header:string[], rows:(string|number)[][]) {
  if (!rows.length) return '_Nothing yet._';
  return [header,header.map(()=>'---'),...rows].map(row=>'| '+row.map(x=>String(x).replaceAll('|','\\|')).join(' | ')+' |').join('\n');
}
const link = (e:Entry) => `[\`${e.name}/\`](./${encodeURIComponent(e.name)}/)`;
function overview(root:Entry) {
  return table(['Node','What goes in','Items','Files','Size','Updated'],Object.entries(nodes).map(([name,[what,one,many]])=>{
    const n = child(root,name)!;
    const count = dirs(n).length;
    return [link(n),what,`${count} ${count===1 ? one : many}`,n.count,human(n.size)!,date(n.newest)];
  }));
}
function collection(e:Entry) {
  const kids = dirs(e);
  return e.name === 'sessions' ? table(['Date','Session','Topic','Files','Size'],kids.reverse().map(k=>
    [k.name.slice(0,10),link(k),description(k,true),k.count,human(k.size)!])) :
    table(['Category','What','Files','Size','Updated'],kids.map(k=>[link(k),description(k,false),k.count,human(k.size)!,date(k.newest)]));
}
function refresh() {
  const root = scan(workRoot());
  const changed:string[] = [];
  function update(target:Entry|undefined, blocks:Record<string,()=>string>) {
    if (!target || target.kids) return;
    const original = fs.readFileSync(target.file,'utf8');
    let next = original;
    for (const [kind,render] of Object.entries(blocks)) {
      const a = `<!-- ${kind}:start -->`, b = `<!-- ${kind}:end -->`;
      next = next.replace(new RegExp(`${a}[\\s\\S]*?${b}`),()=>`${a}\n${render()}\n${b}`);
    }
    if (next !== original) { fs.writeFileSync(target.file,next); changed.push(path.relative(root.file,target.file)); }
  }
  function visit(e:Entry) {
    const blocks:Record<string,()=>string> = {};
    if (e===root) blocks.index=()=>overview(root);
    else {
      if (e===child(root,'sessions') || e===child(root,'data')) blocks.index=()=>collection(e);
      blocks.tree=()=>tree(e,4);
    }
    update(child(e,'README.md'),blocks);
    dirs(e).filter(k=>k.name!=='config').forEach(visit);
  }
  visit(root);
  update(child(root,'INDEX.md'),{tree:()=>tree(root,Infinity)});
  console.log(changed.length ? `updated:\n  ${changed.join('\n  ')}` : 'already up to date');
}
try { refresh(); } catch (error) { console.error(error instanceof Error ? error.message : error); process.exitCode = 1; }
