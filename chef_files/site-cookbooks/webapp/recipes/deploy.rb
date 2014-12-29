git_user = node[:webapp][:deploy_user]
git_group = node[:webapp][:deploy_group]
git_repo_url = node[:webapp][:repo_url]
git_repo_branch = node[:webapp][:repo_branch]
app_name = node[:webapp][:app_name]

# The wrapper script that allow the server to checkout
# latest code without being blocked by "knownhosts".
git_ssh_wrapper = "/home/#{git_user}/git_ssh_wrapper.sh"

# The user home directory.
git_user_dir = "/home/#{git_user}"

# this only a location where locate repos
# we will link app to other place
repo_dir = "/home/#{git_user}/repos/#{app_name}"
repo_app_dir = "/home/#{git_user}/repos/#{app_name}/#{app_name}"
app_dir = "/home/#{git_user}/#{app_name}"

# Sychronize latest source code to a local directory on the server.
git repo_dir do
	only_if { node['webapp']['git_deploy'] }
    repository git_repo_url
    revision git_repo_branch

    user git_user
    group git_group

    # Need to execute the git command in a wrapper to avoid the "known host" issue.
    ssh_wrapper git_ssh_wrapper
    action :sync
    notifies :reload, 'service[nginx]'
    notifies :restart, 'service[supervisor]'
end

# The location where the app will be checked out (just a link)
link repo_app_dir do
  to app_dir
end

# Generate local settings for web-admin app
template "#{app_dir}/local_settings.py" do
    source 'local_settings.py.erb'
    user git_user
    group git_group
    mode   '0644'
end


# Install g++ package, required by python-geohash
apt_package "g++" do
    action :install
end

# Generate a script that automatically install all python requirements using pip.
# Need to hard code this a bit for now. Will find a way to do this better once I
# know more about the code base. The extra option `--allow-external mysql-connector-python`
# looks weird.
script "Install Requirements" do
    interpreter "bash"
    code <<-EOH
    sudo pip install -r #{app_dir}/requirements.txt \
        --allow-external mysql-connector-python \
        --allow-external python-geohash
    EOH
end
