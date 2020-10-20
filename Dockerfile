FROM ubuntu:20.04 

ARG DEBIAN_FRONTEND=noninteractive

ARG root_version=6.22.02
ENV ROOT_VERSION=$root_version

ARG cxx_standard=17
ENV CXX_STANDARD=$cxx_standard

# install dependencies
WORKDIR /soft
COPY requirements.txt /tmp
COPY packages /tmp
RUN echo $ROOT_VERSION && apt-get update && apt-get -y install --no-install-recommends $(cat /tmp/packages) \
&& curl https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | gpg --dearmor - | tee /etc/apt/trusted.gpg.d/kitware.gpg /dev/null \
&& apt-add-repository 'deb https://apt.kitware.com/ubuntu/ focal main' \
&& apt-get update && apt-get install -y --no-install-recommends cmake \
&& python3 -m pip install wheel \
&& python3 -m pip install -r /tmp/requirements.txt \
&& apt remove -y gnupg apt-transport-https ca-certificates \
&& apt autoremove -y && apt autoclean -y && rm -rf /var/lib/apt/lists/* && rm -rf /tmp/*

#build Root
RUN curl -O "https://root.cern.ch/download/root_v${ROOT_VERSION}.source.tar.gz"  && \
tar -xzf "root_v${ROOT_VERSION}.source.tar.gz" && cd "root-${ROOT_VERSION}/build/" \
&& cmake -DCMAKE_CXX_STANDARD=$CXX_STANDARD -Dbuiltin_xrootd=ON .. \
&& cmake --build . --target install  -- -j$(nproc --all) \
&& cd ../.. && rm -r "root_v${ROOT_VERSION}.source.tar.gz" "root-${ROOT_VERSION}"
