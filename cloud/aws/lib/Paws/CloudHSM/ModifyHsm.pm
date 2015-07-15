
package Paws::CloudHSM::ModifyHsm {
  use Moose;
  has EniIp => (is => 'ro', isa => 'Str');
  has ExternalId => (is => 'ro', isa => 'Str');
  has HsmArn => (is => 'ro', isa => 'Str', required => 1);
  has IamRoleArn => (is => 'ro', isa => 'Str');
  has SubnetId => (is => 'ro', isa => 'Str');
  has SyslogIp => (is => 'ro', isa => 'Str');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'ModifyHsm');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::CloudHSM::ModifyHsmResponse');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::CloudHSM::ModifyHsm - Arguments for method ModifyHsm on Paws::CloudHSM

=head1 DESCRIPTION

This class represents the parameters used for calling the method ModifyHsm on the 
Amazon CloudHSM service. Use the attributes of this class
as arguments to method ModifyHsm.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to ModifyHsm.

As an example:

  $service_obj->ModifyHsm(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 EniIp => Str

  

The new IP address for the elastic network interface attached to the
HSM.










=head2 ExternalId => Str

  

The new external ID.










=head2 B<REQUIRED> HsmArn => Str

  

The ARN of the HSM to modify.










=head2 IamRoleArn => Str

  

The new IAM role ARN.










=head2 SubnetId => Str

  

The new identifier of the subnet that the HSM is in.










=head2 SyslogIp => Str

  

The new IP address for the syslog monitoring server.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method ModifyHsm in L<Paws::CloudHSM>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

