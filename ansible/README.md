c3voc - configuration management
================================

# Installation

To manage hosts with [ansible](http://ansible.com/)  you only need to install `ansible` on your machine.

``` debian
  sudo aptitude install ansible
```

# Usage

Syntax validation.

```
  ansible-playbook -i event -l mixers site.yml --syntax-check
```

Basic `ansible` call to deploy new config to a specific host. Passwords will be pulled from keepass.

```
  ./ansible-playbook-keepass --ask-pass --ask-become-pass -u voc --become --become-method=su -i event -l mazdermind.lan.c3voc.de site.yml
```

_On the first call you will be prompted for the location to your keepass file and password. The keepass file location will be stored in ``.keepass_file_path`` the password obviously not._

Basic `ansible` call to deploy new config to a set of hosts on an event.

```
  ./ansible-playbook-keepass -u voc --sudo -i event -l saal1 site.yml
```

## Keepass Password

In case you need to do a lot of playbook runs you can also set the password using the following although it is not recommended.

```
  export KEEPASS_PW='…'
  ./ansible-playbook-keepass … site.yml
```

# Host notes

## router.lan.c3voc.de

What you need:

* install plain debian
* setting hostname to `router.lan.c3voc.de`
* make sure you have two network interfaces configured with names
  `pbl` (public) and `int` (internal)
* run ansible to deploy config

## monitoring.lan.c3voc.de

You have to name the monitoring host `monitoring.lan.c3voc.de`. After
deployment, you have to run `check_mk -I && check_mk -O` inventory each host.

# TODO

Have a look into `TODO` file.

# Docs

* `ansible-doc -l` lists all available modules
* `ansible-doc $module` opens a very helpful knowledge page for a given module
* [Documentation Page](http://docs.ansible.com/)
