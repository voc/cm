#!/usr/bin/env python3

import os
import sys
from json import dump, load
from traceback import print_exc


def replace_credentials(credentials, database):
    for key, value in credentials.get("userconfig", {}).items():
        database["userconfig"][key] = value

    for instance, config in credentials.get("instance", {}).items():
        for instance_identifier in database["instance"]:
            if (
                database["instance"][instance_identifier]["instance_type"]
                == config["instance_type"]
            ):
                for key, value in config.items():
                    database["instance"][instance_identifier][key] = value
    return database


def main():
    companion_home = "/var/opt/bitfocus-companion/"
    credentialfile = "/var/opt/bitfocus-companion/passwords.json"

    with open(credentialfile, "r") as credfile:
        credentials = load(credfile)

    for filename in os.listdir(companion_home):
        print(f"working on directory '{filename}'")
        try:
            with open(os.path.join(companion_home, filename, "db"), "r") as db:
                companion_database = load(db)
        except NotADirectoryError:
            print("not a directory potentially containing a database")
            continue
        except FileNotFoundError:
            print("no database found in this directory")
            continue
        except Exception:
            print_exc(file=sys.stdout)
            continue


        new_database = replace_credentials(credentials, companion_database)
        with open(
            os.path.join(companion_home, filename, "db.tmp"), "w"
        ) as new_db:
            dump(new_database, new_db)
        os.replace(
            os.path.join(companion_home, filename, "db"),
            os.path.join(companion_home, filename, "db.bak"),
        )
        os.replace(
            os.path.join(companion_home, filename, "db.tmp"),
            os.path.join(companion_home, filename, "db"),
        )
        print(
            f"Credentials updated in {os.path.join(companion_home, filename, 'db')}"
        )


if __name__ == "__main__":
    main()