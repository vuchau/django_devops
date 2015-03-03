name "postgresql"
description "Postgresql Database"

if node[:databag][:encrypted]
	db_info = Chef::EncryptedDataBagItem.load("secrets", "database")
else
	db_info = data_bag_item("secrets", "database")
end

postgres_pass = db_info["POSTGRES_PASS"]
db_name = db_info["DATABASE_NAME"]
db_user = db_info["DATABASE_USER"]
db_pass = db_info["DATABASE_PASS"]

override_attributes(
	:postgresql => {
		:config => {"listen_addresses" => '*'},
		:config_pgtune => {:db_type => "web",
			               :tune_sysctl => true},
		:password => {"postgres" => postgres_pass},
		:db_name => db_name,
		:pg_hba => [{
			:comment => '# EC2 internal access',
			:type => 'host',
			:db => 'all',
			:user => 'postgres',
			:addr => "0.0.0.0/0",
			:method => 'md5'
		}]
	},
	"build_essential" => {"compiletime" => true},
	:sysctl => {:conf_dir => "/etc/sysctl.d",
		:allow_sysctl_conf=>true}
)

run_list(
  "recipe[webapp::database]"
)
