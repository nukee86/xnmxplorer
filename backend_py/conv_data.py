import sqlite3
import json
import re
from datetime import datetime

def is_within_five_minutes_of_hour(created_at_str):
    # Parse the 'created_at' string into a datetime object
    created_at = datetime.strptime(created_at_str, "%Y-%m-%d %H:%M:%S")
    # Extract the minute component from the 'created_at' timestamp
    minutes = created_at.minute
    # Check if the 'created_at' time is within the first 5 minutes or the last 5 minutes of the hour
    return 0 <= minutes < 5 or 55 <= minutes < 60
    
# Connect to the 'blockchain' database
conn_blockchain = sqlite3.connect("blockchain.db")
cursor_blockchain = conn_blockchain.cursor()

# Connect to the 'blocks' database
conn_blocks = sqlite3.connect("blocks.db")
cursor_blocks = conn_blocks.cursor()

# Create the 'xuni' table if it doesn't exist
cursor_blocks.execute("""
    CREATE TABLE IF NOT EXISTS xuni (
        block_id INTEGER PRIMARY KEY AUTOINCREMENT,
        hash_to_verify TEXT,
        key TEXT UNIQUE,
        account TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )
""")

# Create the 'super_blocks' table if it doesn't exist
cursor_blocks.execute("""
    CREATE TABLE IF NOT EXISTS super_blocks (
        block_id INTEGER PRIMARY KEY AUTOINCREMENT,
        hash_to_verify TEXT,
        key TEXT UNIQUE,
        account TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )
""")

# Create the 'regular' table if it doesn't exist
cursor_blocks.execute("""
    CREATE TABLE IF NOT EXISTS regular (
        block_id INTEGER PRIMARY KEY AUTOINCREMENT,
        hash_to_verify TEXT,
        key TEXT UNIQUE,
        account TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )
""")

# Create the 'progress' table if it doesn't exist
cursor_blocks.execute("""
    CREATE TABLE IF NOT EXISTS progress (
        last_processed_id INTEGER
    )
""")

# Fetch the last processed id from the progress table or insert an initial value if it doesn't exist
cursor_blocks.execute("SELECT last_processed_id FROM progress")
result = cursor_blocks.fetchone()
if result:
    last_processed_id = result[0]
else:
    # If the progress table is empty, insert an initial value
    cursor_blocks.execute("INSERT INTO progress (last_processed_id) VALUES (0)")
    conn_blocks.commit()
    last_processed_id = 0

# Fetch records from the 'blockchain' table in batches starting from the last processed id
batch_size = 1000  # You can adjust this value as needed
while True:
    cursor_blockchain.execute("SELECT records_json, id FROM blockchain WHERE id > ? LIMIT ?", (last_processed_id, batch_size))
    batch_records = cursor_blockchain.fetchall()
    
    if not batch_records:
        break
    
    for record in batch_records:
        records_json = record[0]
        records_list = json.loads(records_json)  # Assuming records_json is in JSON format

        for item in records_list:
            hash_to_verify = item.get("hash_to_verify")
            key = item.get("key")
            account = item.get("account")
            created_at = item.get("date")
            capital_count = sum(1 for char in re.sub('[0-9]', '', hash_to_verify) if char.isupper())
            try:
                if is_within_five_minutes_of_hour(created_at) and "XUNI" in hash_to_verify:
                    cursor_blocks.execute("INSERT OR IGNORE INTO xuni (hash_to_verify, key, account, created_at) VALUES (?, ?, ?, ?)", (hash_to_verify, key, account, created_at))
                elif capital_count >= 65:
                    cursor_blocks.execute("INSERT OR IGNORE INTO super_blocks (hash_to_verify, key, account, created_at) VALUES (?, ?, ?, ?)", (hash_to_verify, key, account, created_at))
                    cursor_blocks.execute("INSERT OR IGNORE INTO regular (hash_to_verify, key, account, created_at) VALUES (?, ?, ?, ?)", (hash_to_verify, key, account, created_at))
                else:
                    cursor_blocks.execute("INSERT OR IGNORE INTO regular (hash_to_verify, key, account, created_at) VALUES (?, ?, ?, ?)", (hash_to_verify, key, account, created_at))
            except sqlite3.IntegrityError as e:
                print(f"Conflict detected for record: {record}")
                # Handle the conflict or log it as needed
        # Update the last processed id in the progress table
        last_processed_id = record[1]
    
    conn_blocks.commit()  # Commit the inserts to 'xuni', 'super_blocks', and 'regular' tables
    # Update the progress table with the last processed id
    cursor_blocks.execute("UPDATE progress SET last_processed_id = ?", (last_processed_id,))
    conn_blocks.commit()  # Commit the progress update
    print(f'processed {last_processed_id} blocks')

print(f"Processed up to record with id {last_processed_id}.")

# Close the database connections
conn_blockchain.close()
conn_blocks.close()

