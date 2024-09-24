
# SSM Connectivity Check Script

This script checks the connectivity of EC2 instances across multiple AWS accounts and regions via AWS Systems Manager (SSM). It generates a CSV file with details about each instance, including whether it is connectable via SSM, the associated IAM role (if any), and whether the IAM role has the necessary SSM policy attached.

## Features

- Check SSM connectivity status of EC2 instances in multiple AWS accounts and regions.
- Retrieve details about each instance, such as Instance ID, private IP address, and server name.
- Determine if an instance is using an IAM role, and whether that role has the `AmazonSSMManagedInstanceCore` policy attached.
- Generates a CSV file with the results and appends a random suffix to the filename for uniqueness.

## Prerequisites

- AWS CLI installed and configured with profiles for each AWS account.
- `jq` command-line tool installed for processing JSON output.
- Sufficient permissions to list EC2 instances and IAM roles, as well as to query SSM status.

## Script Configuration

### AWS Profiles and Regions

The script uses predefined AWS CLI profiles and AWS regions. Update the `profiles` and `regions` variables in the script to match your AWS environment:

```bash
profiles=("585775954072" "567667309200" "830540098783")  # Replace with your AWS account profiles
regions=("eu-west-1" "eu-west-2")  # Replace with the desired AWS regions
```

### SSM Policy

The script checks if the IAM role attached to the instance has the `AmazonSSMManagedInstanceCore` policy. You can update this policy ARN in the script if needed:

```bash
ssm_policy_arn="arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
```

### CSV Output File

The script generates a CSV file with a random suffix for uniqueness:

```bash
output_file="ssm_connectivity_results_${random_suffix}.csv"
```

The file will contain the following columns:

- `Account`: AWS account profile used.
- `Region`: AWS region where the instance resides.
- `Instance ID`: The ID of the EC2 instance.
- `Primary IP`: The private IP address of the EC2 instance.
- `Server Name`: The value of the `Name` tag for the instance (if present).
- `SSM Status`: Whether the instance is connectable via SSM.
- `IAM Role`: The IAM role attached to the instance (if any).
- `SSM Policy Attached`: Whether the IAM role has the SSM policy attached.

## Running the Script

1. **Clone or Download** the script to your local environment.

2. **Make the script executable** (if necessary):
   ```bash
   chmod +x check_ssm.sh
   ```

3. **Run the script**:
   ```bash
   ./check_ssm.sh
   ```

4. The script will output progress to the terminal as it checks each profile and region.

5. Once the script completes, the results will be saved to a CSV file with a randomly generated suffix. For example:
   ```
   ssm_connectivity_results_16323456789123456.csv
   ```

## Example Output

An example CSV file will look like this:

```
Account,Region,Instance ID,Primary IP,Server Name,SSM Status,IAM Role,SSM Policy Attached
585775954072,eu-west-2,i-0facdd3bfb067b5f4,172.17.2.22,Teleport Server,Not Connectable,No Role,N/A
567667309200,eu-west-1,i-0123456789abcdef0,172.17.1.10,DatabaseServer,Connectable,N/A,N/A
```

## Troubleshooting

- Ensure that you have the necessary IAM permissions to query EC2, SSM, and IAM resources in the specified AWS accounts.
- If you encounter issues with JSON processing, ensure that `jq` is installed and accessible in your system’s `$PATH`.
- If an instance is not connectable via SSM, check whether the instance has an IAM role with the correct SSM policy attached.

## Dependencies

- **AWS CLI**: Required to interact with AWS services. [Install AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)
- **jq**: A command-line tool for processing JSON. [Install jq](https://stedolan.github.io/jq/download/)
