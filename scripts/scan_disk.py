"""
UNIVERSAL DISK SCANNER
======================
Usage:
  python scan_disk.py E:\
  python scan_disk.py E:\ -f -o report.txt
  python scan_disk.py E:\ -f -m 100
  python scan_disk.py E:\ -d 3
"""

import os
import sys
import argparse
import time
from collections import defaultdict
from datetime import datetime

CATEGORIES = {
    "Video": {".mp4",".mkv",".avi",".mov",".wmv",".flv",".webm",".m4v",".mpg",".mpeg",".ts",".vob",".3gp"},
    "Audio": {".mp3",".flac",".wav",".aac",".ogg",".wma",".m4a",".opus",".alac",".aiff"},
    "Images": {".jpg",".jpeg",".png",".gif",".bmp",".svg",".webp",".ico",".tiff",".tif",".raw",".psd",".heic"},
    "Documents": {".pdf",".doc",".docx",".xls",".xlsx",".ppt",".pptx",".odt",".ods",".odp",".rtf",".epub",".djvu"},
    "Text": {".txt",".md",".csv",".tsv",".log",".ini",".cfg",".conf",".yml",".yaml",".toml"},
    "Code": {".py",".js",".ts",".html",".css",".java",".c",".cpp",".h",".cs",".go",".rs",".rb",".php",".sh",".bat",".ps1",".sql",".r",".swift",".kt",".lua",".json",".xml"},
    "Archives": {".zip",".rar",".7z",".tar",".gz",".bz2",".xz",".iso",".dmg",".cab"},
    "Executables": {".exe",".msi",".dll",".so",".app",".deb",".rpm",".apk"},
    "Fonts": {".ttf",".otf",".woff",".woff2",".eot"},
    "Subtitles": {".srt",".ass",".ssa",".vtt",".sub",".idx"},
    "Databases": {".db",".sqlite",".sqlite3",".mdb",".accdb"},
    "Torrents": {".torrent"},
}

SKIP_DIRS = {"$RECYCLE.BIN","System Volume Information","$WinREAgent","node_modules","__pycache__",".git",".vscode",".idea"}

def get_cat(ext):
    ext = ext.lower()
    for cat, exts in CATEGORIES.items():
        if ext in exts:
            return cat
    return "Other"

def fmt_sz(b):
    if b < 1024: return str(b) + " B"
    if b < 1024**2: return "{:.1f} KB".format(b/1024)
    if b < 1024**3: return "{:.1f} MB".format(b/1024**2)
    return "{:.2f} GB".format(b/1024**3)

def fmt_dt(ts):
    try: return datetime.fromtimestamp(ts).strftime("%Y-%m-%d %H:%M")
    except: return "?"

def scan(root, max_depth=None):
    tree = {}
    all_files = []
    errors = []

    for dirpath, dirnames, filenames in os.walk(root):
        rel = os.path.relpath(dirpath, root)
        depth = 0 if rel == "." else rel.count(os.sep) + 1

        if max_depth is not None and depth > max_depth:
            dirnames.clear()
            continue

        dirnames[:] = [d for d in dirnames if not d.startswith(".") and d not in SKIP_DIRS]
        dirnames.sort()

        folder_size = 0
        folder_files = []

        for fname in filenames:
            fpath = os.path.join(dirpath, fname)
            try:
                st = os.stat(fpath)
                sz = st.st_size
                mt = st.st_mtime
            except (OSError, PermissionError):
                errors.append(fpath)
                continue

            ext = os.path.splitext(fname)[1]
            info = {
                "name": fname,
                "rel": os.path.relpath(fpath, root),
                "size": sz,
                "ext": ext.lower(),
                "cat": get_cat(ext),
                "mod": mt,
            }
            folder_files.append(info)
            all_files.append(info)
            folder_size += sz

        tree[rel] = {
            "depth": depth,
            "own_size": folder_size,
            "own_count": len(folder_files),
            "files": folder_files,
        }

    for key in sorted(tree, key=lambda x: x.count(os.sep), reverse=True):
        ts = tree[key]["own_size"]
        tc = tree[key]["own_count"]
        pfx = key + os.sep if key != "." else ""
        for ok in tree:
            if ok != key and ok.startswith(pfx):
                ts += tree[ok]["own_size"]
                tc += tree[ok]["own_count"]
        tree[key]["total_size"] = ts
        tree[key]["total_count"] = tc

    return tree, all_files, errors

def make_report(root, tree, files, errors, show_files=False, min_mb=0, top_n=50):
    L = []
    w = L.append
    total_sz = sum(f["size"] for f in files)

    w("=" * 80)
    w("DISK SCAN REPORT")
    w("Path: " + root)
    w("Date: " + datetime.now().strftime("%Y-%m-%d %H:%M"))
    w("Total files: " + str(len(files)))
    w("Total size: " + fmt_sz(total_sz))
    w("=" * 80)

    # disk space
    try:
        import shutil
        dt, du, df = shutil.disk_usage(root)
        pct_used = du * 100 / dt
        pct_free = df * 100 / dt
        w("")
        w("DISK: {} total, {} used ({:.1f}%), {} free ({:.1f}%)".format(
            fmt_sz(dt), fmt_sz(du), pct_used, fmt_sz(df), pct_free))
    except:
        dt, du, df = 0, 0, 0

    # folder tree
    w("")
    w("=" * 80)
    w("FOLDER TREE")
    w("=" * 80)
    w("")

    children = defaultdict(list)
    for k, v in tree.items():
        if k == ".":
            continue
        parent = os.path.dirname(k) if os.sep in k else "."
        children[parent].append((k, v))

    for p in children:
        children[p].sort(key=lambda x: -x[1]["total_size"])

    rt = tree.get(".", {})
    w("{root}  [{sz}, {cnt} files]".format(
        root=root, sz=fmt_sz(rt.get("total_size", 0)), cnt=rt.get("total_count", 0)))

    if show_files and rt.get("files"):
        for fi in sorted(rt["files"], key=lambda x: -x["size"]):
            if fi["size"] < min_mb * 1024 ** 2:
                continue
            w("  {name}  [{sz}] [{cat}] [{mod}]".format(
                name=fi["name"], sz=fmt_sz(fi["size"]), cat=fi["cat"], mod=fmt_dt(fi["mod"])))

    def print_tree(parent, indent=1):
        for k, v in children.get(parent, []):
            if v["total_size"] < 1024 * 1024:
                continue
            pfx = "  " * indent + "| "
            name = os.path.basename(k)
            w("{pfx}{name}/  [{sz}, {cnt} files]".format(
                pfx=pfx, name=name, sz=fmt_sz(v["total_size"]), cnt=v["total_count"]))
            if show_files and v["files"]:
                for fi in sorted(v["files"], key=lambda x: -x["size"]):
                    if fi["size"] < min_mb * 1024 ** 2:
                        continue
                    fpfx = "  " * (indent + 1) + "  "
                    w("{fpfx}{name}  [{sz}] [{cat}] [{mod}]".format(
                        fpfx=fpfx, name=fi["name"], sz=fmt_sz(fi["size"]),
                        cat=fi["cat"], mod=fmt_dt(fi["mod"])))
            print_tree(k, indent + 1)

    print_tree(".")

    # by category
    w("")
    w("=" * 80)
    w("FILES BY CATEGORY")
    w("=" * 80)
    w("")

    cats = defaultdict(lambda: {"count": 0, "size": 0})
    for f in files:
        cats[f["cat"]]["count"] += 1
        cats[f["cat"]]["size"] += f["size"]

    sc = sorted(cats.items(), key=lambda x: -x[1]["size"])
    w("  {:<20} {:>8} {:>14} {:>7}".format("Category", "Count", "Size", "%"))
    w("  {} {} {} {}".format("-" * 20, "-" * 8, "-" * 14, "-" * 7))
    for cat, st in sc:
        pct = st["size"] * 100 / total_sz if total_sz else 0
        w("  {:<20} {:>8} {:>14} {:>6.1f}%".format(cat, st["count"], fmt_sz(st["size"]), pct))
    w("  {} {} {} {}".format("-" * 20, "-" * 8, "-" * 14, "-" * 7))
    w("  {:<20} {:>8} {:>14} {:>7}".format("TOTAL", len(files), fmt_sz(total_sz), "100.0%"))

    # by extension
    w("")
    w("=" * 80)
    w("FILES BY EXTENSION (top 30)")
    w("=" * 80)
    w("")

    exts = defaultdict(lambda: {"count": 0, "size": 0})
    for f in files:
        e = f["ext"] if f["ext"] else "(none)"
        exts[e]["count"] += 1
        exts[e]["size"] += f["size"]

    se = sorted(exts.items(), key=lambda x: -x[1]["size"])[:30]
    w("  {:<12} {:>8} {:>14} {:>7}".format("Ext", "Count", "Size", "%"))
    w("  {} {} {} {}".format("-" * 12, "-" * 8, "-" * 14, "-" * 7))
    for ext, st in se:
        pct = st["size"] * 100 / total_sz if total_sz else 0
        w("  {:<12} {:>8} {:>14} {:>6.1f}%".format(ext, st["count"], fmt_sz(st["size"]), pct))

    # top largest files
    w("")
    w("=" * 80)
    w("TOP {} LARGEST FILES".format(top_n))
    w("=" * 80)
    w("")

    sf = sorted(files, key=lambda x: -x["size"])[:top_n]
    w("  {:>12}  {:<12} {:<18} {}".format("Size", "Cat", "Modified", "Path"))
    w("  {}  {} {} {}".format("-" * 12, "-" * 12, "-" * 18, "-" * 40))
    for f in sf:
        w("  {:>12}  {:<12} {:<18} {}".format(
            fmt_sz(f["size"]), f["cat"], fmt_dt(f["mod"]), f["rel"]))

    # top largest folders
    w("")
    w("=" * 80)
    w("TOP {} LARGEST FOLDERS".format(top_n))
    w("=" * 80)
    w("")

    sfd = sorted(tree.items(), key=lambda x: -x[1]["total_size"])[:top_n]
    w("  {:>12}  {:>6}  {}".format("Size", "Files", "Path"))
    w("  {}  {}  {}".format("-" * 12, "-" * 6, "-" * 50))
    for k, v in sfd:
        p = k if k != "." else "(root)"
        w("  {:>12}  {:>6}  {}".format(fmt_sz(v["total_size"]), v["total_count"], p))

    # duplicates
    w("")
    w("=" * 80)
    w("POTENTIAL DUPLICATES (same name, >1 MB)")
    w("=" * 80)
    w("")

    nm = defaultdict(list)
    for f in files:
        if f["size"] > 1024 ** 2:
            nm[f["name"].lower()].append(f)

    dc = 0
    for name, fl in sorted(nm.items(), key=lambda x: -x[1][0]["size"]):
        if len(fl) > 1:
            dc += 1
            ts = sum(f["size"] for f in fl)
            w("  {} ({} copies, {} total)".format(name, len(fl), fmt_sz(ts)))
            for f in fl:
                w("    {:>12}  {}".format(fmt_sz(f["size"]), f["rel"]))
            w("")
    if not dc:
        w("  None found.")

    # recent files
    w("")
    w("=" * 80)
    w("RECENTLY MODIFIED (last 30 days, top 30)")
    w("=" * 80)
    w("")

    cutoff = time.time() - 30 * 86400
    recent = sorted([f for f in files if f["mod"] > cutoff], key=lambda f: -f["mod"])[:30]
    if recent:
        for f in recent:
            w("  {}  {:>12}  {}".format(fmt_dt(f["mod"]), fmt_sz(f["size"]), f["rel"]))
    else:
        w("  None.")

    # empty folders
    w("")
    w("=" * 80)
    w("EMPTY FOLDERS")
    w("=" * 80)
    w("")

    empties = [k for k, v in tree.items() if v["total_count"] == 0 and k != "."]
    if empties:
        for e in sorted(empties):
            w("  " + e)
    else:
        w("  None.")

    # errors
    if errors:
        w("")
        w("=" * 80)
        w("ACCESS ERRORS ({})".format(len(errors)))
        w("=" * 80)
        for e in errors[:20]:
            w("  " + e)
        if len(errors) > 20:
            w("  ... and {} more".format(len(errors) - 20))

    # AI summary
    w("")
    w("=" * 80)
    w("AI-READY SUMMARY")
    w("=" * 80)
    w("")
    w("path: " + root)
    w("scan_date: " + datetime.now().isoformat())
    w("total_folders: " + str(len(tree)))
    w("total_files: " + str(len(files)))
    w("total_size_bytes: " + str(total_sz))
    w("total_size_human: " + fmt_sz(total_sz))
    try:
        import shutil
        dt2, du2, df2 = shutil.disk_usage(root)
        w("disk_total_bytes: " + str(dt2))
        w("disk_free_bytes: " + str(df2))
        w("disk_free_human: " + fmt_sz(df2))
    except:
        pass

    cat_parts = []
    for c, s in sc:
        cat_parts.append("{}: {}".format(c, s["count"]))
    w("categories: {" + ", ".join(cat_parts) + "}")

    ext_parts = []
    for e, s in se[:10]:
        ext_parts.append("{}: {}".format(e, s["count"]))
    w("top_extensions: {" + ", ".join(ext_parts) + "}")

    w("duplicates_found: " + str(dc))
    w("access_errors: " + str(len(errors)))
    w("empty_folders: " + str(len(empties)))

    return "\n".join(L)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Universal disk scanner")
    parser.add_argument("path", help="Path to scan")
    parser.add_argument("-o", "--output", help="Save to file")
    parser.add_argument("-d", "--max-depth", type=int, default=None, help="Max depth")
    parser.add_argument("-f", "--show-files", action="store_true", help="Show files in tree")
    parser.add_argument("-m", "--min-size", type=float, default=0, help="Min file size MB (with -f)")
    parser.add_argument("-t", "--top", type=int, default=50, help="Top N items")

    args = parser.parse_args()
    root = args.path

    if not os.path.exists(root):
        print("  Error: " + root + " not found")
        sys.exit(1)

    print("")
    print("  Scanning " + root + " ...")
    t0 = time.time()

    tree, files, errs = scan(root, args.max_depth)
    elapsed = time.time() - t0

    out = make_report(root, tree, files, errs,
                      show_files=args.show_files,
                      min_mb=args.min_size,
                      top_n=args.top)

    out += "\n\nScan completed in {:.1f}s\n".format(elapsed)

    if args.output:
        with open(args.output, "w", encoding="utf-8") as fh:
            fh.write(out)
        sz = os.path.getsize(args.output) / 1024
        print("  Saved to {} ({:.1f} KB)".format(args.output, sz))
    else:
        print(out)

    if not args.output:
        input("\n  Press Enter to close...")
