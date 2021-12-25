FROM debian:unstable-20211220-slim

# build-essential - make
RUN apt-get update && \
  apt-get upgrade -y && \
  apt-get install --no-install-recommends -y \
  build-essential \
  clang

RUN mkdir --parents /workspace
WORKDIR /workspace

COPY . /workspace

CMD ["/bin/bash"]
