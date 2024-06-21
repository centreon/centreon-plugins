#!/usr/bin/env python3
import glob
import subprocess
import sys
import os
import json


def get_tests_folders(plugin_name):
    folder_list = []
    pkg_file = open("./packaging/" + plugin_name + "/pkg.json")
    packaging = json.load(pkg_file)
    for file in packaging["files"]: # loop on "files" array in pkg.json file.
        if file.endswith("/") and os.path.exists("tests/robot/" + file): # if this is a directory and there is test for it.
            folder_list.append("tests/robot/" + file)
    return folder_list


def get_plugin_full_path(plugin_name):
    pkg_file = open("./packaging/" + plugin_name + "/pkg.json")
    packaging = json.load(pkg_file)
    return "/usr/lib/centreon/plugins/" + packaging["plugin_name"]


def test_plugin(plugin_name):
    folders_list = get_tests_folders(plugin_name)
    print(f"{plugin_name} folders_list : {folders_list}")
    if len(folders_list) == 0:
        return 0  # no tests present at the moment, but we still have tested the plugin can be installed.
    robot_results = subprocess.run("robot --exclude notauto -v ''CENTREON_PLUGINS:" + get_plugin_full_path(plugin_name) + " " + " ".join(folders_list),
                   shell=True, check=False)
    return robot_results.returncode


def try_command(cmd, error):
    return_obj = subprocess.run(cmd, shell=True, check=False)
    print(return_obj)
    if return_obj.returncode != 0:
        print(error)
        sys.exit(1)


def launch_snmp_sim():
    subprocess.run("useradd snmp", shell=True, check=False)
    # we don't want to quit if this fail because it often means the user already exist.

    # this folder seem needed to launch snmp plugins. I didn't reproduce in my env, but without it,
    # the first snmp plugin launched by robot prepend the message "Created directory: /var/lib/snmp/cert_indexes".
    try_command(cmd="mkdir -p /var/lib/snmp/cert_indexes/", error="can't create /var/lib/snmp/cert_indexes/ dir")
    try_command(cmd="chown snmp:snmp -R /var/lib/snmp/cert_indexes/", error="can't set cert_indexes folder permissions")

    snmpsim_cmd = "snmpsim-command-responder --logging-method=null --agent-udpv4-endpoint=127.0.0.1:2024 --process-user=snmp --process-group=snmp --data-dir='./tests/robot' &"
    try_command(cmd=snmpsim_cmd, error="can't launch snmp sim daemon.")

def refresh_packet_manager(archi):
    with open('/var/log/robot-plugins-installation-tests.log', "a") as outfile:
        if archi == "deb":
            outfile.write("apt-get update\n")
            output_status = (subprocess.run(
                    "apt-get update",
                shell=True, check=False, stderr=subprocess.STDOUT, stdout=outfile)).returncode
        elif archi == "rpm":
            return 0
        else:
            print(f"Unknown architecture, expected deb or rpm, got {archi}. Exiting.")
            exit(1)
    return output_status

def install_plugin(plugin, archi):
    with open('/var/log/robot-plugins-installation-tests.log', "a") as outfile:
        if archi == "deb":
            outfile.write("apt-get install -o 'Binary::apt::APT::Keep-Downloaded-Packages=1;' -y ./" + plugin.lower() + "*.deb\n")
            output_status = (subprocess.run(
                    "apt-get install -o 'Binary::apt::APT::Keep-Downloaded-Packages=1;' -y ./" + plugin.lower() + "*.deb",
                shell=True, check=False, stderr=subprocess.STDOUT, stdout=outfile)).returncode
        elif archi == "rpm":
            outfile.write("dnf install -y ./" + plugin + "*.rpm\n")
            output_status = (subprocess.run("dnf install -y ./" + plugin + "*.rpm", shell=True, check=False,
                                        stderr=subprocess.STDOUT, stdout=outfile)).returncode
        else:
            print(f"Unknown architecture, expected deb or rpm, got {archi}. Exiting.")
            exit(1)
    return output_status


def remove_plugin(plugin, archi):
    with open('/var/log/robot-plugins-installation-tests.log', "a") as outfile:
        if archi == "deb":
            outfile.write("apt-get -o 'Binary::apt::APT::Keep-Downloaded-Packages=1;' autoremove -y " + plugin.lower() + "\n")
            output_status = (subprocess.run(
                "apt-get -o 'Binary::apt::APT::Keep-Downloaded-Packages=1;' autoremove -y " + plugin.lower(),
                shell=True, check=False, stderr=subprocess.STDOUT, stdout=outfile)).returncode
            # -o 'Binary::apt::APT::Keep-Downloaded-Packages=1;' is an option to force apt to keep the package in
            # /var/cache/apt/archives, so it do not re download them for every installation.
            # 'autoremove', contrary to 'remove' all dependancy while removing the original package.

        elif archi == "rpm":
            outfile.write("dnf remove -y " + plugin + "\n")
            output_status = (subprocess.run("dnf remove -y " + plugin, shell=True, check=False,
                                            stderr=subprocess.STDOUT, stdout=outfile)).returncode
        else:
            print(f"Unknown architecture, expected deb or rpm, got {archi}. Exiting.")
            exit(1)
    # Remove cache files
    tmp_files = glob.glob('/tmp/cache/*')
    for file in tmp_files:
        try:
            os.remove(file)
        except Exception as e:
            print(f"Erreur while removing file {file} : {str(e)}")
    return output_status


if __name__ == '__main__':
    print("starting program")
    if len(sys.argv) < 2:
        print("please provide architecture (deb or rpm) and list of plugin to test as arguments (one plugin name per "
              "argument, separated by space)")
        sys.exit(1)

    launch_snmp_sim()
    archi = sys.argv.pop(1)  # expected either deb or rpm.
    script_name = sys.argv.pop(0)

    # Create a directory for cache files
    os.mkdir("/tmp/cache")

    error_install = 0
    error_tests = 0
    error_purge = 0
    nb_plugins = 0
    list_plugin_error = []

    # call apt update (or maybe dnf clean all if needed)
    refresh_packet_manager(archi)

    for plugin in sys.argv:
        print("plugin : ", plugin)
        folders_list = get_tests_folders(plugin)
        if len(folders_list) == 0:
            print(f"we don't test {plugin} as it don't have any robots tests.")
            continue

        nb_plugins += 1
        tmp = install_plugin(plugin, archi)
        if tmp > 0:
            list_plugin_error.append(plugin)
        error_install += tmp
        tmp = test_plugin(plugin)
        if tmp > 0:
            list_plugin_error.append(plugin)
        error_tests += tmp
        tmp = remove_plugin(plugin, archi)
        if tmp > 0:
            list_plugin_error.append(plugin)
        error_purge += tmp

    print(f"{nb_plugins} plugins tested.\n      there was {error_install} installation error, {error_tests} test "
          f"errors, and {error_purge} removal error list of error : {list_plugin_error}",)

    if error_install != 0 or error_tests != 0 or error_purge != 0:
        exit(1)
    exit(0)
    # the snmpsim daemon is still runing when we exit, as this script is mainly run in a docker on CI, it will be
    # cleared up eventually.
    # to clear it up manually, use ps -ax | grep snmpsim-command-respond | cut -dp -f1 | sudo xargs kill
