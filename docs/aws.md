# AWS RDS Integration

This feature allows Redmine to connect to an AWS RDS PostgreSQL database using credentials dynamically retrieved from AWS Secrets Manager.


## **Configuration**

Use [docker-compose-aws.yml](../docker-compose-aws.yml) as a starting point and set the following environment variables under the `redmine` service:

```yaml
services:
  redmine:
    environment:
      - AWS_DB_CREDENTIALS_SECRET_REGION=<AWS_REGION>
      - AWS_DB_CREDENTIALS_SECRET_NAME=<SECRET_NAME_OR_ARN>
      - DB_NAME=redmine
      - DB_CREATE=false
```

- **`AWS_DB_CREDENTIALS_SECRET_REGION`**: Specify the AWS region where the secret is stored (e.g., `us-east-1`).
- **`AWS_DB_CREDENTIALS_SECRET_NAME`**: Provide the name or ARN of the secret containing the database credentials.
- **`DB_NAME`**: Specifies the database name.
- **`DB_CREATE`**: Prevents Redmine from trying to create or overwrite the database during startup.

**Note**:
Unlike other setups, there is no PostgreSQL companion container running alongside Redmine.
You will connect directly to an AWS RDS PostgreSQL instance.

## **AWS Secrets Manager Setup**

To store the database credentials securely, create a secret in AWS Secrets Manager.
Use the following steps:

1. Log in to the **AWS Management Console** and navigate to **Secrets Manager**.
2. Click **Store a new secret** and select **Credentials for Amazon RDS database** as the secret type.
3. Enter your database credentials (username and password).
4. Select your RDS database instance from the list.
5. Configure the secret name (e.g., `redmine_aws_rds_credentials`) and save the secret.

If you selected "Credentials for Amazon RDS database" the secret will have the following fields, at least:
* engine (it will be translated into "adapter" (eg: postgresql, mysql))
* username
* password
* host
* port

## **Database Preparation**

Before starting the container:

1. Create the PostgreSQL role and database on your RDS instance manually. Use the same process as for a PostgreSQL companion container as in [External PostgreSQL Server](#external-postgresql-server):

  ```sql
  CREATE ROLE redmine with LOGIN CREATEDB PASSWORD 'password';
  CREATE DATABASE redmine_production;
  GRANT ALL PRIVILEGES ON DATABASE redmine_production to redmine;
  ```

2. Ensure the docker-compose.yml file `DB_CREATE=false` environment variable is set to avoid Redmine overwriting the database.

## **IAM Permissions and EC2 Configuration**

Ensure that:
1. The EC2 instance running the Redmine container has the appropriate IAM role attached. This role should grant:
   - Access to read the secret from AWS Secrets Manager.
   - Network access to the RDS instance.

   Example IAM policy for accessing the secret:
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Action": "secretsmanager:GetSecretValue",
         "Resource": "arn:aws:secretsmanager:<AWS_REGION>:<AWS_ACCOUNT_ID>:secret:<SECRET_NAME>"
       }
     ]
   }
   ```

2. Security group rules are configured to allow connections from the EC2 instance to the RDS instance.

## **How It Works**

When the container starts:
1. It fetches the database credentials from AWS Secrets Manager using the provided `AWS_DB_CREDENTIALS_SECRET_REGION` and `AWS_DB_CREDENTIALS_SECRET_NAME`.
2. These credentials are used to establish a connection to the AWS RDS PostgreSQL instance.

This approach eliminates hardcoding sensitive credentials in the `docker-compose.yml` file, enhancing security and flexibility.

Note: Although the credentials are not hardcoded in the `docker-compose.yml` file, during runtime, they will be written to the config/database.yml file inside the container, just like in the other docker-compose template examples provided by this image.

## **Debugging**

You can check if your AWS EC2 instance is properly configured to have access to get the secrets by using the same script used inside the container.

```bash
gem install aws-sdk-secretsmanager
ruby assets/runtime/get_aws_secret.rb secret_name us-east-1
```

With the received credentials you may try to connect to AWS RDS instance and see if the AWS EC2 instance is allowed to do so.

```bash
psql -h host -U username -d database
```

Check AWS official documentation for more detailed information.
