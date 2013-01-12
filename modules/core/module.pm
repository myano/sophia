use MooseX::Declare;
use Method::Signatures::Modifiers;

class core::module with API::Module
{
    use feature qw(switch);

    has 'name'  => (
        default => 'core::module',
        is      => 'ro',
        isa     => 'Str',
    );

    has 'version'   => (
        default     => '1.0',
        is          => 'ro',
        isa         => 'Str',
    );

    method run ($event)
    {
        # load command:
        # 1. <trigger>load <module>
        # 2. <trigger>reload <module>
        # 3. <trigger>unload <module>

        # first thing is to see which
        # command is used: load, (re|un)load
        my ($command, @modules) = split(' ', $event->content);
        
        # no $module? In other words,
        # split ' ' returned only one entry
        # then this is not a valid command
        unless (@modules)
        {
            return;
        }

        $command = lc $command;
        my $modulehandler = $event->sophia->modulehandler;

        given ($command)
        {
            when ('load')
            {
                for my $module (@modules)
                {
                    my $loaded = $modulehandler->load_module($module);
                    $event->reply("$module successfully loaded.")   if ($loaded);
                    $event->reply("$module failed to load.")        unless ($loaded);
                }
            }

            when ('reload')
            {
                for my $module (@modules)
                {
                    my $loaded = $modulehandler->reload_module($module);
                    $event->reply("$module successfully reloaded.")     if ($loaded);
                    $event->reply("$module failed to reload.")          unless ($loaded);
                }
            }

            when ('unload')
            {
                for my $module (@modules)
                {
                    my $loaded = $modulehandler->unload_module($module);
                    $event->reply("$module successfully unloaded.")     if ($loaded);
                    $event->reply("$module failed to unload.")          unless ($loaded);
                }
            }
        }
    }
}
