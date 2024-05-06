FROM ubuntu:24.04

ENV TZ=Asia/Shanghai LANG=en_US.UTF-8  DEBIAN_FRONTEND=noninteractive UMASK=0022 CATALINA_HOME=/usr/local/tomcat CATALINA_BASE=/app/tomcat TOMCAT_MAJOR=9 
ENV PATH=$CATALINA_HOME/bin:/usr/java/latest/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin 

RUN export TZ=Asia/Shanghai LANG=en_US.UTF-8  DEBIAN_FRONTEND=noninteractive;\
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime ;\
    sed -i -e 's@ .*.ubuntu.com@ http://mirrors.163.com@g' -e 's@ .*.debian.org@ http://mirrors.163.com@g' /etc/apt/sources.list.d/ubuntu.sources;\
    apt-get update ; apt-get install -y --no-install-recommends ca-certificates curl wget apt-transport-https tzdata \
    dumb-init iproute2 iputils-ping iputils-arping telnet less vim-tiny unzip gosu fonts-dejavu-core tcpdump \
    net-tools socat traceroute jq mtr-tiny dnsutils psmisc \
    cron logrotate runit  gosu bsdiff libtcnative-1 libjemalloc-dev  vim netcat-openbsd openjdk-21-jdk openjdk-8-jdk; \
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime ;\
    useradd -u 8080 -s /bin/bash -o app; \
    mkdir -p ~/.pip && echo [global] > ~/.pip/pip.conf && echo "index-url = https://pypi.tuna.tsinghua.edu.cn/simple" >> ~/.pip/pip.conf ;  \
    echo registry=http://npmreg.mirrors.ustc.edu.cn/ > ~/.npmrc ; \
    apt-get clean  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
