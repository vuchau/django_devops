name            "staging"
description     "Staging Environment"

override_attributes(
	"webapp" => {
		"repo_url" => "https://github.com/thuongdinh/django_devops_example.git",
		"repo_branch" => "develop",
		"git_deploy" => true,
		"databag" => {
			"encrypted" => false
		}
	},

	"nginx" => {
		"default_site_enabled" => false
	}
)
