from datetime import timedelta
from redis import Redis
import pymysql
import os
pymysql.install_as_MySQLdb()

SECRET_KEY = 'customsecret'
SQLALCHEMY_DATABASE_URI = 'mysql+pymysql://superset:superset@database/superset'
RATELIMIT_STORAGE_URI = "redis://redis:6379/5"
HTML_SANITIZATION = False
FEATURE_FLAGS = {
    'DASHBOARD_RBAC': True,
    "ENABLE_TEMPLATE_PROCESSING": True,
    "ESCAPE_MARKDOWN_HTML": False,
    "EMBEDDED_SUPERSET": True
}

# Enable CORS
ENABLE_CORS = True
# Get API_URL from environment variable and allow it in CORS
API_URL = os.environ.get('API_URL', 'http://127.0.0.1:8081')
CORS_OPTIONS = {
    'supports_credentials': True,
    'origins': [API_URL, "http://localhost:8081"],
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

# JWT Algorithm - MUST be RS256 for RSA keys
GUEST_TOKEN_JWT_ALGO = "RS256"
GUEST_TOKEN_JWT_AUDIENCE = os.environ.get('SUPERSET_GUEST_JWT_AUD', 'helioviewer_audience')
# JWT Public Key for verifying tokens
# Copy the entire contents of yourkey.pem here
GUEST_TOKEN_JWT_SECRET =
# Guest role name - this role must exist in Superset
GUEST_ROLE_NAME = "Gamma"

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
SESSION_COOKIE_SAMESITE = "None"   # For HTTP development. Use "None" with Secure=True for production HTTPS

# Increase dashboard size limit
SUPERSET_DASHBOARD_POSITION_DATA_LIMIT = 250000

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

#
# Custom Public Role Configuration
#
def FLASK_APP_MUTATOR(app):
    """
    Called at app startup to customize the Public role with specific permissions
    """
    from superset import security_manager

    # Create a custom role with specific permissions for Public
    custom_public_role = security_manager.add_role("CustomPublic")

    # Define the exact permissions for the Public role
    desired_permissions = [
        ("can_read", "Chart"),
        ("can_read", "Dashboard"),
        ("can_read", "DashboardPermalinkRestApi"),
        ("can_read", "EmbeddedDashboard"),
        ("can_dashboard_permalink", "Superset"),
        ("can_slice", "Superset"),
        ("can_explore_json", "Superset"),
        ("can_dashboard", "Superset"),
        ("all_datasource_access", "all_datasource_access"),
    ]

    # Create permissions if they don't exist and collect them
    pvms = []
    for permission_name, view_menu_name in desired_permissions:
        security_manager.add_permission_view_menu(permission_name, view_menu_name)
        pvm = security_manager.find_permission_view_menu(permission_name, view_menu_name)
        if pvm:
            pvms.append(pvm)

    # Set only these permissions on the CustomPublic role
    custom_public_role.permissions = pvms
    security_manager.get_session.commit()

# Tell Superset to copy permissions from CustomPublic to Public
PUBLIC_ROLE_LIKE = "CustomPublic"

# Custom Security Manager to allow RS256 algorithm for guest tokens
from superset.security.manager import SupersetSecurityManager
from jwt import PyJWT

class CustomSecurityManager(SupersetSecurityManager):
    def __init__(self, appbuilder):
        super().__init__(appbuilder)
        # Create a PyJWT instance with RS256 explicitly in allowed algorithms
        self.pyjwt_for_guest_token = PyJWT(options={"verify_signature": True})

CUSTOM_SECURITY_MANAGER = CustomSecurityManager
