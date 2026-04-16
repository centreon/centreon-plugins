# Centreon Plugins sequence diagram

## Cookbook

The description of the diagram uses the [Mermaid](https://mermaid.js.org/) syntax, which is natively supported by 
Github. You may also check out the file locally and generate the diagram with the following
[mermaid-cli](https://github.com/mermaid-js/mermaid-cli) (`mmdc`) command:

```bash
mmdc -f -i sequence_diagram.mmd -o sequence_diagram.pdf
```

Other output formats such as *png* and *svg* are also available.

## Explanation

### Use case

The provided sequence diagram has been written while debugging this command line:

```bash
perl centreon_plugins.pl --plugin='cloud::azure::database::elasticpool::plugin' --mode='storage'
```

As explained in [plugins_advanced.md](plugins_advanced.md), each mode can use various types of counters, with various
data types and structures. Here, the `maps_counters_type` is of type **3**, which means the most complex case, when 
metrics and statuses are associated to instances organized in groups.
The other types are not explained here, but you may find the keys to understanding them.

### Side notes

In the diagram, almost all the `.pm` files' names are constants in every use case, except for two:
- _plugin.pm_: the name is always the same by convention, but its location depends on what is given as the `--plugin` option
- _themode.pm_: stands for the mode of the plugin that is being used (given as the `--mode` option). For example, cpu.pm, memory.pm... 

### Complete diagram

The complete diagram can be natively displayed by Github [here](sequence_diagram.mmd).

## Interesting parts of the diagram for developers

When you develop a new mode for a plugin, your responsibility will be to provide the necessary functions in _themode.pm_.

### new()

This constructor must call the inherited one (`$class->SUPER::new()`) and then add the options that are specific to this mode.

```mermaid
sequenceDiagram
    script_custom.pm ->> +themode.pm: $self->{modes}{<br/>$self->{mode_name}<br/>}->new()
        Note right of themode.pm: Here "themode.pm" stands<br/>for cpu.pm, uptime.pm<br/>or whatever mode file
        create participant counter.pm
        themode.pm ->> +counter.pm: new()
            Note right of counter.pm: counter::new() constructor<br/>inherited by themode.pm
            create participant mode.pm
            counter.pm ->> +mode.pm: $class->SUPER::new()
                create participant perfdata.pm
                mode.pm ->> +perfdata.pm: centreon::plugins::<br/>perfdata->new(<br/>output => $options{output})
                    Note right of perfdata.pm: Stores a reference<br/>to the output object<br/>Initialises thlabel
                perfdata.pm -->> -mode.pm: Back from new()
            mode.pm -->> -counter.pm: Back from new()
            counter.pm -> counter.pm: centreon::plugins::misc::<br/>mymodule_load(...)
            Note right of counter.pm: Loads statefile.pm if necessary
            counter.pm ->> +themode.pm: $self->set_counters(%options);
                Note left of themode.pm: set_counters() must<br/>define the counter's<br/>structure
            themode.pm -->> -counter.pm: Back from set_counters()

            rect rgb(230, 255, 255)
                loop For each counter/subcounter
                    counter.pm -> counter.pm: get_threshold_prefix(<br/>name => $counter<br/>)
                    Note right of counter.pm: Builds the thresholds<br/>label (thlabel)
                    counter.pm ->> options.pm: add_options()
                    Note right of counter.pm: Adds "very long thresholds<br/>options" with thlabel
                    counter.pm ->> options.pm: add_options()
                    Note right of counter.pm: Adds thresholds options<br/>with label redirecting to<br/>the long thresholds
                    create participant values.pm
                    counter.pm ->> values.pm: $_->{obj} =<br/>centreon::plugins::values->new(...)
                    Note right of values.pm: Stores references to<br/>various objects (statefile,<br/>output, perfdata) and initiates others
                    counter.pm ->> values.pm: $_->{obj}->set()
                    Note right of values.pm: Stores the counter's<br/>"set" object's attributes<br/>into values' $self<br/>(ie $self->{obj} for counter.pm)
                    Note right of counter.pm: End of for each counter/subcounter
                end
            end
            Note right of counter.pm: Still in new()
        counter.pm -->> -themode.pm: Back to new() after<br/>the inherited constructor
        themode.pm ->> options.pm: add_options()
        Note left of options.pm: Adds options that<br/>are specific to the mode<br/>such as filters
    themode.pm -->> -script_custom.pm: Back from $self-><br/>{modes}{$self->{mode_name}}<br/>->new() to init()
```

### check_options()

This method must check that all mandatory options have been given and control they're valid.

```mermaid
sequenceDiagram
    script_custom.pm ->> +themode.pm: $self->{mode}->check_options()
        themode.pm ->> +counter.pm: $self->SUPER::check_options()
            counter.pm ->> +mode.pm: $self->SUPER::init(%options);
                mode.pm -> mode.pm: %{$self->{option_results}} =<br/>>%{$options{option_results}};
                mode.pm -> mode.pm: Apply the default options<br/>values when none given
            mode.pm -->> -counter.pm: Back to check_options()
            counter.pm -> counter.pm: Handle --list-counters option
            counter.pm -> counter.pm: If type 2 counter, prepares<br/>the macros substitutions.
            rect rgb(230, 255, 255)
                loop For each counter/subcounter
                    counter.pm ->> +values.pm: $sub_counter->{obj}->init(<br/>option_results => $self->{option_results})
                        values.pm ->> +perfdata.pm: $self->{perfdata}->threshold_validate()
                            perfdata.pm -> perfdata.pm: centreon::plugins::misc::parse_threshold(<br/>threshold => $options{value});
                            Note left of perfdata.pm: This function checks the<br/>conformity of threshold<br/>Splits into a global status and<br/>"result_perf" (arobase, end, infinite_neg,<br/>infinite_pos, start)
                            Note left of perfdata.pm: Stores the result in $self->{threshold_label}->{$options{label}}
                        perfdata.pm -->> -values.pm: Back to init()
                    values.pm -->> -counter.pm: Back to check_options()
                end
            end
            counter.pm -> counter.pm: $self->change_macros(...)
            Note right of counter.pm: Replaces all the %{macros}<br/>with the adequate<br/>Perl expressions for<br/>future eval
            counter.pm -> counter.pm: $self->{statefile_value}->check_options(...);
            Note right of counter.pm: If statefile is used
        counter.pm -->> -themode.pm: Back to check_options()
        Note right of themode.pm: Checks that the mode-specific<br/>options are valid
    themode.pm -->> -script_custom.pm: Back to init() from check_options()
```

### set_counters()

This method will describe how you decide to structure the collected data in order to let the plugins classes (`counter`, 
`mode`, `perfdata`, `values` and  `output`) handle them.

```mermaid
sequenceDiagram
    counter.pm ->> +themode.pm: $self->set_counters(%options);
        Note left of themode.pm: set_counters() must<br/>define the counter's<br/>structure
    themode.pm -->> -counter.pm: Back from set_counters()
```
    
### manage_selection()

This method is the one that will be the most specific to the plugin and the mode you're working on since it will have to
cope with both the protocol and the data structures in input and in output.

```mermaid
sequenceDiagram
    counter.pm ->> +themode.pm: $self->manage_selection(%options)
        Note left of themode.pm: Gathers the data and stores<br/>them in the counters<br/>structure
    themode.pm -->> -counter.pm: Back from manage_selection()
```

### Callback functions

> The callback functions must be defined in the corresponding _themode.pm_ file but they actually apply to objects with the **values** class (defined in the **values.pm** file). You should bear it in mind while writing these functions, to know what data you can access.

#### closure_custom_calc

This function receives a hash called `%options`, which contains a hash reference under `$options{new_datas}`. The function must feed `$self->{result_values}` for further processing.
The default function that will be called is `centreon::plugins::templates::catalog_functions::catalog_status_calc()`.

```mermaid
sequenceDiagram
    values.pm ->> themode.pm: $self->{closure_custom_calc}->(...)
```

#### closure_custom_output

This method must return a string to be displayed in the output using data stored as attributes of `$self->{result_values}` where the available keys are the strings listed in the `key_values` entries.

#### closure_custom_threshold_check

This callback function can be defined to implement custom logic in the evaluation of the returned status.

```mermaid
sequenceDiagram
    values.pm ->> +themode.pm: return &{$self->{closure_custom_threshold_check}}($self, %options);
        Note right of themode.pm: WARNING: This function is declared in themode.pm but is actually called as a method for class values
        Note right of values.pm: If this function closure_custom_threshold_check is defined
    themode.pm ->> perfdata.pm: $self->{perfdata}->threshold_check()
    themode.pm -->> -values.pm: Back from closure_custom_threshold_check
```