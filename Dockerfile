# CUDA 8: https://github.com/NVIDIA/nvidia-docker/blob/master/ubuntu-14.04/cuda/8.0/runtime/Dockerfile
# CAFFE: https://github.com/BVLC/caffe/blob/master/docker/standalone/gpu/Dockerfile
# CAFFE & CUDA 8 ISSUES: https://github.com/NVIDIA/nvidia-docker/issues/165
# DIGITS 4: https://github.com/NVIDIA/nvidia-docker/blob/master/ubuntu-14.04/digits/4.0/Dockerfile




# INSTALL CAFFE
# 
# https://github.com/BVLC/caffe/blob/master/docker/standalone/gpu/Dockerfile
#
# FROM nvidia/cuda:7.5-cudnn5-devel-ubuntu14.04
FROM nvidia/cuda:8.0-cudnn5-runtime
MAINTAINER caffe-maint@googlegroups.com

# http://stackoverflow.com/questions/22179301/how-do-you-run-apt-get-in-a-dockerfile-behind-a-proxy
# ENV http_proxy <HTTP_PROXY>
# ENV https_proxy <HTTP_PROXY>

# RUN echo $HTTP_PROXY
# RUN echo $http_proxy

# http://layer0.authentise.com/docker-4-useful-tips-you-may-not-know-about.html
# pick a mirror for apt-get
# RUN echo "deb mirror://mirrors.ubuntu.com/mirrors.txt trusty main restricted universe multiverse" > /etc/apt/sources.list && \
#     echo "deb mirror://mirrors.ubuntu.com/mirrors.txt trusty-updates main restricted universe multiverse" >> /etc/apt/sources.list && \
#     echo "deb mirror://mirrors.ubuntu.com/mirrors.txt trusty-security main restricted universe multiverse" >> /etc/apt/sources.list && \
#     DEBIAN_FRONTEND=noninteractive apt-get update

# cache apt-get requests locally. 
# Requires: docker run -d -p 3142:3142 --name apt_cacher_run apt_cacher
# https://docs.docker.com/engine/examples/apt-cacher-ng/
# docker build --build-arg APT_PROXY=http://$(ipconfig getifaddr en0):3142 . -t coreindustries/digits-tensorflow .
# RUN  echo 'Acquire::http { Proxy "http://10.11.29.250:3142"; };' >> /etc/apt/apt.conf.d/01proxy
# RUN  echo 'Acquire::http { Proxy "'+HTTP_PROXY+'"; };' >> /etc/apt/apt.conf.d/01proxy

RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        software-properties-common \
        gcc \
        cmake \
        git \
        wget \
        vim \
        graphviz \
        libatlas-base-dev \
        libboost-all-dev \
        libgflags-dev \
        libgoogle-glog-dev \
        libhdf5-serial-dev \
        libleveldb-dev \
        liblmdb-dev \
        libopencv-dev \
        libprotobuf-dev \
        libsnappy-dev \
        protobuf-compiler \
        python-dev \
        python-numpy \
        python-pip \
        python-scipy \
        libhdf5-dev \
        swig

ENV CAFFE_ROOT=/opt/caffe
WORKDIR $CAFFE_ROOT

# FIXME: clone a specific git tag and use ARG instead of ENV once DockerHub supports this.
ENV CLONE_TAG=master

RUN git clone -b ${CLONE_TAG} --depth 1 https://github.com/BVLC/caffe.git . && \
    for req in $(cat python/requirements.txt) pydot; do pip install $req; done && \
    mkdir build && cd build && \
    # cmake -DUSE_CUDNN=1 .. && \
    cmake -DCUDA_ARCH_NAME=Manual -DCUDA_ARCH_BIN="61" -DCUDA_ARCH_PTX="61" -DUSE_CUDNN=1 .. && \
    make -j"$(nproc)"

ENV PYCAFFE_ROOT $CAFFE_ROOT/python
ENV PYTHONPATH $PYCAFFE_ROOT:$PYTHONPATH
ENV PATH $CAFFE_ROOT/build/tools:$PYCAFFE_ROOT:$PATH
RUN echo "$CAFFE_ROOT/build/lib" >> /etc/ld.so.conf.d/caffe.conf && ldconfig

WORKDIR /workspace


#
# https://github.com/NVIDIA/nvidia-docker/blob/master/ubuntu-14.04/digits/4.0/Dockerfile
# INSTALL DIGITS 4.0

ENV DIGITS_VERSION 4.0
LABEL com.nvidia.digits.version="4.0"


# https://github.com/NVIDIA/DIGITS/blob/master/docs/BuildTorch.md
# example location - can be customized
ENV TORCH_BUILD=/opt/torch
ENV TORCH_HOME=$TORCH_BUILD/install

RUN git clone https://github.com/torch/distro.git $TORCH_BUILD --recursive
RUN cd $TORCH_BUILD && \
./install-deps && \
./install.sh -b 
# RUN source ~/.bashrc


# https://github.com/NVIDIA/DIGITS/blob/master/docs/BuildDigits.md
# example location - can be customized
ENV DIGITS_HOME=/opt/digits
RUN git clone https://github.com/NVIDIA/DIGITS.git $DIGITS_HOME

RUN sudo pip install -r $DIGITS_HOME/requirements.txt

VOLUME /data
VOLUME /jobs

COPY digits.cfg digits/digits.cfg

EXPOSE 34448
WORKDIR /opt/digits

# turn this on if you want Digits to start automatically
#ENTRYPOINT ["/opt/digits/digits-server"]





#
# INSTALL TENSORFLOW
#
# https://github.com/tensorflow/tensorflow/blob/master/tensorflow/tools/docker/Dockerfile.gpu
#
# CUDA 8 / cuDNN 4
## http://textminingonline.com/dive-into-tensorflow-part-iii-gtx-1080-ubuntu16-04-cuda8-0-cudnn5-0-tensorflow

MAINTAINER Craig Citro <craigcitro@google.com>

# Pick up some TF dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        curl \
        libfreetype6-dev \
        libpng12-dev \
        libzmq3-dev \
        pkg-config \
        python \
        python-dev \
        rsync \
        software-properties-common \
        unzip \
        default-jre \
        default-jdk \
        && \
    apt-get clean

WORKDIR /opt

RUN wget https://github.com/bazelbuild/bazel/releases/download/0.3.0/bazel-0.3.0-installer-linux-x86_64.sh && chmod +x bazel-0.3.0-installer-linux-x86_64.sh && ./bazel-0.3.0-installer-linux-x86_64.sh --user

RUN curl -O https://bootstrap.pypa.io/get-pip.py && \
    python get-pip.py && \
    rm get-pip.py

RUN pip --no-cache-dir install \
        ipykernel \
        jupyter \
        matplotlib \
        numpy \
        scipy \
        && \
    python -m ipykernel.kernelspec

ENV TENSORFLOW_VERSION 0.10.0rc0
ENV TENSORFLOW_HOME=/opt/tensorflow

# --- DO NOT EDIT OR DELETE BETWEEN THE LINES --- #
# These lines will be edited automatically by parameterized_docker_build.sh. #
# COPY _PIP_FILE_ /
# RUN pip --no-cache-dir install /_PIP_FILE_
# RUN rm -f /_PIP_FILE_

# Install TensorFlow GPU version.
RUN pip --no-cache-dir install \
    http://storage.googleapis.com/tensorflow/linux/gpu/tensorflow-${TENSORFLOW_VERSION}-cp27-none-linux_x86_64.whl
# --- ~ DO NOT EDIT OR DELETE BETWEEN THE LINES --- #

# Set up our notebook config.
COPY jupyter_notebook_config.py /root/.jupyter/

# Copy sample notebooks.
COPY notebooks /notebooks

# Jupyter has issues with being run directly:
#   https://github.com/ipython/ipython/issues/7062
# We just add a little wrapper script.
COPY run_jupyter.sh /


# Make it easy to find things
RUN ln -s /usr/local/lib/python2.7/dist-packages/tensorflow/ /root/tensorflow


# TensorBoard
EXPOSE 6006
# IPython
EXPOSE 8888

WORKDIR "/notebooks"

CMD ["/run_jupyter.sh"]



RUN rm -rf /var/lib/apt/lists/*
