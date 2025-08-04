FROM public.ecr.aws/amazonlinux/amazonlinux:2023 AS builder

ARG VALKEY_VERSION=8.1.3
ENV VALKEY_VERSION=${VALKEY_VERSION}

RUN dnf update -y && \
    dnf install -y gcc make wget openssl-devel tar gzip && \
    dnf clean all

RUN wget https://github.com/valkey-io/valkey/archive/refs/tags/${VALKEY_VERSION}.tar.gz && \
    tar xzf ${VALKEY_VERSION}.tar.gz && \
    cd valkey-${VALKEY_VERSION} && \
    make distclean && \
    make valkey-cli BUILD_TLS=yes && \
    install -m 755 src/valkey-cli /usr/local/bin/ && \
    cd .. && \
    rm -rf valkey-${VALKEY_VERSION} ${VALKEY_VERSION}.tar.gz


FROM public.ecr.aws/amazonlinux/amazonlinux:2023

COPY ./container/check_login.sh .
RUN chmod 700 check_login.sh

COPY --from=builder /usr/local/bin/valkey-cli /usr/local/bin/

RUN dnf update -y && \
    dnf install -y procps openssl util-linux && \
    dnf -y localinstall --nogpgcheck https://dev.mysql.com/get/mysql80-community-release-el9-1.noarch.rpm && \
    rpm --import https://repo.mysql.com/RPM-GPG-KEY-mysql-2022 && \
    dnf -y install --nogpgcheck mysql mysql-community-client && \
    dnf clean all

ENV SLEEP_SECONDS=900
ENTRYPOINT ["sh", "-c", "./check_login.sh $SLEEP_SECONDS"]
