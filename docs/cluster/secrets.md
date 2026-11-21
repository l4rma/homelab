# Secrets

The repository is public, so no secret is ever stored in Git, not even encrypted.
Secrets live in **AWS SSM Parameter Store** (region `eu-west-1`) and
[external-secrets](https://external-secrets.io/) copies them into the cluster as
normal Kubernetes Secrets.

```text
AWS SSM /homelab/<namespace>/<name>   (SecureString)
        │  read by the IAM user homelab-external-secrets
        ▼
ClusterSecretStore aws-ssm            (kubernetes/infrastructure/external-secrets/)
        │
        ▼
ExternalSecret in the app's folder    (in Git: only names and paths, no values)
        │
        ▼
Secret in the app's namespace         (created and refreshed by external-secrets)
```

## Bootstrap (done by hand, not in Git)

1. IAM user `homelab-external-secrets` with an inline policy that allows only
   `ssm:GetParameter`, `ssm:GetParameters` and `ssm:GetParametersByPath` on
   `parameter/homelab` and `parameter/homelab/*`. SecureStrings use the AWS managed
   key `aws/ssm`, which needs no extra KMS permission.
2. Its access key as the Secret `external-secrets/aws-ssm-credentials`
   (keys `access-key-id` and `secret-access-key`).

Same pattern as cert-manager's Route53 key. Later this moves to Terraform.

## Adding a secret

1. Store the value in AWS (it never touches the repo):

   ```sh
   aws ssm put-parameter --region eu-west-1 --type SecureString \
     --name /homelab/<namespace>/<name> --value '<value>'
   ```

   To change it later, add `--overwrite`. The value ends up in the shell history and, while
   the command runs, in the process list. To avoid that, create it in the AWS Console instead:
   **Systems Manager → Parameter Store → Create parameter**, tier Standard, type
   **SecureString** (KMS key `alias/aws/ssm`), and paste the value.
2. Add an `externalsecret.yaml` to the app's folder:

   ```yaml
   apiVersion: external-secrets.io/v1
   kind: ExternalSecret
   metadata:
     name: <app>-secrets
   spec:
     refreshInterval: 1h
     secretStoreRef:
       kind: ClusterSecretStore
       name: aws-ssm
     target:
       name: <app>-secrets            # the Kubernetes Secret that gets created
     data:
       - secretKey: DB_PASSWORD       # key in the Kubernetes Secret
         remoteRef:
           key: /homelab/<namespace>/db-password
   ```

3. Check `kubectl -n <namespace> get externalsecret`: `STATUS` should be
   `SecretSynced`.

A changed value in AWS reaches the cluster within `refreshInterval`. Apps that read the
Secret only at start-up need a restart to see it.

## Cost

Standard parameters are free. Reading SecureStrings uses KMS, which is free up to
20 000 requests a month. With `refreshInterval: 1h` that is room for about 25
ExternalSecrets; raise the interval if there are many more.
