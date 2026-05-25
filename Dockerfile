FROM --platform=linux/amd64 ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV DISPLAY=:1

RUN apt update && apt install -y \
    xfce4 xfce4-goodies \
    tigervnc-standalone-server \
    novnc websockify \
    dbus-x11 xterm \
    firefox \
    curl wget net-tools \
    && apt clean

# Setup VNC
RUN mkdir -p /root/.vnc

# password kosong (insecure)
RUN echo "" | vncpasswd -f > /root/.vnc/passwd
RUN chmod 600 /root/.vnc/passwd

# XFCE startup
RUN printf '#!/bin/sh\nunset SESSION_MANAGER\nunset DBUS_SESSION_BUS_ADDRESS\nexec startxfce4\n' > /root/.vnc/xstartup && chmod +x /root/.vnc/xstartup

# Start script
RUN printf '#!/bin/bash\n\
export DISPLAY=:1\n\
PORT=${PORT:-8080}\n\
\n\
# hapus lock lama\n\
rm -rf /tmp/.X1-lock /tmp/.X11-unix/X1\n\
vncserver -kill :1 >/dev/null 2>&1 || true\n\
\n\
# start VNC\n\
vncserver :1 -geometry 1280x720 -depth 24 -localhost no -SecurityTypes None\n\
sleep 5\n\
\n\
# test VNC port dulu\n\
netstat -tlnp\n\
\n\
# noVNC ke port Railway\n\
exec websockify --web=/usr/share/novnc/ $PORT localhost:5901\n' > /start.sh && chmod +x /start.sh

CMD ["/start.sh"]
