c3voc - configuration management
================================

# Installation

To manage hosts with [ansible](http://ansible.com/)  you only need to install `ansible` on your machine.

``` debian
  sudo aptitude install ansible
```


```
  # You can optionally do this inside a virtualenv to avoid polluting your python installation
  pip3 install libkeepass pykeepass

```

# Usage

Syntax validation.

```
  ansible-playbook site.yml -l mixers --syntax-check
```

Basic `ansible` call to deploy new config to a specific host. Passwords will be pulled from keepass.

```
  ./ansible-playbook-keepass site.yml -l mazdermind.lan.c3voc.de
```

_On the first call you will be prompted for the location to your keepass file and password. The keepass file location will be stored in ``.keepass_file_path`` the password obviously not._

Basic `ansible` call to deploy new config to a set of hosts on an event.

```
  ./ansible-playbook-keepass site.yml -l saal1
```

Run ad-hoc commands
```
  ansible -i event/ transcoders -m shell -a "echo hello world"
```

## Keepass Password

The Keepass password will be automatically derived using your GPG-keyring or MacOS Keychain when available. It is recommended that you set up one of these options if you need to do a lot of playbook runs.

To test whether decrypting on-the-fly via GPG works you can do the following:

```
gpg -d <path-to-password-repo>/keepass_password.asc
```

## Keepass Version

If you use ``./ansible-playbook-keepass`` a sanity check verifies that your passwords checkout is recent enough. to update it, make sure the passsword checkout is correct and run ``./update_keepass_version``

# Host notes

## router.lan.c3voc.de

What you need:

* install plain debian
* setting hostname to `router.lan.c3voc.de`
* make sure you have two network interfaces configured with names
  `pbl` (public) and `int` (internal)
* run ansible to deploy config

# TODO

Have a look into `TODO` file.

# Docs

* `ansible-doc -l` lists all available modules
* `ansible-doc $module` opens a very helpful knowledge page for a given module
* [Documentation Page](http://docs.ansible.com/)
