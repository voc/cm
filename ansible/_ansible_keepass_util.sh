#
# Read config, use env or ask for keepass file
# and store it if entered. 
#
KEEPASS_FILE_CONFIG=".keepass_file_path"
KEEPASS_VERSION_CONFIG=".keepass_version"

set_keepass_dir() {
    if [ -z "${KEEPASS}" -a -r "${KEEPASS_FILE_CONFIG}" ]; then
      KEEPASS=`cat ${KEEPASS_FILE_CONFIG} | xargs`

      # If the path is empty or does not exist, delete the conf
      if [ -z "${KEEPASS}" -o ! -f "${KEEPASS}" -o ! -r "${KEEPASS}" ]; then
        echo "Stored keepass path '${KEEPASS}' is not readable file,"\
             "deleting configuration file"
        rm "${KEEPASS_FILE_CONFIG}"
        unset KEEPASS
      fi
    fi

    if [ -z "${KEEPASS}" ]; then
      echo -n "Keepass file path (…voc.kdbx): "
      read -r KEEPASS
    fi

    KEEPASS_DIR=$(dirname "${KEEPASS}")
    if [ -f "${KEEPASS_VERSION_CONFIG}" ]; then
      KEEPASS_REQUIRED_VERSION=$(cat "${KEEPASS_VERSION_CONFIG}")
      ( cd "${KEEPASS_DIR}"; git merge-base --is-ancestor $KEEPASS_REQUIRED_VERSION HEAD )

      if [ $? -ne 0 ]; then
        echo "keepass checkout must be newer or equal to ${KEEPASS_REQUIRED_VERSION}, which it isn't"
        echo "do a git pull before continuing"

        exit 1
      fi
    fi
}

ask_keepass_password() {
    #
    # Check if keepass file exists
    #
    if [ -z "${KEEPASS_FILE_CONFIG}" -o ! -f "${KEEPASS}" -o ! -r "${KEEPASS}" ]; then
      >&2 echo "Keepass file '${KEEPASS}' not a readable file, exit"
      exit 1
    else
      # If the file seems to exist, store it
      echo "${KEEPASS}" > "${KEEPASS_FILE_CONFIG}"
    fi

    #
    # Try to decrypt keepass password on-the-fly using GPG-keyring
    #
    if [ -z "${KEEPASS_PW}" ]; then
      KEEPASS_PW=`gpg -d "${KEEPASS_DIR}/keepass_password.asc" 2> /dev/null`
    fi

    #
    # Ask for the keepass file, query keychain or use the env var
    #
    if [ -z "${KEEPASS_PW}" ]; then
      if [[ "$OSTYPE" == "darwin"* ]]; then
        KEEPASS_PW=`security find-generic-password  -w -a "${KEEPASS}"`
      else
        echo -n "Keepass Password (or export KEEPASS_PW): "
        read -ers KEEPASS_PW
      fi
      echo ""
    fi

    if [ -z "${KEEPASS_PW}" ]; then
      >&2 echo "password is empty, exit"
      exit 1
    fi
}
