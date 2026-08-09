#!/usr/bin/env python3
"""
Translate all untranslated academic paper abstracts to Chinese in BookBaker database.
"""

import psycopg2
from psycopg2.extras import RealDictCursor

# Database connection parameters
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
    """Fetch all papers that need translation."""
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

def update_translation(paper_id, translation):
    """Update the Chinese translation for a paper."""
    conn = get_connection()
    try:
        with conn.cursor() as cur:
            cur.execute(
                "UPDATE bb_papers SET abstract_zh = %s WHERE id = %s",
                (translation, paper_id)
            )
        conn.commit()
    finally:
        conn.close()

def translate_abstract(abstract):
    """
    Translate English abstract to Chinese.
    This is a placeholder - actual translation will be done by the AI.
    """
    # The actual translation will be provided inline
    pass

if __name__ == "__main__":
    papers = fetch_untranslated_papers()
    print(f"Found {len(papers)} papers to translate")
    for i, paper in enumerate(papers[:5]):
        print(f"\n--- Paper {i+1} (ID: {paper['id']}) ---")
        print(paper['abstract'][:200] + "..." if len(paper['abstract']) > 200 else paper['abstract'])
