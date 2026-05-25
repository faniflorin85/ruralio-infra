# Ruralio — Infrastructură AWS cu Terraform

Infrastructură ca și cod (IaC) pentru găzduirea site-ului de prezentare
**Casa Dunărea** (ruralio.ro), cu deploy automat prin GitHub Actions.

## Ce conține

- **VPC** cu o subrețea publică și una privată
- **Internet Gateway** + **Route Table** pentru acces la internet
- **Security Group** (HTTP, HTTPS, SSH restricționat)
- **Instanță EC2** (`t3.micro`, Ubuntu 22.04) cu **Elastic IP**
- **Nginx** instalat automat la pornire
- **OIDC + IAM Role** pentru autentificarea GitHub Actions fără chei statice
- **Pipeline CI/CD**: `plan` pe Pull Request, `apply` + deploy site pe `main`

## Structură

```
ruralio-infra/
├── .github/workflows/deploy.yml   # pipeline CI/CD
├── terraform/                     # codul de infrastructură
│   ├── main.tf                    # provider + backend S3
│   ├── network.tf                 # VPC, subnets, IGW, route table
│   ├── security.tf                # security group
│   ├── compute.tf                 # EC2 + Elastic IP
│   ├── github-oidc.tf             # OIDC provider + rol IAM
│   ├── variables.tf               # variabile
│   ├── outputs.tf                 # valori afișate după apply
│   ├── user-data.sh               # script de pornire (Nginx)
│   └── terraform.tfvars.example   # șablon de variabile
├── site/                          # fișierele site-ului
└── .gitignore
```

---

## Pași de pornire

### 1. Creează backend-ul pentru state (o singură dată)

State-ul Terraform stă într-un bucket S3 cu lock în DynamoDB. Acestea
trebuie create înainte de `terraform init`:

```bash
export AWS_PROFILE=ruralio

aws s3api create-bucket \
  --bucket ruralio-terraform-state-332241527149 \
  --region eu-central-1 \
  --create-bucket-configuration LocationConstraint=eu-central-1

aws s3api put-bucket-versioning \
  --bucket ruralio-terraform-state-332241527149 \
  --versioning-configuration Status=Enabled

aws dynamodb create-table \
  --table-name ruralio-terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region eu-central-1
```

### 2. Generează o cheie SSH

```bash
ssh-keygen -t ed25519 -f ~/.ssh/ruralio -N ""
```

Aceasta creează `~/.ssh/ruralio` (privată) și `~/.ssh/ruralio.pub` (publică).
Terraform folosește cheia publică pentru instanță.

### 3. Configurează variabilele

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

Editează `terraform.tfvars`:
- `ssh_allowed_cidr` — IP-ul tău public + `/32` (află-l cu `curl ifconfig.me`)
- `github_repo` — repository-ul tău, format `owner/repo`

### 4. Primul apply (de pe laptop)

```bash
terraform init
terraform plan
terraform apply
```

Primul `apply` se rulează local pentru că rolul OIDC nu există încă —
pipeline-ul nu se poate autentifica până nu îl creează Terraform.

După apply, notează valorile din `outputs`: IP-ul public și ARN-ul rolului.

### 5. Configurează GitHub

1. Creează un repository pe GitHub și urcă acest cod:
   ```bash
   git init
   git add .
   git commit -m "Initial infrastructure"
   git remote add origin git@github.com:owner/ruralio-infra.git
   git push -u origin main
   ```

2. În repository → Settings → Secrets and variables → Actions, adaugă
   secret-ul **`SSH_PRIVATE_KEY`** cu conținutul fișierului `~/.ssh/ruralio`
   (cheia privată — necesară pentru ca pipeline-ul să copieze site-ul).

3. Verifică în `deploy.yml` că `role-to-assume` are Account ID-ul corect.

### 6. DNS pentru ruralio.ro

La furnizorul domeniului, creează două înregistrări **A** către Elastic IP:

```
ruralio.ro       A    <Elastic IP din outputs>
www.ruralio.ro   A    <același IP>
```

### 7. Activează HTTPS

Conectează-te la server și rulează Certbot:

```bash
ssh -i ~/.ssh/ruralio ubuntu@<Elastic IP>
sudo certbot --nginx -d ruralio.ro -d www.ruralio.ro
```

---

## Flux de lucru zilnic

1. Modifici codul (site sau infrastructură)
2. Creezi un branch și un Pull Request → pipeline-ul rulează `terraform plan`
3. Verifici planul, apoi faci merge în `main`
4. Pipeline-ul rulează `terraform apply` și copiază site-ul pe server

## Costuri

`t3.micro` este în free tier în primul an. După, costul lunar e mic
(instanță + Elastic IP atașată sunt gratuite cât instanța rulează).
S3 și DynamoDB pentru state costă fracțiuni de cent.

## Distrugerea infrastructurii

```bash
cd terraform
terraform destroy
```
