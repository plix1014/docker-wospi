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


RUN apt update && \
  apt install -y curl unzip gnupg lsb-release ca-certificates net-tools coreutils cron bc mingetty screen lftp ntpdate gnuplot vim sudo python-serial python-dateutil python-pandas python-numpy python-ephem python-pip && \
  apt-get -y clean && \
  rm -r /var/cache/apt /var/lib/apt/lists/* && \
  pip install images2gif windrose Adafruit_Python_DHT

ENV HOMEPATH=/home/wospi

RUN groupadd -g 1003 wospi
RUN useradd -ms /bin/bash -u 1003 -g 1003 -G dialout -c "Weather Observation System for Raspberry Pi" -d $HOMEPATH wospi
#RUN echo "LC_CTYPE=en_US.UTF-8" >> $HOMEPATH/.profile

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
WORKDIR $HOMEPATH
ADD data/lftp.config.tar.gz $HOMEPATH
ADD data/wospi.tools.tar.gz $HOMEPATH

## TODO only for dev
#ADD data/dev/upload_cwop.py $HOMEPATH/tools
ADD data/wospi.tools_for_tests.tar.gz $HOMEPATH/tools


ADD data/scripts/fscp /usr/local/bin
ADD data/scripts/entrypoint.sh /

# add cron jobs
ADD data/cron/wetter_cron /etc/cron.d/wetter
ADD data/cron/wospi_cron /etc/cron.d/wospi
ADD data/scripts/rc.wospi /etc/init.d/wospi


RUN chown -R wospi:wospi $HOMEPATH /var/tmp/temp_plot /var/log/wospi


# additional user, probably not required
#RUN useradd -ms /home/wx/wxview.sh -c "WOSPI virtual terminal" wx
#COPY --chown=wx:wospi --chmod=755 data/scripts/wxview.sh /home/wx


# only for dev
# sudo and vim nice to have, but not necessary
RUN echo "wospi ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/030_wospi-nopasswd

#USER wospi

WORKDIR $HOMEPATH/wetter

#CMD ["python", "wospi.pyc"]
#ENTRYPOINT ["python", "wospi.pyc"]

ENTRYPOINT ["/entrypoint.sh"]
CMD ["wospi"]

