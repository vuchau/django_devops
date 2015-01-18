# Django DevOps

## Features
 - Generate Django project template (base on two scoops)
 - Django 1.7
 - Celery
 - Redis (cache + queue)
 - Postgres
 - Chef
 - Vagrant
 - AWS deployment


## Constraints
 - python (> 2.7)
 - pip
 - vagrant
 - ruby (gem)
 - xcode command line (Mac OS users)
 - chef-dk (https://downloads.chef.io/chef-dk/)


## Usage

### Init project structure

	mkdir <project_name> && cd <project_name>
    curl https://raw.githubusercontent.com/thuongdinh/django_devops/v0.1.3/django_devops.sh | bash
    cookiecutter https://github.com/thuongdinh/cookiecutter-django-tastypie.git

### Install needed gem

	bundle

### Update chef configuration

Update chef configuration inside chef-files/roles if needed

### Vagrant up

	vagrant up
	vagrant ssh


## Deployment

// TODO


## Troubleshooting

1. Could not determine Berks version

	Install chefdk
	export PATH=/opt/chefdk/bin:$PATH #/opt/chefdk/bin needs to be present before your RBENV bits.
