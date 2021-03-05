FROM alpine

# Install python/pip
ENV PYTHONUNBUFFERED=1
RUN apk --update-cache add --update --no-cache python3 && ln -sf python3 /usr/bin/python
RUN python3 -m ensurepip
RUN pip3 install --no-cache --upgrade pip setuptools

RUN apk --update-cache add --no-cache --update hugo go git
RUN apk --update-cache add --no-cache --virtual build-dependencies python3-dev \
    && pip install --no-cache academic \
    && apk del build-dependencies

RUN rm -rf /var/cache/apk/*

RUN mkdir /hugo
WORKDIR /hugo

ENTRYPOINT [ "/usr/bin/academic" ]
