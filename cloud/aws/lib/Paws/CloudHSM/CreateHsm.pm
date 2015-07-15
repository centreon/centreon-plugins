
package Paws::CloudHSM::CreateHsm {
  use Moose;
  has ClientToken => (is => 'ro', isa => 'Str');
  has EniIp => (is => 'ro', isa => 'Str');
  has ExternalId => (is => 'ro', isa => 'Str');
  has IamRoleArn => (is => 'ro', isa => 'Str', required => 1);
  has SshKey => (is => 'ro', isa => 'Str', required => 1);
  has SubnetId => (is => 'ro', isa => 'Str', required => 1);
  has SubscriptionType => (is => 'ro', isa => 'Str', required => 1);
  has SyslogIp => (is => 'ro', isa => 'Str');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'CreateHsm');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::CloudHSM::CreateHsmResponse');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::CloudHSM::CreateHsm - Arguments for method CreateHsm on Paws::CloudHSM

=head1 DESCRIPTION

This class represents the parameters used for calling the method CreateHsm on the 
Amazon CloudHSM service. Use the attributes of this class
as arguments to method CreateHsm.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to CreateHsm.

As an example:

  $service_obj->CreateHsm(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 ClientToken => Str

  

A user-defined token to ensure idempotence. Subsequent calls to this
action with the same token will be ignored.










=head2 EniIp => Str

  

The IP address to assign to the HSM's ENI.










=head2 ExternalId => Str

  

The external ID from B<IamRoleArn>, if present.










=head2 B<REQUIRED> IamRoleArn => Str

  

The ARN of an IAM role to enable the AWS CloudHSM service to allocate
an ENI on your behalf.










=head2 B<REQUIRED> SshKey => Str

  

The SSH public key to install on the HSM.










=head2 B<REQUIRED> SubnetId => Str

  

The identifier of the subnet in your VPC in which to place the HSM.










=head2 B<REQUIRED> SubscriptionType => Str

  

The subscription type.










=head2 SyslogIp => Str

  

The IP address for the syslog monitoring server.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method CreateHsm in L<Paws::CloudHSM>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

