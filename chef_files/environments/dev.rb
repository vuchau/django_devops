name            "development"
description     "Development Environment"

globals_deploy_users = data_bag_item("globals", "deploy_users")
globals_deploy_groups = data_bag_item("globals", "deploy_groups")

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
		"deploy_user" => globals_deploy_users["dev"],
		"deploy_group" => globals_deploy_groups["dev"]
	},

	"nginx" => {
		"default_site_enabled" => false
	}
)
