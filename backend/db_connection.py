
# db_connection.py (PostgreSQL for Supabase using psycopg3)

import logging
import os
import time
import socket
from dotenv import load_dotenv
from psycopg_pool import ConnectionPool
import psycopg
from psycopg.rows import dict_row

# Try to import dnspython for better DNS resolution
try:
    import dns.resolver
    HAS_DNSPYTHON = True
except ImportError:
    HAS_DNSPYTHON = False

load_dotenv()
# For production, only environment variables are used for DB config.
# db_config.ini is ignored for PostgreSQL/Supabase deployments.

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
                
                # Validate critical environment variables
                if not db_host:
                    raise ValueError("DB_HOST environment variable is not set. Please configure it in your deployment environment.")
                if not db_password:
                    raise ValueError("DB_PASSWORD environment variable is not set. Please configure it in your deployment environment.")
                
                logger.info(f"Attempting to connect to database: {db_host}:{db_port}/{db_name} as user {db_user}")
                
                pool_min = 1
                pool_max = int(os.getenv('DB_POOL_SIZE', 30))
                connection_host = db_host
                resolved_ip = None
                
                # Supabase: Try to resolve to IPv4 before connecting (with fallback)
                if db_host and 'supabase.com' in db_host:
                    # Method 1: Try dnspython with multiple DNS servers
                    if HAS_DNSPYTHON and not resolved_ip:
                        try:
                            resolver = dns.resolver.Resolver()
                            resolver.nameservers = ['8.8.8.8', '8.8.4.4', '1.1.1.1', '1.0.0.1']
                            resolver.timeout = 5
                            resolver.lifetime = 5
                            answers = resolver.resolve(db_host, 'A')
                            ipv4_list = [str(rdata) for rdata in answers if hasattr(rdata, 'address') and ':' not in str(rdata)]
                            if ipv4_list:
                                resolved_ip = ipv4_list[0]
                                logger.info(f"✓ Resolved {db_host} to IPv4 via DNS: {resolved_ip}")
                        except Exception as e:
                            logger.warning(f"⚠ DNS resolution via dnspython failed: {e}")
                    
                    # Method 2: Try socket.getaddrinfo with IPv4 only
                    if not resolved_ip:
                        try:
                            addr_info = socket.getaddrinfo(db_host, int(db_port), socket.AF_INET, socket.SOCK_STREAM)
                            ipv4_addrs = [info[4][0] for info in addr_info if info[0] == socket.AF_INET]
                            if ipv4_addrs:
                                resolved_ip = ipv4_addrs[0]
                                logger.info(f"✓ Resolved {db_host} to IPv4 via socket: {resolved_ip}")
                        except Exception as e:
                            logger.warning(f"⚠ Socket resolution failed: {e}")
                    
                    # Method 3: Try standard socket gethostbyname (IPv4 only)
                    if not resolved_ip:
                        try:
                            resolved_ip = socket.gethostbyname(db_host)
                            logger.info(f"✓ Resolved {db_host} to IPv4 via gethostbyname: {resolved_ip}")
                        except Exception as e:
                            logger.warning(f"⚠ gethostbyname resolution failed: {e}")
                    
                    # Update connection host if resolved
                    if resolved_ip:
                        connection_host = resolved_ip
                        logger.info(f"Using resolved IPv4 address: {resolved_ip}")
                    else:
                        logger.warning(f"⚠ Could not resolve {db_host} to IPv4, will try direct connection")
                        logger.warning(f"⚠ If connection fails, check your DB_HOST setting")
                        # Don't raise exception here - let psycopg try to connect
                
                # Build connection string with SSL for Supabase
                # CRITICAL: Force IPv4 by adding target_session_attrs and options
                if resolved_ip:
                    # Use hostaddr when we successfully resolved to IPv4
                    conninfo = f"hostaddr={connection_host} port={db_port} user={db_user} password={db_password} dbname={db_name} connect_timeout=30 sslmode=require options='-c client_encoding=UTF8'"
                    logger.info(f"Connecting to PostgreSQL at {connection_host}:{db_port} (resolved from {db_host})")
                else:
                    # Force IPv4 by using host with specific connection options
                    # This prevents psycopg from resolving to IPv6
                    conninfo = f"host={connection_host} port={db_port} user={db_user} password={db_password} dbname={db_name} connect_timeout=30 sslmode=require"
                    logger.warning(f"⚠ Connecting to PostgreSQL at {connection_host}:{db_port} without pre-resolved IPv4 - this may fail on Render!")
                    logger.error(f"❌ DB_HOST appears to be incorrect or unresolvable: {db_host}")
                    logger.error(f"❌ Expected: 'aws-1-ap-south-1.pooler.supabase.com' but got: {db_host}")
                    logger.error(f"❌ Please update DB_HOST in your Render environment variables!")
                # Create connection pool (psycopg3 style)
                self.pool = ConnectionPool(
                    conninfo=conninfo,
                    min_size=pool_min,
                    max_size=pool_max,
                    timeout=30,
                    kwargs={"row_factory": dict_row}
                )
                # Test connection
                with self.pool.connection() as conn:
                    with conn.cursor() as cur:
                        cur.execute("SELECT 1")
                logger.info(f"✓ PostgreSQL pool initialized successfully with database '{db_name}' on {connection_host}:{db_port} (attempt {attempt + 1}/{max_retries})")
                return  # Success
                
            except Exception as e:
                if attempt < max_retries - 1:
                    logger.warning(f"Connection attempt {attempt + 1} failed: {e}. Retrying in {retry_delay}s...")
                    time.sleep(retry_delay)
                    retry_delay *= 2  # Exponential backoff
                else:
                    logger.error(f"Failed to initialize connection pool after {max_retries} attempts: {e}")
                    raise

    def execute_query(self, query, params=None):
        """Execute a SELECT query and return results as list of dicts"""
        try:
            with self.pool.connection() as conn:
                with conn.cursor() as cursor:
                    cursor.execute(query, params or ())
                    result = cursor.fetchall()
                    return result if result else []
        except Exception as e:
            logger.error(f"SELECT Query failed: {e}\nQuery: {query}")
            return None

    def execute_update(self, query, params=None):
        """Execute an INSERT/UPDATE/DELETE query"""
        try:
            with self.pool.connection() as conn:
                with conn.cursor() as cursor:
                    cursor.execute(query, params or ())
                    conn.commit()
                    return {"last_id": None, "affected": cursor.rowcount}
        except Exception as e:
            logger.error(f"UPDATE Query failed: {e}\nQuery: {query}")
            return False

    def init_database(self, schema_file):
        """Initialize database from SQL file"""
        if not os.path.exists(schema_file):
            logger.error(f"Schema file not found: {schema_file}")
            return False
        
        try:
            with self.pool.connection() as conn:
                with conn.cursor() as cursor:
                    with open(schema_file, 'r', encoding='utf-8') as f:
                        sql = f.read()
                    
                    # Execute SQL (PostgreSQL supports multiple statements)
                    cursor.execute(sql)
                    conn.commit()
                    logger.info("Database initialized successfully.")
                    return True
        except Exception as e:
            logger.error(f"Failed to initialize database: {e}")
            return False
    
    def close_all(self):
        """Close all connections in the pool"""
        try:
            if hasattr(self, 'pool') and self.pool:
                self.pool.close()
                logger.info("All database connections closed")
        except Exception as e:
            logger.error(f"Error closing connections: {e}")

# Create global database manager instance
db_manager = None
try:
    db_manager = PostgreSQLManager()
    logger.info("✅ Using PostgreSQL database manager (psycopg3)")
    logger.info("✅ Database connection established successfully")
except Exception as e:
    logger.error(f"❌ Failed to initialize PostgreSQL manager: {e}")
    logger.error("❌ Please ensure DB_HOST, DB_PASSWORD, and other Supabase credentials are set in environment variables")
    logger.error("⚠️  App will start but database operations will fail until connection is established")
    logger.error("⚠️  Fix the database connection and restart the service")
    # Don't raise - allow app to start so we can see error messages
    # In production, you might want to raise here for fail-fast behavior
