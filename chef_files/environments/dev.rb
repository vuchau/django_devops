name            "development"
description     "Development Environment"

override_attributes(
  "webapp" => {
    "repo_url" => "",
    "repo_branch" => "develop",
    "git_deploy" => false,
    "databag" => {
      "encrypted" => false
    },
    "supervisor" => {
      "enable_services" => false
    },
    'deploy_user' => 'vagrant',
    'deploy_group' => 'vagrant',
    'django_app' => {
      'allow_hosts' => %w('*')
    },
    'gunicorn' => {
      'port' => '8001',
      'num_worker' => '2'
    },
  },
  "nginx" => {
    "default_site_enabled" => false
  }
)
