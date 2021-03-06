# Django DevOps

## Features
 - Generate Django project template (base on two scoops)
 - Django 1.7
 - Celery
 - Redis (cache + queue)
 - Postgresql
 - Chef
 - Vagrant
 - Server deployment (fabric)


## Constraints
 - python (> 2.7)
 - [pip](https://pip.pypa.io/en/latest/installing.html)
 - vagrant
 - ruby (gem)
 - xcode command line (Mac OS users)
 - [chef-dk](https://downloads.chef.io/chef-dk/)


## Usage

### Init project structure

	mkdir <project_name> && cd <project_name>
    curl https://raw.githubusercontent.com/thuongdinh/django_devops/v0.1.5/django_devops.sh | bash
    cookiecutter https://github.com/thuongdinh/cookiecutter-django-tastypie.git # type your project information

### Install needed gem

	gem install bundler
	bundle install

### Update system configuration

Update chef configuration inside chef-files if needed, including:
	
1. **update app_name attribute**: chef_files/data_bags/globals/webapp_info.json (note: app_name must be equal with your current django folder that's be create use **cookiecutter** above)
2. **create new envs folder**: create new env forlder inside chef_files/data_bags & add databag item for any env attribute, pls refer to folder dev_envs for example


### Development env with Vagrant

	vagrant up
	vagrant ssh

## Security with encrypted_data_bag

1. Create secrect key: openssl rand -base64 512 > ~/.chef/encrypted_data_bag_secret
2. For development env (vagrant) add line chef.encrypted_data_bag_secret_key_path = "~/.chef/encrypted_data_bag_secret" between line 28 & 41 to Vagrantfile
3. Create your databag item file (json format) e.g. file at ~/.chef/aws_key.json with content
	{ "id":"aws_access_key", "KEY":"AWS_ACCESS_KEY_ID", "VALUE":"AWS_ACCESS_KEY_ID_VALUE"}
	Note: this file should not be commited to git. id should be your databag item name we will create step #4
4. Create encrypted databag item file: EDITOR=vi knife solo data bag create dev_envs aws_access_key --json-file ~/.chef/aws_key.json --secret-file ~/.chef/encrypted_data_bag_secret
	After this step, you will see a json file inside data_bags/dev_envs with encrypted content
5. Let's set value of webapp => databag => encrypted attribute to true (inside your environment file), so chef know should read this data_bag with encrypted method
6. For deployment, please refer to commends from line 24 to 26 in fabfile.py & line 6 to 8 in chef_files/.chef/knife.rb

## Deployment

1. Make sure you workstation can connect to remote servers
	a. Use key pem: add path to key pem file to each env func in fabfile (staging, prod, uat), ```env.key_filename = <your path> ```
	b. Add your public rsa key to server 
2. Create server_config.json file, add server addresses, role to each & create group of servers want to deploy, below is format

	{
		"django-chef-example": {
	      	"host": "104.236.238.102",
	      	"user": "root",
	      	"node": "allin"
	  	},
	  	"dev_servers": ["django-chef-example"]
	}
3. Init environemnts files, includes requirements.txt & django config.
	e.g. If you want deploy **staging** env, create staging.py file inside django_project/config folder & create staging.txt inside requirements
3. Init servers with command

	```
	fab <env> s:<group> init_node
	```

	with **env** is your env (staging, dev, prod, uat), and group is name of group server e.g. dev_servers
	This command will install chef, copy needed files & cook nodes. Servers will be ready after this command

4. For next time deployment, run command: ```fab <env> s:<group> deploy```

Use ```fab --list``` to see list of commands can be used.


## Folder structure

### Local Repository

1. **chef-files**: contains chef configuration + cookbooks
2. **backup**: contains backup files (excluse all file in this folder)
3. **fabfile.py**: deployment scripts
4. **Vagrantfile**: vagrant configuration
5. **app_name**: django project you created with cookiecutter command
6. **requirements.txt**: needed tools for init project 

### Remote Server

Assume **ubuntu** is your deploy user

1. **/home/ubuntu/repos/webapp**: git repository of project
2. **/home/ubuntu/bin**: helpers bash script
3. **/home/ubuntu/<app_name>**: django project folder (this is a link created from source path /home/ubuntu/repos/webapp/<app_name>)
4. **/home/ubuntu/celery_run.sh**: bash script allow to run celery command (if you want to use this command on server, make sure current pointer located at /home/ubuntu/<app_name>/<app_name> path)
5. **/home/ubuntu/web_run.sh**: bash script allow to run gunicorn web command
6. **/home/ubuntu/logs**: contains all log files, including celery & web


## Troubleshooting

1. Could not determine Berks version

	Install chefdk
	export PATH=/opt/chefdk/bin:$PATH #/opt/chefdk/bin needs to be present before your RBENV bits.		
