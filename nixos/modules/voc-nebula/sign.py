#!/usr/bin/env python3
# signs nebula certs and manages them in sops encrypted files
import os
import subprocess
import argparse
import sys
import json
from contextlib import contextmanager


def main():
    parser = argparse.ArgumentParser(
        description="sign certificates using cfssl and stores them in encrypted files using sops"
    )
    parser.add_argument(
        "--hosts", type=str, help="path to hosts json file", default="hosts.json"
    )
    parser.add_argument("--name", type=str, help="sign only cert with this name")
    parser.add_argument(
        "--force", action="store_true", help="force overwriting existing certs"
    )
    args = parser.parse_args()

    hosts = []
    with open(args.hosts) as f:
        hosts = json.load(f)

    if not args.force:
        print("Not replacing existing certs, use --force to overwrite")

    secrets = read_secret("secrets.yaml")
    ca_cert = secrets["ca"]["cert"]
    ca_key = secrets["ca"]["key"]
    changed = False
    for host in hosts:
        if "name" not in host:
            print("Skipping host without name")
            continue
        if "ip" not in host:
            print(f"Skipping {host['name']}, no ip defined")
            continue
        if "groups" not in host:
            host["groups"] = []
        if args.name and host["name"] != args.name:
            continue
        if host["name"] in secrets and not args.force:
            continue
        print(f"Signing cert for {host['name']}")
        res = nebula_sign_cert(host, ca_cert, ca_key)
        secrets[host["name"]] = res
        changed = True
    if changed:
        write_secret("secrets.yaml", secrets)
    print("All certs up to date.")


# sign a nebula cert for the given host
def nebula_sign_cert(host: dict, ca_cert: str, ca_key: str) -> dict:
    cert = ""
    key = ""
    with nebula_ca(ca_key, ca_cert):
        subprocess.check_output(
            [
                "nebula-cert",
                "sign",
                "-name",
                host["name"],
                "-ip",
                host["ip"],
                "-out-crt",
                "tmp.crt",
                "-out-key",
                "tmp.key",
                "-groups",
                ",".join(host["groups"]),
            ]
        )
    with open("tmp.crt") as f:
        cert = f.read()
    os.remove("tmp.crt")
    with open("tmp.key") as f:
        key = f.read()
    os.remove("tmp.key")
    return {"cert": cert, "key": key}


# manage temporary ca files
@contextmanager
def nebula_ca(key=str, cert=str):
    try:
        with open("ca.key", "w+t") as f:
            f.write(key)
        with open("ca.crt", "w+t") as f:
            f.write(cert)
        yield
    finally:
        os.remove("ca.key")
        os.remove("ca.crt")


# read sops secret from file
def read_secret(path: str) -> dict:
    output = subprocess.check_output(
        ["sops", "--decrypt", "--output-type", "json", path]
    )
    return json.loads(output)


# write sops secret to file
def write_secret(path: str, data: dict):
    tmp_path = os.path.basename(path)
    cmd = [
        "sops",
        "--encrypt",
        "--input-type",
        "json",
        "--output-type",
        "yml",
        "--output",
        tmp_path,
        "--filename-override",
        tmp_path,
        "/dev/stdin",
    ]

    # Create a subprocess
    proc = subprocess.Popen(
        cmd,
        stdin=subprocess.PIPE,
        text=True,
    )

    # Write to stdin
    proc.stdin.write(json.dumps(data))
    proc.stdin.flush()
    proc.stdin.close()
    proc.wait()
    if proc.returncode != 0:
        try:
            os.remove(tmp_path)
        except OSError:
            pass
        sys.exit(f"Failed to write secret to {path}")
    os.replace(tmp_path, path)


if __name__ == "__main__":
    main()
