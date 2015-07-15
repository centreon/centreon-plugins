
package Paws::CloudSearch::DeleteAnalysisScheme {
  use Moose;
  has AnalysisSchemeName => (is => 'ro', isa => 'Str', required => 1);
  has DomainName => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DeleteAnalysisScheme');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::CloudSearch::DeleteAnalysisSchemeResponse');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'DeleteAnalysisSchemeResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::CloudSearch::DeleteAnalysisScheme - Arguments for method DeleteAnalysisScheme on Paws::CloudSearch

=head1 DESCRIPTION

This class represents the parameters used for calling the method DeleteAnalysisScheme on the 
Amazon CloudSearch service. Use the attributes of this class
as arguments to method DeleteAnalysisScheme.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DeleteAnalysisScheme.

As an example:

  $service_obj->DeleteAnalysisScheme(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> AnalysisSchemeName => Str

  

The name of the analysis scheme you want to delete.










=head2 B<REQUIRED> DomainName => Str

  



=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DeleteAnalysisScheme in L<Paws::CloudSearch>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

