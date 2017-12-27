#
# Read config, use env or ask for keepass file
# and store it if entered. 
#
KEEPASS_FILE_CONFIG=".keepass_file_path"
KEEPASS_VERSION_CONFIG=".keepass_version"

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
