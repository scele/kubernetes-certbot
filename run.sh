#/usr/bin/env bash

set -e

if kubectl get secret ${SECRET_NAME}; then
    echo "Secret ${SECRET_NAME} already exists, nothing to do."
    exit 0
fi

if [ "$CERT_PROVIDER" = "kubernetes" ]; then

    echo "Generating cluster internal certificate for ${CERT_DOMAIN}"

    cat <<EOF | cfssl genkey - | cfssljson -bare server
{
  "hosts": [
    "${CERT_DOMAIN}"
  ],
  "CN": "${CERT_DOMAIN}",
  "key": {
    "algo": "ecdsa",
    "size": 256
  }
}
EOF

    cat <<EOF | kubectl create -f -
apiVersion: certificates.k8s.io/v1beta1
kind: CertificateSigningRequest
metadata:
  name: ${CERT_DOMAIN}
spec:
  groups:
  - system:authenticated
  request: $(cat server.csr | base64 | tr -d '\n')
  usages:
  - digital signature
  - key encipherment
  - server auth
EOF

    echo "Approving certificate"
    kubectl certificate approve ${CERT_DOMAIN}
    kubectl get csr ${CERT_DOMAIN} -o jsonpath='{.status.certificate}' | base64 -d > server.crt

    echo "Creating Kubernetes secret ${SECRET_NAME}"
    kubectl create secret tls ${SECRET_NAME} --cert=server.crt --key=server-key.pem

elif [ "$CERT_PROVIDER" = "letsencrypt" ]; then

    echo "Requesting certificate from LetsEncrypt for ${CERT_DOMAIN}"
    certbot certonly \
        -n --agree-tos \
        -d ${CERT_DOMAIN} \
        $@

    echo "Generating kubernetes secret ${SECRET_NAME}"
    cat << EOF > "secret.yml"
apiVersion: v1
kind: Secret
metadata:
  name: "${SECRET_NAME}"
type: Opaque
data:
  cert.pem: "$(cat /etc/letsencrypt/live/${CERT_DOMAIN}/cert.pem | base64 --wrap=0)"
  chain.pem: "$(cat /etc/letsencrypt/live/${CERT_DOMAIN}/chain.pem | base64 --wrap=0)"
  fullchain.pem: "$(cat /etc/letsencrypt/live/${CERT_DOMAIN}/fullchain.pem | base64 --wrap=0)"
  privkey.pem: "$(cat /etc/letsencrypt/live/${CERT_DOMAIN}/privkey.pem | base64 --wrap=0)"
EOF

    kubectl apply -f "secret.yml"

else
    echo "Unknown provider"
    exit 1
fi
