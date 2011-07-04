#!/usr/bin/env python
#######################################################
# Prey Trigger - (c) 2011 Fork Ltd.
# Written by Tomas Pollak <tomas@forkhq.com>
# Licensed under the GPLv3
#######################################################

import os
import sys
import subprocess
import gobject
import dbus
from datetime import datetime, timedelta
from dbus.mainloop.glib import DBusGMainLoop

min_interval = 2 # minutes
log_file = "/var/log/prey.log"
prey_command = "/usr/share/prey/prey.sh"

try:
   log_output = open(log_file, 'wb')
except IOError:
   print "No write access to log file: " + log_file + ". Prey log will go to /dev/null!"
   log_output = open('/dev/null', 'w')

#######################
# helpers
#######################

def connected():
    return nm_interface.state() == 3

# only for testing purposes
def log(message):
    if sys.argv[1] and sys.argv[1] == '--debug':
        os.system("echo '" + message + "' | espeak 2> /dev/null")

def run_prey():
    global run_at
    two_minutes = timedelta(minutes=min_interval)
    now = datetime.now()
    log("Should we run Prey?")
    if (run_at is None) or (now - run_at > two_minutes):
        log("Running Prey!")
        subprocess.Popen(prey_command, stdout=log_output, stderr=subprocess.STDOUT, shell=True)
        run_at = datetime.now()

#######################
# event handlers
#######################

def network_state_changed(*args):
    log("Network change detected")
    if connected():
        run_prey()

#def system_resumed(*args):
#    alert("System resumed")
#    run_prey()

#######################
# main
#######################

if __name__ == '__main__':

    log("Initializing")
    run_at = None
    run_prey()

    # Setup message bus.
    bus = dbus.SystemBus(mainloop=DBusGMainLoop())

    # Connect so StateChanged signal from NetworkManager
    try:
        nm = bus.get_object('org.freedesktop.NetworkManager', '/org/freedesktop/NetworkManager')
        nm_interface = dbus.Interface(nm, 'org.freedesktop.NetworkManager')
        nm_interface.connect_to_signal('StateChanged', network_state_changed)
    except dbus.exceptions.DBusException:
        print "NetworkManager DBus interface not found! Please make sure NM is installed."
        sys.exit(1)

    # upower = bus.get_object('org.freedesktop.UPower', '/org/freedesktop/UPower')
    # if upower.CanSuspend:
    # upower.connect_to_signal('Resuming', system_resumed, dbus_interface='org.freedesktop.UPower')

    loop = gobject.MainLoop()
    loop.run()
