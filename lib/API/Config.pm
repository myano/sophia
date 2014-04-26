use MooseX::Declare;
use Method::Signatures::Modifiers;

class API::Config
{
    use API::Log qw(error_log);
    use Constants;
    use Exporter;
    use YAML::Tiny;
    use base qw(Exporter);
    use feature qw(switch);

    our @EXPORT_OK = qw(parse_main_config reload_main_config);
    our %EXPORT_TAGS = (
        ALL        => \@EXPORT_OK,
    );

    method parse_yaml_config ($config_path)
    {
        my @configs;

        my $yaml = YAML::Tiny->read($config_path);

        unless ($yaml)
        {
            error_log('sophia', "Unable to parse config file: $config_path");
        }

        for my $block (@$yaml)
        {
            while (my ($key, $value) = each %$block)
            {
                my %config = (
                    $key    => $value,
                );

                push @configs, \%config;
            }
        }

        return \@configs;
    }

    method get_config ($config_path)
    {
        my $options = $self->parse_yaml_config($config_path);

        my %configs;
        my %global;
        my %tmp;

        for my $option (@$options)
        {
            if (exists $option->{global})
            {
                while (my ($key, $value) = each %{$option->{global}})
                {
                    $global{$key} = $value;
                }

                $configs{global} = \%global;
            }
            elsif (exists $option->{operators})
            {
                my @opers;

                while (my ($key, $value) = each %{$option->{operators}})
                {
                    push @opers, +{ $key => $value };
                }

                $configs{operators} = \@opers;
            }
            elsif (exists $option->{server})
            {
                %tmp = %global;

                while (my ($key, $value) = each %{$option->{server}})
                {
                    $tmp{$key} = $value;
                }

                # channels is supposed to be a hash, but YAML processes it as an array
                if (exists $tmp{channels})
                {
                    my %channels = map { $_ => 1 } @{$tmp{channels}};
                    $tmp{channels} = \%channels;
                }

                # ports starting with + indicates ssl
                if (exists $tmp{port})
                {
                    if (index($tmp{port}, '+') == 0)
                    {
                        $tmp{port}   = substr $tmp{port}, 1;
                        $tmp{usessl} = TRUE;
                    }
                }

                if (!exists $configs{servers})
                {
                    $configs{servers} = [\%tmp];
                }
                else
                {
                    push @{$configs{servers}}, \%tmp;
                }
            }
        }

        return \%configs;
    }

    method save_config ($config_path)
    {
    }
}
