FROM centos:8

LABEL name="PGSQL12"
LABEL author="Hein"
LABEL email="hein.puth@gmail.com"

##Prep OS##
RUN yum update -y
RUN yum upgrade -y
RUN yum install make gcc binutils pkgconfig autoconf automake bison flex gcc-c++ gettext patch libtool rpm-build -y
RUN yum install wget git yum-utils nano unzip -y
RUN yum install libuuid-devel openssl-devel libevent-devel readline-devel libxml2-devel libxslt-devel libffi-devel -y

##Variables##
#postgres
ARG PGVER=12
ARG PGSRC="https://ftp.postgresql.org/pub/source/v12.1/postgresql-12.1.tar.gz"
ARG PGPORT=5433
ARG PGDIR="/opt/pg12"
ARG PGDATADIR="/data"
ARG PGLOGFILE="/data/error.log"
ARG PGCFG="/etc/pg12"

#python
ARG PYSRC="https://www.python.org/ftp/python/3.6.9/Python-3.6.9.tgz"
ARG PYDIR="/opt/python3"

VOLUME  [$PGDATADIR]
EXPOSE $PGPORT


##Prep for compile##
RUN mkdir -p /prep

#py
RUN wget -c ${PYSRC} -O /prep/py.tar.gz
RUN mkdir -p /prep/python
RUN tar xfz /prep/py.tar.gz --strip-components 1 -C /prep/python
WORKDIR /prep/python
RUN ./configure --prefix=$PYDIR --enable-shared --with-distutils
RUN make -j 6 
RUN make -j 6 install
RUN $PYDIR/bin/python3 -m pip install --upgrade pip
RUN ls -l $PYDIR

#pg
RUN wget -c ${PGSRC} -O /prep/pg.tar.gz
RUN ls -l /prep
RUN mkdir -p /prep/pgsql
RUN tar xfz /prep/pg.tar.gz --strip-components 1 -C /prep/pgsql

RUN ls -l /prep

WORKDIR /prep/pgsql
RUN ./configure PYTHON=${PYDIR}/bin/python3 --prefix=$PGDIR --with-pgport=$PGPORT --with-python --with-openssl --with-libxml --with-libxslt --with-uuid=e2fs
RUN make -j 6 world
RUN make -j 6 check
RUN make -j 6 install-world

RUN $PGDIR/bin/initdb -D $PGDATADIR
RUN echo "host all  all    0.0.0.0/0  md5" >> $PGDATADIR/pg_hba.conf
RUN echo "listen_addresses='*'" >> $PGDATADIR/postgresql.conf

RUN $PGDIR/bin/pg_ctl -s -D $PGDATADIR start -w -t 120 -l $PGLOGFILE &&\
    $PGDIR/bin/psql --command "CREATE USER docker WITH SUPERUSER PASSWORD 'docker';" &&\
    $PGDIR/bin/createdb -O docker docker

CMD ["${PGDIR}/bin/pg_ctl","-s", "-D", $PGDATADIR, "start","-w","-t","120","-l", $PGLOGFILE]
