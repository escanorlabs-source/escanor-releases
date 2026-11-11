# Escanor apt repository

Files behind https://www.escanor.in/apt. Install Escanor Desktop on Debian, Ubuntu and their relatives:

```sh
curl -fsSL https://www.escanor.in/apt/escanor-archive-keyring.gpg | sudo tee /usr/share/keyrings/escanor-archive-keyring.gpg >/dev/null && echo "deb [signed-by=/usr/share/keyrings/escanor-archive-keyring.gpg] https://www.escanor.in/apt ./" | sudo tee /etc/apt/sources.list.d/escanor.list
sudo apt update && sudo apt install escanor
```

Updates then come with `sudo apt upgrade`. This branch is written by the release script; do not edit it by hand.
