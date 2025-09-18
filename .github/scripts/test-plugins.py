#!/usr/bin/env python3
import glob
import subprocess
import sys
import os
import json


def try_command(cmd, error):
    return_obj = subprocess.run(cmd, shell=True, check=False)
    print(return_obj)
    if return_obj.returncode != 0:
        print(error)
        sys.exit(1)


def launch_snmp_sim():
    subprocess.run("useradd snmp", shell=True, check=False)
    # We don't want to quit if this fail because it often means the user already exist.

    # This folder is needed to launch snmp plugins".
    try_command(cmd="mkdir -p /var/lib/snmp/cert_indexes/", error="can't create /var/lib/snmp/cert_indexes/ dir")
    try_command(cmd="chown snmp:snmp -R /var/lib/snmp/cert_indexes/", error="can't set cert_indexes folder permissions")

    snmpsim_cmd = "snmpsim-command-responder --logging-method=null --agent-udpv4-endpoint=127.0.0.1:2024 --process-user=snmp --process-group=snmp --data-dir='./tests' &"
    try_command(cmd=snmpsim_cmd, error="Can't launch snmpsim daemon.")


def refresh_packet_manager(archi):
    with open('/var/log/test-plugins-installation.log', "a") as outfile:
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


# Install plugin, from local file if build is true, from repository if false.
def install_plugin(plugin, archi, build):
    with open('/var/log/test-plugins-installation.log', "a") as outfile:
        if archi == "deb":
            if build:
                install_name = "./" + plugin.lower() + "*.deb"
            else:
                install_name = plugin.lower()
            command = "apt-get install -o 'Binary::apt::APT::Keep-Downloaded-Packages=1;' -y " + install_name
            outfile.write(command + "\n")
            output_status = (subprocess.run(command, shell=True, check=False, stderr=subprocess.STDOUT, stdout=outfile)).returncode
        elif archi == "rpm":
            if build:
                install_name = "./" + plugin + "*.rpm"
            else:
                install_name = plugin
            command = "dnf install --setopt=keepcache=True -y " + install_name
            outfile.write(command + "\n")
            output_status = (subprocess.run(command, shell=True, check=False, stderr=subprocess.STDOUT, stdout=outfile)).returncode
        else:
            print(f"Unknown architecture, expected deb or rpm, got {archi}. Exiting.")
            exit(1)
    return output_status


def test_plugin(plugin_command, plugin_paths):
    tests_path = []
    for path in plugin_paths:
        if os.path.exists(f"tests/{path}"):
            tests_path.append("tests/" + path)
    if len(tests_path) == 0:
        with open('/var/log/test-plugins-help.log', "a") as outfile:
            command = "/usr/lib/centreon/plugins/" + plugin_command + " --help"
            output_status = (subprocess.run(command, shell=True, check=False, stderr=subprocess.STDOUT, stdout=outfile)).returncode
            print(f"No tests for {plugin_command}, checking it can be executed with --help")
        if output_status == 3:
            return 0
        else:
            return output_status
    else:
        robot_results = subprocess.run( "robot --exclude notauto -v ''CENTREON_PLUGINS:/usr/lib/centreon/plugins/" + plugin_command + " " + " ".join(tests_path),
                                    shell=True, check=False)
        return robot_results.returncode


def remove_plugin(plugin, archi):
    with open('/var/log/test-plugins-installation.log', "a") as outfile:
        if archi == "deb":
            command = "export SUDO_FORCE_REMOVE=yes; apt-get -o 'Binary::apt::APT::Keep-Downloaded-Packages=1;' autoremove -y " + plugin.lower()
            outfile.write(command + "\n")
            output_status = (subprocess.run(command, shell=True, check=False, stderr=subprocess.STDOUT, stdout=outfile)).returncode
            # -o 'Binary::apt::APT::Keep-Downloaded-Packages=1;' is an option to force apt to keep the package in
            # /var/cache/apt/archives, so it do not re download them for every installation.
            # 'autoremove', contrary to 'remove' all dependancy while removing the original package.

        elif archi == "rpm":
            command = "dnf remove --setopt=protected_packages= --setopt=keepcache=True -y " + plugin
            outfile.write(command + "\n")
            output_status = (subprocess.run(command, shell=True, check=False, stderr=subprocess.STDOUT, stdout=outfile)).returncode
        else:
            print(f"Unknown architecture, expected deb or rpm, got {archi}. Exiting.")
            exit(1)
    # Remove cache files
    tmp_files = glob.glob('/dev/shm/*')
    for file in tmp_files:
        try:
            os.remove(file)
        except Exception as e:
            print(f"Erreur while removing file {file} : {str(e)}")
    return output_status


if __name__ == '__main__':
    print("Starting program")
    if len(sys.argv) < 1:
        print("Please provide architecture (deb or rpm)")
        sys.exit(1)

    launch_snmp_sim()
    archi = sys.argv.pop(1)  # expected either deb or rpm.
    script_name = sys.argv.pop(0)

    nb_plugins = 0
    error_install = 0
    error_tests = 0
    error_purge = 0
    list_plugin_error = set()

    # call apt update (or maybe dnf clean all if needed)
    refresh_packet_manager(archi)

    with open("plugins.json") as plugins_file:
        plugins = json.load(plugins_file)
        for plugin in plugins:
            print("Testing plugin : ", plugin)

            nb_plugins += 1
            tmp = install_plugin(plugin, archi, plugins[plugin]["build"])
            if tmp > 0:
                error_install += 1
                list_plugin_error.add(plugin)
            else:
                if plugins[plugin]["test"]:
                    tmp = test_plugin(plugins[plugin]["command"], plugins[plugin]["paths"])
                    if tmp > 0:
                        error_tests += 1
                        list_plugin_error.add(plugin)
            tmp = remove_plugin(plugin, archi)
            if tmp > 0:
                error_purge += 1
                list_plugin_error.add(plugin)

    print(f"{nb_plugins} plugins tested.\n      there was {error_install} installation error, {error_tests} test "
          f"errors, and {error_purge} removal error list of error : {list_plugin_error}", )

    if error_install != 0 or error_tests != 0 or error_purge != 0:
        exit(1)
    exit(0)
    # the snmpsim daemon is still running when we exit, as this script is mainly run in a docker on CI, it will be
    # cleared up eventually.
    # to clear it up manually, use ps -ax | grep snmpsim-command-respond | cut -dp -f1 | sudo xargs kill
