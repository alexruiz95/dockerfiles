# DESCRIPTION:	  Create OpenPTV container with its dependencies
# AUTHOR:		  Alex Liberzon <alexlib@eng.tau.ac.il>
# COMMENTS:
#	This file describes how to build an OpenPTV and OpenPTV-Python container with all
#	dependencies installed. It uses native X11 unix socket.
#	Tested on Mac OS X
# USAGE:
#	# Download Dockerfile
#	# Build openptv image
#	docker build -t openptv .
#
#	docker run -v /tmp/.X11-unix:/tmp/.X11-unix \
#		--device=/dev/sda:/dev/sda \
#		-e DISPLAY=unix$DISPLAY openptv
#
#
#    On Mac OS X: 
#    # read https://blog.bennycornelissen.nl/bwc-gui-apps-in-docker-on-osx/
#    # use a simple version by those steps:
#     
#    open -a XQuartz
#    IP=$(ifconfig en0 | grep inet | awk '$1=="inet" {print $2}')
#    xhost + $IP
#    docker run --rm -it --name openptv -e DISPLAY=$IP:0 -v /tmp/.X11-unix:/tmp/.X11-unix openptv
# 
#   Save these commands in a run_openptv.sh and make it executable
# -------------------------------------------------------------------
#   On Windows:
#   # read https://dev.to/darksmile92/run-gui-app-in-linux-docker-container-on-windows-host-4kde
# 
# USAGE:
#   # Use PowerShell in administrtive mode
#   # Run Docker Linux Containers
#	# Download Dockerfile
# 
#   ipconfig
#   set-variable -name DISPLAY -value XX.XX.XXX.XXX:0.0
#   # Run VcXSRV 
#	docker build -t openptv .
#   docker run --rm -it --name openptv -e DISPLAY=$DISPLAY openptv
#   # Now in bash:
#       python pyptv_gui.py ../../test_cavity
#
#   # If error, you may need to fix the dask/ufunc.py as shown above


FROM continuumio/miniconda
MAINTAINER Alex Liberzon <alexlib@tauex.tau.ac.il>

ENV LANG en-US

WORKDIR /home

RUN conda update -y conda && \
    conda install -y \
    gcc_linux-64 \
    gxx_linux-64 \
    gfortran_linux-64 \
    numpy \
    scipy \
    cython \
    scikit-image \
    pyqt \
    chaco \
    enable \
    nose \
    kiwisolver \
    future && \
    conda clean --tarballs && \
    conda clean --packages && \
    apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libglu1-mesa \
    libgtk2.0-dev \
    nano \
    cmake && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    wget https://github.com/libcheck/check/files/71408/check-0.10.0.tar.gz && \
    tar -xvf check-0.10.0.tar.gz && \
    rm check-0.10.0.tar.gz && \
    cd check-0.10.0 && \
    ./configure && \
    make && \
    make install
    
RUN cd /home && \
    git clone --depth 1 -b master --recursive --single-branch https://github.com/alexlib/pyptv.git && \
    cd /home/pyptv/openptv/liboptv && mkdir build && cd build && \
    cmake ../ -G "Unix Makefiles" && \
    make && \
    make verify && \
    make install && \
    cd /home/pyptv/openptv/py_bind && \
    python setup.py build_ext -I/usr/local/include -L/usr/local/lib && \
    python setup.py install && \
    cd /home/pyptv && \
    python setup.py install && \
    cd /home && \
    git clone --depth 1 -b master --single-branch https://github.com/OpenPTV/test_cavity.git

RUN sed -i 's/cbrt/#cbrt/' /opt/conda/lib/python2.7/site-packages/dask/array/ufunc.py
    
ENV LD_LIBRARY_PATH /usr/local/lib:${LD_LIBRARY_PATH}

WORKDIR /home/pyptv/pyptv/

# CMD python pyptv_gui.py /home/test_cavity

CMD ["python", "./pyptv_gui.py", "../../test_cavity"]

