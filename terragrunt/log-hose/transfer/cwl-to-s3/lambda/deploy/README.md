# Lambda Deployment with lambroll

This directory contains the necessary files for deploying the CloudWatch Logs to S3 Lambda function using lambroll.

## Files

- `function.json`: Configuration file for the Lambda function
- `function_deploy.mk`: Makefile for building and deploying the Lambda function
- `.envrc.example`: Example environment variables file

## Setup

1. Copy the `.envrc.example` file to `.envrc` and update the values as needed:

```bash
cp .envrc.example .envrc
```

2. Edit the `.envrc` file to set the appropriate values for your environment:

```bash
export LAMBDA_EXECUTION_ROLE=arn:aws:iam::${AWS_ACCOUNT_ID}:role/your-lambda-role
```

3. Load the environment variables:

```bash
source .envrc
```

Or if you're using [direnv](https://direnv.net/), simply run:

```bash
direnv allow
```

## Usage

### Build the Lambda function

```bash
make -f function_deploy.mk build
```

This will:
- Create a Python virtual environment
- Install the required dependencies
- Copy the Lambda function code to a dist directory

### Package the Lambda function

```bash
make -f function_deploy.mk package
```

This will create a ZIP file of the Lambda function code.

### Deploy the Lambda function

```bash
make -f function_deploy.mk deploy
```

This will deploy the Lambda function using lambroll.

### Clean up

```bash
make -f function_deploy.mk clean
```

This will remove the dist directory, ZIP file, and virtual environment.

## Full Deployment

To build, package, and deploy the Lambda function in one command:

```bash
make -f function_deploy.mk deploy
```