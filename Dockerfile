FROM debian:buster-slim

ARG CONT_VER WOSPI_VERSION WOSPI_RELEASE_DATE TERM LANG

ENV CONT_VER=${CONT_VER:-0.5}
ENV WOSPI_VERSION=${WOSPI_VERSION:-20191127}
ENV WOSPI_RELEASE_DATE=${WOSPI_RELEASE_DATE:-2019-11-27}
ENV TERM=${TERM:-xterm-256color}
ENV LANG=${LANG:-en_US.UTF-8}


LABEL com.wospi.version=${WOSPI_VERSION}
LABEL com.wospi.release-date=${WOSPI_RELEASE_DATE}
LABEL com.wospi.maintainer="Torkel M. Jodalen <tmj@bitwrap.no>"
LABEL com.wospi.container.maintainer="plix1014"


RUN apt update && apt install -y curl unzip gnupg lsb-release ca-certificates net-tools coreutils mingetty screen lftp ntpdate gnuplot vim sudo python-serial python-dateutil python-pandas python-numpy python-ephem python-pip 

RUN pip install images2gif windrose

ENV HOMEPATH=/home/wospi

RUN groupadd -g 1004 wospi
RUN useradd -ms /bin/bash -u 1001 -g 1004 -G dialout -c "Weather Observation System for Raspberry Pi" -d $HOMEPATH wospi
RUN echo "LC_CTYPE=en_US.UTF-8" >> $HOMEPATH/.profile

# create directories
RUN bash -c 'mkdir -p $HOMEPATH/csv_data /var/tmp/temp_plot /var/log/wospi'

WORKDIR $HOMEPATH/wetter

# wospi distribution
ADD data/wospi.20191127.tar.gz .

# my slight changes to original files
ADD data/wospi.local_mods.tar.gz .

# my additional scripts
ADD data/wospi.my_addons.tar.gz .

# my tools for other weather sites
ADD data/tools.tar.gz $HOMEPATH
ADD data/lftp.config.tar.gz $HOMEPATH


WORKDIR $HOMEPATH

ADD data/fscp /usr/local/bin

RUN chown -R wospi:wospi $HOMEPATH /var/tmp/temp_plot /var/log/wospi


# additional user, probably not required
RUN useradd -ms /home/wx/wxview.sh -c "WOSPI virtual terminal" wx
COPY --chown=wx:wospi --chmod=755 data/wxview.sh /home/wx


# only for dev
# sudo and vim nice to have, but not necessary
RUN echo "wospi ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/030_wospi-nopasswd

USER wospi

WORKDIR $HOMEPATH/wetter

#ENTRYPOINT ["/bin/bash"]
#CMD ["/bin/bash"]

#ENTRYPOINT ["/usr/bin/python", "wospi.pyc"]

CMD ["python", "wospi.pyc"]


