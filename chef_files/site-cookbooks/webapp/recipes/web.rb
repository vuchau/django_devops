git_user = node[:webapp][:deploy_user]
git_group = node[:webapp][:deploy_group]

# The location where the vitualenv will be located
git_venv = "/home/#{git_user}/venv"

# The location where the app will be checked out.
app_name = node[:webapp][:app_name]
app_dir = "/home/#{git_user}/#{app_name}"

directory "/home/#{git_user}/logs" do
  owner git_user
  group git_group
  mode '0755'
  action :create
end

# Generate local settings for web-joinwav app
template "/home/#{git_user}/web_run.sh" do
    source 'web_run.sh.erb'
    user git_user
    group git_group
    mode   '0755'
    variables(
        :port => node[:webapp][:port],
        :user => git_user,
        :group => git_group,
        :name => node[:webapp][:app_name],
        :worker => node[:webapp][:workers]
    )
end

# Generate a supervisor service entry and autostart it
supervisor_service "django-web" do
    command "/home/#{git_user}/web_run.sh"
    autostart true
    user 'root'
end

# Generate a site configuration
template "#{node['nginx']['dir']}/sites-available/django-web" do
    source 'nginx.erb'
    owner  'root'
    group  node['root_group']
    mode   '0644'

    variables(
        :domain => node[:webapp][:domain],
        :port => node[:webapp][:port],
        :app_home => app_dir,
        :app_name => node[:webapp][:app_name],
        :env_home => git_venv,
        :http_supported => node[:webapp][:http_supported],
        :https_supported => node[:webapp][:https_supported],
        :https_port => node[:webapp][:https_port],
        :rewrite_domain => node[:webapp][:rewrite_domain]
    )

    # Notifies nginx to reload if the flare definition file changed
    notifies :reload, 'service[nginx]'
end

# Enable the django-web site
nginx_site 'django-web' do
    enable true
end
