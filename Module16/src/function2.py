"""
Lambda Function 2
-----------------
A simple "receiver" function.

It takes whatever data it is given in the event and returns a nicely
formatted JSON response. Useful as a second step in a small workflow
or just to practice invoking Lambdas directly.
"""

import json
from datetime import datetime, timezone


def handler(event, context):
    print("Function 2 invoked")
    print("Received data:", json.dumps(event))

    # Pull a couple of friendly fields out of the event if they exist.
    name = event.get("name", "there")
    payload = event.get("data", event)

    body = {
        "message": f"Hello {name}, Function 2 received your data.",
        "received_at": datetime.now(timezone.utc).isoformat(),
        "data": payload,
    }

    response = {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(body, indent=2),
    }

    print("Function 2 response:", json.dumps(response))
    return response
