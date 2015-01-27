# Retry global information from databag
globals_deploy_users = data_bag_item("globals", "deploy_users")
globals_deploy_groups = data_bag_item("globals", "deploy_groups")
globals_webapp_info = data_bag_item("globals", "webapp_info")

git_user = globals_deploy_users[node.chef_environment]
git_group = globals_deploy_groups[node.chef_environment]
git_ssh_wrapper = "/home/#{git_user}/git_ssh_wrapper.sh"

# The location where the vitualenv will be located
git_venv = "/home/#{git_user}/venv"

# The location where the app will be checked out.
app_name = globals_webapp_info["app_name"]
app_dir = "/home/#{git_user}/#{app_name}"

# Install git package for code checkout
package 'git' do
    action :install
end

# Create the group & user for git deployment
# The user will take care of checking out latest code from github
# and deploy to a local repository.
group git_group do
    action :create
    not_if { ::File.exists?("/home/#{git_user}")}
end

user git_user do
    comment "Github Deploy user"
    shell "/bin/bash"
    home "/home/#{git_user}"
    gid git_group
    supports :manage_home => true
    uid   node[:webapp][:deploy_uid]
    action :create
    not_if { ::File.exists?("/home/#{git_user}")}
end

python_virtualenv git_venv do
    owner git_user
    group git_group
    action :create
    not_if { ::File.exists?("/home/#{git_user}/venv")}
end
