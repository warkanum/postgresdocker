FROM centos:8

LABEL name="PGSQL12"
LABEL author="Hein"
LABEL email="hein.puth@gmail.com"
LABEL maintainer="hein.puth@gmail.com"


##Prep OS##
RUN yum update -y
RUN yum upgrade -y
RUN yum install make gcc binutils pkgconfig autoconf automake bison flex gcc-c++ gettext patch libtool rpm-build -y
RUN yum install wget git yum-utils unzip -y
RUN yum install libuuid-devel openssl-devel libevent-devel readline-devel libxml2-devel libxslt-devel libffi-devel -y

##Variables##
#postgres
ARG PGVER=12
ARG PGSRC="https://ftp.postgresql.org/pub/source/v12.1/postgresql-12.1.tar.gz"
ARG PGDIR="/opt/pg12"
ARG PGCFG="/etc/pg12"

#python
ARG PYSRC="https://www.python.org/ftp/python/3.6.9/Python-3.6.9.tgz"
ARG PYDIR="/opt/python3"

ENV PG_MAJOR 12
ENV PGDATADIR="/data"
ENV PGLOGFILE="/data/error.log"
ENV PGPORT=5433
ENV RUNUUSER=dbadm
ENV PGUSER=dbadm
ENV PGDBNAME=demo
ENV PGMD5PW=md5c4b131c8a66d914edbadb5b49c52b45f

ENV LANG en_ZA.utf8

VOLUME  [$PGDATADIR]
EXPOSE $PGPORT

RUN useradd -m -G users $RUNUUSER

##Prep for compile##
RUN echo -e "\e[0;33mStarting Compile Process \e[0m"
RUN mkdir -p /prep

#py
RUN wget -c ${PYSRC} -O /prep/py.tgz
#COPY Python-3.6.9.tgz /prep/py.tgz #for local testing
RUN mkdir -p /usr/src/python
RUN tar xfz /prep/py.tgz --strip-components 1 -C /usr/src/python
WORKDIR /usr/src/python
#Add --enable-optimizations for 20% exec speed and huge compile cost.
RUN ./configure --prefix=$PYDIR --libdir=$PYDIR/lib --includedir=$PYDIR/include --enable-shared --with-ensurepip=install
RUN make -j 8 && make install
RUN $PYDIR/bin/python3 -m pip install --upgrade pip
ENV PYTHONPATH=$PYDIR
ENV PATH=$PYDIR/lib:$PATH

RUN echo $PYDIR/lib > /etc/ld.so.conf.d/dockerpython.conf
RUN ldconfig
#COPY test_python.py /prep/test_python.py
#RUN $PYDIR/bin/python3 /prep/test_python.py
RUN echo -e "\e[0;33mPython installed to $PYDIR \e[0m"

#pg
RUN wget -c ${PGSRC} -O /prep/pg.tar.gz
#COPY postgresql-12.1.tar.gz /prep/pg.tar.gz #for local testing
RUN mkdir -p /usr/src/postgres
RUN tar xfz /prep/pg.tar.gz --strip-components 1 -C /usr/src/postgres


RUN mkdir -p /usr/src/postgres/build
WORKDIR /usr/src/postgres/build
#ENV CPLUS_INCLUDE_PATH=$PYDIR/include:$PYDIR/include/python3.6m:/usr/src/python:/usr/src/python/include:$CPLUS_INCLUDE_PATH
#ENV LIBRARY_PATH=$PYDIR/lib:$LIBRARY_PATH

RUN ../configure PYTHON=${PYDIR}/bin/python3 --prefix=$PGDIR --with-pgport=$PGPORT --with-python --with-openssl --with-libxml --with-libxslt --with-uuid=e2fs
RUN make -j 8 world && make install-world
RUN echo -e "\e[0;33mPostgres installed to $PGDIR \e[0m"

##cleanup
RUN rm -Rf /usr/src/python
RUN rm -Rf /usr/src/postgres
RUN rm -Rf /prep/* 

RUN mkdir -p $PGDATADIR
RUN chown $RUNUUSER:users -R /prep
RUN chown $RUNUUSER:users -R $PGDATADIR
RUN chown $RUNUUSER:users -R $(dirname $PGLOGFILE)

USER $RUNUUSER
WORKDIR /prep

ENV PATH=$PGDIR/bin/:$PATH
RUN initdb -D $PGDATADIR
RUN echo "host all  all    0.0.0.0/0  md5" >> $PGDATADIR/pg_hba.conf
RUN echo "listen_addresses='*'" >> $PGDATADIR/postgresql.conf
COPY dbsetup.pgsql /prep/dbsetup.pgsql

RUN pg_ctl -s -D $PGDATADIR start -w -t 120 -l $PGLOGFILE &&\
    psql --dbname postgres --command "CREATE USER $PGUSER WITH SUPERUSER PASSWORD '$PGMD5PW';" ||\
    echo -e "\e[0;33m User create failed.  \e[0m" &&\
    createdb -O $PGUSER -T template0 $PGDBNAME ||\
    echo -e "\e[0;33m Database create failed.  \e[0m"  &&\
    psql --dbname $PGDBNAME -f /prep/dbsetup.pgsql ||\
    echo -e "\e[0;33m Database setup file failed.  \e[0m" 

HEALTHCHECK CMD pg_ctl status -D $PGDATADIR

COPY entrypoint.sh /usr/local/bin/

ENTRYPOINT ["entrypoint.sh"]
CMD pg_ctl start -D $PGDATADIR -w -t 120 -l $PGLOGFILE
