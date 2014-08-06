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
  ansible-playbook -u root -i event -l 192.168.122.1 site.yml
```

# Docs

* `ansible-doc -l` lists all available modules
* `ansible-doc $module` opens a very helpful knowledge page for a given module
* [Documentation Page](http://docs.ansible.com/)
