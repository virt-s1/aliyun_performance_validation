FROM fedora:32

# metadata
LABEL author="Charles Shih"
LABEL maintainer="cheshi@redhat.com"
LABEL version="1.0"
LABEL description="This image provdes environment for aliyun_performance_validation project."

# Keeps Python from generating .pyc files in the container
ENV PYTHONDONTWRITEBYTECODE 1

# Turns off buffering for easier container logging
ENV PYTHONUNBUFFERED 1

# configure application
WORKDIR /root/workspace

# install basic packages
RUN dnf install -y jq psmisc findutils \
    which ncurses tree procps-ng shyaml bc

# install additional packages
RUN dnf install -y pip

# install pip requirements
ADD ./requirements.txt /tmp/requirements.txt
RUN python3 -m pip install -r /tmp/requirements.txt

# create mount point
RUN mkdir -p /root/workspace/repo
RUN mkdir -p /root/workspace/logs

# Export volumes
VOLUME [ "/root/workspace/repo" ]
VOLUME [ "/root/workspace/logs" ]

# During debugging, this entry point will be overridden.
CMD ["/bin/bash"]

