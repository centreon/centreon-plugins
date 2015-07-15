
package Paws::CloudSearch::DescribeDomains {
  use Moose;
  has DomainNames => (is => 'ro', isa => 'ArrayRef[Str]');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DescribeDomains');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::CloudSearch::DescribeDomainsResponse');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'DescribeDomainsResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::CloudSearch::DescribeDomains - Arguments for method DescribeDomains on Paws::CloudSearch

=head1 DESCRIPTION

This class represents the parameters used for calling the method DescribeDomains on the 
Amazon CloudSearch service. Use the attributes of this class
as arguments to method DescribeDomains.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DescribeDomains.

As an example:

  $service_obj->DescribeDomains(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 DomainNames => ArrayRef[Str]

  

The names of the domains you want to include in the response.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DescribeDomains in L<Paws::CloudSearch>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

