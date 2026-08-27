# Module 16 Assignment — S3-triggered Lambdas on LocalStack

A small, beginner-friendly project that runs AWS **S3 + Lambda + IAM** locally
using **LocalStack** and **Docker**. No real AWS account or cost involved.

## What's in here

| File                | Purpose                                                                 |
| ------------------- | ---------------------------------------------------------------------- |
| `docker-compose.yml`| Starts LocalStack on port `4566` with `s3, lambda, iam`.              |
| `src/function1.py`  | Lambda triggered by S3 uploads — logs bucket name + object key.       |
| `src/function2.py`  | Lambda that receives data and returns a formatted JSON response.      |
| `deploy.sh`         | Creates the bucket, deploys both Lambdas, wires the S3 trigger, tests it. |
| `update_lambda.sh`  | Updates `function1` (uppercase filename + timestamp) and redeploys.   |

## Prerequisites

- Docker + Docker Compose
- `zip`
- **awslocal** (recommended): `pip install awscli-local`
  - If you don't install it, the scripts automatically fall back to
    `aws --endpoint-url=http://localhost:4566` (needs the AWS CLI).

Dummy credentials are enough for LocalStack — the scripts set:

```
AWS_ACCESS_KEY_ID=test
AWS_SECRET_ACCESS_KEY=test
AWS_DEFAULT_REGION=us-east-1
```

## Step-by-step

### 1. Start LocalStack

```bash
docker compose up -d
docker compose ps          # localstack should be "healthy"/"running"
```

Quick health check:

```bash
curl http://localhost:4566/_localstack/health
```

You should see `s3`, `lambda`, and `iam` listed as available.

### 2. Deploy everything

```bash
chmod +x deploy.sh update_lambda.sh
./deploy.sh
```

This will:

1. Create S3 bucket `my-event-bucket`.
2. Zip `src/function1.py` and `src/function2.py` and deploy them as Lambdas.
3. Add an S3 event notification: `s3:ObjectCreated:*` → `function1`.
4. Create `test.txt` and upload it to the bucket (fires the event).
5. Print `function1`'s CloudWatch logs — you should see the **bucket name**
   and **object key** logged.

### 3. Test function2 directly (optional)

```bash
awslocal lambda invoke \
  --function-name function2 \
  --payload '{"name":"Ashik","data":{"course":"DevOps","module":16}}' \
  --cli-binary-format raw-in-base64-out \
  out.json

cat out.json
```

You should get a formatted JSON response with a greeting and timestamp.

### 4. Update function1 and redeploy

```bash
./update_lambda.sh
```

This rewrites `function1` to also log the **object key in UPPERCASE** and a
**processing timestamp**, pushes it with `awslocal lambda update-function-code`,
uploads a new file, and shows the updated logs.

### 5. Verify outputs

```bash
# Bucket exists
awslocal s3 ls

# Objects in the bucket
awslocal s3 ls s3://my-event-bucket

# Lambdas deployed
awslocal lambda list-functions --query 'Functions[].FunctionName'

# function1 logs (bucket name + object key, then uppercase + timestamp)
awslocal logs tail /aws/lambda/function1 --format short
```

## Cleanup

```bash
docker compose down -v
rm -rf build .localstack test.txt test-updated.txt out.json
```

## Submission screenshot checklist

- [ ] `docker compose ps` showing LocalStack running
- [ ] `curl .../_localstack/health` showing s3, lambda, iam
- [ ] `./deploy.sh` output: bucket created + both Lambdas deployed
- [ ] `awslocal lambda list-functions` showing `function1` and `function2`
- [ ] `function1` logs showing the **bucket name and object key**
- [ ] `function2` direct invoke output (`out.json`) with formatted JSON
- [ ] `./update_lambda.sh` output showing **UPPERCASE key + timestamp** in logs
- [ ] `awslocal s3 ls s3://my-event-bucket` showing the uploaded test files
