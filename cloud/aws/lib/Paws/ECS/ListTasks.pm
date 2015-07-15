
package Paws::ECS::ListTasks {
  use Moose;
  has cluster => (is => 'ro', isa => 'Str');
  has containerInstance => (is => 'ro', isa => 'Str');
  has desiredStatus => (is => 'ro', isa => 'Str');
  has family => (is => 'ro', isa => 'Str');
  has maxResults => (is => 'ro', isa => 'Int');
  has nextToken => (is => 'ro', isa => 'Str');
  has serviceName => (is => 'ro', isa => 'Str');
  has startedBy => (is => 'ro', isa => 'Str');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'ListTasks');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::ECS::ListTasksResponse');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::ECS::ListTasks - Arguments for method ListTasks on Paws::ECS

=head1 DESCRIPTION

This class represents the parameters used for calling the method ListTasks on the 
Amazon EC2 Container Service service. Use the attributes of this class
as arguments to method ListTasks.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to ListTasks.

As an example:

  $service_obj->ListTasks(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 cluster => Str

  

The short name or full Amazon Resource Name (ARN) of the cluster that
hosts the tasks you want to list. If you do not specify a cluster, the
default cluster is assumed..










=head2 containerInstance => Str

  

The container instance UUID or full Amazon Resource Name (ARN) of the
container instance that you want to filter the C<ListTasks> results
with. Specifying a C<containerInstance> will limit the results to tasks
that belong to that container instance.










=head2 desiredStatus => Str

  

The task status that you want to filter the C<ListTasks> results with.
Specifying a C<desiredStatus> of C<STOPPED> will limit the results to
tasks that are in the C<STOPPED> status, which can be useful for
debugging tasks that are not starting properly or have died or
finished. The default status filter is C<RUNNING>.










=head2 family => Str

  

The name of the family that you want to filter the C<ListTasks> results
with. Specifying a C<family> will limit the results to tasks that
belong to that family.










=head2 maxResults => Int

  

The maximum number of task results returned by C<ListTasks> in
paginated output. When this parameter is used, C<ListTasks> only
returns C<maxResults> results in a single page along with a
C<nextToken> response element. The remaining results of the initial
request can be seen by sending another C<ListTasks> request with the
returned C<nextToken> value. This value can be between 1 and 100. If
this parameter is not used, then C<ListTasks> returns up to 100 results
and a C<nextToken> value if applicable.










=head2 nextToken => Str

  

The C<nextToken> value returned from a previous paginated C<ListTasks>
request where C<maxResults> was used and the results exceeded the value
of that parameter. Pagination continues from the end of the previous
results that returned the C<nextToken> value. This value is C<null>
when there are no more results to return.










=head2 serviceName => Str

  

The name of the service that you want to filter the C<ListTasks>
results with. Specifying a C<serviceName> will limit the results to
tasks that belong to that service.










=head2 startedBy => Str

  

The C<startedBy> value that you want to filter the task results with.
Specifying a C<startedBy> value will limit the results to tasks that
were started with that value.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method ListTasks in L<Paws::ECS>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

