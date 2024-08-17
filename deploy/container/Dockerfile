FROM public.ecr.aws/amazonlinux/amazonlinux:2023
COPY ./check_login.sh .
RUN chmod 700 check_login.sh
RUN dnf update -y && \
    dnf install -y procps && \
    dnf -y localinstall --nogpgcheck https://dev.mysql.com/get/mysql80-community-release-el9-1.noarch.rpm && \
    rpm --import https://repo.mysql.com/RPM-GPG-KEY-mysql-2022 && \
    dnf -y install --nogpgcheck mysql mysql-community-client
ENTRYPOINT ["./check_login.sh"]
