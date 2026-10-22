FROM debian:bookworm-slim
RUN dpkg --add-architecture i386 \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
       wine wine32:i386 wine64 xvfb openbox x11vnc novnc websockify \
       scrot xdotool x11-utils fonts-liberation file innoextract p7zip-full cabextract \
    && rm -rf /var/lib/apt/lists/* \
    && useradd --uid 1000 --create-home wine
COPY installer.exe /opt/reference/installer.exe
COPY start.sh /opt/reference/start.sh
RUN chmod 0555 /opt/reference/start.sh && chmod 0444 /opt/reference/installer.exe
USER 1000:1000
ENV DISPLAY=:99 HOME=/home/wine WINEPREFIX=/home/wine/prefix WINEARCH=win32 WINEDEBUG=-all
EXPOSE 6080
ENTRYPOINT ["/bin/sh", "/opt/reference/start.sh"]
