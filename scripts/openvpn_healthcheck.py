#!/usr/bin/env python
import os
import sys
import time
import datetime
import subprocess

fping_path = 'fping'
fping_urls = ['ftp.sunet.se', 'google.se']
openvpn_interface_name = 'openvpn'
openvpn_pid_file = '/var/run/openvpn/openvpn.pid'
sleep_time = 120

def printer(msg):
    now = datetime.datetime.fromtimestamp(time.time()).strftime('%Y-%m-%d %H:%M:%S')
    msg = '[%s] %s' % (now, msg)
    print msg

def run_command(command):
    p = subprocess.Popen(command, shell = False, stdout = subprocess.PIPE, stderr = subprocess.PIPE)
    p_stdout, p_stderr = p.communicate()
    p_exit_code = p.returncode
    return p_stdout, p_stderr, p_exit_code

def check_connection():
    conn_alive = False
    for url in fping_urls:
        if not openvpn_interface_name:
            cmd = [fping_path, '-C', '1', '-q', url]
        else:
            cmd = [fping_path, '-C', '1', '-q', '-I', openvpn_interface_name, url]
        stdout, stderr, exit_code = run_command(cmd)
        if exit_code == 0:
            conn_alive = True
            break
        else:
            printer("error: fping failed to %s" % (url))

    return conn_alive

def kill_openvpn():
    openvpn_running = False
    openvpn_pid = ""
    if os.path.isfile(openvpn_pid_file):
        with open(openvpn_pid_file, 'r') as f:
            openvpn_pid = f.readline().strip()

    if openvpn_pid.isdigit():
        try:
            os.kill(int(openvpn_pid), 9)
        except OSError:
            openvpn_running = False
        else:
            openvpn_running = True

    if openvpn_running:
        return True
    else:
        return False

def main():
    # check if we can connect to the world from openvpn interface
    conn_alive =  check_connection()
    if not conn_alive:
        # kill openvpn if not alive, so it restarts
        kill_openvpn()

if __name__ == '__main__':
    while True:
        time.sleep(sleep_time)
        main()
