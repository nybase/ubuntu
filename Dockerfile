FROM ubuntu:24.04

ENV TZ=Asia/Shanghai LANG=en_US.UTF-8  DEBIAN_FRONTEND=noninteractive UMASK=0022 CATALINA_HOME=/usr/local/tomcat CATALINA_BASE=/app/tomcat TOMCAT_MAJOR=9 
ENV PATH=$CATALINA_HOME/bin:/usr/java/latest/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin 

RUN export TZ=Asia/Shanghai LANG=en_US.UTF-8  DEBIAN_FRONTEND=noninteractive TOMCAT_MAJOR=9;\
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime ;\
    sed -i -e 's@ .*.ubuntu.com@ http://mirrors.163.com@g' -e 's@ .*.debian.org@ http://mirrors.163.com@g' /etc/apt/sources.list.d/ubuntu.sources;\
    apt-get update ; apt-get install -y --no-install-recommends ca-certificates curl wget apt-transport-https tzdata \
    dumb-init iproute2 iputils-ping iputils-arping telnet less vim-tiny unzip gosu fonts-dejavu-core tcpdump \
    net-tools socat traceroute jq mtr-tiny dnsutils psmisc \
    cron logrotate runit  gosu bsdiff libtcnative-1 libjemalloc-dev  vim netcat-openbsd openjdk-21-jdk openjdk-8-jdk; \
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime ;\
    useradd -u 8080 -m -s /bin/bash -o app; \
    mkdir -p ~/.pip && echo [global] > ~/.pip/pip.conf && echo "index-url = https://pypi.tuna.tsinghua.edu.cn/simple" >> ~/.pip/pip.conf ;  \
    echo registry=http://npmreg.mirrors.ustc.edu.cn/ > ~/.npmrc ; \
    apt-get clean  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* ;\
	test -d /usr/lib/jvm/java-1.8-openjdk      && ln -s /usr/lib/jvm/java-1.8-openjdk /usr/lib/jvm/temurin-8-jdk || true;\
	test -d /usr/lib/jvm/java-21-openjdk       && ln -s /usr/lib/jvm/java-21-openjdk /usr/lib/jvm/temurin-21-jdk || true ; \
	test -d /usr/lib/jvm/java-8-openjdk-amd64  && ln -s /usr/lib/jvm/java-8-openjdk-amd64 /usr/lib/jvm/temurin-8-jdk || true; \
	test -d /usr/lib/jvm/java-21-openjdk-amd64 && ln -s /usr/lib/jvm/java-21-openjdk-amd64 /usr/lib/jvm/temurin-21-jdk || true; \
    mkdir -p /usr/java/jvm; ln -s /usr/lib/jvm/temurin-8-jdk /usr/java/jvm/jdk1.8 || true; ln -s /usr/lib/jvm/temurin-21-jdk /usr/java/jdk-21 || true ; \
	TOMCAT_VER=`wget -q https://mirrors.tuna.tsinghua.edu.cn/apache/tomcat/tomcat-${TOMCAT_MAJOR}/ -O - | grep -v M|grep v${TOMCAT_MAJOR}|tail -1|awk '{split($0,c,"<a") ; split(c[2],d,"/") ;split(d[1],e,"v") ; print e[2]}'` ;\
    echo $TOMCAT_VER;wget -q -c https://mirrors.tuna.tsinghua.edu.cn/apache/tomcat/tomcat-${TOMCAT_MAJOR}/v${TOMCAT_VER}/bin/apache-tomcat-${TOMCAT_VER}.tar.gz -P /tmp ;\
    echo "app"> /etc/cron.allow  ;\
    mkdir -p /logs /usr/local/tomcat /app/tomcat/conf /app/tomcat/logs /app/tomcat/work /app/tomcat/bin /app/tomcat/lib/org/apache/catalina/util /app/lib /app/tmp /app/bin /app/war /app/jmx /app/skywalking  /app/otel ; \
    tar zxf /tmp/apache-tomcat-${TOMCAT_VER}.tar.gz -C /usr/local/tomcat --strip-components 1 ;\
    cp -rv /usr/local/tomcat/conf/* /app/tomcat/conf/ ;\
    rm -rf /usr/local/tomcat/webapps/* /app/tomcat/conf/context.xml || true;\
    sed -i -e 's@webapps@/app/war@g' -e 's@SHUTDOWN@UP_8001@g' /app/tomcat/conf/server.xml ;\
    sed -i -e 's/maxParameterCount="1000"$/maxParameterCount="1000" maxHttpHeaderSize="65536"  maxConnections="16384" \n maxThreads="1500" minSpareThreads="25" \
    maxSpareThreads="75"  acceptCount="1500" \n keepAliveTimeout="30000" enableLookups="false"  disableUploadTimeout="true"/g'  /app/tomcat/conf/server.xml;\
    echo -e "server.info=WAF\nserver.number=\nserver.built=\n" | tee /app/tomcat/lib/org/apache/catalina/util/ServerInfo.properties ;\
    echo "<tomcat-users/>" | tee  /app/tomcat/conf/tomcat-users.xml ;\
    SKYWALKING_AGENT_VER=`wget -q http://mirrors.cloud.tencent.com/apache/skywalking/java-agent/ -O - |grep 'href'|tail -1 | awk '{split($2,c,">") ; split(c[2],d,"/<") ; print d[1]}'` ;\
    echo $SKYWALKING_AGENT_VER;wget -q -c http://mirrors.cloud.tencent.com/apache/skywalking/java-agent/$SKYWALKING_AGENT_VER/apache-skywalking-java-agent-$SKYWALKING_AGENT_VER.tgz  -P /tmp;\
    tar zxf /tmp/apache-skywalking-java-agent-$SKYWALKING_AGENT_VER.tgz -C /app/skywalking --strip-components 1 ;\
    JMX_EXPORTER_VER=`wget -q https://mirrors.cloud.tencent.com/nexus/repository/maven-public/io/prometheus/jmx/jmx_prometheus_javaagent/maven-metadata.xml -O -|grep '<version>'| tail -1 | awk '{split($1,c,">") ; split(c[2],d,"<") ; print d[1]}'` ;\
    echo $JMX_EXPORTER_VER;wget -q -c https://mirrors.cloud.tencent.com/nexus/repository/maven-public/io/prometheus/jmx/jmx_prometheus_javaagent/${JMX_EXPORTER_VER}/jmx_prometheus_javaagent-${JMX_EXPORTER_VER}.jar -O /app/jmx/jmx_prometheus_javaagent.jar; \
    echo -e 'rules:\n- pattern: ".*"\n' > /app/jmx/config.yaml ;\
    OTEL_VER=$(wget -q https://mirrors.cloud.tencent.com/nexus/repository/maven-public/io/opentelemetry/javaagent/opentelemetry-javaagent/maven-metadata.xml -O -|grep '<version>'|grep -v -i SNAPSHOT| tail -1 | awk '{split($1,c,">") ; split(c[2],d,"<") ; print d[1]}') ;\
    echo $OTEL_VER;wget -q -c https://mirrors.cloud.tencent.com/nexus/repository/maven-public/io/opentelemetry/javaagent/opentelemetry-javaagent/${OTEL_VER}/opentelemetry-javaagent-${OTEL_VER}.jar -O /app/otel/opentelemetry-javaagent.jar; \
    echo "set mouse-=a" >> ~/.vimrc ;  echo "set mouse-=a" >> /home/app/.vimrc ;\
    chown app:app -R /usr/local/tomcat /app /logs /home/app/.vimrc ; 
    

WORKDIR /app/war

EXPOSE 8080
USER   8080

CMD ["catalina.sh", "run"]

