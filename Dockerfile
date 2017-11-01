FROM debian:9.2

RUN \
  apt-get update && \
  apt-get install ---yes python-pip curl && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN pip install \
  certbot-dns-route53

RUN \
  curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.8.0/bin/linux/amd64/kubectl && \
  chmod +x kubectl && \
  mv kubectl /usr/local/bin

RUN \
  apt-get update && \
  apt-get install --yes libssl-dev libffi-dev && \
  pip install -U setuptools pip && \
  pip install cryptography==1.9

RUN \
  curl -LO https://pkg.cfssl.org/R1.2/cfssl_linux-amd64 && \
  chmod +x cfssl_linux-amd64 && \
  mv cfssl_linux-amd64 /usr/local/bin/cfssl && \
  curl -LO https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64 && \
  chmod +x cfssljson_linux-amd64 && \
  mv cfssljson_linux-amd64 /usr/local/bin/cfssljson

COPY run.sh .

ENTRYPOINT ["/bin/bash", "/run.sh"]
