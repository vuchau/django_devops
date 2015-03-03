from os import environ

from base import *

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql_psycopg2',
        'NAME': environ.get('DATABASE_NAME'),
        'USER': environ.get('DATABASE_USER'),
        'PASSWORD': environ.get('DATABASE_PASSWORD'),
        'HOST': environ.get('DATABASE_HOST'),
        'PORT': environ.get('DATABASE_PORT'),
    }
}


STATIC_ROOT = 'backend_path/static'

########## HOST CONFIGURATION
# See: https://docs.djangoproject.com/en/1.7/ref/settings/#allowed-hosts
ALLOWED_HOSTS = ['127.0.0.1', '*']
########## END HOST CONFIGURATION

DEBUG = False

########## CACHE CONFIGURATION
# See: https://docs.djangoproject.com/en/dev/ref/settings/#caches
CACHES = {
    'default': {
        'BACKEND': 'django.core.cache.backends.locmem.LocMemCache',
    }
}

try:
    from local_settings import *
except:
    pass
