# Settings for the web admin/api application
# ------------------------------------------
webapp = default[:webapp]

webapp[:deploy_user] = "deploy"
webapp[:deploy_group] = "deploy"
webapp[:deploy_uid] = 9001

# The flare app git repository
# Must override this for real project
webapp[:repo_url] = ""
webapp[:repo_branch] = "develop"
webapp[:git_deploy] = false

# Web App Info
webapp[:domain] = "webapp"
webapp[:app_name] = "webapp_django" # should replace name here
webapp[:port] = "9191"
webapp[:workers] = "2"
webapp[:http_supported] = true
webapp[:https_supported] = false
webapp[:http_port] = "80"
webapp[:https_port] = "443"

# Database
webapp[:db_user] = "django_dev"
webapp[:db_password] = "django_dev"

# Disable the default nginx site
default['nginx']['default_site_enabled'] = false
