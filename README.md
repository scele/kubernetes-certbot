# kubernetes-certbot

Simplify the process of requesting, signing and storing certificates into
Kubernetes secrets.

## Examples

Request a new staging certificate from LetsEncrypt for `myservice.example.com`
and store it in a secret `myservice-tls` (assumes running on AWS, and
assumes [sufficient IAM permissions](https://github.com/certbot/certbot/blob/master/certbot-dns-route53/examples/sample-aws-policy.json) for Route 53):

```sh
kubectl run scele/kubernetes-certbot:1.5 \
    --provider letsencrypt \
    --secret myservice-tls \
    --domain myservice.example.com \
    --email admin@example.com
    --dns-route53
    --staging
```

Perform above sequence before installing a Helm chart:

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: myservice-certbot
  annotations:
    "helm.sh/hook": pre-install
    "helm.sh/hook-delete-policy": hook-succeeded
spec:
  backoffLimit: 1
  template:
    metadata:
      name: myservice-certbot
    spec:
      restartPolicy: Never
      containers:
        - name: certbot
          image: "scele/kubernetes-certbot:1.5"
          imagePullPolicy: Always
          args:
            - --secret myservice-tls
            - --provider letsencrypt
            - --domain myservice.example.com
            - --email admin@example.com
            - --dns-route53
            - --staging
```

Request a new cluster-internal certificate from
the [default Kubernetes certificate manager](https://kubernetes.io/docs/tasks/tls/managing-tls-in-a-cluster/),
and store it in a secret `myservice-tls` (assumes the user has permissions to approve certificates):

```sh
kubectl run scele/kubernetes-certbot:1.5 \
    --provider kubernetes \
    --secret myservice-tls \
    --domain myservice.default.svc.cluster.local
```

Perform above sequence before installing a Helm chart:

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: myservice-certbot
  annotations:
    "helm.sh/hook": pre-install
    "helm.sh/hook-delete-policy": hook-succeeded
spec:
  backoffLimit: 1
  template:
    metadata:
      name: myservice-certbot
    spec:
      restartPolicy: Never
      containers:
        - name: certbot
          image: "scele/kubernetes-certbot:1.5"
          imagePullPolicy: Always
          args:
            - --secret myservice-tls
            - --provider kubernetes
            - --domain myservice.default.svc.cluster.local
```
