#!/usr/bin/env python
#######################################################
# Prey Trigger - (c) 2011 Fork Ltd.
# Written by Tomas Pollak <tomas@forkhq.com>
# Licensed under the GPLv3
#######################################################

import os
import subprocess
from datetime import datetime, timedelta
import gobject
import dbus
from dbus.mainloop.glib import DBusGMainLoop

prey_command = "/usr/share/prey/prey.sh -i"
prey_output = open("/var/log/prey.log", 'wb')
min_interval = 2

#######################
# helpers
#######################

def connected():
    return nm_interface.state() == 3

# only for testing purposes
def alert(message):
    os.system("echo '" + message + "' | espeak")

def run_prey():
    global run_at
    alert("Should we run Prey?")
    two_minutes = timedelta(minutes=min_interval)
    now = datetime.now()
    if (run_at is None) or (now - run_at > two_minutes):
        alert("Running Prey")
        subprocess.Popen(prey_command.split(), stdout=prey_output, stderr=prey_output, shell=True)
        run_at = datetime.now()

#######################
# event handlers
#######################

def network_state_changed(*args):
    alert("Network change detected")
    if connected():
        run_prey()

def device_now_active(*args):
    alert("Device now active")
    if connected():
        run_prey()

def system_resumed(*args):
    alert("System resumed")
    run_prey()

#######################
# main
#######################

if __name__ == '__main__':

    alert("Initializing")
    run_at = None
    run_prey()

    # Setup message bus.
    bus = dbus.SystemBus(mainloop=DBusGMainLoop())

    # Connect so StateChanged signal from NetworkManager
    nm = bus.get_object('org.freedesktop.NetworkManager', '/org/freedesktop/NetworkManager')
    nm_interface = dbus.Interface(nm, 'org.freedesktop.NetworkManager')
    nm_interface.connect_to_signal('StateChanged', network_state_changed)

    # upower = bus.get_object('org.freedesktop.UPower', '/org/freedesktop/UPower')
    # if upower.CanSuspend:
    # upower.connect_to_signal('Resuming', system_resumed, dbus_interface='org.freedesktop.UPower')

    loop = gobject.MainLoop()
    loop.run()
