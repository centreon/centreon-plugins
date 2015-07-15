
package Paws::IAM::UpdateAccessKey {
  use Moose;
  has AccessKeyId => (is => 'ro', isa => 'Str', required => 1);
  has Status => (is => 'ro', isa => 'Str', required => 1);
  has UserName => (is => 'ro', isa => 'Str');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'UpdateAccessKey');
  class_has _returns => (isa => 'Str', is => 'ro');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::IAM::UpdateAccessKey - Arguments for method UpdateAccessKey on Paws::IAM

=head1 DESCRIPTION

This class represents the parameters used for calling the method UpdateAccessKey on the 
AWS Identity and Access Management service. Use the attributes of this class
as arguments to method UpdateAccessKey.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to UpdateAccessKey.

As an example:

  $service_obj->UpdateAccessKey(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> AccessKeyId => Str

  

The access key ID of the secret access key you want to update.










=head2 B<REQUIRED> Status => Str

  

The status you want to assign to the secret access key. C<Active> means
the key can be used for API calls to AWS, while C<Inactive> means the
key cannot be used.










=head2 UserName => Str

  

The name of the user whose key you want to update.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method UpdateAccessKey in L<Paws::IAM>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

