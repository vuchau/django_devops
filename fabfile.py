import os, json, datetime
from tempfile import mkdtemp
from contextlib import contextmanager
from functools import wraps

import fabric.network
import fabric.state
from fabric.operations import put
from fabric.contrib.files import exists
from fabric.api import (
    env, local, sudo, run, cd, prefix,
    task, settings, execute, runs_once
)
from fabric.colors import green as _green, yellow as _yellow, red as _red
from fabric.context_managers import hide, show, lcd
from config import Config
import time

# Read global setting from data bag of chef
# this help sync global env for both chef & fabfile
env.global_deploy_users = json.load(open("chef_files/data_bags/globals/deploy_users.json"))["raw_data"]
env.global_deploy_groups = json.load(open("chef_files/data_bags/globals/deploy_groups.json"))["raw_data"]
env.global_webapp_info = json.load(open("chef_files/data_bags/globals/webapp_info.json"))["raw_data"]

# Set default env attributes
# that help run dev env without run
# set env function first, e.g.
# fab dev pull --> fab pull
env.env_name = "dev"

# Static variable settings
POSTGRES_USER = "postgres"
REMOTE_BACKUP_FOLDER = "/backup"
DATABASE_NAME = "django_dev" # TODO: check this later
CHEF_VERSION = "12.0.3"

# This section used to check if current system support
# YAML or JSON to parse config file
YAML_AVAILABLE = True
try:
    import yaml
except ImportError:
    YAML_AVAILABLE = False


JSON_AVAILABLE = True
try:
    import simplejson as json
except ImportError:
    try:
        import json
    except ImportError:
        JSON_AVAILABLE = False

#----- ENV FUNCTIONS -------
# Source: http://fueledbylemons.com/blog/2011/04/09/server-configs-and-fabric

def _load_config(**kwargs):
    """Find and parse server config file.

    If `config` keyword argument wasn't set look for default
    'server_config.yaml' or 'server_config.json' file.

    """
    config, ext = os.path.splitext(kwargs.get('config',
        'server_config.yaml' if os.path.exists('server_config.yaml') else 'server_config.json'))

    if not os.path.exists(config + ext):
        print _red('Error. "%s" file not found.' % (config + ext))
        return {}
    if YAML_AVAILABLE and ext == '.yaml':
        loader = yaml
    elif JSON_AVAILABLE and ext =='.json':
        loader = json
    else:
        print _red('Parser package not available')
        return {}
    # Open file and deserialize settings.
    with open(config + ext) as config_file:
        return loader.load(config_file)

@task
def s(*args, **kwargs):
    """Set destination servers or server groups by comma delimited list of names"""
    # Load config
    servers = _load_config(**kwargs)
    # If no arguments were recieved, print a message with a list of available configs.
    if not args:
        print 'No server name given. Available configs:'
        for key in servers:
            print _green('\t%s' % key)

    # Create `group` - a dictionary, containing copies of configs for selected servers. Server hosts
    # are used as dictionary keys, which allows us to connect current command destination host with
    # the correct config. This is important, because somewhere along the way fabric messes up the
    # hosts order, so simple list index incrementation won't suffice.
    env.group = {}
    # For each given server name
    for name in args:
        #  Recursive function call to retrieve all server records. If `name` is a group(e.g. `all`)
        # - get it's members, iterate through them and create `group`
        # record. Else, get fields from `name` server record.
        # If requested server is not in the settings dictionary output error message and list all
        # available servers.
        _build_group(name, servers)


    # Copy server hosts from `env.group` keys - this gives us a complete list of unique hosts to
    # operate on. No host is added twice, so we can safely add overlaping groups. Each added host is
    # guaranteed to have a config record in `env.group`.
    env.hosts = env.group.keys()

def _build_group(name, servers):
    """Recursively walk through servers dictionary and search for all server records."""
    # We're going to reference server a lot, so we'd better store it.
    server = servers.get(name, None)
    # If `name` exists in servers dictionary we
    if server:
        # check whether it's a group by looking for `members`
        if isinstance(server, list):
            if fabric.state.output['debug']:
                    puts("%s is a group, getting members" % name)
            for item in server:
                # and call this function for each of them.
                _build_group(item, servers)
        # When, finally, we dig through to the standalone server records, we retrieve
        # configs and store them in `env.group`
        else:
            if fabric.state.output['debug']:
                    puts("%s is a server, filling up env.group" % name)
            env.group[server['host']] = server
    else:
        print _red('Error. "%s" config not found. Run `fab s` to list all available configs' % name)

def _setup(func):
    """
    Copies server config settings from `env.group` dictionary to env variable.

    This way, tasks have easier access to server-specific variables:
        `env.owner` instead of `env.group[env.host]['owner']`

    """
    @wraps(func)
    def func_with_setup(*args, **kwargs):
        # If `s:server` was run before the current command - then we should copy values to
        # `env`. Otherwise, hosts were passed through command line with `fab -H host1,host2
        # command` and we skip.
        if env.get("group", None):
            for key,val in env.group[env.host].items():
                setattr(env, key, val)
                if fabric.state.output['debug']:
                    puts("[env] %s : %s" % (key, val))

        func(*args, **kwargs)
        # Don't keep host connections open, disconnect from each host after each task.
        # Function will be available in fabric 1.0 release.
        # fabric.network.disconnect_all()
    return func_with_setup


#----- HELPER FUNCTIONS -------

@contextmanager
def virtualenv():
    """
    Activate Virtual env before doing any task.
    """
    activate_venv = "source /home/{git_user}/venv/bin/activate" \
                        .format(git_user=env.global_deploy_users[env.env_name])
    with prefix(activate_venv):
        yield


@contextmanager
def cdproject():
    """
    Change directory to project dir.
    """
    project_path = "/home/{git_user}/{app_name}/{app_name}" \
                        .format(git_user=env.global_deploy_users[env.env_name],
                                app_name=env.global_webapp_info["app_name"])
    with cd(project_path):
        yield


@task
@_setup
def install_chef():
    """
    Install chef-solo on the server.
    """
    print(_yellow("--INSTALLING CHEF--"))
    if env.get("key_filename", None):
        local("knife solo prepare -i {key_file} {user}@{host} --bootstrap-version {chef_version}" \
            .format(key_file=env.key_filename,
                user=env.user,
                host=env.host_string,
                chef_version=CHEF_VERSION))
    else:
        local("knife solo prepare {user}@{host} --bootstrap-version {chef_version}" \
            .format(user=env.user,
                host=env.host_string,
                chef_version=CHEF_VERSION))


@task
@_setup
def run_chef():
    """
    Read configuration from the appropriate node file and bootstrap
    the node.
    """
    print(_yellow("--RUNNING CHEF--"))
    node = "./nodes/{name}.json".format(name=env.node)
    with lcd('chef_files'):
        if env.get("key_filename", None):
            local("knife solo cook -i {key_file} {user}@{host} {node}".format(key_file=env.key_filename,
                                                                user=env.user,
                                                                host=env.host_string,
                                                                node=node))
        else:
            local("knife solo cook {user}@{host} {node}".format(user=env.user,
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
        print(_green("Start download sql"))
        get(OUT, '/backup/%s' % NAME)


#----- AWS TASKS -------


#----- DEPLOYMENT TASKS -------

@runs_once
@task
@_setup
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
@_setup
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
@_setup
def collect_statics():
    """
    Collect statics.

    Note: this task only do once, make sure there are no
    any duplicated when run deploy on multiple remote servers
    """
    with virtualenv():
        with cdproject():
            run("python manage.py collectstatic --noinput")


@task
@_setup
def pull(branch_name="develop", commit_id=None):
    """
    Pull code for remote servers.
    Note: assume that we had repo was cloned already

    branch_name The branch want to pull code, default is develope

    commit_id   The commit id want to pull code, default is None
    """
    repos = "/home/{git_user}/repos/webapp" \
                .format(git_user=env.global_deploy_users[env.env_name])

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
@_setup
def restart():
    """
    Restart all services on servers.

    Each node (server) own his role, so this task will simple
    delegate this task to server by run a bash script on server.
    This script generated by chef base on roles of node.
    """
    restart_service_path = "/home/{git_user}/restart_services.sh" \
                                .format(git_user=env.global_deploy_users[env.env_name])

    if exists(restart_service_path):
        sudo(restart_service_path)


@task
@_setup
def deploy(branch_name="develop", commit_id=None):
    """
    Combine others tasks for deployment purpose.
    """
    execute(pull, branch_name, commit_id)
    execute(migrate)
    execute(collect_statics)
    execute(restart)


@task
@_setup
def echo():
    """
    Echo to make sure server is available.
    """
    # Your task goes here
    run('uname -a')
