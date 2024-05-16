FROM BASE

COPY overlay/ /

RUN /usr/local/bin/setup.sh
