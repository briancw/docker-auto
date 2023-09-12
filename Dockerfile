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
RUN adduser auto
USER auto

# Setup Virtualenv
ENV VIRTUAL_ENV=/home/auto/venv
RUN python3 -m venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

# Python Deps
RUN pip install -U pip setuptools wheel
RUN pip install torch torchvision --no-cache-dir --extra-index-url https://download.pytorch.org/whl/cu118
# RUN --mount=type=cache,target=/home/auto/.cache/pip pip install torch

# Install Automatic1111
ADD https://api.github.com/repos/AUTOMATIC1111/stable-diffusion-webui/git/refs/heads/master version.json
RUN git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui.git /home/auto/sd
WORKDIR /home/auto/sd
ENV install_dir=/home/auto/sd
RUN pip install -r requirements_versions.txt
RUN pip install xformers
RUN /bin/bash -c "/home/auto/sd/webui.sh --skip-torch-cuda-test --exit"

# Install Codeformer deps
RUN wget https://github.com/xinntao/facexlib/releases/download/v0.1.0/detection_Resnet50_Final.pth -P repositories/CodeFormer/weights/facelib/
RUN wget https://github.com/sczhou/CodeFormer/releases/download/v0.1.0/parsing_parsenet.pth -P repositories/CodeFormer/weights/facelib/

# Add extensions so that their deps can be auto installed
WORKDIR /home/auto/sd/extensions
RUN git clone https://github.com/Bing-su/adetailer.git
RUN git clone https://github.com/Mikubill/sd-webui-controlnet.git
RUN git clone https://github.com/AlUlkesh/stable-diffusion-webui-images-browser.git
WORKDIR /home/auto/sd/
RUN /bin/bash -c "/home/auto/sd/webui.sh --skip-torch-cuda-test --exit"

# Install Roop seperately
WORKDIR /home/auto/sd/extensions
RUN git clone https://github.com/Gourieff/sd-webui-reactor.git
WORKDIR /home/auto/sd/
RUN /bin/bash -c "/home/auto/sd/webui.sh --skip-torch-cuda-test --exit"

# Set some ENV vars
#ENV LD_PRELOAD=libtcmalloc.so
ENV PYTHONUNBUFFERED=1
ENV LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libtcmalloc.so
ENV PYTORCH_CUDA_ALLOC_CONF='garbage_collection_threshold:0.9,max_split_size_mb:512'
#ENV SAFETENSORS_FAST_GPU=1
CMD ["python", "launch.py", "--listen", "--xformers", "--data-dir=/home/auto/sd/data", "--embeddings-dir=/home/auto/sd/data/models/embeddings"]
