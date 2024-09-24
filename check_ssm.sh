#!/bin/bash

# Define AWS CLI profiles and regions
profiles=("585775954072" "567667309200" "830540098783")  # Replace with your AWS account profiles
regions=("eu-west-1" "eu-west-2")  # Replace with the desired AWS regions

# Generate a random suffix using the date command (you can also use /dev/urandom for more randomness)
random_suffix=$(date +%s%N)

# Define the output CSV file with the random suffix
output_file="ssm_connectivity_results_${random_suffix}.csv"  # Output CSV file
ssm_policy_arn="arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"  # SSM policy ARN to check# Function to initialize the CSV file

# Function to initialize the CSV file
initialize_csv() {
  echo "Account,Region,Instance ID,Primary IP,Server Name,SSM Status,IAM Role,SSM Policy Attached" > "$output_file"
}

# Function to check if an IAM role has the SSM policy attached
check_iam_role_policy() {
  local role_name=$1
  local profile=$2

  if [ -z "$role_name" ]; then
    echo "No Role"
    return
  fi

  # Get the policies attached to the role
  policies=$(aws iam list-attached-role-policies \
    --role-name "$role_name" \
    --profile "$profile" \
    --query 'AttachedPolicies[*].PolicyArn' \
    --output text 2>/dev/null)

  if [[ $policies == *"$ssm_policy_arn"* ]]; then
    echo "Yes"
  else
    echo "No"
  fi
}

# Function to check SSM connectivity in a region and output to CSV
check_ssm_connectivity() {
  local profile=$1
  local region=$2

  echo "Checking EC2 instances in profile $profile, region $region..."

  # Get a list of running EC2 instances in the region
  instance_info=$(aws ec2 describe-instances \
    --profile "$profile" \
    --region "$region" \
    --filters "Name=instance-state-name,Values=running" \
    --query 'Reservations[*].Instances[*].[InstanceId,PrivateIpAddress,Tags[?Key==`Name`].Value | [0],IamInstanceProfile.Arn]' \
    --output json)

  if [ -z "$instance_info" ]; then
    echo "No running instances found in profile $profile, region $region"
    return
  fi

  # Get the list of instances that are managed by SSM
  ssm_managed=$(aws ssm describe-instance-information \
    --profile "$profile" \
    --region "$region" \
    --query 'InstanceInformationList[*].InstanceId' \
    --output text)

  # Iterate over each instance and write to CSV
  echo "$instance_info" | jq -r '.[][] | @tsv' | while IFS=$'\t' read -r instance_id private_ip server_name iam_instance_profile; do
    if [[ $ssm_managed == *"$instance_id"* ]]; then
      ssm_status="Connectable"
      iam_role_name="N/A"
      ssm_policy_attached="N/A"
    else
      ssm_status="Not Connectable"
      
      # Check if the instance has an IAM role attached (i.e., IamInstanceProfile is not null)
      if [ "$iam_instance_profile" == "null" ] || [ -z "$iam_instance_profile" ]; then
        iam_role_name="No Role"
        ssm_policy_attached="N/A"
      else
        # Extract the role name from the IAM role ARN
        iam_role_name=$(echo "$iam_instance_profile" | awk -F/ '{print $NF}')
        
        # Ensure the role name doesn't contain invalid characters or None
        if [ "$iam_role_name" != "None" ] && [[ "$iam_role_name" =~ ^[a-zA-Z0-9+=,.@_-]+$ ]]; then
          # Check if the role has the SSM policy attached
          ssm_policy_attached=$(check_iam_role_policy "$iam_role_name" "$profile")
        else
          iam_role_name="Invalid Role Name"
          ssm_policy_attached="N/A"
        fi
      fi
    fi

    # Append the instance details to the CSV file
    echo "$profile,$region,$instance_id,$private_ip,$server_name,$ssm_status,$iam_role_name,$ssm_policy_attached" >> "$output_file"

  done
}

# Main script to iterate through profiles and regions
initialize_csv
for profile in "${profiles[@]}"; do
  echo "Processing profile $profile..."
  
  # Iterate over regions
  for region in "${regions[@]}"; do
    check_ssm_connectivity "$profile" "$region"
  done

done

echo "SSM connectivity check completed. Results saved to $output_file."