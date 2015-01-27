# Retry global information from databag
globals_deploy_users = data_bag_item("globals", "deploy_users")
globals_deploy_groups = data_bag_item("globals", "deploy_groups")
globals_webapp_info = data_bag_item("globals", "webapp_info")

git_user = globals_deploy_users[node.chef_environment]
git_group = globals_deploy_groups[node.chef_environment]
log_dir = "/home/#{git_user}/logs"
home_dir = "/home/#{git_user}"
git_venv = "/home/#{git_user}/venv"

app_name = globals_webapp_info["app_name"]
app_dir = "/home/#{git_user}/#{app_name}"
celery_app_dir = "#{app_dir}/#{app_name}"

# Create a directory to hold the id_rsa file.
directory log_dir do
  owner         git_user
  group         git_group
  mode          '0755'
  action        :create
end

# Generate local settings for web-admin app
template "#{home_dir}/celery_run.sh" do
    source      'celery_run.sh.erb'
    user        git_user
    group       git_group
    mode        '0755'
    variables(
        :enable_beat => node[:webapp][:celery][:enable_beat],
        :app_instance => node[:webapp][:celery][:app_instance],
        :log_level => node[:webapp][:celery][:log_level],
        :env_path => git_venv
    )
end

# Generate a supervisor service entry and autostart it
if node[:webapp][:supervisor][:enable_services]
	supervisor_service "celery" do
	    command         "#{home_dir}/celery_run.sh"
	    directory       celery_app_dir
	    autostart       node[:webapp][:supervisor][:autostart]
	    autorestart     node[:webapp][:supervisor][:autorestart]
	    stdout_logfile "#{log_dir}/celery-worker.log"
	    stderr_logfile "#{log_dir}/celery-worker-error.log"

	    user            git_user

	    # Need to wait for currently executing tasks to finish at shutdown.
	    # Increase this if you have very long running tasks.
	    stopwaitsecs    600

	    # When resorting to send SIGKILL to the program to terminate it
	    # send SIGKILL to its whole process group instead,
	    # taking care of its children as well.
	    killasgroup     true
	end
end
