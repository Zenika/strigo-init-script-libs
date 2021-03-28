#!/bin/bash

# failfast
set -e

# Define these 2 variables if you want to customize the default installation,
# then copy-paste the remainder of the script:
# - the version of code-server to install
# code_server_version=3.7.2
# - the code-server extensions to install (space-separated names)
# code_server_extensions="ms-azuretools.vscode-docker coenraads.bracket-pair-colorizer-2"

# https://github.com/cdr/code-server/blob/master/doc/install.md#debian-ubuntu

apt-get install -y curl

# Install code-server
apt-get install -y curl
code_server_version=${code_server_version-3.9.2}
curl -fsSLo /tmp/code-server.deb "https://github.com/cdr/code-server/releases/download/v${code_server_version}/code-server_${code_server_version}_amd64.deb"
apt-get install -y /tmp/code-server.deb

# Setup code-server
mkdir --parent /home/ubuntu/.config/code-server/
cat << EOF > /home/ubuntu/.config/code-server/config.yaml
bind-addr: {{ .STRIGO_RESOURCE_DNS }}:9999
auth: password
password: '{{ .STRIGO_WORKSPACE_ID }}'
disable-telemetry: true
EOF
chown -R ubuntu: /home/ubuntu/.config/

# Enable and start code-server
systemctl enable --now code-server@ubuntu

# Display code-server password in terminal
cat <<\EOF > /etc/profile.d/code-server-password.sh
if [ $USER = ubuntu ]; then
  echo -ne '\nCode-server '
  grep '^password:' ~/.config/code-server/config.yaml
  echo
fi
EOF

# Install extensions, if any
if [[ $code_server_extensions && ${code_server_extensions-_} ]]; then
  code_server_extensions_array=($code_server_extensions)
  for code_server_extension in ${code_server_extensions_array[@]}; do
    sudo -iu ubuntu code-server code-server --install-extension ${code_server_extension}
  done
fi