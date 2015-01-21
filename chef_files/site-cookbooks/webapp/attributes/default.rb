# Settings for the web application
# --------------------------------
webapp = default[:webapp]

webapp[:deploy_user] = "ubuntu"
webapp[:deploy_group] = "ubuntu"
webapp[:deploy_uid] = 9001

# The flare app git repository
# Must override this for real project
webapp[:repo_url] = ""
webapp[:repo_branch] = "develop"
webapp[:git_deploy] = false

# Web App Info
webapp[:domain] = "webapp"
webapp[:rewrite_domain] = false
webapp[:app_name] = "todos"
webapp[:port] = "9191"
webapp[:workers] = "2"
webapp[:http_supported] = true
webapp[:https_supported] = false
webapp[:http_port] = "80"
webapp[:https_port] = "443"
webapp[:application_wsgi] = "config.wsgi:application"

# Gunicorn config
# TODO: not support bind_sock = false now
# please don't update this value
webapp[:gunicorn][:bind_sock] = true
webapp[:gunicorn][:bind_sock_path] = "unix:/tmp/gunicorn_#{webapp[:domain]}.sock"

# Database
webapp[:db_user] = "django_dev"
webapp[:db_password] = "django_dev"

# Disable the default nginx site
default['nginx']['default_site_enabled'] = false

# Default override allow_sysctl_conf
# all attribute will be written to sysctl.conf file
default['sysctl']['allow_sysctl_conf'] = true

