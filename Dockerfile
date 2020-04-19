FROM fpco/stack-build

# Install pandoc
RUN stack setup
RUN stack install pandoc roman-numerals-0.5.1.5 syb-0.6 pandoc-crossref-0.2.5.0 pandoc-include-0.0.1

#RUN stack install RUN stack install

## Install Latex and fonts
RUN apt-get update -y \
  && apt-get install -y --no-install-recommends \
  texlive-latex-base \
  texlive-xetex latex-xcolor \
  texlive-math-extra \
  texlive-latex-extra \
  texlive-fonts-extra \
  texlive-bibtex-extra \
  lmodern \
  ttf-bitstream-vera \
  fontconfig

## Install Node
RUN curl -sL https://deb.nodesource.com/setup_13.x | bash - && \
  apt-get install -y nodejs

## Install Java
RUN set -ex; \
  \
  apt-get update; \
  apt-get install -y \
  openjdk-8-jdk; \
  rm -rf /var/lib/apt/lists/*;

RUN mkdir -p ~/bin; curl -Ls https://git.io/sbt > ~/bin/sbt && chmod 0755 ~/bin/sbt

ENV PATH=~/bin:$PATH

WORKDIR /source