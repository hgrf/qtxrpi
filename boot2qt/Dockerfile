FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive
RUN apt update && \
    apt install -y gawk wget git diffstat unzip texinfo gcc build-essential \
        chrpath socat cpio python3 python3-pip python3-pexpect xz-utils \
        debianutils iputils-ping python3-git python3-jinja2 libegl1-mesa \
        libsdl1.2-dev pylint3 xterm python3-subunit mesa-common-dev python \
        git-lfs g++-multilib gcc-multilib libxkbcommon-dev \
        libxkbcommon-x11-dev libwayland-cursor++0 libwayland-cursor0 \
        locales \
        && \
    rm -rf /var/lib/apt/lists/*

RUN wget -O /usr/bin/repo https://storage.googleapis.com/git-repo-downloads/repo && \
    chmod a+x /usr/bin/repo

RUN locale-gen en_US.UTF-8
RUN update-locale LANG=en_US.UTF-8
ENV LANG=en_US.UTF-8

RUN adduser --disabled-password --gecos "" builder
USER builder

RUN git config --global user.email "you@example.com"
RUN git config --global user.name "Your Name"
