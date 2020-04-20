FROM thomasweise/docker-pandoc

## Install Node the easy way

# This doesn't work on "development" versions of Ubuntu
# like the one on which the thomasweise/docker-pandoc is based.

# RUN curl -sL https://deb.nodesource.com/setup_13.x | bash - && \
#   apt-get install -y --no-install-recommends \
#   nodejs

## Install Node manually

RUN apt-get update -y \
  && apt-get install -y gnupg lsb

ENV APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=DontWarn

RUN curl -sSL https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add - \
  && VERSION=node_12.x \
  && DISTRO="$(lsb_release -s -c)" \
  && echo "deb https://deb.nodesource.com/$VERSION $DISTRO main" | tee /etc/apt/sources.list.d/nodesource.list \
  && echo "deb-src https://deb.nodesource.com/$VERSION $DISTRO main" | tee -a /etc/apt/sources.list.d/nodesource.list \
  && apt-get update -y \
  && apt-get install -y nodejs

## Install Java

RUN set -ex \
  && apt-get update -y \
  && DEBIAN_FRONTEND=noninteractive \
  && mkdir -p /usr/share/man/man1 \
  && apt-get install -y default-jdk-headless \
  && apt-get clean \

  ## Install SBT

  RUN mkdir -p ~/bin; curl -Ls https://git.io/sbt > ~/bin/sbt && chmod 0755 ~/bin/sbt

## Install fonts

RUN apt-get install -y ttf-bitstream-vera

## Clean up

RUN rm -rf /var/lib/apt/lists/*

## Tweak PATH

ENV PATH=~/bin:$PATH

## Yay! We're done!

WORKDIR /source
