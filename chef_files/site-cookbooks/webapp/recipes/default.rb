git_user = node[:webapp][:deploy_user]
git_group = node[:webapp][:deploy_group]
git_ssh_wrapper = "/home/#{git_user}/git_ssh_wrapper.sh"

# The location where the vitualenv will be located
git_venv = "/home/#{git_user}/venv"

# The location where the app will be checked out.
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
end


user git_user do
    comment "Github Deploy user"
    shell "/bin/bash"
    home "/home/#{git_user}"
    gid git_group
    supports :manage_home => true
    uid   node[:webapp][:deploy_uid]
    action :create
end

# Create a directory to hold the id_rsa file.
directory "/home/#{git_user}/.ssh" do
  owner git_user
  group git_group

  # Only owner can write to this directory
  mode '0755'
  action :create
end

# Makes the id_rsa file for authenticating with github. This key should has already
# been registered with github account.
cookbook_file "/home/#{git_user}/.ssh/id_rsa" do
    source 'id_rsa'
    owner git_user
    group git_group

    # Only owner has read permission to this key
    mode '0400'
    action :create
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

python_virtualenv git_venv do
    owner git_user
    group git_group
    action :create
end
