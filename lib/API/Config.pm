use MooseX::Declare;
use Method::Signatures::Modifiers;

class API::Config
{
    use API::Log qw(error_log);
    use Constants;
    use Exporter;
    use base qw(Exporter);
    use feature qw(switch);

    our @EXPORT_OK = qw(load_main_config reload_main_config);
    our %EXPORT_TAGS = (
        ALL        => \@EXPORT_OK,
    );

    method load_main_config
    {
        open my $fh, '<', $sophia::CONFIGURATIONS{MAIN_CONFIG}
            or error_log('sophia', "Unable to open config file: $!");

        LINE: while (<$fh>)
        {
            chomp;
            s/\A\s+//;
            next LINE if /\A#/ || /\A\s*\z/;  # ignoring comments and lame lines

            my @opts = split(' ');
            next LINE if scalar @opts != 2;

            $opts[0] = lc $opts[0];

            given ($opts[0])
            {
                when ('channel')
                {
                    $sophia::SOPHIA{channels}{$opts[1]} = 1;
                }
                when ('port')
                {
                    if (index($opts[1], '+') == 0)
                    {
                        $sophia::SOPHIA{usessl} = TRUE;
                        $opts[1] = substr($opts[1], 1);
                    }

                    $sophia::SOPHIA{port} = $opts[1];
                }
                default
                {
                    $sophia::SOPHIA{$opts[0]} = $opts[1] if exists $sophia::SOPHIA{$opts[0]};
                }
            }
        }

        close $fh;
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
