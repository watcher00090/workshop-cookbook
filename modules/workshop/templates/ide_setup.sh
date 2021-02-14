#!/bin/bash
mkdir /home/ubuntu/ide
mkdir /home/ubuntu/workshop
git clone ${workshop_url} /home/ubuntu/workshop
cd ide
echo '{
  "private": true,
  "dependencies": {
    "@theia/callhierarchy": "next",
    "@theia/file-search": "next",
    "@theia/git": "next",
    "@theia/markers": "next",
    "@theia/messages": "next",
    "@theia/mini-browser": "next",
    "@theia/navigator": "next",
    "@theia/outline-view": "next",
    "@theia/plugin-ext-vscode": "next",
    "@theia/preferences": "next",
    "@theia/preview": "next",
    "@theia/search-in-workspace": "next",
    "@theia/terminal": "next"
  },
  "devDependencies": {
    "@theia/cli": "next"
  },
  "scripts": {
    "prepare": "yarn run clean && yarn build && yarn run download:plugins",
    "clean": "theia clean",
    "build": "theia build --mode development",
    "start": "theia start --plugins=local-dir:plugins",
    "download:plugins": "theia download:plugins"
  },
  "theiaPluginsDir": "plugins",
  "theiaPlugins": {
    "vscode-builtin-css": "https://github.com/theia-ide/vscode-builtin-extensions/releases/download/v1.39.1-prel/css-1.39.1-prel.vsix",
    "vscode-builtin-html": "https://github.com/theia-ide/vscode-builtin-extensions/releases/download/v1.39.1-prel/html-1.39.1-prel.vsix",
    "vscode-builtin-javascript": "https://github.com/theia-ide/vscode-builtin-extensions/releases/download/v1.39.1-prel/javascript-1.39.1-prel.vsix",
    "vscode-builtin-json": "https://github.com/theia-ide/vscode-builtin-extensions/releases/download/v1.39.1-prel/json-1.39.1-prel.vsix",
    "vscode-builtin-markdown": "https://github.com/theia-ide/vscode-builtin-extensions/releases/download/v1.39.1-prel/markdown-1.39.1-prel.vsix",
    "vscode-builtin-npm": "https://github.com/theia-ide/vscode-builtin-extensions/releases/download/v1.39.1-prel/npm-1.39.1-prel.vsix",
    "vscode-builtin-scss": "https://github.com/theia-ide/vscode-builtin-extensions/releases/download/v1.39.1-prel/scss-1.39.1-prel.vsix",
    "vscode-builtin-typescript": "https://github.com/theia-ide/vscode-builtin-extensions/releases/download/v1.39.1-prel/typescript-1.39.1-prel.vsix",
    "vscode-builtin-typescript-language-features": "https://github.com/theia-ide/vscode-builtin-extensions/releases/download/v1.39.1-prel/typescript-language-features-1.39.1-prel.vsix"
  }
}' > package.json
curl -fsSL https://deb.nodesource.com/setup_12.x | sudo -E bash -
while ! sudo apt-get install -y nodejs; do
    sleep 10
done
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
while ! sudo apt-get update; do
    sleep 10
done
while ! sudo apt-get install yarn -y; do
    sleep 10
done
while ! yarn install; do
    sleep 10
done
while ! yarn theia build; do 
    sleep 10
done
# su -c 'nohup yarn start /home/ubuntu/workshop --hostname 0.0.0.0 --port 3000 &' ubuntu
#sudo nohup yarn start /home/ubuntu/workshop --hostname 0.0.0.0 --port 3000 & echo 'started'

#echo '
#(cd ~/ide && yarn start /home/ubuntu/workshop --hostname 0.0.0.0 --port 3000) &
#THEIA_IDE_PID=$!
#disown -h $THEIA_IDE_PID' > /home/ubuntu/start_theia.sh
#chmod +x /home/ubuntu/start_theia.sh
#/bin/bash -c "/home/ubuntu/start_theia.sh"

#(nohup cd ~/ide && yarn start /home/ubuntu/workshop --hostname 0.0.0.0 --port 3000 & < /dev/null > std.out 2> std.err

#cd /home/ubuntu/ide
#nohup yarn start /home/ubuntu/workshop --hostname 0.0.0.0 --port 3000 & < /dev/null > std.out 2> std.err

# cd /home/ubuntu/ide
#setsid yarn start /home/ubuntu/workshop --hostname 0.0.0.0 --port 3000
#setsid nohup yarn start /home/ubuntu/workshop --hostname 0.0.0.0 --port 3000 & < /dev/null > std.out 2> std.err

#sudo su -
#sudo su -c 'cd /home/ubuntu/ide && nohup yarn start /home/ubuntu/workshop --hostname 0.0.0.0 --port 3000 &' ubuntu

#cd /home/ubuntu/ide
#nohup yarn start /home/ubuntu/workshop --hostname 0.0.0.0 --port 3000 < /dev/null > std.out 2> std.err & echo parent
#MY_PID=$!
#disown -h $MY_PID

#setsid nohup yarn start /home/ubuntu/workshop --hostname 0.0.0.0 --port 3000 < /dev/null > std.out 2> std.err
#echo "theia ide setup complete"

#
# start Theia IDE 
# "cd /home/ubuntu/ide",
# "(nohup yarn start /home/ubuntu/workshop --hostname 0.0.0.0 --port 3000 < /dev/null > std.out 2> std.err) & echo Theia IDE started.....",
#
      
# ssh -i test_pair.pem ec2-user@3.15.173.157 "(nohup sleep 10000 < /dev/null > std.out 2> std.err) & cat /home/ec2-user/tmpfile.txt"
# cd /home/ubuntu/ide
# (nohup yarn start /home/ubuntu/workshop --hostname 0.0.0.0 --port 3000 < /dev/null > std.out 2> std.err) & echo Theia IDE started.....