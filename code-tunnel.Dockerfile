FROM archlinux:latest

ARG USUARIO=aictur
ENV TUNNELNAME=k8s

RUN pacman -Syu --noconfirm --needed coreutils git base-devel zsh sudo curl wget go openssl fzf tldr python python-pip python-pipx terraform kubectl less jq && \
    useradd $USUARIO -m && passwd -d $USUARIO && printf "${USUARIO} ALL=(ALL) ALL\n" | tee -a /etc/sudoers && \
    git clone https://aur.archlinux.org/yay.git && chmod -R 777 yay && cd yay && sudo -u $USUARIO bash -c 'GOFLAGS=-buildvcs=false makepkg -si --noconfirm && yay -Y --gendb && yay -Syu --devel && yay -Y --devel --save'

RUN curl -Lk 'https://code.visualstudio.com/sha/download?build=stable&os=cli-alpine-x64' --output vscode_cli.tar.gz && tar -xf vscode_cli.tar.gz && \
    chmod 555 ./code && mv ./code /bin/code

USER $USUARIO
WORKDIR /home/${USUARIO}

RUN yay -Syu --noconfirm neovim-git nvm

#Setear zsh shell

ENTRYPOINT /bin/code tunnel --accept-server-license-terms --name $TUNNELNAME
