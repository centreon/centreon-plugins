# How to have my pull request accepted quickly ?

## Code

Read the documentation available [here](./plugins_global.md) and [there](./plugins_advanced.md) and take inspiration 
from the latest features made available in the codebase. Please find below some examples of recent improvements

### Declaring options with `add_options()`
  
  - Use `default` option in `add_options()` method to avoid useless code in `check_options()`.
  - Use greater_than, less_than_or_equal, regexp_match, and other validation options to avoid implementing check_options() (see [Plugins Options](plugins_global.md#options)).

### Declaring counters with constants

Constants are defined in [here](../../../src/centreon/plugins/constants.pm), they have been created to make code more 
human-readable.

- **Counter types:** if you're a long-time contributor to this project, you may know what the numeric counter types 
mean, but we expect you to switch to this new way of declaring the counters to make it more explicit to everyone. 
You'll find examples in the other markdown documentation files.
- **Skip cases:** to skip some cases, the counter definition may contain:
  ```skipped_code => { -2 => 1, -10 => 1 }```
  This is much more understandable this way: 
  ```skipped_code => { NOT_PROCESSED() => 1, NO_VALUE() => 1 }```

### Use the short_msg parameter of option_exit

When you need to display an error message and exit the plugin, it is simpler to use a single `option_exit` call rather than calling `add_opton_msg` followed by `option_exit`.
For example:

```perl
    $self->{output}->option_exit(short_msg => "Cannot encode JSON result");
```

Instead of:

```perl
    $self->{output}->add_option_msg(short_msg => "Cannot encode JSON result"); 
    $self->{output}->option_exit(); 
```

### Prefer Placeholder-Based Functions Instead of Callback Functions

When declaring counters, if you only need to display the value of variables, it is often simpler and faster to use the `prefix_output`, `suffix_output`, and `long_output` functions with `%{}` placeholders rather than implementing `cb_prefix_output`, `cb_suffix_output`, `cb_long_output`, and other callback functions.
For example:

```perl
sub set_counters {
    my ($self, %options) = @_;
    $self->{maps_counters_type} = [
        { name => 'metrics', type => COUNTER_TYPE_MULTIPLE,
          prefix_output => "'%{display}' ",
          long_output => "Checking '%{display}' ",
```

Instead of:

```perl
sub prefix_metric_output {
    my ($self, %options) = @_;
    return "'" . $options{instance_value}->{display} . "' ";
}

sub long_output {
    my ($self, %options) = @_;
    return "Checking '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;
    $self->{maps_counters_type} = [
        { name => 'metrics', type => COUNTER_TYPE_MULTIPLE,
          cb_prefix_output => 'prefix_metric_output',
          cb_long_output => 'long_output',
```

| Callback-based function | Placeholder-based equivalent  |
|-------------------------|-------------------------------|
| cb_prefix_output        | prefix_output                 |
| cb_suffix_output        | suffix_output                 |
| cb_long_output          | long_output                   |
| closure_custom_output   | output_template               |


### Use the functions provided by Misc.pm

In general, before implementing something from scratch, check whether an existing function in [centreon/plugins/misc.pm](../../../src/centreon/plugins/misc.pm) already provides the required functionality.

Please refer to the [misc.pm](../../../src/centreon/plugins/misc.pm) documentation for the list of available functions and examples of their usage.

## Documentation

- Write the payload in the comments when it's relevant (and not too long). The JSON response of a REST API may be useful
to understand the code.
- Comment the tricky parts, explain the errors/difficulties you met.
- Always document the plugin's options in the [POD](https://perldoc.perl.org/perlpod) at the end of the file.
- Always explode the --warning-*/--critical-* options' documentation to --warning-counter1, --warning-counter2, etc.

## Tests

In this project we do unit tests for functions that are widely used and integration tests with Robot framework to run 
them, and snmpsim and Mockoon to mock the devices.

Your code will be accepted quicker if we can test it with data and tests that are provided to us.

Follow the instructions [here](../../../tests/README.md) to have the best chances for your PR to be accepted.
