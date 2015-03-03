from os import environ
from base import *

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql_psycopg2',
        'NAME': environ.get('DATABASE_NAME', 'example_dev'),
        'USER': environ.get('DATABASE_USER', 'vagrant'),
        'PASSWORD': environ.get('DATABASE_PASSWORD', 'vagrant'),
        'HOST': environ.get('DATABASE_HOST', '127.0.0.1'),
        'PORT': environ.get('DATABASE_PORT', '5432'),
    }
}

try:
    from local_settings import *
except:
    pass
