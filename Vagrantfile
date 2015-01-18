# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"


Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

	# You need to use Vagrant 1.5+
	# This box will be downloaded from vagrant cloud.
	config.vm.box = "precise64"
    config.vm.box_url = "http://files.vagrantup.com/precise64.box"

	config.vm.hostname = "django.local"
	config.vm.network :private_network, ip: "192.168.33.101"

	config.vm.synced_folder "chef_files", "/chef_files"

	# Uncomment this file if you want to sync the actual source code
	# from the host machine for development.
	# config.vm.synced_folder "<your_django_project>", "/home/deploy/webapp_django"

	config.berkshelf.enabled = true
	config.berkshelf.berksfile_path = "chef_files/Berksfile"

	config.vm.provision "chef_solo" do |chef|
		chef.cookbooks_path = ["chef_files/cookbooks", "chef_files/site-cookbooks"]
		chef.environments_path = "chef_files/environments"
		chef.roles_path = "chef_files/roles"
		chef.data_bags_path = "chef_files/data_bags"
		chef.environment = "development"

		# Updates system & install chef-dk software so that we can
		# develop and test chef recipes in this box.
		chef.add_role "vagrant"
		chef.json = {}
	end

	config.vm.provider :virtualbox do |vb|
		# This box requires quite a bit of memory
		vb.customize ["modifyvm", :id, "--memory", "2048"]
	end
end
