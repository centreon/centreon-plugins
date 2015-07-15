
package Paws::MachineLearning::UpdateDataSource {
  use Moose;
  has DataSourceId => (is => 'ro', isa => 'Str', required => 1);
  has DataSourceName => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'UpdateDataSource');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::MachineLearning::UpdateDataSourceOutput');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::MachineLearning::UpdateDataSource - Arguments for method UpdateDataSource on Paws::MachineLearning

=head1 DESCRIPTION

This class represents the parameters used for calling the method UpdateDataSource on the 
Amazon Machine Learning service. Use the attributes of this class
as arguments to method UpdateDataSource.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to UpdateDataSource.

As an example:

  $service_obj->UpdateDataSource(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> DataSourceId => Str

  

The ID assigned to the C<DataSource> during creation.










=head2 B<REQUIRED> DataSourceName => Str

  

A new user-supplied name or description of the C<DataSource> that will
replace the current description.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method UpdateDataSource in L<Paws::MachineLearning>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

