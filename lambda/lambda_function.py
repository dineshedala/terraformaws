import boto3
import io
import os
import urllib.parse
import pandas as pd
from datetime import datetime, timezone

s3 = boto3.client("s3")

REQUIRED_COLUMNS = {"DeptName", "Salary"}


def lambda_handler(event, context):
    print(f"Payload from s3 event: {event}")
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

    # Read the CSV from S3 directly into a DataFrame
    response = s3.get_object(Bucket=bucket, Key=key)
    content = response["Body"].read().decode("utf-8")
    df = pd.read_csv(io.StringIO(content))

    if not REQUIRED_COLUMNS.issubset(df.columns):
        print(f"Missing required columns in {key}. Found: {list(df.columns)}")
        return {
            "statusCode": 400,
            "body": f"CSV must contain columns: {REQUIRED_COLUMNS}",
        }

    # Add processed_at timestamp
    df["processed_at"] = datetime.now(timezone.utc).isoformat()

    # Rank salary within each department, highest salary = rank 1
    # method="min" gives standard RANK() behavior: ties share a rank,
    # next rank skips accordingly (1, 1, 3)
    df["SalaryRank"] = (
        df.groupby("DeptName")["Salary"]
        .rank(method="min", ascending=False)
        .astype(int)
    )

    # Sort by department, then by rank within department
    df = df.sort_values(by=["DeptName", "SalaryRank"]).reset_index(drop=True)

    # Build new file name
    base_name = os.path.basename(key)
    new_key = f"processed-{base_name}"

    # Write back to the same bucket
    csv_buffer = io.StringIO()
    df.to_csv(csv_buffer, index=False)

    s3.put_object(
        Bucket=bucket,
        Key=new_key,
        Body=csv_buffer.getvalue().encode("utf-8"),
        ContentType="text/csv",
    )

    print(f"Wrote result to s3://{bucket}/{new_key}")
    return {"statusCode": 200, "body": f"Processed and saved as {new_key}"}
