
package Paws::CloudHSM::ModifyLunaClient {
  use Moose;
  has Certificate => (is => 'ro', isa => 'Str', required => 1);
  has ClientArn => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'ModifyLunaClient');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::CloudHSM::ModifyLunaClientResponse');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::CloudHSM::ModifyLunaClient - Arguments for method ModifyLunaClient on Paws::CloudHSM

=head1 DESCRIPTION

This class represents the parameters used for calling the method ModifyLunaClient on the 
Amazon CloudHSM service. Use the attributes of this class
as arguments to method ModifyLunaClient.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to ModifyLunaClient.

As an example:

  $service_obj->ModifyLunaClient(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> Certificate => Str

  

The new certificate for the client.










=head2 B<REQUIRED> ClientArn => Str

  

The ARN of the client.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method ModifyLunaClient in L<Paws::CloudHSM>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

