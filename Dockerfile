#
# ssh server installution
# Reference to https://docs.docker.jp/engine/examples/running_ssh_service.html
#
FROM eclipse-temurin:11.0.17_8-jdk

RUN apt-get update \
    && apt-get install -y openssh-server git \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir /var/run/sshd
RUN echo 'root:jenkins' | chpasswd
RUN echo 'PermitRootLogin yes' > /etc/ssh/sshd_config.d/permit-root-login.conf
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" > /etc/profile.d/docker-ssh.sh

# container has the jdk path already. But when connect through vscode, in terminal, dont have the jdk path.
# so, make custom profile in Dockerfile layer.
RUN echo "export PATH=/opt/java/openjdk/bin/java:$PATH" > /etc/profile.d/java-path.sh

# ssh secret key configuration
RUN mkdir /root/.ssh \
    && chown root:root /root/.ssh \
    && chmod 700 /root/.ssh

#
# maven installution
#
ARG MAVEN_VERSION=3.8.7
ARG USER_HOME_DIR="/root"
ARG SHA=21c2be0a180a326353e8f6d12289f74bc7cd53080305f05358936f3a1b6dd4d91203f4cc799e81761cf5c53c5bbe9dcc13bdb27ec8f57ecf21b2f9ceec3c8d27
ARG BASE_URL=https://apache.osuosl.org/maven/maven-3/${MAVEN_VERSION}/binaries

RUN mkdir -p /usr/share/maven /usr/share/maven/ref \
  && curl -fsSL -o /tmp/apache-maven.tar.gz ${BASE_URL}/apache-maven-${MAVEN_VERSION}-bin.tar.gz \
  && echo "${SHA}  /tmp/apache-maven.tar.gz" | sha512sum -c - \
  && tar -xzf /tmp/apache-maven.tar.gz -C /usr/share/maven --strip-components=1 \
  && rm -f /tmp/apache-maven.tar.gz \
  && ln -s /usr/share/maven/bin/mvn /usr/bin/mvn

ENV MAVEN_HOME /usr/share/maven
ENV MAVEN_CONFIG "$USER_HOME_DIR/.m2"

#
#
#
EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]
