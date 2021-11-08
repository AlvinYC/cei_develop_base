FROM pytorch/pytorch:1.3-cuda10.1-cudnn7-devel
MAINTAINER alvin

ARG user=docker
ARG local_package=utils_thisbuild
ARG github=workspace 
#vscode server 1.54.2
ARG vscommit=fd6f3bce6709b121a895d042d343d71f317d74e7

# udpate timezone
RUN apt-get update \
    &&  DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends tzdata

RUN TZ=Asia/Taipei \
    && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime \
    && echo $TZ > /etc/timezone \
    && dpkg-reconfigure -f noninteractive tzdata 

# install necessary ubuntu application
RUN apt-get update && apt-get install -y \
    apt-utils sudo vim zsh curl git make unzip \
    wget openssh-server rsync iproute2\
    powerline fonts-powerline \
    # necessary ubuntu package for sudo add-apt-repository ppa:deadsnakes/ppa
    software-properties-common \
    # zsh by ssh issue : icons.zsh:168: character not in range
    language-pack-en \
    libsndfile1 \
    unrar gnuplot

# install https://github.com/openai/gym mention package
RUN apt-get install -y libglu1-mesa-dev libgl1-mesa-dev \
    libosmesa6-dev xvfb ffmpeg curl patchelf \
    libglfw3 libglfw3-dev cmake zlib1g zlib1g-dev swig

# docker account
RUN useradd -m ${user} && echo "${user}:${user}" | chpasswd && adduser ${user} sudo;\
    echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers;\
    chmod 777 /etc/ssh/sshd_config; echo 'GatewayPorts yes' >> /etc/ssh/sshd_config; chmod 644 /etc/ssh/sshd_config

# change workspace
USER ${user}
WORKDIR /home/${user}

# oh-my-zsh setup
ARG omzthemesetup="POWERLEVEL9K_MODE=\"nerdfont-complete\"\n\
ZSH_THEME=\"powerlevel9k\/powerlevel9k\"\n\n\
POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(ip pyenv virtualenv context dir vcs)\n\
POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status root_indicator background_jobs history time)\n\
POWERLEVEL9K_VIRTUALENV_BACKGROUND=\"green\"\n\
POWERLEVEL9K_PYENV_PROMPT_ALWAYS_SHOW=true\n\
POWERLEVEL9K_PYENV_BACKGROUND=\"orange1\"\n\
POWERLEVEL9K_DIR_HOME_SUBFOLDER_FOREGROUND=\"white\"\n\
POWERLEVEL9K_PYTHON_ICON=\"\\U1F40D\"\n"

# ssh/zsh plugin
RUN cd ~/ ; mkdir .ssh ;\
    sudo mkdir /var/run/sshd ;\
    sudo sed -ri 's/session required pam_loginuid.so/#session required pam_loginuid.so/g' /etc/pam.d/sshd ;\
    sudo ssh-keygen -A ;\
    wget https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh -O - | zsh || true ;\
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/plugins/zsh-syntax-highlighting ;\
    git clone https://github.com/bhilburn/powerlevel9k.git ~/.oh-my-zsh/custom/themes/powerlevel9k ;\
    git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions ;\
    git clone https://github.com/davidparsson/zsh-pyenv-lazy.git ~/.oh-my-zsh/custom/plugins/pyenv-lazy ;\
    echo "source ~/.oh-my-zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" >> ~/.zshrc ;\
    sed -i -r "1s/^/export TERM=\"xterm-256color\"\n/" ~/.zshrc ;\
    sed -i -r "2s/^/LC_ALL=\"en_US.UTF-8\"\n/" ~/.zshrc ;\
    sed -i -r "s/^plugins=.*/plugins=(git zsh-autosuggestions virtualenv screen pyenv-lazy)/" ~/.zshrc ;\
    sed -i -r "s/^ZSH_THEM.*/${omzthemesetup}/" ~/.zshrc ;\
    wget https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/SourceCodePro.zip ;\
    unzip SourceCodePro.zip -d ~/.fonts ;\
    fc-cache -fv  ;\
    sudo chsh -s $(which zsh) ${user}

# ubuntu 18.04 jupyter notebook
#RUN sudo apt-get -y install ipython ipython-notebook 
#RUN sudo apt-get -y install ipython
# ubuntu 16.04 jupyter notebook
RUN sudo apt-get -y install ipython ipython-notebook;\
    python3 -m pip install --user jupyter==1.0.0;\
    echo "export PATH=/home/${user}/.local/bin:$PATH" >> ~/.zshrc
    
# remote plot matplotlib output (Mac --> dockerhost --> container)
RUN sudo apt-get install libcairo2-dev pkg-config python3-dev libgirepository1.0-dev -y;\
    sudo apt-get install python3-gi gobject-introspection gir1.2-gtk-3.0 xauth -y;\
    sudo apt-get install libcanberra-gtk-module libcanberra-gtk3-module -y;\
    python3 -m pip install --user pycairo==1.19.1 --no-use-pep517;\
    python3 -m pip install --user gobject==0.1.0 PyGObject==3.30.5 --no-use-pep517;\
    python3 -m pip install --user matplotlib;\
    sudo sed -iE "s/X11Forwarding yes/X11UseLocalhost no\nX11Forwarding yes/" /etc/ssh/sshd_config;\
    echo "export LANG=en_US.UTF-8" >> /home/${user}/.zshrc;\
    echo "export LANGUAGE=en_US:en" >> /home/${user}/.zshrc;\
    echo "export LC_ALL=en_US.UTF-8" >> /home/${user}/.zshrc

# vscode server part
RUN curl -sSL "https://update.code.visualstudio.com/commit:${vscommit}/server-linux-x64/stable" -o /home/${user}/vscode-server-linux-x64.tar.gz;\
    mkdir -p ~/.vscode-server/bin/${vscommit};\
    tar zxvf /home/${user}/vscode-server-linux-x64.tar.gz -C ~/.vscode-server/bin/${vscommit} --strip 1;\
    touch ~/.vscode-server/bin/${vscommit}/0

# jupyter notebook config 'auto newline in cell'
ARG JUCELL="{\
  \"MarkdownCell\": {\
    \"cm_config\": {\
      \"lineWrapping\": true\
    }\
  },\
  \"CodeCell\": {\
    \"cm_config\": {\
      \"lineWrapping\": true\
    }\
  }\
}"

# update jupyter notebook config 
RUN mkdir /home/${user}/${github} -p;\
    /home/docker/.local/bin/jupyter notebook --generate-config;\
    sed -ir "s/\#c\.NotebookApp\.token.*/c\.NotebookApp\.token = \'\'/" ~/.jupyter/jupyter_notebook_config.py;\
    sed -ir "s/#c\.NotebookApp\.password =.*/c\.NotebookApp\.password = u\'\'/" ~/.jupyter/jupyter_notebook_config.py;\
    sed -ir "s/#c\.NotebookApp\.ip = .*/c\.NotebookApp\.ip = \'\*\'/" ~/.jupyter/jupyter_notebook_config.py;\
    sed -ir "s/#c\.NotebookApp\.notebook_dir.*/c\.NotebookApp\.notebook_dir = \'\/home\/docker\/${github}\'/" ~/.jupyter/jupyter_notebook_config.py;\
    mkdir -p ~/.jupyter/nbconfig;\
    echo ${JUCELL} > ~/.jupyter/nbconfig/notebook.json        
 
ADD id_rsa*.pub /home/${user}/.ssh/authorized_keys

ENTRYPOINT sudo service ssh restart && zsh
                    

