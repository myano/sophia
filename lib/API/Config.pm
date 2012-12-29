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

    method parse_main_config
    {
        my %global;
        my @configs;

        my $yaml = YAML::Tiny->read($sophia::CONFIGURATIONS{MAIN_CONFIG});

        error_log('sophia', 'Unable to parse config file.')     if (!$yaml);

        for my $block (@$yaml)
        {

            if (exists $block->{global})
            {
                while (my ($key, $value) = each %{$block->{global}})
                {
                    $global{$key} = $value;
                }
            }
            elsif (exists $block->{server})
            {
                my %config = %global;

                while (my ($key, $value) = each %{$block->{server}})
                {
                    $config{$key} = $value;
                }

                # channels is supposed to be a hash, but YAML processes it as an array
                if (exists $config{channels})
                {
                    my %channels = map { $_ => 1 } @{$config{channels}};
                    $config{channels} = \%channels;
                }

                # ports starting with + indicates ssl
                if (exists $config{port})
                {
                    if (index($config{port}, '+') == 0)
                    {
                        $config{port}   = substr $config{port}, 1;
                        $config{usessl} = TRUE;
                    }
                }

                push @configs, \%config;
            }
        }

        return \@configs;
    }

    method reload_main_config
    {
        # clear all channels
        %{$sophia::SOPHIA{channels}} = ();

        my %OLD_SOPHIA = %sophia::SOPHIA;

        $self->load_main_config();

        # if the config changed port, server, ircname, or username, restart sophia
        my @settings = qw(port server realname username);
        for my $setting (@settings)
        {
            if ($sophia::SOPHIA{$setting} ne $OLD_SOPHIA{$setting})
            {
                $sophia::sophia->yield(quit => 'Restarting ...');
                return;
            }
        }
    }
}
