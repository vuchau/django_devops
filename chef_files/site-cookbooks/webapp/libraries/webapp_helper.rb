module WebappHelpers

	def globals_databagitem(databagitem)
		return Chef::DataBagItem.load("globals", databagitem)
	end

    def git_user()
    	return globals_databagitem("deploy_users")[node.chef_environment]
    end

    def git_group()
    	return globals_databagitem("deploy_groups")[node.chef_environment]
    end

    def app_name()
    	return globals_databagitem("webapp_info")["app_name"]
    end

end
