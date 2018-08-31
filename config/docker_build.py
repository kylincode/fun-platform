
from ..common import *

# This is a minimal settings file allowing us to run "update_assets"
# in the Dockerfile

DATABASES = {"default": {}}

XQUEUE_INTERFACE = {"url": None, "django_auth": None}

STATICFILES_STORAGE = "openedx.core.storage.ProductionStorage"

STATIC_ROOT = "/edx/var/edxapp/static/"

# edx-platform theme directory
COMPREHENSIVE_THEME_DIRS = ["/edx/app/edxapp/edx-platform/themes"]
