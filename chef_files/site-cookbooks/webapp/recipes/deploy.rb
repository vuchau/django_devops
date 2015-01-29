::Chef::Recipe.send(:include, WebappHelpers)

# Retry global information from databag
git_user = get_git_user()
git_group = get_git_group()
app_name = get_app_name()

git_repo_url = node[:webapp][:repo_url]
git_repo_branch = node[:webapp][:repo_branch]

# The wrapper script that allow the server to checkout
# latest code without being blocked by "knownhosts".
git_ssh_wrapper = "/home/#{git_user}/git_ssh_wrapper.sh"

# The user home directory.
git_user_dir = "/home/#{git_user}"

# this only a location where locate repos
# we will link app to other place
repo_dir = "/home/#{git_user}/repos/webapp"
repo_app_dir = "#{repo_dir}/#{app_name}"
app_dir = "/home/#{git_user}/#{app_name}"

# Makes the id_rsa file for authenticating with github. This key should has already
# been registered with github account.
if node[:webapp][:git_deploy]

	directory "/home/#{git_user}/repos" do
	  owner git_user
	  group git_group
	  mode '0755'
	  action :create
	  not_if { ::File.exists?("/home/#{git_user}/repos")}
	end

	# Create a directory to hold the id_rsa file.
	directory "/home/#{git_user}/.ssh" do
	  owner git_user
	  group git_group

	  # Only owner can write to this directory
	  mode '0755'
	  action :create
	end

	cookbook_file "/home/#{git_user}/.ssh/id_rsa" do
	    source 'id_rsa'
	    owner git_user
	    group git_group

	    # Only owner has read permission to this key
	    mode '0400'
	    action :create
	end
end

# Generate a wrapper to execute git command without
# being asked for confirm github as a known host.
template git_ssh_wrapper do
    source "git_ssh_wrapper.sh.erb"
    owner git_user
    group git_group

    # Only owner can write
    # Others can execute
    mode '0755'

    variables(
        :deploy_user => git_user
    )
end

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
    # TODO: not need reload service here, we will create another bashscript
    # fro ad-hoc task like this one.
    # notifies :reload, 'service[nginx]'
    # notifies :restart, 'service[supervisor]'
end

# TODO: find official way to do this instead of use
# ln command like this, it made recipe is not
# cross os
script "Create django link" do
    interpreter "bash"
    code <<-EOH
    ln -s #{repo_app_dir} #{app_dir}
    EOH
    not_if { ::File.exists?("#{app_dir}")}
end

# Generate a script that automatically install all python requirements using pip.
script "Install Requirements" do
    interpreter "bash"
    code <<-EOH
    #{git_user_dir}/venv/bin/pip install -r #{app_dir}/requirements/#{node.chef_environment}.txt
    EOH
end

# Migrate database
execute "#{git_user_dir}/venv/bin/python manage.py syncdb --noinput" do
  	cwd "#{app_dir}/#{app_name}"
end

execute "#{git_user_dir}/venv/bin/python manage.py migrate --noinput" do
  	cwd "#{app_dir}/#{app_name}"
end
