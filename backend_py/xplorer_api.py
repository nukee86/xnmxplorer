from flask import Flask, request, jsonify
import sqlite3
import threading

app = Flask(__name__)

def get_db(db_name):
    db = getattr(threading.current_thread(), db_name, None)
    if db is None:
        db = sqlite3.connect(f'/home/ubuntu/python/xenminer/{db_name}', check_same_thread=False)
        setattr(threading.current_thread(), db_name, db)
    return db

# # Connect to the SQLite3 database with check_same_thread=False
# conn = sqlite3.connect('/home/ubuntu/python/xenminer/blocks.db', check_same_thread=False)
# cursor = conn.cursor()

# Define your API endpoints
@app.route('/blocks/count', methods=['GET'])
def get_block_count():
    db = get_db('stats.db')
    cursor = db.cursor()

    try:
        cursor.execute("SELECT total_regular,total_xuni,total_super_blocks FROM total_stats")
        row = cursor.fetchone()
        if row:
            regular_count, xuni_count, superblock_count = row
        else:
            regular_count, xuni_count, superblock_count = 0, 0, 0

    except Exception as e:
        return "Error: "+ str(e)
    finally:
        cursor.close()
    
    return jsonify({
        'xuni_count': xuni_count,
        'superblock_count': superblock_count,
        'regular_count': regular_count
    })

@app.route('/blocks/count/<account>', methods=['GET'])
def get_block_counts(account):
    db = get_db('stats.db')
    cursor = db.cursor()

    try:
        cursor.execute("SELECT count_regular, count_xuni, count_super_blocks FROM account_stats WHERE account=?", (account,))
        row = cursor.fetchone()
        if row:
            regular_count, xuni_count, superblock_count = row
        else:
            regular_count, xuni_count, superblock_count = 0, 0, 0

    except Exception as e:
        return "Error: "+ str(e)
    finally:
        cursor.close()
    
    return jsonify({
        'account': account,
        'regular_count': regular_count,
        'superblock_count': superblock_count,
        'xuni_count': xuni_count
    })

@app.route('/blocks/latest', methods=['GET'])
def get_latest_blocks_by_type():
    block_type = request.args.get('type')  # Get the block type from the request query parameters
    n = int(request.args.get('n', 10))  # Get the number of blocks to retrieve (default to 10)
    db = get_db('blocks.db')
    cursor = db.cursor()

    try:
        if block_type == 'regular':
            cursor.execute("SELECT * FROM regular ORDER BY block_id DESC LIMIT ?", (n,))
        elif block_type == 'xuni':
            cursor.execute("SELECT * FROM xuni ORDER BY block_id DESC LIMIT ?", (n,))
        elif block_type == 'super':
            cursor.execute("SELECT * FROM super_blocks ORDER BY block_id DESC LIMIT ?", (n,))
        else:
            return jsonify({'error': 'Invalid block type'}), 400
        latest_blocks = cursor.fetchall()
    except Exception as e:
        return "Error: "+ str(e)
    finally:
        cursor.close()

    return jsonify({
        'latest_blocks': latest_blocks
    })

@app.route('/blocks/search', methods=['GET'])
def search_hashes():
    search_string = request.args.get('search_string')  # Get the search string from the query parameters

    db = get_db('blocks.db')
    cursor = db.cursor()

    try:
        # Search in the 'regular' table
        cursor.execute("SELECT COUNT(*), MAX(hash_to_verify) FROM regular WHERE hash_to_verify LIKE ?", ('%' + search_string + '%',))
        regular_count, latest_regular_hash = cursor.fetchone()

        # Search in the 'xuni' table
        cursor.execute("SELECT COUNT(*), MAX(hash_to_verify) FROM xuni WHERE hash_to_verify LIKE ?", ('%' + search_string + '%',))
        xuni_count, latest_xuni_hash = cursor.fetchone()
    except Exception as e:
        return "Error: "+ str(e)
    finally:
        cursor.close()

    return jsonify({
        'search_string': search_string,
        'regular_count': regular_count,
        'latest_regular_hash': latest_regular_hash,
        'xuni_count': xuni_count,
        'latest_xuni_hash': latest_xuni_hash
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)

