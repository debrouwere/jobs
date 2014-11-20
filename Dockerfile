FROM redis
MAINTAINER Stijn Debrouwere <stijn@debrouwere.org>
RUN apt-get -y install lua5.1 liblua5.1-dev luarocks
RUN luarocks install luasec OPENSSL_LIBDIR=/usr/lib/x86_64-linux-gnu
RUN luarocks install jobs-0.1.0-0.rockspec
ENTRYPOINT ["job", "init"]