
package Paws::Route53Domains::UpdateTagsForDomain {
  use Moose;
  has DomainName => (is => 'ro', isa => 'Str', required => 1);
  has TagsToUpdate => (is => 'ro', isa => 'ArrayRef[Paws::Route53Domains::Tag]');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'UpdateTagsForDomain');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::Route53Domains::UpdateTagsForDomainResponse');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::Route53Domains::UpdateTagsForDomain - Arguments for method UpdateTagsForDomain on Paws::Route53Domains

=head1 DESCRIPTION

This class represents the parameters used for calling the method UpdateTagsForDomain on the 
Amazon Route 53 Domains service. Use the attributes of this class
as arguments to method UpdateTagsForDomain.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to UpdateTagsForDomain.

As an example:

  $service_obj->UpdateTagsForDomain(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> DomainName => Str

  

The domain for which you want to add or update tags.

The name of a domain.

Type: String

Default: None

Constraints: The domain name can contain only the letters a through z,
the numbers 0 through 9, and hyphen (-). Hyphens are allowed only when
theyaposre surrounded by letters, numbers, or other hyphens. You
canapost specify a hyphen at the beginning or end of a label. To
specify an Internationalized Domain Name, you must convert the name to
Punycode.

Required: Yes










=head2 TagsToUpdate => ArrayRef[Paws::Route53Domains::Tag]

  

A list of the tag keys and values that you want to add or update. If
you specify a key that already exists, the corresponding value will be
replaced.

Type: A complex type containing a list of tags

Default: None

Required: No

'E<gt>

Each tag includes the following elements:

=over

=item *

Key

The key (name) of a tag.

Type: String

Default: None

Valid values: Unicode characters including alphanumeric, space, and
".:/=+\-@"

Constraints: Each key can be 1-128 characters long.

Required: Yes

=item *

Value

The value of a tag.

Type: String

Default: None

Valid values: Unicode characters including alphanumeric, space, and
".:/=+\-@"

Constraints: Each value can be 0-256 characters long.

Required: Yes

=back












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method UpdateTagsForDomain in L<Paws::Route53Domains>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

