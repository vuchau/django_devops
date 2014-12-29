include_recipe "sysctl"
include_recipe "postgresql::ruby"
include_recipe "postgresql::client"
include_recipe "postgresql::server"
include_recipe "postgresql::config_pgtune"
include_recipe "database"


# create our application database

postgresql_connection_info = {
    :host      => '127.0.0.1',
    :port      => 5432,
    :username  => 'postgres',
    :password  => node['postgresql']['password']['postgres']
}

database node["postgresql"]["db_name"] do
  connection postgresql_connection_info
  provider   Chef::Provider::Database::Postgresql
  action :create
end

# config_pgtune doesn't bump up the shmmax/shmall, meaning postgres can't be restarted
# without a sysctl call
# code from https://raw.github.com/styx/chef-postgresql/master/recipes/config_pgtune.rb

if node['postgresql'].attribute?('config_pgtune') &&
   node['postgresql']['config_pgtune'].attribute?('tune_sysctl') &&
   node['postgresql']['config_pgtune']['tune_sysctl']

  node.default['sysctl']['kernel']['shmmin'] = 1 * 1024 * 1024 * 1024 # 1 Gb
  node.default['sysctl']['kernel']['shmmax'] = node['memory']['total'].to_i * 1024
  node.default['sysctl']['kernel']['shmall'] = (node['memory']['total'].to_i * 1024 * 0.9 / 4096).floor

  bash "setup values immediately" do
    user 'root'
    group 'root'
    code <<-EOH
      sysctl -w kernel.shmmin=#{node.default['sysctl']['kernel']['shmmin']}
      sysctl -w kernel.shmmax=#{node.default['sysctl']['kernel']['shmmax']}
      sysctl -w kernel.shmall=#{node.default['sysctl']['kernel']['shmall']}
    EOH
  end

end

# restart the cluster to pick up changes
service 'postgresql' do
  supports :restart => true
  action :restart
end