
package Paws::KMS::CreateAlias {
  use Moose;
  has AliasName => (is => 'ro', isa => 'Str', required => 1);
  has TargetKeyId => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'CreateAlias');
  class_has _returns => (isa => 'Str', is => 'ro');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::KMS::CreateAlias - Arguments for method CreateAlias on Paws::KMS

=head1 DESCRIPTION

This class represents the parameters used for calling the method CreateAlias on the 
AWS Key Management Service service. Use the attributes of this class
as arguments to method CreateAlias.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to CreateAlias.

As an example:

  $service_obj->CreateAlias(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> AliasName => Str

  

String that contains the display name. The name must start with the
word "alias" followed by a forward slash (alias/). Aliases that begin
with "alias/AWS" are reserved.










=head2 B<REQUIRED> TargetKeyId => Str

  

An identifier of the key for which you are creating the alias. This
value cannot be another alias but can be a globally unique identifier
or a fully specified ARN to a key.

=over

=item * Key ARN Example -
arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012

=item * Globally Unique Key ID Example -
12345678-1234-1234-1234-123456789012

=back












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method CreateAlias in L<Paws::KMS>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

