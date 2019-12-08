FROM centos:8

LABEL name="C8PG12"
LABEL author="Hein"
LABEL email="hein.puth@gmail.com"

##Prep OS##
RUN yum update -y
RUN yum upgrade -y
RUN yum install make gcc binutils pkgconfig autoconf automake bison flex gcc-c++ gettext patch libtool rpm-build -y
RUN yum install wget git yum-utils nano unzip -y
RUN yum install libuuid-devel openssl-devel libevent-devel readline-devel libxml2-devel libxslt-devel libffi-devel -y

##Variables##
VOLUME  [$PGDATADIR]
EXPOSE $PGPORT

#postgres
ARG PGVER=12
ARG PGSRC="https://ftp.postgresql.org/pub/source/v12.1/postgresql-12.1.tar.gz"
ARG PGPORT=5433
ARG PGDIR="/opt/pg12"
ARG PGDATADIR="/data"

#python
ARG PYSRC="https://www.python.org/ftp/python/3.6.9/Python-3.6.9.tgz"
ARG PYDIR="/opt/python3"

##Prep for compile##
RUN mkdir -p /prep

#py
RUN wget ${PYSRC} -O /prep/py.tar.gz
RUN mkdir -p /prep/python
RUN tar xfz /prep/py.tar.gz --strip-components 1 -C /prep/python
WORKDIR /prep/python
RUN ./configure --prefix=$PGDIR --enable-shared --with-distutils
RUN make -j 6 
RUN make -j 6 install
RUN $PGDIR/bin/python3 -m pip install --upgrade pip

#pg
RUN wget ${PGSRC} -O /prep/pg.tar.gz
RUN ls -l /prep
RUN mkdir -p /prep/pgsql
RUN tar xfz /prep/pg.tar.gz --strip-components 1 -C /prep/pgsql

WORKDIR /prep/pgsql
RUN ./configure PYTHON=${PYDIR}/bin --prefix=$PGDIR --with-pgport=$PGPORT --with-python --with-openssl --with-libxml --with-libxslt --with-uuid=e2fs
RUN make -j 6 world
RUN make -j 6 check
RUN make -j 6 install-world

RUN $PGDIR/bin/initdb -D $PGDATADIR

