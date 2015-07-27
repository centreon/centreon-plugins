package Paws::API::EndpointResolver;
  use Moose::Role;
  use URI::Template;
  use Paws::Exception;

  has region => (is => 'rw', isa => 'Str|Undef');
  requires 'service';

  has _endpoint_info => (
    is => 'ro',
    init_arg => undef,
    lazy => 1,
    default => sub {
      shift->_construct_endpoint;
    }
  );

  has _region_for_signature => (
    is => 'rw', 
    isa => 'Str', 
    lazy => 1,
    init_arg => undef, 
    default => sub {
      my $self = shift;
      $self->_endpoint_info->{ credentialScope }->{ region } or $self->region;
    }
  );


  has endpoint_host => (
    is => 'ro',
    isa => 'Str',
    lazy => 1,
    default => sub {
      shift->_endpoint_info->{ url }->host;
    }
  ); 

  has _api_endpoint => (
    is => 'ro',
    isa => 'Str',
    lazy => 1,
    default => sub {
      shift->_endpoint_info->{ url }->as_string;
    }
  ); 

  has region_rules => (is => 'ro', isa => 'ArrayRef');

  has _default_rules => (is => 'ro', isa => 'ArrayRef', default => sub {
    [ { constraints => [ [ 'region', 'startsWith', 'cn-' ] ], 
        properties => { signatureVersion => 'v4' }, 
        uri => '{scheme}://{service}.{region}.amazonaws.com.cn'
      },
      { constraints => [ [ 'region', 'notEquals', undef ] ],
        uri => '{scheme}://{service}.{region}.amazonaws.com'
      },
    ]    
    },
  );

  has default_scheme => ( is => 'ro', isa => 'Str', default => 'https' );

  sub _construct_endpoint {
    my ($self) = @_;

    my $args = {};
    $args->{ service } = $self->service;
    $args->{ region  } = $self->region;
    $args->{ scheme  } = $self->default_scheme if (not defined $args->{scheme});

    my $service_rules = $self->region_rules;
    my $endpoint_info = $self->_match_rules($self->region_rules, $args->{ region }, $args);
    if (not defined $self->region_rules) {
      $endpoint_info = $self->_match_rules($self->region_rules, $args->{ region }, $args);
    }
    if (not defined $endpoint_info) {
      $endpoint_info = $self->_match_rules($self->_default_rules, $args->{ region }, $args);
    }

    if ( not defined $endpoint_info ) {
      my $region_for_exception = (defined $args->{ region }) ? $args->{ region } : '';
      Paws::Exception->throw(
        message => "No endpoint for service $args->{ service } in region '$region_for_exception'",
        code => 'NoRegionError',
        request_id => ''
      );
    } else {
      my $template = URI::Template->new($endpoint_info->{uri});
      my $url = $template->process($args);
      $endpoint_info->{ url } = $url;
    }

    return $endpoint_info;
  }

  sub _match_rules {
    my ( $self, $service_rules, $region, $args ) = @_;

    return undef if (not defined $service_rules);
    return undef if scalar(@$service_rules) == 0;

    for my $rule ( @$service_rules ) {
      if ( $self->_matches_rule($rule, $region, $args) ) {
        return { uri => $rule->{ uri }, (defined $rule->{ properties }) ? %{ $rule->{ properties } } : () };
      }
    }
    return undef;
  }

  sub _matches_rule {
    my( $self, $rule, $region, $args ) = @_;

    return 1 if (not defined $rule->{ constraints });

    my @constraints = @{ $rule->{ constraints } };
    for my $constraint (@constraints) {
      return 1 if ( $self->_matches_constraint($region, $constraint, $args) );
    }
    return 0;
  }

  has constraints => (
    is => 'ro',
    init_arg => undef,
    default => sub {
      {
      startsWith => sub {
        my ( $a, $v ) = @_;
        return 0 if (not defined $a and defined $v);
        return 0 if (defined $a and not defined $v);
        return $a =~ /^$v.*/i;
      },
      notStartsWith => sub {
        my ( $a, $v ) = @_;
        return 0 if (not defined $a);
        return $a !~ /^$v.*/i;
      },
      equals => sub {
        my ( $a, $v ) = @_;
        return 0 if (not defined $a and defined $v);
        return 0 if (defined $a and not defined $v);
        return 1 if (not defined $a and not defined $v);
        return $a eq $v;
      },
      notEquals => sub {
        # in the sample json, notEqual region's is always null
        # this needs review
        my ( $a, $v ) = @_;
        return 1 if (defined $a and not defined $v);
        return 1 if (not defined $a and defined $v);
        return 0 if (not defined $a and not defined $v);
        return $a ne $v;
      },
      oneOf => sub {
        my ( $a, $v ) = @_;
        for my $b (@$v) {
          return not defined($a) if (not defined($b));
          return not defined($b) if (not defined($a));
          return 1 if $a eq $b;
        }
        return 0;
      }
      };
    }
  );

  sub _matches_constraint {
    my ($self, $region, $constraint, $args ) = @_;
    my $property = $constraint->[0];
    die "We only know how to apply constraints to region" if ($property ne 'region');
    my $func  = $constraint->[1];
    my $value = $constraint->[2];
    return $self->constraints->{$func}->($region,$value);
  }


1;

