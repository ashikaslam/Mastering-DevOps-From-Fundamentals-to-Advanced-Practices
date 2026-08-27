#!/usr/bin/env bash
#
# update_lambda.sh
# ----------------
# Demonstrates updating a Lambda after it has already been deployed.
#
# It rewrites src/function1.py so that it also:
#   - logs the object key in UPPERCASE
#   - logs a processing timestamp
# then repackages the code and pushes it with:
#   awslocal lambda update-function-code
#
# Run deploy.sh first so that function1 already exists.

set -euo pipefail

FUNC1_NAME="function1"
BUILD_DIR="build"

# Pick awslocal, or fall back to the AWS CLI with the LocalStack endpoint.
if command -v awslocal >/dev/null 2>&1; then
  AWS="awslocal"
else
  AWS="aws --endpoint-url=http://localhost:4566"
fi
export AWS_DEFAULT_REGION="us-east-1"
export AWS_ACCESS_KEY_ID="test"
export AWS_SECRET_ACCESS_KEY="test"

echo "==> Rewriting src/function1.py with extra details"

cat > src/function1.py <<'PY'
"""
Lambda Function 1 (updated)
---------------------------
Triggered by an S3 "object created" event.

Updated version now also logs:
  - the object key in UPPERCASE
  - a processing timestamp
"""

import json
from datetime import datetime, timezone


def handler(event, context):
    print("Function 1 invoked (updated version)")
    print("Raw event:", json.dumps(event))

    processed_at = datetime.now(timezone.utc).isoformat()
    print(f"Processing timestamp: {processed_at}")

    processed = []

    for record in event.get("Records", []):
        s3_info = record.get("s3", {})
        bucket_name = s3_info.get("bucket", {}).get("name", "unknown-bucket")
        object_key = s3_info.get("object", {}).get("key", "unknown-key")

        print(f"New object uploaded -> bucket: {bucket_name}, key: {object_key}")
        print(f"Object key (uppercase): {object_key.upper()}")

        processed.append({
            "bucket": bucket_name,
            "key": object_key,
            "key_uppercase": object_key.upper(),
            "processed_at": processed_at,
        })

    response = {
        "statusCode": 200,
        "body": json.dumps({
            "message": "Function 1 (updated) processed the S3 event",
            "processed_at": processed_at,
            "objects": processed,
        }),
    }

    print("Function 1 response:", json.dumps(response))
    return response
PY

echo "==> Repackaging function1"
mkdir -p "$BUILD_DIR"
rm -f "$BUILD_DIR/function1.zip"
zip -j "$BUILD_DIR/function1.zip" src/function1.py

echo "==> Updating Lambda code for $FUNC1_NAME"
$AWS lambda update-function-code \
  --function-name "$FUNC1_NAME" \
  --zip-file "fileb://$BUILD_DIR/function1.zip"

# Wait for the update to settle.
sleep 3

echo "==> Uploading a fresh file to trigger the updated function"
echo "Updated run - $(date)" > test-updated.txt
$AWS s3 cp test-updated.txt "s3://my-event-bucket/test-updated.txt"

sleep 8

LOG_GROUP="/aws/lambda/$FUNC1_NAME"
echo ""
echo "==> Fetching latest logs from $LOG_GROUP"
STREAMS=$($AWS logs describe-log-streams \
  --log-group-name "$LOG_GROUP" \
  --order-by LastEventTime --descending \
  --query 'logStreams[0].logStreamName' --output text)

echo "Latest log stream: $STREAMS"
echo "----------------------------------------"
$AWS logs get-log-events \
  --log-group-name "$LOG_GROUP" \
  --log-stream-name "$STREAMS" \
  --query 'events[].message' --output text
echo "----------------------------------------"

echo ""
echo "Done. You should now see the UPPERCASE key and processing timestamp in the logs."
