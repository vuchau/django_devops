name            "development"
description     "Development Environment"

override_attributes(
	"webapp" => {
		"repo_url" => "",
		"repo_branch" => "develop",
		"git_deploy" => false,
	},

	"nginx" => {
		"default_site_enabled" => false
	}
)
