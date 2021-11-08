## cei_develop_base

provide pytorch develop environment， include
1. ubuntu 16.04
2. oh_my_zsh w/ POWERLEVEL9K
3. open-ssh w/ X11 trust model
5. pytorch 1.3 w/ cuda10.1-cudnn7 (nvidia driver must >= 418, ref: [Nvidia  website table 2](https://docs.nvidia.com/deploy/cuda-compatibility/index.html#binary-compatibility__table-toolkit-driver))
6. python 3.6.9 w/ anaconda (python -m pip install --user pacakge, if you don't wanna use anaconda)
7. jupyter notebook 1.0.0
8. vscode_server 1.54.2
9. root user account named 'docker'
10. some usefull linux softwares such as rar, gnuplot, curl, ffmpeg

before docker build, you need make sure you have the following 4 files
```
 alvin@alvin1080ti> tree
.
├── Dockerfile
├── docker_run.txt
├── id_rsa.pub (you should prepare this file from your local machine ~/.ssh/id_rsa.pub)
└── README.md
```
docker build example
```
docker build -t cei_develop_base:torch1.3 .
```
docker run command example (same as docker_run.txt)
```
docker run -it\
 --rm\
 --gpus=all\
 --shm-size=256m\
 -p 7788:22\
 -p 8888:8888\
 -v /media/alvin/HD/model_ouput/:/home/docker/model_output\
 -v /tmp/.X11-unix:/tmp/.X11-unix\
 -e DISPLAY=unix$DISPLAY\
 -e GDK_SCALE\
 -e GDK_DPI_SCALE\
 --name ssh_demo cei_develop_base:torch1.3
```

