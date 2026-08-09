#!/usr/bin/env python3
"""
Fetch all untranslated papers for translation.
"""

import psycopg2
from psycopg2.extras import RealDictCursor
import json

DB_CONFIG = {
    'host': 'localhost',
    'port': 5433,
    'dbname': 'bookbaker',
    'user': 'bb_admin',
    'password': 'bb2026!'
}

def get_connection():
    return psycopg2.connect(**DB_CONFIG)

def fetch_untranslated_papers():
    conn = get_connection()
    try:
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute("""
                SELECT id, abstract FROM bb_papers 
                WHERE abstract_zh IS NULL 
                AND abstract IS NOT NULL 
                AND length(abstract) > 50 
                ORDER BY year DESC
            """)
            papers = cur.fetchall()
        return papers
    finally:
        conn.close()

if __name__ == "__main__":
    papers = fetch_untranslated_papers()
    # Save to JSON file for processing
    with open('/root/papers_to_translate.json', 'w', encoding='utf-8') as f:
        json.dump([dict(p) for p in papers], f, ensure_ascii=False, indent=2)
    print(f"Saved {len(papers)} papers to /root/papers_to_translate.json")
