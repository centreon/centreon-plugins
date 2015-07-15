
package Paws::MachineLearning::GetDataSource {
  use Moose;
  has DataSourceId => (is => 'ro', isa => 'Str', required => 1);
  has Verbose => (is => 'ro', isa => 'Bool');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'GetDataSource');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::MachineLearning::GetDataSourceOutput');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::MachineLearning::GetDataSource - Arguments for method GetDataSource on Paws::MachineLearning

=head1 DESCRIPTION

This class represents the parameters used for calling the method GetDataSource on the 
Amazon Machine Learning service. Use the attributes of this class
as arguments to method GetDataSource.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to GetDataSource.

As an example:

  $service_obj->GetDataSource(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> DataSourceId => Str

  

The ID assigned to the C<DataSource> at creation.










=head2 Verbose => Bool

  

Specifies whether the C<GetDataSource> operation should return
C<DataSourceSchema>.

If true, C<DataSourceSchema> is returned.

If false, C<DataSourceSchema> is not returned.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method GetDataSource in L<Paws::MachineLearning>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

