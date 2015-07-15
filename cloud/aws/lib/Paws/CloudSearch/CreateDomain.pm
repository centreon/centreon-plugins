
package Paws::CloudSearch::CreateDomain {
  use Moose;
  has DomainName => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'CreateDomain');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::CloudSearch::CreateDomainResponse');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'CreateDomainResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::CloudSearch::CreateDomain - Arguments for method CreateDomain on Paws::CloudSearch

=head1 DESCRIPTION

This class represents the parameters used for calling the method CreateDomain on the 
Amazon CloudSearch service. Use the attributes of this class
as arguments to method CreateDomain.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to CreateDomain.

As an example:

  $service_obj->CreateDomain(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> DomainName => Str

  

A name for the domain you are creating. Allowed characters are a-z
(lower-case letters), 0-9, and hyphen (-). Domain names must start with
a letter or number and be at least 3 and no more than 28 characters
long.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method CreateDomain in L<Paws::CloudSearch>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

