
package Paws::CloudHSM::DescribeHsm {
  use Moose;
  has HsmArn => (is => 'ro', isa => 'Str');
  has HsmSerialNumber => (is => 'ro', isa => 'Str');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DescribeHsm');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::CloudHSM::DescribeHsmResponse');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::CloudHSM::DescribeHsm - Arguments for method DescribeHsm on Paws::CloudHSM

=head1 DESCRIPTION

This class represents the parameters used for calling the method DescribeHsm on the 
Amazon CloudHSM service. Use the attributes of this class
as arguments to method DescribeHsm.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DescribeHsm.

As an example:

  $service_obj->DescribeHsm(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 HsmArn => Str

  

The ARN of the HSM. Either the I<HsmArn> or the I<SerialNumber>
parameter must be specified.










=head2 HsmSerialNumber => Str

  

The serial number of the HSM. Either the I<HsmArn> or the
I<HsmSerialNumber> parameter must be specified.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DescribeHsm in L<Paws::CloudHSM>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

