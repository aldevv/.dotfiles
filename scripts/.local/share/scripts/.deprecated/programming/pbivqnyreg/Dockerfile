FROM jfloff/alpine-python:3.8

WORKDIR /usr/src/app

COPY . .

RUN apk update \
    && apk add --update py-pip python3 postgresql-libs \
    && apk add --virtual .build-deps gcc python3-dev musl-dev postgresql-dev \
    && apk add build-base python-dev py-pip jpeg-dev zlib-dev \
    && python3 -m pip install --upgrade pip \
    && python3 -m pip install -r requirements.txt --no-cache-dir \
    && apk --purge del .build-deps \
    && chmod +x bootstrap
