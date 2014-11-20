FROM redis
MAINTAINER Stijn Debrouwere <stijn@debrouwere.org>
ADD .
RUN apt-get update
RUN apt-get upgrade -y
RUN apt-get -y install openssl libssl-dev lua5.1 liblua5.1-dev luarocks
RUN luarocks install luasec OPENSSL_LIBDIR=/usr/lib/x86_64-linux-gnu
RUN luarocks install rockspec/jobs-scm-1.rockspec
ENTRYPOINT ["job", "init"]