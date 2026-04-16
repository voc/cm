{ secretpath, curl }:
''
  #
  # Deploy a DNS challenge using nsupdate
  #

  set -e
  set -u
  set -o pipefail
  shopt -s nullglob

  action="$1"
  fqdn="$2"
  token="$3"

  # Remove the "_acme-challenge." prefix and trailing dot from the domain name
  fqdn="''${fqdn#"_acme-challenge."}"
  fqdn="''${fqdn%.}"

  case "$action" in
      "present")
          echo " + Adding challenge token to DNS... " + "Domain: $fqdn"
          response="$(${curl}/bin/curl -s --show-error "https://lednsapi.c3voc.de/lednsapi/set" -F "secret=@${secretpath}" -F "domain=$fqdn" -F "token=$token")"
          if [ ! "$response" = "OK" ]; then
              echo "Error deploying tokens:"
              echo "$response"
              exit 1
          fi
          ;;
      "cleanup")
          echo " + Deleting challenge token from DNS... " + "Domain: $fqdn"
          response="$(${curl}/bin/curl -s --show-error "https://lednsapi.c3voc.de/lednsapi/clear" -F "secret=@${secretpath}" -F "domain=$fqdn" -F "token=$token")"
          if [ ! "$response" = "OK" ]; then
              echo "Error deleting tokens:"
              echo "$response"
              exit 1
          fi
          ;;
  esac

''
