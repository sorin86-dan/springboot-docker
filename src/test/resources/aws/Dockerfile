FROM jenkins/jenkins:jdk11

USER root

#=============================================================
# Set sudo without password
#=============================================================
RUN apt-get update \
      && apt-get install -y sudo \
      && rm -rf /var/lib/apt/lists/*
RUN echo "jenkins ALL=NOPASSWD: ALL" >> /etc/sudoers

#=============================================================
# Install Maven
#=============================================================
RUN apt-get update \
      && apt-get install maven -y


#=============================================================
# Install AWS CLI
#=============================================================
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install

USER jenkins