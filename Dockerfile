# Base image
FROM node:16-alpine AS base

WORKDIR /srv/
RUN apk add --no-cache git

#########################################################################

# Builder image
FROM base AS builder-web

WORKDIR /srv/
# I set it to this branch because development was broken. To change to a stable branch when they make one.
# at the time of this writting streamio web is beta.
RUN git clone --branch refactor/video-player https://github.com/Stremio/stremio-web.git


WORKDIR /srv/stremio-web
RUN npm install
# RUN npm audit fix
RUN npm audit fix --force
RUN npm run build

RUN git clone https://github.com/Stremio/stremio-shell.git
RUN wget $(cat stremio-shell/server-url.txt)


##########################################################################
LABEL description="Stremio's web player and streaming Server"

# Main image
FROM node:16-alpine

WORKDIR /srv/stremio
COPY ./stremio-web-service-run.sh ./
COPY ./extract_certificate.js ./
RUN chmod +x *.sh
COPY --from=builder-web /srv/stremio-web/build ./build
COPY --from=builder-web /srv/stremio-web/server.js ./
RUN npm install -g http-server


ENV FFMPEG_BIN=
ENV FFPROBE_BIN=

# Custom application path for storing server settings, certificates, etc
ENV APP_PATH="/srv/stremio-config/"
ENV NO_CORS=1
ENV CASTING_DISABLED=
# Set this to your lan or public ip.
ENV IPADDRESS=

RUN apk add --no-cache ffmpeg openssl curl

VOLUME ["$APP_PATH"]

# Expose default ports
EXPOSE 8080 11470 12470

CMD ["./stremio-web-service-run.sh"]
