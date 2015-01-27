import os, json, datetime
from tempfile import mkdtemp
from contextlib import contextmanager

from fabric.operations import put
from fabric.api import (
    env, local, sudo, run, cd, prefix,
    task, settings, execute, runs_once
)
from fabric.colors import green as _green, yellow as _yellow
from fabric.context_managers import hide, show, lcd
import boto
import boto.ec2
from config import Config
import time

# Read global setting from data bag of chef
# this help sync global env for both chef & fabfile
global_deploy_users = json.load(open("chef_files/data_bags/globals/deploy_users.json"))["raw_data"]
global_deploy_groups = json.load(open("chef_files/data_bags/globals/deploy_groups.json"))["raw_data"]
global_webapp_info = json.load(open("chef_files/data_bags/globals/webapp_info.json"))["raw_data"]

# Set default env attributes
# that help run dev env without run
# set env function first, e.g.
# fab dev pull --> fab pull
env.env_name = "dev"

# Static variable settings
POSTGRES_USER = "postgres"
REMOTE_BACKUP_FOLDER = "/backup"
DATABASE_NAME = "django_dev" # TODO: check this later


#----- HELPER FUNCTIONS -------

@contextmanager
def virtualenv():
    """
    Activate Virtual env before doing any task.
    """
    activate_venv = "source /home/{git_user}/venv/bin/activate" \
                        .format(git_user=global_deploy_users[env.env_name])
    with prefix(env.activate):
        yield


@contextmanager
def cdproject():
    """
    Change directory to project dir.
    """
    project_path = "source /home/{git_user}/{app_name}/{app_name}" \
                        .format(git_user=global_deploy_users[env.env_name],
                                app_name=global_webapp_infop["app_name"])
    with cd(project_path):
        yield


def install_chef():
    """
    Install chef-solo on the server.
    """
    print(_yellow("--INSTALLING CHEF--"))
    local("knife solo prepare -i {key_file} {host}".format(key_file=env.key_filename,
                                                           host=env.host_string))


def run_chef(name):
    """
    Read configuration from the appropriate node file and bootstrap
    the node

    :param name:
    :return:
    """
    print(_yellow("--RUNNING CHEF--"))
    node = "./nodes/{name}_node.json".format(name=name)
    with lcd('chef_files'):
        local("knife solo cook -i {key_file} {host} {node}".format(key_file=env.key_filename,
                                                           host=env.host_string,
                                                           node=node))


@task
def dev():
    """
    Set dev env.
    """
    env.env_name = "dev"


@task
def staging():
    """
    Set staging env.
    """
    env.env_name = "staging"


@task
def uat():
    """
    Set uat env.
    """
    env.env_name = "uat"


@task
def prod():
    """
    Set prod env.
    """
    env.env_name = "prod"


def backup_db_simple_postgresql(is_download=True):
    """
    Simple backup db function for postgresql.
    Export db to sql & download file to local
    """
    today = datetime.date.today()
    NAME = '%s-%s.sql' % (DATABASE_NAME, today)
    OUT = '%s/%s' % (REMOTE_BACKUP_FOLDER, NAME)

    # Check folder backup is exist then create
    if not exists(REMOTE_BACKUP_FOLDER):
        sudo('mkdir %s' % REMOTE_BACKUP_FOLDER)

    # Assign permission on backup folder
    sudo('chmod 777 %s' % REMOTE_BACKUP_FOLDER)

    if exists(OUT):
        sudo('rm %s' % OUT)

    sudo('pg_dump %s > %s' % (DATABASE_NAME, OUT), user=POSTGRES_USER)

    if is_download:
        # Assign permission on local folder
        print(green("Start download sql"))
        get(OUT, '/backup/%s' % NAME)


#----- AWS TASKS -------


#----- DEPLOYMENT TASKS -------

@runs_once
@task
def backup_db():
    """
    Backup database.

    Note: This task only do once, make sure there are no
          any duplicated when run deploy on multiple remote servers.
          Backup database is a complex task, base on infrastructure &
          database type, so just provide simple postgress backup here.
    """
    execute(backup_db_simple_postgresql, True)


@runs_once
@task
def migrate():
    """
    Migration database.

    Note: this task only do once, make sure there are no
    any duplicated when run deploy on multiple remote servers
    """
    with virtualenv():
        with cdproject():
            run("python manage.py syncdb --noinput")
            run("python manage.py migrate --noinput")


@runs_once
@task
def collect_statics():
    """
    Collect statics.

    Note: this task only do once, make sure there are no
    any duplicated when run deploy on multiple remote servers
    """
    with virtualenv():
        with cdproject():
            run("python manage.py collectstatic")


@task
def pull(branch_name="develop", commit_id=None):
    """
    Pull code for remote servers.
    Note: assume that we had repo was cloned already

    branch_name The branch want to pull code, default is develope

    commit_id   The commit id want to pull code, default is None
    """
    repos = "/home/{git_user}/repos/webapp" \
                .format(git_user=global_deploy_users[env.env_name])

    with cd(repos):
        try:
            run("git checkout {branch_name}".format(branch_name=branch_name))
        except Exception, e:
            pass

        # Retry current commit id
        if not commit_id:
            run("git pull origin {branch_name}".format(branch_name=branch_name))
        else:
            run("git fetch origin {branch_name}".format(branch_name=branch_name))
            run("git reset --hard %s" % commit_id)


@task
def restart():
    """
    Restart all services on servers.

    Each node (server) own his role, so this task will simple
    delegate this task to server by run a bash script on server.
    This script generated by chef base on roles of node.
    """
    restart_service_path = "/home/{git_user}/restart_services.sh" \
                                .format(git_user=global_deploy_users[env.env_name])

    if exists(restart_service_path):
        sudo(restart_service_path)

