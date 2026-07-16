FROM centos:8

LABEL name="PGSQL12" \
  author="Hein" \
  email="hein.puth@gmail.com" \
  maintainer="hein.puth@gmail.com"


##Prep OS##
RUN yum update -y && yum upgrade -y &&\
  yum install make gcc binutils pkgconfig autoconf automake \
  bison flex gcc-c++ gettext patch libtool rpm-build -y &&\ 
  yum install wget git yum-utils unzip -y  &&\
  yum install libuuid-devel openssl-devel libevent-devel \
  readline-devel libxml2-devel libxslt-devel libffi-devel -y &&\
  yum clean all

##Variables##
#postgres
ARG PGVER=12
ARG PGSRC="https://ftp.postgresql.org/pub/source/v12.1/postgresql-12.1.tar.gz"
ARG PGDIR="/opt/pg12"
ARG PGCFG="/etc/pg12"

#python
ARG PYSRC="https://www.python.org/ftp/python/3.6.9/Python-3.6.9.tgz"
ARG PYDIR="/opt/python3"

ENV PG_MAJOR=12 \
    PGDATADIR="/data"  \
    PGLOGFILE="/data/error.log"  \
    PGPORT=5433  \
    DUSER=dbadm  \
    DGROUP=dbadm \
    PGUSER=dbadm \
    PGDBNAME=demo \
    PGMD5PW=md5c4b131c8a66d914edbadb5b49c52b45f

#ENV LANG en_ZA.utf8

VOLUME  [$PGDATADIR]
EXPOSE $PGPORT

RUN useradd -m -G users $DUSER

##Prep for compile##
RUN echo -e "\e[0;33mStarting Download and Extract \e[0m" &&\
  mkdir -p /prep &&\
  mkdir -p /usr/src/python &&\
  mkdir -p /usr/src/postgres/build &&\
  wget -c ${PYSRC} -O /prep/py.tgz &&\
  wget -c ${PGSRC} -O /prep/pg.tar.gz  &&\
  tar xfz /prep/py.tgz --strip-components 1 -C /usr/src/python  &&\
  tar xfz /prep/pg.tar.gz --strip-components 1 -C /usr/src/postgres &&\
  rm -f /prep/*.tgz 

#Copy outside files.
COPY test_python.py /prep/test_python.py
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY dbsetup.pgsql /prep/dbsetup.pgsql

RUN echo -e "\e[0;33mStarting Compile Process \e[0m"
WORKDIR /usr/src/python
#Add --enable-optimizations for 20% exec speed and huge compile cost.
RUN ./configure --prefix=$PYDIR --libdir=$PYDIR/lib --includedir=$PYDIR/include --enable-shared \
  --with-ensurepip=install &&\
  make -j 8 &&\
  make install

RUN $PYDIR/bin/python3 -m pip install --upgrade pip
ENV PYTHONPATH=$PYDIR \
    PATH=$PYDIR/lib:$PATH

RUN echo $PYDIR/lib > /etc/ld.so.conf.d/dockerpython.conf &&\
    ldconfig  &&\
    echo -e "\e[0;33mPython installed to $PYDIR \e[0m" &&\
    $PYDIR/bin/python3 /prep/test_python.py

WORKDIR /usr/src/postgres/build

RUN ../configure PYTHON=${PYDIR}/bin/python3 --prefix=$PGDIR --with-pgport=$PGPORT \
  --with-python --with-openssl --with-libxml --with-libxslt --with-uuid=e2fs  &&\
  make -j 8 world && make install-world &&\
  echo -e "\e[0;33mPostgres installed to $PGDIR \e[0m"

##cleanup
RUN rm -Rf /usr/src/python &&\
    rm -Rf /usr/src/postgres &&\
    rm -Rf /prep/* 

RUN mkdir -p $PGDATADIR  &&\
    chown $DUSER:users -R /prep  &&\
    chown $DUSER:users -R $PGDATADIR  &&\
    chown $DUSER:users -R $(dirname $PGLOGFILE)

USER $DUSER
WORKDIR /tmp

ENV PATH=$PGDIR/bin/:$PATH
RUN initdb -D $PGDATADIR
RUN echo "host all  all    0.0.0.0/0  md5" >> $PGDATADIR/pg_hba.conf &&\
    echo "listen_addresses='*'" >> $PGDATADIR/postgresql.conf

RUN pg_ctl -s -D $PGDATADIR start -w -t 120 -l $PGLOGFILE &&\
    psql --dbname postgres --command "CREATE USER $PGUSER WITH SUPERUSER PASSWORD '$PGMD5PW';" ||\
    echo -e "\e[0;33m User create failed.  \e[0m" &&\
    createdb -O $PGUSER -T template0 $PGDBNAME ||\
    echo -e "\e[0;33m Database create failed.  \e[0m"  &&\
    psql --dbname $PGDBNAME -f /prep/dbsetup.pgsql ||\
    echo -e "\e[0;33m Database setup file failed.  \e[0m" 

#HEALTHCHECK CMD pg_ctl status -D $PGDATADIR

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD pg_ctl start -D $PGDATADIR -w -t 120 -l $PGLOGFILE
