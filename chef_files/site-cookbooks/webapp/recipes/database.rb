include_recipe "sysctl"
include_recipe "sysctl::default"
include_recipe "postgresql::ruby"
include_recipe "postgresql::client"
include_recipe "postgresql::server"
include_recipe "postgresql::config_pgtune"
include_recipe "database"
include_recipe "database::postgresql"


template ("/etc/postgresql/#{node['postgresql']['version']}/main/pg_hba.conf") do
  source 'pg_hba.conf.erb'
  owner 'postgres'
end

service 'postgresql' do
  action :restart
end

# create our application database
conn_info = {
    :host      => '127.0.0.1',
    :port      => 5432,
    :username  => 'postgres',
    :password  => node['postgresql']['password']['postgres']
}

postgresql_database_user node["webapp"]["db_user"] do
  connection conn_info
  password node["webapp"]["db_password"]
  action :create
  not_if { `sudo -u postgres psql -tAc \"SELECT * FROM pg_roles WHERE rolname='#{node['webapp']['db_user']}'\" | wc -l`.chomp == "1" }
end

postgresql_database node["webapp"]["db_name"] do
  connection conn_info
  action :create
  not_if { `sudo -u postgres psql -tAc \"SELECT * FROM pg_database WHERE datname='#{node['postgresql']['db_name']}'\" | wc -l`.chomp == "1" }
end

postgresql_database_user node["webapp"]["db_user"] do
  connection conn_info
  database_name node["webapp"]["db_name"]
  privileges [:all]
  action :grant
  not_if { `sudo -u postgres psql -tAc \"SELECT * FROM pg_database WHERE datname='#{node['postgresql']['db_name']}'\" | wc -l`.chomp == "1" }
end

# config_pgtune doesn't bump up the shmmax/shmall, meaning postgres can't be restarted
# without a sysctl call
# code from https://raw.github.com/styx/chef-postgresql/master/recipes/config_pgtune.rb
if node['postgresql'].attribute?('config_pgtune') &&
   node['postgresql']['config_pgtune'].attribute?('tune_sysctl') &&
   node['postgresql']['config_pgtune']['tune_sysctl']

  node.default['sysctl']['kernel']['shmmax'] = node['memory']['total'].to_i * 1024
  node.default['sysctl']['kernel']['shmall'] = (node['memory']['total'].to_i * 1024 * 0.9 / 4096).floor

  bash "setup values immediately" do
    user 'root'
    group 'root'
    code <<-EOH
      sysctl -w kernel.shmmax=#{node.default['sysctl']['kernel']['shmmax']}
      sysctl -w kernel.shmall=#{node.default['sysctl']['kernel']['shmall']}
    EOH
  end

  # Append kernel.shmmax & shmall to config file
  template "/etc/sysctl.conf" do
  	user 'root'
	  source "sysctl.conf.erb"
	  mode   '0644'
	  variables(
        :shmmax => node.default['sysctl']['kernel']['shmmax'],
        :shmall => node.default['sysctl']['kernel']['shmall']
    )
	end

end

# restart the cluster to pick up changes
service 'postgresql' do
  supports :restart => true
  action :restart
end
