FROM --platform=linux/amd64 ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV DISPLAY=:1
ENV PULSE_SERVER=127.0.0.1

# Base packages
RUN apt update -y && apt install --no-install-recommends -y \
    xfce4 \
    xfce4-goodies \
    tigervnc-standalone-server \
    novnc \
    websockify \
    sudo \
    xterm \
    vim \
    net-tools \
    curl \
    wget \
    git \
    tzdata \
    dbus-x11 \
    x11-utils \
    x11-xserver-utils \
    x11-apps \
    software-properties-common \
    pulseaudio \
    pulseaudio-utils \
    ffmpeg \
    python3 \
    python3-pip \
    && apt clean

# Firefox repo
RUN add-apt-repository ppa:mozillateam/ppa -y
RUN echo 'Package: *' >> /etc/apt/preferences.d/mozilla-firefox
RUN echo 'Pin: release o=LP-PPA-mozillateam' >> /etc/apt/preferences.d/mozilla-firefox
RUN echo 'Pin-Priority: 1001' >> /etc/apt/preferences.d/mozilla-firefox
RUN echo 'Unattended-Upgrade::Allowed-Origins:: "LP-PPA-mozillateam:jammy";' \
    > /etc/apt/apt.conf.d/51unattended-upgrades-firefox

RUN apt update -y && apt install -y firefox xubuntu-icon-theme

# VNC setup
RUN mkdir -p /root/.vnc
RUN touch /root/.Xauthority

# Startup script
RUN echo '#!/bin/bash\n\
export DISPLAY=:1\n\
\n\
# Start PulseAudio\n\
pulseaudio --start --exit-idle-time=-1\n\
pactl load-module module-null-sink sink_name=virtual_output || true\n\
pactl set-default-sink virtual_output\n\
\n\
# Start VNC\n\
vncserver -localhost no -SecurityTypes None -geometry 1024x768 --I-KNOW-THIS-IS-INSECURE\n\
\n\
# SSL cert\n\
openssl req -new -subj "/C=JP" -x509 -days 365 -nodes -out /self.pem -keyout /self.pem\n\
\n\
# noVNC\n\
websockify -D --web=/usr/share/novnc/ --cert=/self.pem 6080 localhost:5901\n\
\n\
# Audio stream\n\
ffmpeg -f pulse -i virtual_output.monitor \
-acodec libmp3lame \
-b:a 128k \
-f mp3 \
-listen 1 \
http://0.0.0.0:8000 &\n\
\n\
tail -f /dev/null' > /start.sh && chmod +x /start.sh

EXPOSE 5901
EXPOSE 6080
EXPOSE 8000

CMD ["/start.sh"]
