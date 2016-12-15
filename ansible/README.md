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

Basic `ansible` call to deploy new config to a specific host.

```

  ansible-playbook --ask-pass --ask-become-pass -u voc --become --become-method=su -i event -l mazdermind.lan.c3voc.de site.yml
```

Basic `ansible` call to deploy new config to a set of hosts on an event.

```
  ansible-playbook -u voc --sudo -i event -l saal1 site.yml
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
