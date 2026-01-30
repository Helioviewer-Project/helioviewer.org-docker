from datetime import timedelta
from redis import Redis
import os
import pymysql
pymysql.install_as_MySQLdb()

SECRET_KEY = 'customsecret'

# Read database connection details from environment variables
db_user = os.environ.get('SUPERSET_DB_USER', 'superset')
db_pass = os.environ.get('SUPERSET_DB_PASS', 'superset')
db_host = os.environ.get('SUPERSET_DB_HOST', 'postgres')
db_name = os.environ.get('SUPERSET_DB_NAME', 'superset')
SQLALCHEMY_DATABASE_URI = f'postgresql+psycopg2://{db_user}:{db_pass}@{db_host}/{db_name}'
RATELIMIT_STORAGE_URI = "redis://redis:6379/5"
HTML_SANITIZATION = False
FEATURE_FLAGS = {
    'DASHBOARD_RBAC': True,
    "ENABLE_TEMPLATE_PROCESSING": True,
    "ESCAPE_MARKDOWN_HTML": False,
    "EMBEDDED_SUPERSET": True
}

# Flask-WTF flag for CSRF
WTF_CSRF_ENABLED = True
# Add endpoints that need to be exempt from CSRF protection
WTF_CSRF_EXEMPT_LIST = []
WTF_CSRF_TIME_LIMIT = 7200

# Enable Long Queries with CELERY
class CeleryConfig(object):
    broker_url = "redis://redis:6379/6"
    imports = ("superset.tasks.scheduler")
    result_backend = "redis://localhost:6379/7"
    worker_prefetch_multiplier = 10
    task_acks_late = True
CELERY_CONFIG = CeleryConfig

DATA_CACHE_CONFIG = {
    'CACHE_TYPE': 'RedisCache',
    'CACHE_DEFAULT_TIMEOUT': 86400,
    'CACHE_KEY_PREFIX': 'superset_data_cache',
    'CACHE_REDIS_URL': 'redis://redis:6379/8'
}

# Needed for Handlebars to work
TALISMAN_ENABLED = False
TALISMAN_CONFIG = {
    "content_security_policy": {
        "base-uri": ["'self'"],
        "default-src": ["'self'"],
        "img-src": [
            "'self'",
            "blob:",
            "data:",
            "https://apachesuperset.gateway.scarf.sh",
            "https://static.scarf.sh/",
            # "https://cdn.brandfolder.io", # Uncomment when SLACK_ENABLE_AVATARS is True  # noqa: E501
            "ows.terrestris.de",
        ],
        "worker-src": ["'self'", "blob:"],
        "connect-src": [
            "'self'",
            "https://api.mapbox.com",
            "https://events.mapbox.com",
        ],
        "object-src": "'none'",
        "style-src": [
            "'self'",
            "'unsafe-inline'",
        ],
        "script-src": ["'self'", "'strict-dynamic'"],
    },
    "content_security_policy_nonce_in": ["script-src"],
    "force_https": True,
    "session_cookie_secure": False,
}

# JWT Algorithm - MUST be RS256 for RSA keys
GUEST_TOKEN_JWT_ALGO = "RS256"
GUEST_TOKEN_JWT_AUDIENCE = "superset_audience"
# JWT Public Key for verifying tokens
# Copy the entire contents of yourkey.pem here
GUEST_TOKEN_JWT_SECRET = "your jwt secret"
# Guest role name - this role must exist in Superset
GUEST_ROLE_NAME = "Public"

# 1. Enable server-side sessions
SESSION_SERVER_SIDE = True
# 2. Choose your backend (e.g., 'redis', 'memcached', 'filesystem', 'sqlalchemy')
SESSION_TYPE = 'redis'
# 3. Configure your Redis connection
# Use environment variables for sensitive details
SESSION_REDIS = Redis(
    host="redis",
    port=6379,
    db=9
)

# 4. Ensure the session cookie is signed for integrity
SESSION_USE_SIGNER = True

# Set a short absolute session timeout
# The default is 31 days, which is NOT recommended for production.
PERMANENT_SESSION_LIFETIME = timedelta(hours=8)

# Enforce secure cookie flags to prevent browser-based attacks
SESSION_COOKIE_SECURE = False      # (Set to True for production) Transmit cookie only over HTTPS
SESSION_COOKIE_HTTPONLY = True     # Prevent client-side JS from accessing the cookie
SESSION_COOKIE_SAMESITE = "Strict" # Provide protection against CSRF attacks

# Increase dashboard size limit
SUPERSET_DASHBOARD_POSITION_DATA_LIMIT = 250000
