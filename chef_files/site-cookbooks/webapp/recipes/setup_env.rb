git_user = node[:webapp][:deploy_user]
git_group = node[:webapp][:deploy_group]

# The location where the vitualenv will be located
git_venv = "/home/#{git_user}/venv"

# The location where the app will be checked out.
app_name = node[:webapp][:app_name]
app_dir = "/home/#{git_user}/#{app_name}"

# When ssh to server, it will auto turn on
# virtual env
script "Update .bashrc" do
    interpreter "bash"
    code <<-EOH
echo 'source /home/#{git_user}/venv/bin/activate' >> /home/#{git_user}/.bashrc
EOH
end
