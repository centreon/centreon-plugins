
package Paws::CloudHSM::DescribeHsmResponse {
  use Moose;
  has AvailabilityZone => (is => 'ro', isa => 'Str');
  has EniId => (is => 'ro', isa => 'Str');
  has EniIp => (is => 'ro', isa => 'Str');
  has HsmArn => (is => 'ro', isa => 'Str');
  has HsmType => (is => 'ro', isa => 'Str');
  has IamRoleArn => (is => 'ro', isa => 'Str');
  has Partitions => (is => 'ro', isa => 'ArrayRef[Str]');
  has SerialNumber => (is => 'ro', isa => 'Str');
  has ServerCertLastUpdated => (is => 'ro', isa => 'Str');
  has ServerCertUri => (is => 'ro', isa => 'Str');
  has SoftwareVersion => (is => 'ro', isa => 'Str');
  has SshKeyLastUpdated => (is => 'ro', isa => 'Str');
  has SshPublicKey => (is => 'ro', isa => 'Str');
  has Status => (is => 'ro', isa => 'Str');
  has StatusDetails => (is => 'ro', isa => 'Str');
  has SubnetId => (is => 'ro', isa => 'Str');
  has SubscriptionEndDate => (is => 'ro', isa => 'Str');
  has SubscriptionStartDate => (is => 'ro', isa => 'Str');
  has SubscriptionType => (is => 'ro', isa => 'Str');
  has VendorName => (is => 'ro', isa => 'Str');
  has VpcId => (is => 'ro', isa => 'Str');

}

### main pod documentation begin ###

=head1 NAME

Paws::CloudHSM::DescribeHsmResponse

=head1 ATTRIBUTES

=head2 AvailabilityZone => Str

  

The Availability Zone that the HSM is in.









=head2 EniId => Str

  

The identifier of the elastic network interface (ENI) attached to the
HSM.









=head2 EniIp => Str

  

The IP address assigned to the HSM's ENI.









=head2 HsmArn => Str

  

The ARN of the HSM.









=head2 HsmType => Str

  

The HSM model type.









=head2 IamRoleArn => Str

  

The ARN of the IAM role assigned to the HSM.









=head2 Partitions => ArrayRef[Str]

  

The list of partitions on the HSM.









=head2 SerialNumber => Str

  

The serial number of the HSM.









=head2 ServerCertLastUpdated => Str

  

The date and time the server certificate was last updated.









=head2 ServerCertUri => Str

  

The URI of the certificate server.









=head2 SoftwareVersion => Str

  

The HSM software version.









=head2 SshKeyLastUpdated => Str

  

The date and time the SSH key was last updated.









=head2 SshPublicKey => Str

  

The public SSH key.









=head2 Status => Str

  

The status of the HSM.









=head2 StatusDetails => Str

  

Contains additional information about the status of the HSM.









=head2 SubnetId => Str

  

The identifier of the subnet the HSM is in.









=head2 SubscriptionEndDate => Str

  

The subscription end date.









=head2 SubscriptionStartDate => Str

  

The subscription start date.









=head2 SubscriptionType => Str

  

The subscription type.









=head2 VendorName => Str

  

The name of the HSM vendor.









=head2 VpcId => Str

  

The identifier of the VPC that the HSM is in.











=cut

1;