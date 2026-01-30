
# db_connection.py (PostgreSQL for Supabase)

import logging
import os
import time
from dotenv import load_dotenv
from psycopg2 import pool, Error as PgError
import psycopg2.extras

load_dotenv()

# Configure Logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler()
    ]
)
logger = logging.getLogger("DatabaseManager")

class PostgreSQLManager:
    """PostgreSQL connection manager for Supabase"""
    _instance = None
    
    def __new__(cls):
        if cls._instance is None:
            cls._instance = super(PostgreSQLManager, cls).__new__(cls)
            cls._instance._initialize_pool()
        return cls._instance

    def _initialize_pool(self):
        """Initialize PostgreSQL connection pool with retry logic"""
        max_retries = int(os.getenv('DB_MAX_RETRIES', 3))
        retry_delay = 2
        
        for attempt in range(max_retries):
            try:
                # Get database configuration from environment
                db_host = os.getenv('DB_HOST')
                db_port = os.getenv('DB_PORT', '5432')
                db_user = os.getenv('DB_USER', 'postgres')
                db_password = os.getenv('DB_PASSWORD')
                db_name = os.getenv('DB_NAME', 'postgres')
                pool_size = int(os.getenv('DB_POOL_SIZE', 30))
                
                if not db_host or not db_password:
                    raise ValueError("DB_HOST and DB_PASSWORD must be set in environment variables")
                
                # Create connection pool
                self.pool = psycopg2.pool.ThreadedConnectionPool(
                    minconn=1,
                    maxconn=pool_size,
                    host=db_host,
                    port=db_port,
                    user=db_user,
                    password=db_password,
                    database=db_name,
                    connect_timeout=int(os.getenv('DB_POOL_TIMEOUT', 30)),
                    options='-c statement_timeout=30000'  # 30 second query timeout
                )
                
                # Test connection
                test_conn = self.pool.getconn()
                test_conn.close()
                self.pool.putconn(test_conn)
                
                logger.info(f"PostgreSQL pool initialized successfully with database '{db_name}' on {db_host} (attempt {attempt + 1}/{max_retries})")
                return  # Success
                
            except Exception as e:
                if attempt < max_retries - 1:
                    logger.warning(f"Connection attempt {attempt + 1} failed: {e}. Retrying in {retry_delay}s...")
                    time.sleep(retry_delay)
                    retry_delay *= 2  # Exponential backoff
                else:
                    logger.error(f"Failed to initialize connection pool after {max_retries} attempts: {e}")
                    raise

    def get_connection(self):
        """Get a connection from the pool"""
        try:
            conn = self.pool.getconn()
            return conn
        except Exception as e:
            logger.error(f"Failed to get connection from pool: {e}")
            return None

    def return_connection(self, conn):
        """Return a connection to the pool"""
        if conn:
            try:
                self.pool.putconn(conn)
            except Exception as e:
                logger.error(f"Failed to return connection to pool: {e}")

    def execute_query(self, query, params=None):
        """Execute a SELECT query and return results as list of dicts"""
        conn = self.get_connection()
        if not conn:
            return None
        
        cursor = None
        try:
            cursor = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
            cursor.execute(query, params or ())
            result = cursor.fetchall()
            # Convert to list of regular dicts
            return [dict(row) for row in result] if result else []
        except Exception as e:
            logger.error(f"SELECT Query failed: {e}\nQuery: {query}")
            return None
        finally:
            if cursor:
                try:
                    cursor.close()
                except:
                    pass
            self.return_connection(conn)

    def execute_update(self, query, params=None):
        """Execute an INSERT/UPDATE/DELETE query"""
        conn = self.get_connection()
        if not conn:
            return False
        
        cursor = None
        try:
            cursor = conn.cursor()
            cursor.execute(query, params or ())
            conn.commit()
            return {"last_id": cursor.lastrowid if hasattr(cursor, 'lastrowid') else None, "affected": cursor.rowcount}
        except Exception as e:
            conn.rollback()
            logger.error(f"UPDATE Query failed: {e}\nQuery: {query}")
            return False
        finally:
            if cursor:
                try:
                    cursor.close()
                except:
                    pass
            self.return_connection(conn)

    def init_database(self, schema_file):
        """Initialize database from SQL file"""
        if not os.path.exists(schema_file):
            logger.error(f"Schema file not found: {schema_file}")
            return False
        
        conn = self.get_connection()
        if not conn:
            return False
        
        cursor = None
        try:
            cursor = conn.cursor()
            with open(schema_file, 'r', encoding='utf-8') as f:
                sql = f.read()
            
            # Execute SQL (PostgreSQL supports multiple statements)
            cursor.execute(sql)
            conn.commit()
            logger.info("Database initialized successfully.")
            return True
        except Exception as e:
            conn.rollback()
            logger.error(f"Failed to initialize database: {e}")
            return False
        finally:
            if cursor:
                cursor.close()
            self.return_connection(conn)
    
    def close_all(self):
        """Close all connections in the pool"""
        try:
            if hasattr(self, 'pool') and self.pool:
                self.pool.closeall()
                logger.info("All database connections closed")
        except Exception as e:
            logger.error(f"Error closing connections: {e}")

# Create global database manager instance
try:
    db_manager = PostgreSQLManager()
    logger.info("Using PostgreSQL database manager for Supabase")
except Exception as e:
    logger.error(f"Failed to initialize PostgreSQL manager: {e}")
    logger.error("Please ensure DB_HOST, DB_PASSWORD, and other Supabase credentials are set in environment variables")
    raise
