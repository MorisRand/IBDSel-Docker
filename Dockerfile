FROM ubuntu:20.04 

ARG DEBIAN_FRONTEND=noninteractive

ARG root_version=6.22.02
ENV ROOT_VERSION=$root_version

ARG cxx_standard=17
ENV CXX_STANDARD=$cxx_standard

# install dependencies
WORKDIR /soft
COPY requirements.txt packages xrd_packages /tmp/
RUN apt-get update && apt-get install -y --no-install-recommends apt-transport-https ca-certificates gnupg \
software-properties-common curl \
&& curl https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | gpg --dearmor - | tee /etc/apt/trusted.gpg.d/kitware.gpg /dev/null \
&& curl http://storage-ci.web.cern.ch/storage-ci/storageci.key 2>/dev/null | gpg --dearmor - | tee /etc/apt/trusted.gpg.d/storage-cern-ci.gpg /dev/null \
&& apt-add-repository 'deb https://apt.kitware.com/ubuntu/ focal main' \
&& apt-add-repository 'deb http://storage-ci.web.cern.ch/storage-ci/debian/xrootd/ focal release' \
&& apt-get update && apt-get -y install --no-install-recommends $(cat /tmp/packages) \
&& apt-get install -y  $(cat /tmp/xrd_packages) \
&& python3 -m pip install wheel \
&& python3 -m pip install -r /tmp/requirements.txt \
&& apt remove -y gnupg apt-transport-https ca-certificates \
&& apt autoremove -y && apt autoclean -y && rm -rf /var/lib/apt/lists/* && rm -rf * /usr/share/man/* && rm -rf /tmp/*

#build Root
RUN curl -O "https://root.cern.ch/download/root_v${ROOT_VERSION}.source.tar.gz"  && \
tar -xzf "root_v${ROOT_VERSION}.source.tar.gz" && cd "root-${ROOT_VERSION}/build/" \
&& cmake -DCMAKE_CXX_STANDARD=$CXX_STANDARD -Dbuiltin_xrootd=ON .. \
&& cmake --build . --target install  -- -j$(nproc --all) \
&& cd ../.. && rm -r "root_v${ROOT_VERSION}.source.tar.gz" "root-${ROOT_VERSION}"

ENV LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH
ENV CMAKE_MODULE_PATH=/usr/local/cmake:$CMAKE_MODULE_PATH
