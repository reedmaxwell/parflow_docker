#RMM ParFlow test

# start by building the basic container
FROM centos:latest
MAINTAINER Reed Maxwell <rmaxwell@mines.edu>

# 

RUN yum  install -y  gcc  \
    build-essential \    
    cmake3 \
    make \
    g++  \
    gcc-c++  \
    gdc \
    gcc-gfortran \
    tcl-devel \
    tk-dev \
    git 
RUN yum install -y openmpi
RUN yum install -y zlib 

RUN whereis mpicc
RUN alias which=/usr/bin/whereis
#RUN mpirun --version


# make directories
RUN mkdir /home/parflow
#RUN mkdir parflow
#RUN mkdir silo
#RUN mkdir hypre
# set environment vars

#ENV CC gcc
#ENV CXX g++
#ENV FC gfortran
#ENV F77 gfortran
#ENV PARFLOW_DIR /home/parflow/parflow_build
ENV PARFLOW_DIR /home/parflow/parflow
ENV SILO_DIR /home/parflow/silo-4.10.2 
ENV HYPRE_DIR /home/parflow/hypre
ENV PATH /usr/local/bin/:/usr/bin/gcc:/usr/lib/gcc:/usr/libexec/gcc:$PATH
ENV PATH $PATH:/usr/lib64/openmpi-x86_64/bin/:/usr/include/openmpi-x86_64/

WORKDIR /home/parflow
RUN git clone -b master --single-branch https://github.com/parflow/parflow.git parflow
#RUN pwd
#RUN ls

# build libraries
#SILO

RUN curl "https://wci.llnl.gov/content/assets/docs/simulation/computer-codes/silo/silo-4.10.2/silo-4.10.2.tar.gz" -o "silo-4.10.2.tar.gz"
RUN tar -xvf silo-4.10.2.tar.gz

WORKDIR $SILO_DIR

RUN ./configure  --prefix=$SILO_DIR --disable-silex --disable-hzip --disable-fpzip
RUN make install

#Hypre
WORKDIR /home/parflow

RUN git clone -b master --single-branch https://github.com/LLNL/hypre.git hypre

WORKDIR $HYPRE_DIR/src
RUN ./configure --prefix=$HYPRE_DIR --without-MPI
RUN make install

# build ParFlow
WORKDIR $PARFLOW_DIR/pfsimulator
RUN ./configure --prefix=$PARFLOW_DIR --with-clm --enable-timing --with-silo=$SILO_DIR --with-hypre=$HYPRE_DIR --with-amps=seq --without-mpi --with-amps-sequential-io
RUN   make install


# build PFTools
WORKDIR $PARFLOW_DIR/pftools
RUN ./configure --prefix=$PARFLOW_DIR  --enable-timing --with-silo=$SILO_DIR  --with-amps=seq --without-mpi --with-amps-sequential-io
RUN   make install

# test
WORKDIR $PARFLOW_DIR/test
RUN make check


#RUN  cmake ../parflow \
#        -DPARFLOW_AMPS_LAYER=seq \
#	-DHYPRE_ROOT=$HYPRE_DIR \
#	-DSILO_ROOT=$SILO_DIR \
#	-DPARFLOW_ENABLE_TIMING=TRUE \
#	-DPARFLOW_HAVE_CLM=ON \
#	-DCMAKE_INSTALL_PREFIX=$PARFLOW_DIR


##
WORKDIR $PARFLOW_DIR

CMD ["parflow","/home/parflow/parflow/test/tclsh default_single.tcl 1 1 1"]

ENTRYPOINT ["parflow"]
