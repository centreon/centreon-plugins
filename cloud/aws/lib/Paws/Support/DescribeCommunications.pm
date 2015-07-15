
package Paws::Support::DescribeCommunications {
  use Moose;
  has afterTime => (is => 'ro', isa => 'Str');
  has beforeTime => (is => 'ro', isa => 'Str');
  has caseId => (is => 'ro', isa => 'Str', required => 1);
  has maxResults => (is => 'ro', isa => 'Int');
  has nextToken => (is => 'ro', isa => 'Str');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DescribeCommunications');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::Support::DescribeCommunicationsResponse');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::Support::DescribeCommunications - Arguments for method DescribeCommunications on Paws::Support

=head1 DESCRIPTION

This class represents the parameters used for calling the method DescribeCommunications on the 
AWS Support service. Use the attributes of this class
as arguments to method DescribeCommunications.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DescribeCommunications.

As an example:

  $service_obj->DescribeCommunications(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 afterTime => Str

  

The start date for a filtered date search on support case
communications. Case communications are available for 12 months after
creation.










=head2 beforeTime => Str

  

The end date for a filtered date search on support case communications.
Case communications are available for 12 months after creation.










=head2 B<REQUIRED> caseId => Str

  

The AWS Support case ID requested or returned in the call. The case ID
is an alphanumeric string formatted as shown in this example:
case-I<12345678910-2013-c4c1d2bf33c5cf47>










=head2 maxResults => Int

  

The maximum number of results to return before paginating.










=head2 nextToken => Str

  

A resumption point for pagination.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DescribeCommunications in L<Paws::Support>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

