#!/usr/bin/env python3
"""
Batch translation script for BookBaker database.
Translates abstracts in batches of 10 and updates the database.
"""

import psycopg2
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

def update_translations(batch):
    """Update translations for a batch of papers."""
    conn = get_connection()
    try:
        with conn.cursor() as cur:
            for paper_id, translation in batch:
                cur.execute(
                    "UPDATE bb_papers SET abstract_zh = %s WHERE id = %s",
                    (translation, paper_id)
                )
        conn.commit()
        print(f"Successfully updated {len(batch)} translations")
    except Exception as e:
        conn.rollback()
        print(f"Error updating translations: {e}")
        raise
    finally:
        conn.close()

if __name__ == "__main__":
    # This script will be called with batch data
    import sys
    if len(sys.argv) > 1:
        batch_file = sys.argv[1]
        with open(batch_file, 'r', encoding='utf-8') as f:
            batch = json.load(f)
        update_translations([(item['id'], item['translation']) for item in batch])
    else:
        print("Usage: python batch_update.py <batch_file.json>")
