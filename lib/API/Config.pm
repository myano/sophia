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
}
