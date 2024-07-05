FROM registry.sdcc.bnl.gov/sciserver/gpu-essentials:pytorch-2.1.0b041924c
#FROM registry.sdcc.bnl.gov/sciserver/sciserver-essentials:3.2b041924b
#FROM registry.sdcc.bnl.gov/sciserver/gpu-essentials:2.0a


# To build environment outside of SDCC
USER root
RUN mv /etc/environment /etc/environment.bak

USER idies
WORKDIR /home/idies

# cmake will install latest version to ensure compilation
RUN 	conda init bash && \
	conda install -c conda-forge mamba cmake -n base -y && \
	mamba create -n md python=3.10 -c conda-forge -y && \
	echo "source `which conda`" >> ~/.bashrc && \
	echo "source `which mamba`" >> ~/.bashrc && \
	echo "conda activate md" >> ~/.bashrc

RUN wget https://ftp.gromacs.org/gromacs/gromacs-2024.2.tar.gz && \
    tar -xvf gromacs-2024.2.tar.gz && \
    rm gromacs-2024.2.tar.gz


RUN cd gromacs-2024.2 && \
    mkdir build && \
    cd build && \
    cmake .. \
        -DGMX_BUILD_OWN_FFTW=ON \
        -DREGRESSIONTEST_DOWNLOAD=ON \
        -DGMX_GPU=CUDA \
        -DGMX_USE_RDTSCP=ON \
        -DGMX_SIMD=AVX2_256 \
        -DGMX_BUILD_TESTS=OFF \
        -DGMX_INSTALL_NBLIB_API=OFF \
        -DGMX_HWLOC=OFF \
        -DGMX_MPI=OFF \
        -DGMX_OPENMP=ON \
	-DCUDA_TOOLKIT_ROOT_DIR=/usr/local/cuda-11 && \
    make -j$(nproc) && \
    make check 

# recover proxy settings
USER root
RUN mv /etc/environment.bak /etc/environment

# installation and clean up
RUN cd gromacs-2024.2/build && \
    make install
RUN rm -rf gromacs*


USER idies

# Source GROMACS environment script and verify installation
RUN echo "source /usr/local/gromacs/bin/GMXRC" >> ~/.bashrc
RUN /bin/bash -c "source /usr/local/gromacs/bin/GMXRC && gmx --version"

# Set the default shell to bash
SHELL ["/bin/bash", "-c"]

# CMD
CMD ["bash"]
