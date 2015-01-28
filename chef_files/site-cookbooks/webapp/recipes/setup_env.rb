::Chef::Recipe.send(:include, WebappHelpers)

# Retry global information from databag
git_user = git_user()
git_group = git_group()
app_name = app_name()

# The location where the vitualenv will be located
git_venv = "/home/#{git_user}/venv"

# The location where the app will be checked out.
app_dir = "/home/#{git_user}/#{app_name}"
app_settings_dir = "/home/#{git_user}/#{app_name}/#{app_name}/config/settings"

# When ssh to server, it will auto turn on
# virtual env
script "Update .bashrc" do
    interpreter "bash"
    code <<-EOH
echo 'source /home/#{git_user}/venv/bin/activate' >> /home/#{git_user}/.bashrc
EOH
end

# Load the keys of the items in the 'envs' data bag
envs_databag_key = "#{node.chef_environment}_envs"
envs = data_bag(envs_databag_key)
export_envs = Array.new

envs.each_with_index do |var,i|
  if node[:databag][:encrypted]
	env = Chef::EncryptedDataBagItem.load(envs_databag_key, var)
  else
	env = data_bag_item(envs_databag_key, var)
  end

  export_envs[i] = "os.environ.setdefault(\"#{env['KEY']}\", \"#{env['VALUE']}\")"
end

# Export local_envs if there are any env
if export_envs.length > 0
	template "#{app_settings_dir}/local_envs.py" do
	    source 'local_envs.py.erb'
	    user git_user
	    group git_group
	    mode   '0755'
	    variables(
	        :envs => export_envs
	    )
	end
end

# Create bash script to restart services base on roles of node
export_restart_service_commands = Array.new
if node.recipes.include?("webapp::celery") or node.recipes.include?("webapp::web")
	export_restart_service_commands.push("service supervisor restart")
end

if node.recipes.include?("webapp::web")
	export_restart_service_commands.push("service nginx restart")
end

template "/home/#{git_user}/restart_services.sh" do
    source "restart_services.sh.erb"
    owner git_user
    group git_group

    # Only owner can write
    # Others can execute
    mode '0755'

    variables(
        :commands => export_restart_service_commands
    )
end
