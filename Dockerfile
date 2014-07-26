# Dockerfile for Java application containers on CoreOS.

FROM shift/coreos-ubuntu-confd

MAINTAINER Vincent Palmer <shift-gh@someone.section.me>

ENV DEBIAN_FRONTEND noninteractive
RUN sed 's/main$/main universe/' -i /etc/apt/sources.list

RUN apt-get update && apt-get install -y software-properties-common python-software-properties
RUN add-apt-repository ppa:webupd8team/java -y
RUN apt-get update
RUN echo oracle-java7-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections
RUN apt-get install -y oracle-java7-installer
ADD entrypoint.sh /usr/local/bin/run


