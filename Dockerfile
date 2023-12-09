#------------------------------------------------------------------------------------------
# checkout git
FROM alpine/git:latest
WORKDIR /addon
RUN git clone https://github.com/plix1014/wospi-addon.git
RUN git clone https://github.com/plix1014/serialize_crontab.git
RUN git clone https://github.com/plix1014/vim-tools.git
#WORKDIR /addon/wospi-addon
#RUN git pull

#------------------------------------------------------------------------------------------
# build image
FROM debian:buster-slim as base

ARG CONT_VER WOSPI_VERSION WOSPI_RELEASE_DATE
ARG TESTENV=0
ARG UIDGID=6003


ENV CONT_VER=${CONT_VER:-0.5}
ENV WOSPI_VERSION=${WOSPI_VERSION:-20191127}
ENV WOSPI_RELEASE_DATE=${WOSPI_RELEASE_DATE:-2019-11-27}
ENV TERM=${TERM:-xterm-256color}
ENV LANG=${LANG:-en_US.UTF-8}
ENV TZ=${TZ:-Europe/Vienna}
# wospi config
ENV USERHOME=${USERHOME:-/home/wospi}
ENV HOMEPATH=${HOMEPATH:-${USERHOME}/wetter}
ENV CSVPATH=${CSVPATH:-${USERHOME}/csv_data}
ENV BACKUPPATH=${BACKUPPATH:-${USERHOME}/backup}
ENV TMPPATH=${TMPPATH:-/var/tmp/}
ENV WLOGPATH=${WLOGPATH:-/var/log/wospi}
ENV PYTHONUNBUFFERED=1

# mqtt parameter
ENV MQTT_HOST=${MQTT_HOST:-192.168.20.70}
ENV MQTT_PORT=${MQTT_PORT:-1883}
ENV MQTT_TOPIC_BASE=${MQTT_TOPIC_BASE:-athome/eg/wospi}
ENV WXIN=${WXIN:-/var/tmp/wxdata.xml}

# some lables
LABEL com.wospi.version=${WOSPI_VERSION}
LABEL com.wospi.release-date=${WOSPI_RELEASE_DATE}
LABEL com.wospi.maintainer="Torkel M. Jodalen <tmj@bitwrap.no>"
LABEL com.wospi.container.maintainer="plix1014@gmail.com"

# os config
RUN apt update && \
  apt-get install -y --no-install-recommends curl unzip gnupg lsb-release ca-certificates net-tools coreutils locales cron bc zip mutt lftp gnuplot gsfonts vim sudo python-serial python-dateutil procps gcal sqlite3 iputils-ping ftp telnet python-pandas python-numpy python-ephem python-pil python-pip python-paho-mqtt python-pyinotify python-setuptools libterm-readline-perl-perl libfreetype6-dev pkg-config gcc g++ patch python-dev && \
  pip install --no-cache-dir images2gif windrose Adafruit_Python_DHT python-dotenv && \
  sed -i -e 's,^# en_US,en_US,g' -e 's,^# de_AT,de_AT,g' /etc/locale.gen && \
  locale-gen && \
  update-locale && \
  apt-get -y clean && \
  rm -r /var/cache/apt /var/lib/apt/lists/* /var/log/*log

# patch images2gif
WORKDIR /
COPY data/images2gif.py.diff /tmp
RUN patch -p1 < /tmp/images2gif.py.diff

# user setup
RUN groupadd -g ${UIDGID} wospi && useradd -ms /bin/bash -u ${UIDGID} -g ${UIDGID} -G dialout -c "Weather Observation System for Raspberry Pi" -d $USERHOME wospi

# create directories
RUN bash -c 'mkdir -p $CSVPATH $TMPPATH/wospi $WLOGPATH $BACKUPPATH'


#------------------------------------------------------------------------------------------
# build wospi vanilla image
FROM base as image-vanilla

WORKDIR $HOMEPATH

# wospi distribution start
# https://www.annoyingdesigns.com/wospi/wospi.zip
#
ENV WFILE=/tmp/wospi.zip
RUN curl -S -o $WFILE https://www.annoyingdesigns.com/wospi/wospi.zip && unzip $WFILE && rm $WFILE
#
# wospi distribution end

# add scripts
COPY data/scripts/entrypoint.sh /
COPY data/.vimrc /root
COPY data/.vimrc $USERHOME

# add cron jobs
COPY --chown=root:root --chmod=0755 data/scripts/rc.wospi /etc/init.d/wospi
COPY --chown=root:root --chmod=0644 data/cron/wospi_cron /etc/cron.d/wospi

# set permissions
RUN chown -R wospi:wospi $USERHOME $TMPPATH/wospi $WLOGPATH $BACKUPPATH


# additional user, probably not required
RUN useradd -ms /home/wx/wxview.sh -c "WOSPI virtual terminal" wx
COPY --chown=wx:wospi --chmod=755 data/scripts/wxview.sh /home/wx


# sudo and vim nice to have, but not necessary
RUN echo "wospi ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/030_wospi-nopasswd


USER wospi

# set default dir
WORKDIR $HOMEPATH

# volume for csv files
VOLUME [ "$CSVPATH", "$TMPPATH", "$BACKUPPATH" ]

# start wospi
ENTRYPOINT ["/entrypoint.sh"]
CMD ["wospi"]


#------------------------------------------------------------------------------------------
# build prod image
FROM image-vanilla as image-prod
USER root

# add vcgen binary
ADD data/raspi.libs.tar.gz /

# my personal changes and addons

# my slight changes to original files
ADD data/wospi.local_mods.tar.gz .

# my additional scripts
#ADD data/wospi.my_addons.tar.gz .
COPY --from=0 /addon/wospi-addon/plotannualwind/plot* $HOMEPATH
COPY --from=0 /addon/wospi-addon/plotinternal/plot* $HOMEPATH
COPY --from=0 /addon/wospi-addon/plotrain/plot* $HOMEPATH
COPY --from=0 /addon/wospi-addon/plotsoc/plot* $HOMEPATH
COPY --from=0 /addon/wospi-addon/plotstatistics/plot* $HOMEPATH
COPY --from=0 /addon/wospi-addon/plotsun/plot* $HOMEPATH
COPY --from=0 /addon/wospi-addon/plotuptime/plot* $HOMEPATH
COPY --from=0 /addon/wospi-addon/plotuv/plot* $HOMEPATH
COPY --from=0 /addon/wospi-addon/wxtools.py $HOMEPATH

COPY --from=0 /addon/wospi-addon/transfer/fscp /usr/local/bin

# handy tools
COPY --chown=root:root --chmod=0755 --from=0 /addon/serialize_crontab/serialize_crontab.pl /usr/local/bin
COPY --chown=root:root --chmod=0755 --from=0 /addon/vim-tools/usr/local/bin/vip /usr/local/bin
COPY --chown=root:root --chmod=0755 --from=0 /addon/vim-tools/usr/local/bin/vipdiff /usr/local/bin
COPY --chown=root:root --chmod=0644 --from=0 /addon/vim-tools/usr/local/etc/vip.vim /usr/local/etc


# my tools for other weather sites
WORKDIR $USERHOME
COPY --from=0 /addon/wospi-addon/tools $USERHOME/tools
COPY --from=0 /addon/wospi-addon/satimage/satimage.py $USERHOME/tools
COPY --from=0 /addon/wospi-addon/cwop/upload_cwop.py $USERHOME/tools

# lftp config
ADD data/lftp.config.tar.gz $USERHOME

# add cron jobs
COPY --chown=root:root --chmod=0644 data/cron/wetter_cron /etc/cron.d/wetter

# set permissions
RUN chown -R wospi:wospi $USERHOME $TMPPATH/wospi $WLOGPATH $BACKUPPATH

USER wospi

#------------------------------------------------------------------------------------------
# build dev image
FROM image-prod as image-dev
USER root

## TODO only for dev. Remove in final image!!!!
ADD data/wospi.tools_for_tests.tar.gz /

# set permissions
RUN chown -R wospi:wospi $USERHOME $TMPPATH/wospi $WLOGPATH $BACKUPPATH && chown root:root /etc/cron.d/wetter

USER wospi

