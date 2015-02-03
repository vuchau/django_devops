cookbook_path ["cookbooks", "site-cookbooks"]
node_path     "nodes"
role_path     "roles"
data_bag_path "data_bags"

# Uncommend this line if you have encrypted_data_bag_secret file
# and want to use it on remote server
# encrypted_data_bag_secret ".chef/encrypted_data_bag_secret"

knife[:berkshelf_path] = "cookbooks"
