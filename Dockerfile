FROM python:3.10.12-slim-bookworm

RUN apt-get update -y && apt-get upgrade -y
RUN apt-get install -y \
    git \
    curl \
    wget \
    build-essential \
    libgles2-mesa-dev \
    libglib2.0-0 \
    libgoogle-perftools-dev \
    pkg-config

# Switch to non root user
RUN adduser sd
USER sd

# Setup Virtualenv
ENV VIRTUAL_ENV=/home/sd/venv
RUN python3 -m venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

# Python Deps
RUN pip install -U pip setuptools wheel
RUN pip install torch torchvision --no-cache-dir --extra-index-url https://download.pytorch.org/whl/cu118
RUN pip install xformers

# Make python output unbuffered which is important for docker
ENV PYTHONUNBUFFERED=1

# Install Automatic1111
ADD https://api.github.com/repos/AUTOMATIC1111/stable-diffusion-webui/git/refs/heads/master version.json
RUN git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui.git /home/sd/auto
WORKDIR /home/sd/auto
ENV install_dir=/home/sd/auto
RUN pip install -r requirements_versions.txt
RUN /bin/bash -c "/home/sd/auto/webui.sh --skip-torch-cuda-test --exit"

# Get Codeformer weights
RUN wget https://github.com/xinntao/facexlib/releases/download/v0.1.0/detection_Resnet50_Final.pth -P repositories/CodeFormer/weights/facelib/
RUN wget https://github.com/sczhou/CodeFormer/releases/download/v0.1.0/parsing_parsenet.pth -P repositories/CodeFormer/weights/facelib/

# Add extensions so that their deps can be auto installed
WORKDIR /home/sd/auto/extensions
RUN git clone https://github.com/Bing-su/adetailer.git
RUN git clone https://github.com/Mikubill/sd-webui-controlnet.git
RUN git clone https://github.com/zanllp/sd-webui-infinite-image-browsing.git
WORKDIR /home/sd/auto
RUN /bin/bash -c "/home/sd/auto/webui.sh --skip-torch-cuda-test --exit"

# Install Reactor seperately because it's dependencies are pretty big
WORKDIR /home/sd/auto/extensions
RUN git clone https://github.com/Gourieff/sd-webui-reactor.git
WORKDIR /home/sd/auto
RUN /bin/bash -c "/home/sd/auto/webui.sh --skip-torch-cuda-test --exit"

# Set some ENV vars
ENV PYTORCH_CUDA_ALLOC_CONF='garbage_collection_threshold:0.9,max_split_size_mb:512'
ENV LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libtcmalloc.so
