# Library of Strigo init script snippets


## Suggested practices to write the scripts

### Write elementary script

A script should had a single ability/functionality (support of docker, installation of code_server and some extensions, install nvm, install pyenv+python+poetry).
Then, when creating a new script to initialize a new formation, one should simply concatenate the needed elementary scripts.

### Define optional variables at the beginning of the script

If your script allows some form of customization (version to install, extension names, etc.), one way to ease the integration of a script's code can be:

* to **define some variables at the beginning of the script**, like:

```sh
# code_server_version=3.7.2
# code_server_extensions="ms-azuretools.vscode-docker coenraads.bracket-pair-colorizer-2"
```

* to **write the remainder of the script without any form of customization** (just handling the cases where some variables are not defined, by using default values or skipping instructions), **so that it can be copy-pasted as is**:

```sh
# Install code-server (default values)
code_server_version=${code_server_version:-3.9.2}
curl -fsSLo /tmp/code-server.deb "https://github.com/cdr/code-server/releases/download/v${code_server_version}/code-server_${code_server_version}_amd64.deb"

# [...]

# Install extensions, if any (skips instruction if there are none)
if [[ $code_server_extensions && ${code_server_extensions-_} ]]; then
  code_server_extensions_array=($code_server_extensions)
  for code_server_extension in ${code_server_extensions_array[@]}; do
    sudo -iu ubuntu code-server code-server --install-extension ${code_server_extension}
  done
fi
```

### Tips, how-tos

* use `/home/ubuntu` explicitely instead of `$HOME` because the script is executed with the `root` user (value of `$HOME` is `/root`) whereas the trainees and trainers are connected to their VM as the `ubuntu` user

* create new file with multiline content (`cat << EOF >`):

```sh
cat << EOF > /home/ubuntu/.config/code-server/config.yaml
bind-addr: {{ .STRIGO_RESOURCE_DNS }}:9999
password: '{{ .STRIGO_WORKSPACE_ID }}'
EOF
```

* append multiline content to an existing file (`cat << EOF >>`:

```sh
cat << EOF >> /home/ubuntu/.config/code-server/config.yaml
auth: password
disable-telemetry: true
EOF
```

* append (or create a new file) content to a file **without interpretation of the $... commands** (`cat <<\EOF >`):

```sh
cat <<\EOF >> /home/ubuntu/.bashrc
export PATH="$HOME/.poetry/bin:$PATH"
EOF
```

Without the `\` in front of `EOF`, `$HOME` and `$PATH` would be interpreted before the addition of the content to `~/.bashrc`

* in your final strigo script, make sure to **install docker** (which adds the ubuntu user to the docker group) **before any other service bound to interact with docker**. For example: install `code-server` after `docker` if you plan to use an extension to manage `docker` repositories, images and containers; in this case the ubuntu user is already in the `docker` group when `code-server` is launched (and the extension works properly)

* the log files of the cloud-init capture outputs while the strigo labs VM initializes, so it can help debugging your initialization script following a launch if the instance does not behave the way you intended:

```sh
tail -n 20 /var/log/cloud-init-output.log
tail -n 20 /var/log/cloud-init.log
```

## Code-server customization

The code-server initialization script proposed in [scripts/code-server.sh](scripts/code-server.sh) allows different levels of customization:

* specify the **desired version of `code-server`** by defining the `code_server_version` variable.
Otherwise it installs the latest release

* specify the **extensions you want to install** by defining the `code_server_extensions` variable.
Extension names are separated by the `space` character.
Note: a fix is still necessary (as of version 3.10.2, included) to make the `coenraads.bracket-pair-colorizer-2` extension work with code-server, it is included at the end of the code-server installation script

* preset some **user settings** by defining the `code_server_settings` variable.
It is a JSON string which code-server will use as the [user settings](https://code.visualstudio.com/docs/getstarted/settings).
You can set the dark theme by default (`'{"workbench.colorTheme":"Default Dark+"}'`).
If you want have access (as a trainer and as a trainee) to some command-line tools available for the `ubuntu` system user, you need to **make the code-server terminal a [login shell](https://code.visualstudio.com/docs/editor/integrated-terminal#_configuring-profiles)** so that profile files (`.bashrc` for example) are loaded.
The way to do this has changed across the code-server / vsCode versions:
  * 3.7, 3.8 (and 3.9?) versions: `code_server_settings='{"terminal.integrated.shellArgs.linux": ["-l"]}'`
  * 3.10 versions: `code_server_settings='{"terminal.integrated.defaultProfile.linux":"bash","terminal.integrated.profiles.linux":{"bash":{"path":"bash","args":["-l"]}}}'`
