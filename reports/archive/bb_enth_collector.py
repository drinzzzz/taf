#!/usr/bin/env python3
"""BookBaker ENTH Collector v5 — Jina Reader + DuckDuckGo search, two-pass deep discovery."""

import json, sys, time, re, argparse
from datetime import datetime, timezone
from hashlib import sha256
from urllib.parse import parse_qs, urlparse
import requests

# ── Config ──
HEADERS = {"User-Agent": "BookBaker/5.0 (research; drin@qq.com)"}
REQUEST_TIMEOUT = 30
JINA_DELAY = 2.0
MAX_RETRIES = 2

# ── Tier 1 Sources ──
TIER1_SOURCES = [
    {"title":"AAFP Cat Friendly Practice","url":"https://catvets.com/cat-friendly/cfp/","topics":["environment","stress reduction"],"org":"AAFP"},
    {"title":"AAFP/ISFM Vet Interaction Guidelines","url":"https://catvets.com/resource/aafp-isfm-cat-friendly-veterinary-interaction-guidelines/","topics":["handling","stress reduction"],"org":"AAFP/ISFM"},
    {"title":"AAFP Practice Guidelines","url":"https://catvets.com/clinical-resources/practice-guidelines/","topics":["guidelines","feline medicine"],"org":"AAFP"},
    {"title":"AAFP Educational Toolkits","url":"https://catvets.com/clinical-resources/educational-toolkits/","topics":["education","cat care"],"org":"AAFP"},
    {"title":"Intl Cat Care — Advice Portal (dir)","url":"https://icatcare.org/cat-advice","topics":["cat care","home environment"],"org":"Intl Cat Care"},
    {"title":"Intl Cat Care — Home Life","url":"https://icatcare.org/cat-advice/home-life","topics":["home environment","indoor cats"],"org":"Intl Cat Care"},
    {"title":"Intl Cat Care — All Articles","url":"https://icatcare.org/cat-advice/all-advice-articles-page","topics":["cat care","health"],"org":"Intl Cat Care"},
    {"title":"OSU — Cats Portal (dir)","url":"https://indoorpet.osu.edu/cats","topics":["cats","indoor","behavior"],"org":"Ohio State University"},
    {"title":"OSU — Basic Needs","url":"https://indoorpet.osu.edu/cats/basicneeds","topics":["basic needs","indoor"],"org":"Ohio State University"},
    {"title":"OSU — Feline Life Stressors","url":"https://indoorpet.osu.edu/cats/felinelifestressors","topics":["stress","behavior"],"org":"Ohio State University"},
    {"title":"OSU — Problem Solving","url":"https://indoorpet.osu.edu/cats/problemsolving","topics":["behavior problems","solutions"],"org":"Ohio State University"},
    {"title":"OSU — The Unique Feline","url":"https://indoorpet.osu.edu/cats/uniquefeline","topics":["feline nature","behavior"],"org":"Ohio State University"},
    {"title":"ASPCA Cat Grooming","url":"https://www.aspca.org/pet-care/cat-care/cat-grooming-tips","topics":["grooming","cat care"],"org":"ASPCA"},
    {"title":"ASPCA Cat Care","url":"https://www.aspca.org/pet-care/cat-care","topics":["care","behavior","safety"],"org":"ASPCA"},
    {"title":"IAABC Cat Behavior Checklist","url":"https://iaabc.org/en/behavior-checklist","topics":["behavior assessment"],"org":"IAABC"},
    {"title":"IAABC Cat Resources","url":"https://iaabc.org/en/resources","topics":["resources","behavior"],"org":"IAABC"},
    {"title":"AAHA Behavior Guidelines 2025","url":"https://www.aaha.org/resources/2025-aaha-behavior-management-guidelines/","topics":["behavior","stress management"],"org":"AAHA"},
    {"title":"WSAVA Global Guidelines","url":"https://wsava.org/global-guidelines/","topics":["wellness","guidelines"],"org":"WSAVA"},
]

# ── DDG Search Topics ──
SEARCH_TOPICS = [
    "AAFP feline environmental needs guidelines home design",
    "ISFM cat friendly home environment enrichment recommendations",
    "feline vertical space territory climbing behavior research 2024",
    "multi-cat household stress reduction environment design research",
    "cat dog cohabitation spatial design behavior research",
    "pet-friendly interior design evidence-based biophilic guidelines",
    "cat scratching behavior furniture design enrichment study",
    "cat hiding space security stress cortisol welfare research",
    "feline olfactory pheromone indoor environment Jacobson organ",
    "toxic plants cats comprehensive list ASPCA 2024 updated",
]

# ══════════════════════════════════════════════════
#  Jina / DDG tools
# ══════════════════════════════════════════════════

def jina_read(url):
    for attempt in range(MAX_RETRIES+1):
        try:
            r = requests.get(f"https://r.jina.ai/{requests.utils.quote(url,safe=':/')}", 
                           headers={**HEADERS,"Accept":"text/markdown","Authorization":f"Bearer {JINA_API_KEY}"}, timeout=REQUEST_TIMEOUT)
            if r.status_code==429: time.sleep((attempt+1)*5); continue
            r.raise_for_status(); return r.text
        except:
            if attempt<MAX_RETRIES: time.sleep(3); continue
            return ""
    return ""

def ddg_search(query, limit=5):
    """DuckDuckGo HTML search via Jina Reader"""
    try:
        ddg_url = f"https://html.duckduckgo.com/html/?q={requests.utils.quote(query)}"
        md = jina_read(ddg_url)
        if not md: return []
        results = []
        for m in re.finditer(r'\[([^\]]+)\]\(([^)]+)\)', md):
            text, url = m.group(1), m.group(2)
            if 'uddg=' in url:
                p = urlparse(url); qs = parse_qs(p.query)
                actual = qs.get('uddg', [url])[0]
                if actual.startswith('http'): url = actual
            if url.startswith('http') and len(text) > 30 and 'duckduckgo.com' not in url:
                results.append({"title": text[:80], "snippet": text[:300], "url": url})
        seen = set(); unique = []
        for r in results:
            if r["url"] not in seen: seen.add(r["url"]); unique.append(r)
        return unique[:limit]
    except Exception as e:
        print(f"  DDG search error: {e}", file=sys.stderr)
        return []

# ══════════════════════════════════════════════════
#  Content matching
# ══════════════════════════════════════════════════

CHAPTER_KEYWORDS = {
    1:["cat friendly","feline friendly","environmental needs","stress","压力","indoor cat","室内猫"],
    2:["behavior","feline behavior","territory","olfactory","pheromone","scratching","circadian","vertical space"],
    3:["interior design","design principle","空间设计","biophilic","spatial","pet furniture"],
    4:["single cat","core territory","核心区","resource","hiding","躲藏","隐蔽","security"],
    5:["room","balcony","kitchen","window","plant","toxic","安全","阳台","厨房","植物"],
    6:["multi-cat","conflict","social dynamic","群体","资源分区"],
    7:["cat dog","cohabitation","coexistence","interspecies","猫狗","犬"],
    8:["large home","complex","multi-level","大户型","多层"],
    9:["human-animal bond","共同友好","wellbeing","mental health","biophilic design","共生"],
}

def match_chapters(text):
    tl = text.lower(); scores = {}
    for ch,kws in CHAPTER_KEYWORDS.items():
        s = sum(1 for kw in kws if kw.lower() in tl)
        if s>0: scores[ch]=s
    return sorted(scores,key=lambda c:scores[c],reverse=True)[:2]

def extract_key_point(text, max_len=250):
    skip = [r'^\*\s*\[',r'^!\[',r'^Title:',r'^URL Source:',r'^Warning:',r'^Markdown Content:',
            r'^#',r'Skip to ',r'Find People',r'^Always on\.',r'^\d+\.\s']
    lines = [l.strip() for l in text.split("\n") if l.strip() and len(l.strip())>=50 
             and not any(re.match(p,l.strip()) for p in skip)]
    for l in lines:
        if 80<=len(l)<=max_len: return l
    for l in lines:
        if 50<=len(l)<=max_len: return l
    return lines[0][:max_len] if lines else text[:max_len]

def make_item(content, source, url, tags, chapters, org=""):
    return {"content":content,"source":source,"source_ref":url,"tags":tags,"chapters":chapters,
            "citation":f"{org or source}. ({datetime.now(timezone.utc).strftime('%Y, %B %d')}). Retrieved from {url}",
            "timestamp":datetime.now(timezone.utc).isoformat(),
            "hash":sha256((content[:200]+url).encode()).hexdigest()[:12]}

# ══════════════════════════════════════════════════
#  Two-pass discovery
# ══════════════════════════════════════════════════

def discover_deep_urls(md_text, base_domain, max_urls=6):
    urls = set()
    for m in re.finditer(r'\[([^\]]*)\]\s*\(\s*(https?://[^\s\)]+)\s*\)', md_text):
        urls.add((m.group(1).strip().lower(), m.group(2)))
    skip_domains = ["facebook.com","twitter.com","instagram.com","youtube.com","linkedin.com",
        "pinterest.com","t.co","bat.bing.com","google.com","analytics.","doubleclick.net",
        "fonts.googleapis","cdn.","secure.aspca.org/donate","shop.iaabc.org"]
    skip_paths = ["/login","/wp-login",".jpg",".png",".gif",".svg",".webp",".ico",
        ".css",".js",".pdf",".xml","/donate","/privacy","/terms","/contact"]
    valid = []
    for label,url in urls:
        if any(d in url for d in skip_domains): continue
        if base_domain not in url: continue
        if any(p in url.lower() for p in skip_paths): continue
        path = url.split(base_domain,1)[-1] if base_domain in url else url
        if len([s for s in path.strip("/").split("/") if s])<2: continue
        valid.append((label,url))
    seen = set(); unique = []
    for l,u in valid:
        if u not in seen: seen.add(u); unique.append((l,u))
    return unique[:max_urls]

# ══════════════════════════════════════════════════
#  Main
# ══════════════════════════════════════════════════

def run_collection(quick=False):
    start = time.time()
    all_results = []
    stats = {"sources":0,"pages":0,"deep":0,"searches":0,"hits":0}

    # Phase 1: Tier 1 + two-pass
    print(f"[Phase 1] {len(TIER1_SOURCES)} sources + two-pass...", file=sys.stderr)
    for src in TIER1_SOURCES:
        stats["sources"]+=1
        md = jina_read(src["url"]); stats["pages"]+=1
        if not md: continue

        link_count = len(re.findall(r'\[([^\]]+)\]\s*\(https?://', md))
        base_domain = src["url"].split("/")[2]

        if link_count > 50:
            deep = discover_deep_urls(md, base_domain, max_urls=6)
            if deep:
                print(f"  dir {src['title'][:35]}... -> {len(deep)} sub-pages", file=sys.stderr)
                found = 0
                for label, url in deep:
                    title = label.replace("-"," ").title()[:35] if label else url.split("/")[-2][:35]
                    art = jina_read(url); stats["deep"]+=1; stats["pages"]+=1
                    if art and len(art)>200:
                        ch = match_chapters(art)
                        if ch:
                            kp = extract_key_point(art)
                            all_results.append(make_item(kp,f"{src['org']}: {title}",url,["type:deep_article","tier:1",f"org:{src['org']}"],ch,src["org"]))
                            found+=1
                    time.sleep(JINA_DELAY)
                    if found>=4: break
                print(f"    = {found} matched", file=sys.stderr)
                continue

        chapters = match_chapters(md)
        if chapters:
            kp = extract_key_point(md)
            all_results.append(make_item(kp,src["title"],src["url"],["type:reference","tier:1",f"org:{src['org']}"],chapters,src["org"]))
        time.sleep(JINA_DELAY)

    # Phase 2: DDG Search
    if not quick:
        print(f"\n[Phase 2] DDG Search ({len(SEARCH_TOPICS)} topics)...", file=sys.stderr)
        for topic in SEARCH_TOPICS:
            print(f"  search {topic[:45]}...", file=sys.stderr, end="", flush=True)
            hits = jina_search(topic, limit=5)
            stats["searches"]+=1
            if hits:
                print(f" {len(hits)} hits", file=sys.stderr)
                for hit in hits:
                    ch = match_chapters(hit["snippet"])
                    if ch:
                        stats["hits"]+=1
                        all_results.append(make_item(hit["snippet"][:300],f"DDG: {hit['title'][:40]}",hit["url"],["type:jina_search","tier:2"],ch))
            else:
                print(" 0", file=sys.stderr)
            time.sleep(1.5)

    elapsed = int(time.time()-start)
    stats["total"]=len(all_results)
    print(f"\nDone: {stats['total']} results in {elapsed}s (src:{stats['sources']} pg:{stats['pages']} deep:{stats['deep']} search:{stats['searches']}/{stats['hits']})", file=sys.stderr)

    return {"metadata":{"collector":"bb_enth_collector v5","host":"ENTH (HK)","mode":"quick" if quick else "full",
            "timestamp":datetime.now(timezone.utc).isoformat(),"stats":stats},"results":all_results}

if __name__=="__main__":
    p = argparse.ArgumentParser()
    p.add_argument("--quick",action="store_true")
    a = p.parse_args()
    r = run_collection(quick=a.quick)
    print(json.dumps(r,ensure_ascii=False,indent=2))
