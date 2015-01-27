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
		}
	},

	"nginx" => {
		"default_site_enabled" => false
	}
)
