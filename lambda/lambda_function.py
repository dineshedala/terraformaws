import boto3
import csv
import io
import os
import urllib.parse
from datetime import datetime, timezone

s3 = boto3.client("s3")


def lambda_handler(event, context):
    record = event["Records"][0]
    bucket = record["s3"]["bucket"]["name"]
    key = urllib.parse.unquote_plus(record["s3"]["object"]["key"])

    # Avoid infinite loop: skip files we already processed
    if key.startswith("processed-"):
        print(f"Skipping already-processed file: {key}")
        return {"statusCode": 200, "body": "Skipped"}

    if not key.lower().endswith(".csv"):
        print(f"Skipping non-CSV file: {key}")
        return {"statusCode": 200, "body": "Skipped - not a CSV"}

    print(f"Processing s3://{bucket}/{key}")

    # Read the CSV from S3
    response = s3.get_object(Bucket=bucket, Key=key)
    content = response["Body"].read().decode("utf-8")

    reader = csv.DictReader(io.StringIO(content))
    fieldnames = reader.fieldnames + ["processed_at"]

    output = io.StringIO()
    writer = csv.DictWriter(output, fieldnames=fieldnames)
    writer.writeheader()

    timestamp = datetime.now(timezone.utc).isoformat()
    for row in reader:
        row["processed_at"] = timestamp
        writer.writerow(row)

    # Build new file name
    base_name = os.path.basename(key)
    new_key = f"processed-{base_name}"

    # Write back to the same bucket
    s3.put_object(
        Bucket=bucket,
        Key=new_key,
        Body=output.getvalue().encode("utf-8"),
        ContentType="text/csv",
    )

    print(f"Wrote result to s3://{bucket}/{new_key}")
    return {"statusCode": 200, "body": f"Processed and saved as {new_key}"}
