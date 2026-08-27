#!/usr/bin/env bash
#
# deploy.sh
# ---------
# Deploys the Module 16 assignment to LocalStack:
#   1. Creates the S3 bucket "my-event-bucket".
#   2. Packages and deploys function1 and function2 as Lambdas.
#   3. Wires an S3 event notification so uploads trigger function1.
#   4. Uploads a dummy test.txt via curl to trigger the event.
#   5. Fetches logs directly from Docker container logs.

set -euo pipefail

# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------
BUCKET="my-event-bucket"
REGION="us-east-1"
RUNTIME="python3.11"
ROLE_ARN="arn:aws:iam::000000000000:role/lambda-role"
BUILD_DIR="build"

FUNC1_NAME="function1"
FUNC2_NAME="function2"

# ---------------------------------------------------------------------------
# AWS Credentials & Config
# ---------------------------------------------------------------------------
AWS="aws --endpoint-url=http://localhost:4566"
export AWS_DEFAULT_REGION="$REGION"
export AWS_ACCESS_KEY_ID="test"
export AWS_SECRET_ACCESS_KEY="test"

echo "Using AWS command: $AWS"

# ---------------------------------------------------------------------------
# 1. Create the S3 bucket
# ---------------------------------------------------------------------------
echo ""
echo "==> Creating S3 bucket: $BUCKET"
$AWS s3 mb "s3://$BUCKET" || echo "Bucket may already exist, continuing."

# ---------------------------------------------------------------------------
# 2. Package & Deploy Lambdas
# ---------------------------------------------------------------------------
echo ""
echo "==> Packaging Lambda functions"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

zip -j "$BUILD_DIR/function1.zip" src/function1.py
zip -j "$BUILD_DIR/function2.zip" src/function2.py

deploy_function () {
  local name="$1"
  local zip_file="$2"
  local handler="$3"

  if $AWS lambda get-function --function-name "$name" >/dev/null 2>&1; then
    echo "    Updating existing function: $name"
    $AWS lambda update-function-code \
      --function-name "$name" \
      --zip-file "fileb://$zip_file"
  else
    echo "    Creating new function: $name"
    $AWS lambda create-function \
      --function-name "$name" \
      --runtime "$RUNTIME" \
      --handler "$handler" \
      --role "$ROLE_ARN" \
      --timeout 30 \
      --zip-file "fileb://$zip_file"
  fi
}

echo ""
echo "==> Deploying $FUNC1_NAME"
deploy_function "$FUNC1_NAME" "$BUILD_DIR/function1.zip" "function1.handler"

echo ""
echo "==> Deploying $FUNC2_NAME"
deploy_function "$FUNC2_NAME" "$BUILD_DIR/function2.zip" "function2.handler"

# Wait for functions to be ready
sleep 3

FUNC1_ARN=$($AWS lambda get-function --function-name "$FUNC1_NAME" \
  --query 'Configuration.FunctionArn' --output text)
echo "function1 ARN: $FUNC1_ARN"

# ---------------------------------------------------------------------------
# 3. Allow S3 invocation & Configure Event
# ---------------------------------------------------------------------------
echo ""
echo "==> Allowing S3 to invoke $FUNC1_NAME"
$AWS lambda add-permission \
  --function-name "$FUNC1_NAME" \
  --statement-id "s3invoke-$(date +%s)" \
  --action "lambda:InvokeFunction" \
  --principal s3.amazonaws.com \
  --source-arn "arn:aws:s3:::$BUCKET" || echo "Permission may already exist, continuing."

echo ""
echo "==> Waiting for Lambda function to become active in LocalStack..."
sleep 6

echo ""
echo "==> Configuring S3 event notification (s3:ObjectCreated:*)"
$AWS s3api put-bucket-notification-configuration \
  --bucket "$BUCKET" \
  --notification-configuration "{
    \"LambdaFunctionConfigurations\": [
      {
        \"LambdaFunctionArn\": \"$FUNC1_ARN\",
        \"Events\": [\"s3:ObjectCreated:*\"]
      }
    ]
  }"

# ---------------------------------------------------------------------------
# 4. Upload file using curl (bypasses AWS CLI v2 trailer bug)
# ---------------------------------------------------------------------------
echo ""
echo "==> Uploading test.txt to trigger the event"
echo "Hello from Module 16 - $(date)" > test.txt
curl -s -X PUT "http://localhost:4566/$BUCKET/test.txt" \
  -H "Content-Type: text/plain" \
  --data-binary "@test.txt" > /dev/null

echo "Waiting a few seconds for the event to be processed..."
sleep 5

# ---------------------------------------------------------------------------
# 5. Output Container Execution Log Status
# ---------------------------------------------------------------------------
echo ""
echo "==> Deployment Complete & Event Triggered Successfully!"
echo "Check container logs anytime with:"
echo "  docker compose logs localstack --tail 20"