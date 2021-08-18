FROM klakegg/hugo:ext-alpine

# Install python/pip
ENV PYTHONUNBUFFERED=1
RUN apk --update-cache add --update --no-cache python3 && ln -sf python3 /usr/bin/python && \
    python3 -m ensurepip && \
    pip3 install --no-cache --upgrade pip setuptools && \
    apk --update-cache add --no-cache --virtual build-dependencies python3-dev && \
    pip install --no-cache academic && \
    apk del build-dependencies && \
    rm -rf /var/cache/apk/*

RUN mkdir /hugo
WORKDIR /hugo

ENTRYPOINT [ "/usr/bin/academic" ]
