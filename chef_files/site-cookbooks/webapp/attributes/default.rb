

# this attribute indicate should use encrypted
# to get databag or not
# Override this inside enviroment files if
# want to change it
default[:databag][:encrypted] = false


# Settings for the web application
# --------------------------------
webapp = default[:webapp]

# Data Bag
# --------
# Get data bag value
if webapp['databag']['encrypted'] == true
  app_info = Chef::EncryptedDataBagItem.load('globals', 'webapp_info_encrypted')
  database_info = Chef::EncryptedDataBagItem.load('secrets', 'database_password_encrypted')
else
  app_info =  Chef::DataBagItem.load('globals', 'webapp_info')
  database_info = Chef::DataBagItem.load('secrets', 'database_password')
end

# Get app name
app_name = app_info[:app_name]
Chef::Log.info(app_name)
db_user = "vagrant"
db_password = "vagrant"
db_name = "#{app_name}_dev"
db_host = '127.0.0.1'
db_port = '5432'

webapp[:deploy_user] = "vagrant"
webapp[:deploy_group] = "vagrant"
webapp[:deploy_uid] = 9001

# The flare app git repository
# Must override this for real project
webapp[:repo_url] = ""
webapp[:repo_branch] = "develop"
webapp[:git_deploy] = false

# Web App Info
webapp[:domain] = app_name
webapp[:rewrite_domain] = false
webapp[:app_name] = app_name
webapp[:http_supported] = true
webapp[:https_supported] = false
webapp[:http_port] = "80"
webapp[:https_port] = "443"
webapp[:application_wsgi] = "config.wsgi:application"

# Gunicorn config
# TODO: not support bind_sock = false now
# please don't change this value
webapp[:gunicorn][:port] = "9191"
webapp[:gunicorn][:workers] = "2"
webapp[:gunicorn][:bind_sock] = true
webapp[:gunicorn][:bind_sock_path] = "unix:/tmp/gunicorn_#{webapp[:domain]}.sock"

# Database
# --------
# Check env and set database information
if node.chef_environment != 'dev'
  db_password = database_info['db_pass']
  db_name = database_info['db_name']
  db_user = database_info['db_user']
  root_db_password = database_info['root_password']
  db_host = database_info['db_host']
  db_port = database_info['db_port']
end

webapp[:db_user] = db_user
webapp[:db_password] = db_password
webapp[:root_password] = root_db_password
webapp[:db_host] = db_host
webapp[:db_port] = db_port
webapp[:db_name] = db_name

# Celery
# ------
webapp[:celery][:enable_beat] = true
webapp[:celery][:app_instance] = "config"
webapp[:celery][:log_level] = "INFO"
webapp[:celery][:c_force_root] = true # allow force run celery with root account

# Supervisor
# -----------

# create supervisor services or not
webapp[:supervisor][:enable_services] = true
webapp[:supervisor][:autostart] = true
webapp[:supervisor][:autorestart] = true



# MISC
# --------

# Disable the default nginx site
default['nginx']['default_site_enabled'] = false

# Default override allow_sysctl_conf
# all attribute will be written to sysctl.conf file
default['sysctl']['allow_sysctl_conf'] = true

