"""
Lambda Function 1
-----------------
Triggered by an S3 "object created" event.

What it does:
  1. Reads the bucket name and object key from the event records.
  2. Logs the details so we can see them in the Lambda logs.
  3. Returns a small JSON response describing what it received.
"""

import json


def handler(event, context):
    print("Function 1 invoked")
    print("Raw event:", json.dumps(event))

    processed = []

    # An S3 event can contain more than one record, so loop over all of them.
    for record in event.get("Records", []):
        s3_info = record.get("s3", {})
        bucket_name = s3_info.get("bucket", {}).get("name", "unknown-bucket")
        object_key = s3_info.get("object", {}).get("key", "unknown-key")

        print(f"New object uploaded -> bucket: {bucket_name}, key: {object_key}")

        processed.append({
            "bucket": bucket_name,
            "key": object_key,
        })

    response = {
        "statusCode": 200,
        "body": json.dumps({
            "message": "Function 1 processed the S3 event",
            "objects": processed,
        }),
    }

    print("Function 1 response:", json.dumps(response))
    return response
