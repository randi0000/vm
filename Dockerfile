FROM kalilinux/kali-rolling@sha256:99a8a101fb7c3747f5f55886d0b698e67424c1815d0b70d057643fce620da324

RUN apt update && \
    DEBIAN_FRONTEND=noninteractive apt install -y kali-desktop-xfce kali-linux-default locales sudo

RUN apt update && \
    DEBIAN_FRONTEND=noninteractive apt install -y xrdp tigervnc-standalone-server && \
    adduser xrdp ssl-cert && \
    echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=en_US.UTF-8

ARG USER=testuser
ARG PASS=1234

RUN useradd -m $USER -p $(openssl passwd $PASS) && \
    usermod -aG sudo $USER && \
    chsh -s /bin/bash $USER

RUN echo "#!/bin/sh\n\
export XDG_SESSION_DESKTOP=xfce\n\
export XDG_SESSION_TYPE=x11\n\
export XDG_CURRENT_DESKTOP=XFCE\n\
export XDG_CONFIG_DIRS=/etc/xdg/xdg-xfce:/etc/xdg\n\
exec dbus-run-session -- xfce4-session" > /xstartup && chmod +x /xstartup

RUN mkdir /home/$USER/.vnc && \
    echo $PASS | vncpasswd -f > /home/$USER/.vnc/passwd && \
    chmod 0600 /home/$USER/.vnc/passwd && \
    chown -R $USER:$USER /home/$USER/.vnc

RUN cp -f /xstartup /etc/xrdp/startwm.sh && \
    cp -f /xstartup /home/$USER/.vnc/xstartup

RUN echo "#!/bin/sh\n\
sudo -u $USER -g $USER -- vncserver -rfbport 5902 -geometry 1920x1080 -depth 24 -verbose -localhost no -autokill no" > /startvnc && chmod +x /startvnc

EXPOSE 3389
EXPOSE 5902

ENV PULSE_SERVER=/tmp/PulseServer
ENV WAYLAND_DISPLAY=wayland-0
ENV XDG_RUNTIME_DIR=/tmp/runtime-dir/
ENV DISPLAY=:0

CMD service dbus start; /usr/lib/systemd/systemd-logind & service xrdp start; /startvnc; bash
