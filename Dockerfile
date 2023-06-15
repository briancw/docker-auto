FROM debian:bullseye

RUN apt-get update -y && apt-get upgrade -y
RUN apt-get install -y git curl wget build-essential libgles2-mesa-dev libgoogle-perftools-dev pkg-config

# Install Python
RUN apt-get install -y python3 python3-pip python3-venv

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

ENV PYTHONUNBUFFERED=1
CMD ["python", "launch.py", "--listen", "--xformers", "--data-dir=/home/auto/sd/data", "--embeddings-dir=/home/auto/sd/data/models/embeddings"]
