# CloudWatch Logs to S3 Lambda Function

This Lambda function processes CloudWatch Logs data sent to a Kinesis Firehose stream and forwards it to S3.

## Overview

The function:
1. Decodes and decompresses the incoming data from CloudWatch Logs
2. Processes each log event, transforming it into a JSON format
3. Handles control messages and data messages differently
4. Manages reingestion of records that exceed size limits
5. Handles error cases and retries

## Python 3.12 Compatibility

The code has been updated to be compatible with Python 3.12. The following changes were made:

1. Added missing imports for `datetime` and `date` which are used in the `json_serial` function
2. Removed commented-out code related to `StringIO` (Python 2) since we're using `io.BytesIO` now

## Testing

### Prerequisites

- Python 3.12
- pip

### Setup

1. Create a virtual environment:
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

2. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

### Running Tests

To run the tests:

```bash
python -m unittest test_lambda_function.py
```

### Test Coverage

The tests cover:

1. Processing of DATA_MESSAGE events
2. Processing of CONTROL_MESSAGE events
3. Transformation of log events

## Deployment

The Lambda function can be deployed using Terragrunt/Terraform as part of the infrastructure setup.

## Dependencies

- boto3: AWS SDK for Python
- moto: For mocking AWS services in tests