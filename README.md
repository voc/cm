# C3VOC central config management repository

## What's in here?

This repository contains all configuration for c3voc systems which are
managed by a config management solution. Due to restructuring, there
are currently (as of 2023-01-08) three config management solutions
which each do different tasks and different systems.

Below you can find a short summary about what each directory does.
Ideally, the authors of the specific solution have added a `README.md`
file inside those directories, too.

## `ansible/`

* Ansible repository.
* Been there since the beginning™.
* Currently only manages systems which are placed in a data center.
* Managed systems will probably get replaced by NixOS machines.

## `bundlewrap/`

* Config management for everything runnning on an event site.
* If you don't know what you need, probably start here.

## `nixos/`

* NixOS configuration
* Everything data center related.

## `common/`

This directory contains configs which are used by atleast two config
management solutions.
