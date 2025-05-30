# Parking Lot Management System

A cloud-based parking lot management system built with Node.js, TypeScript, and deployed on AWS using Terraform.

🚀 **Live Demo**: The application is running at http://3.211.186.205:3000/

Try it out:

```bash
# Park a vehicle
curl -X POST "http://3.211.186.205:3000/entry?plate=ABC123&parkingLot=1"

# Exit with the received ticketId
curl -X POST "http://3.211.186.205:3000/exit?ticketId=TICKET_ID"
```

## Features

- Vehicle entry tracking with license plate and parking lot ID
- Parking fee calculation based on duration ($10/hour, prorated in 15-minute increments)
- RESTful API endpoints for entry and exit operations
- Automated AWS infrastructure deployment using Terraform

## Prerequisites

- Node.js (v18 or later)
- npm
- AWS CLI configured with appropriate credentials
- Terraform installed

## Local Development Setup

1. Clone the repository:

```bash
git clone <your-repository-url>
cd parking-lot-project
```

2. Install dependencies:

```bash
npm install
```

3. Start the development server:

```bash
npm run dev
```

The server will start on port 3000.

## API Endpoints

### Vehicle Entry

```
POST /entry?plate=123-123-123&parkingLot=382
```

Returns: Ticket ID

### Vehicle Exit

```
POST /exit?ticketId=1234
```

Returns:

- License plate
- Total parked time
- Parking lot ID
- Calculated charge

### Testing the API

Since the application listens on all network interfaces, you can test it from any device using the EC2 instance's public IP:

```bash
# Replace YOUR_EC2_IP with the public IP from terraform output
export EC2_IP=YOUR_EC2_IP

# Park a vehicle
curl -X POST "http://$EC2_IP:3000/entry?plate=ABC123&parkingLot=1"

# Exit with the received ticketId
curl -X POST "http://$EC2_IP:3000/exit?ticketId=TICKET_ID"

# Health check
curl "http://$EC2_IP:3000/health"
```

## AWS Deployment

1. Initialize Terraform:

```bash
terraform init
```

2. Review the infrastructure plan:

```bash
terraform plan
```

3. Deploy the infrastructure:

```bash
terraform apply
```

4. After deployment, Terraform will output the public IP of the EC2 instance.

## Infrastructure Components

The Terraform configuration creates the following Free Tier eligible resources:

- VPC with public subnet (Free)
- Internet Gateway (Free)
- Route Table (Free)
- Security Group with ports 22 and 3000 open (Free)
- IAM Role and Instance Profile (Free)
- EC2 t2.micro instance with Amazon Linux 2023 (Free Tier: 750 hours/month)
- 8GB gp3 root volume (Free Tier: 30GB total)
- Elastic IP (Free when associated with running instance)

## AWS Free Tier Usage

This project is designed to run entirely within AWS Free Tier limits:

- Uses t2.micro instance type (750 hours per month free)
- Uses only basic monitoring (included in free tier)
- Keeps EBS volume within free tier limits (30GB)
- Uses free networking features
- All IAM features are always free
- Tagged all resources with "Environment = FreeTier" for tracking

Note: Ensure you don't have other resources using your free tier allocation to avoid charges.

## Security Considerations

- The application runs on port 3000 and listens on all network interfaces (0.0.0.0)
- SSH access (port 22) is enabled for all IPs (0.0.0.0/0)
- Application access (port 3000) is enabled for all IPs (0.0.0.0/0)
- All necessary security groups and IAM roles are automatically configured

⚠️ **Security Notice**: The current configuration allows access from any IP address to both SSH (port 22) and the application (port 3000). This is intentionally configured for ease of development and testing. In a production environment, we should:

- Restrict SSH access to specific IP ranges
- Consider using a VPN or bastion host for SSH access
- Implement proper authentication for the API endpoints
- Consider using AWS API Gateway and proper network isolation

## Cleanup

To destroy the AWS infrastructure:

```bash
terraform destroy
```

## Notes

- The system uses in-memory storage for parking records
- The EC2 instance uses Amazon Linux 2023 (Free tier eligible)
- The application automatically starts on EC2 instance boot
- All infrastructure is created in the us-east-1 region by default
