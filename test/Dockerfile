FROM localhost/openvpn_client:latest

RUN apk add --no-cache bash curl

ENV BATS_VERSION=1.9.0

RUN curl -L -o /tmp/bats.tar.gz https://github.com/bats-core/bats-core/archive/v$BATS_VERSION.tar.gz \
    && tar xf /tmp/bats.tar.gz -C /tmp \
    && cd /tmp/bats-core-$BATS_VERSION \
    && ./install.sh /usr/local

RUN rm /usr/sbin/openvpn
COPY openvpn_mock /usr/sbin/openvpn
RUN chmod +x /usr/sbin/openvpn

WORKDIR /test

COPY *.bats .

RUN chmod +x *.bats

CMD ["bats", "*.bats"]
