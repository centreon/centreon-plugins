
package Paws::MachineLearning::DeleteDataSourceOutput {
  use Moose;
  has DataSourceId => (is => 'ro', isa => 'Str');

}

### main pod documentation begin ###

=head1 NAME

Paws::MachineLearning::DeleteDataSourceOutput

=head1 ATTRIBUTES

=head2 DataSourceId => Str

  

A user-supplied ID that uniquely identifies the C<DataSource>. This
value should be identical to the value of the C<DataSourceID> in the
request.











=cut

1;