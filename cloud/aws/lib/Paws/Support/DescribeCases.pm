
package Paws::Support::DescribeCases {
  use Moose;
  has afterTime => (is => 'ro', isa => 'Str');
  has beforeTime => (is => 'ro', isa => 'Str');
  has caseIdList => (is => 'ro', isa => 'ArrayRef[Str]');
  has displayId => (is => 'ro', isa => 'Str');
  has includeCommunications => (is => 'ro', isa => 'Bool');
  has includeResolvedCases => (is => 'ro', isa => 'Bool');
  has language => (is => 'ro', isa => 'Str');
  has maxResults => (is => 'ro', isa => 'Int');
  has nextToken => (is => 'ro', isa => 'Str');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DescribeCases');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::Support::DescribeCasesResponse');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::Support::DescribeCases - Arguments for method DescribeCases on Paws::Support

=head1 DESCRIPTION

This class represents the parameters used for calling the method DescribeCases on the 
AWS Support service. Use the attributes of this class
as arguments to method DescribeCases.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DescribeCases.

As an example:

  $service_obj->DescribeCases(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 afterTime => Str

  

The start date for a filtered date search on support case
communications. Case communications are available for 12 months after
creation.










=head2 beforeTime => Str

  

The end date for a filtered date search on support case communications.
Case communications are available for 12 months after creation.










=head2 caseIdList => ArrayRef[Str]

  

A list of ID numbers of the support cases you want returned. The
maximum number of cases is 100.










=head2 displayId => Str

  

The ID displayed for a case in the AWS Support Center user interface.










=head2 includeCommunications => Bool

  

Specifies whether communications should be included in the
DescribeCases results. The default is I<true>.










=head2 includeResolvedCases => Bool

  

Specifies whether resolved support cases should be included in the
DescribeCases results. The default is I<false>.










=head2 language => Str

  

The ISO 639-1 code for the language in which AWS provides support. AWS
Support currently supports English ("en") and Japanese ("ja"). Language
parameters must be passed explicitly for operations that take them.










=head2 maxResults => Int

  

The maximum number of results to return before paginating.










=head2 nextToken => Str

  

A resumption point for pagination.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DescribeCases in L<Paws::Support>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

