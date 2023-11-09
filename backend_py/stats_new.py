import sqlite3
import time

def create_account_stats_table():
    # Connect to the 'stats.db' database
    conn_stats = sqlite3.connect('stats.db')
    cursor_stats = conn_stats.cursor()

    # Create the 'account_stats' table if it doesn't exist
    cursor_stats.execute("""
        CREATE TABLE IF NOT EXISTS account_stats (
            account TEXT PRIMARY KEY,
            count_regular INTEGER DEFAULT 0,
            count_xuni INTEGER DEFAULT 0,
            count_super_blocks INTEGER DEFAULT 0
        )
    """)

    conn_stats.commit()
    conn_stats.close()

def update_account_stats():
    # Ensure the 'account_stats' table exists
    create_account_stats_table()

    # Connect to the 'stats.db' database
    conn_stats = sqlite3.connect('stats.db')
    cursor_stats = conn_stats.cursor()

    # List of tables to gather counts from
    tables = ['regular', 'xuni', 'super_blocks']

    for table_name in tables:
        # Connect to the 'blocks.db' database for each table
        conn_blocks = sqlite3.connect('blocks.db')
        cursor_blocks = conn_blocks.cursor()

        # Query the current table to get the account counts
        cursor_blocks.execute(f"""
            SELECT account, COUNT(*) FROM {table_name} GROUP BY account
        """)
        account_counts = cursor_blocks.fetchall()

        # Update the 'account_stats' table in the 'stats.db' database
        for account, count in account_counts:
            # Check if the account exists in account_stats
            cursor_stats.execute("SELECT account FROM account_stats WHERE account = ?", (account,))
            existing_account = cursor_stats.fetchone()

            if existing_account:
                # Account exists, update counts
                update_query = f"""
                    UPDATE account_stats SET count_{table_name} = ? WHERE account = ?
                """
                cursor_stats.execute(update_query, (count, account))
            else:
                # Account doesn't exist, insert a new row
                insert_query = f"""
                    INSERT INTO account_stats (account, count_{table_name}) VALUES (?, ?)
                """
                cursor_stats.execute(insert_query, (account, count))
        
        conn_blocks.close()

    conn_stats.commit()
    conn_stats.close()

def create_total_stats_table():
    # Connect to the 'stats.db' database
    conn_stats = sqlite3.connect('stats.db')
    cursor_stats = conn_stats.cursor()

    # Create the 'total_stats' table if it doesn't exist
    cursor_stats.execute("""
        CREATE TABLE IF NOT EXISTS total_stats (
            id INTEGER PRIMARY KEY,
            total_regular INTEGER DEFAULT 0,
            total_xuni INTEGER DEFAULT 0,
            total_super_blocks INTEGER DEFAULT 0
        )
    """)

    conn_stats.commit()
    conn_stats.close()

def update_total_stats():
    # Ensure the 'total_stats' table exists
    create_total_stats_table()

    # Connect to the 'stats.db' database
    conn_stats = sqlite3.connect('stats.db')
    cursor_stats = conn_stats.cursor()

    # List of tables to gather counts from
    tables = ['regular', 'xuni', 'super_blocks']

    # Initialize total counts
    total_counts = {table: 0 for table in tables}

    for table_name in tables:
        # Connect to the 'blocks.db' database for each table
        conn_blocks = sqlite3.connect('blocks.db')
        cursor_blocks = conn_blocks.cursor()

        # Query the current table to get the total count
        cursor_blocks.execute(f"""
            SELECT MAX(block_id) FROM {table_name}
        """)
        max_block_id = cursor_blocks.fetchone()[0]

        # Update the total counts dictionary
        total_counts[table_name] = max_block_id

        conn_blocks.close()

    # Update the 'total_stats' table in the 'stats.db' database
    update_query = """
        INSERT OR REPLACE INTO total_stats (id, total_regular, total_xuni, total_super_blocks)
        VALUES (1, ?, ?, ?)
    """
    cursor_stats.execute(update_query, (total_counts['regular'], total_counts['xuni'], total_counts['super_blocks']))

    conn_stats.commit()
    conn_stats.close()
print("Starting to gather stats...")
update_account_stats()
update_total_stats()
print("Stats gathering complete.")
