FROM pimachinelearning/raspi-python:3.9.16

RUN apt-get update && apt-get install -y git libatlas3-base libgfortran5 ccache
RUN git clone https://github.com/pytorch/pytorch.git
RUN cd pytorch && git checkout v2.0.1 && git submodule sync
RUN cd pytorch && git submodule update --init --recursive
COPY pip.conf /etc/pip.conf
RUN python3.9 -m pip install --upgrade pip
RUN python3.9 -m pip install cmake ninja
                # piwheels messed up 1.24.3 builds
RUN cd pytorch && python3.9 -m pip install numpy==1.24.2 && python3.9 -m pip install -r requirements.txt
COPY *.patch /pytorch/
RUN cd pytorch && patch -p1 < 0001-Convert-ld-to-zu-in-python_function.cpp-for-the-same.patch && patch -p1 < 0002-Use-zu-instead-of-ld-because-ld-in-python_arg_parser.patch && patch -p1 < '0003-Cast-to-ssize_t-if-int64_t->-ssize_t.patch'

CMD cd pytorch && MAX_JOBS=$(nproc --ignore=${IGNORE_CORES:-8}) USE_XNNPACK=OFF USE_CUDA=0 USE_CUDNN=0 USE_MKLDNN=0 USE_METAL=0 USE_NCCL=OFF USE_NNPACK=1 USE_QNNPACK=0 USE_PYTORCH_QNNPACK=0 USE_DISTRIBUTED=0 BUILD_TEST=0 CFLAGS="-march=armv8-a+crc+simd -mfpu=vfpv3-d16" python3.9 setup.py bdist_wheel
