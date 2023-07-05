FROM localhost/openvpn_client:latest

RUN apk add --no-cache bash curl
RUN curl -L -o bats.tar.gz https://github.com/bats-core/bats-core/archive/v1.4.1.tar.gz \
    && tar -xf bats.tar.gz \
    && cd bats-core-1.4.1 \
    && ./install.sh /usr/local
RUN rm /usr/sbin/openvpn
COPY openvpn_mock /usr/sbin/openvpn

RUN chmod +x /usr/sbin/openvpn

RUN mkdir /test
WORKDIR /test

COPY *.bats .

RUN chmod +x *.bats

CMD ["bats", "*.bats"]
