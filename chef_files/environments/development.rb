name            "development"
description     "Development Environment"

# Specific cookbook version
cookbook "webapp", "= 0.1.0"

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
