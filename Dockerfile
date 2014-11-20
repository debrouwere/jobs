FROM debian:wheezy
MAINTAINER Stijn Debrouwere <stijn@debrouwere.org>

COPY . /jobs/
RUN apt-get update
RUN apt-get -y upgrade
RUN apt-get -y install make build-essential libtool libncurses5-dev
RUN apt-get -y install openssl libssl-dev
RUN apt-get -y install lua5.1 liblua5.1-dev luarocks
RUN luarocks install luasec OPENSSL_LIBDIR=/usr/lib/x86_64-linux-gnu
# once things have stabilized, we might decide to install
# from a repository or from luarocks instead
WORKDIR /jobs
RUN luarocks make rockspec/jobs-scm-1.rockspec
ENTRYPOINT ['job']