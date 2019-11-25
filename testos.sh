#!/bin/bash

if [[ -e /etc/debian_version ]]; then
      echo "Debian Distribution"
      else
      echo "This is not a Debian Distribution. Only Debian 9 - 10 or Ubuntu 18.04 supported"
fi
VERSION_ID=$(cat /etc/os-release | grep "VERSION_ID")

echo "$VERSION_ID"

if [[ "$VERSION_ID" = 'VERSION_ID="9"' ]] && [[ "$VERSION_ID" = 'VERSION_ID="10"' ]] && [[ "$VERSION_ID" = 'VERSION_ID="18.04"' ]]; then
      echo "OS supported"
      else
      echo "Sorry, your Debian/Ubuntu Version is not supported. Only Debian 9 - 10 or Ubuntu 18.04"
      exit 1
fi
