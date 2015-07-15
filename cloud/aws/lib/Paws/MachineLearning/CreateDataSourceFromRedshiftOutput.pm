
package Paws::MachineLearning::CreateDataSourceFromRedshiftOutput {
  use Moose;
  has DataSourceId => (is => 'ro', isa => 'Str');

}

### main pod documentation begin ###

=head1 NAME

Paws::MachineLearning::CreateDataSourceFromRedshiftOutput

=head1 ATTRIBUTES

=head2 DataSourceId => Str

  

A user-supplied ID that uniquely identifies the datasource. This value
should be identical to the value of the C<DataSourceID> in the request.











=cut

1;