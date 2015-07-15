
package Paws::CloudSearch::DeleteIndexField {
  use Moose;
  has DomainName => (is => 'ro', isa => 'Str', required => 1);
  has IndexFieldName => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DeleteIndexField');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::CloudSearch::DeleteIndexFieldResponse');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'DeleteIndexFieldResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::CloudSearch::DeleteIndexField - Arguments for method DeleteIndexField on Paws::CloudSearch

=head1 DESCRIPTION

This class represents the parameters used for calling the method DeleteIndexField on the 
Amazon CloudSearch service. Use the attributes of this class
as arguments to method DeleteIndexField.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DeleteIndexField.

As an example:

  $service_obj->DeleteIndexField(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> DomainName => Str

  

=head2 B<REQUIRED> IndexFieldName => Str

  

The name of the index field your want to remove from the domain's
indexing options.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DeleteIndexField in L<Paws::CloudSearch>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

