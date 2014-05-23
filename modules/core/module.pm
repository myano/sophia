use MooseX::Declare;
use Method::Signatures::Modifiers;

class core::module with API::Module
{
    use feature qw(switch);
    use Class::Inspector;

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

    method access ($event)
    {
        return $event->is_sender_operator();
    }

    method run ($event)
    {
        # load command:
        # 1. <trigger>load <module>
        # 2. <trigger>reload <module>
        # 3. <trigger>unload <module>

        # first thing is to see which
        # command is used: load, (re|un)load
        my ($command, @modules) = split(/\s+/, $event->content);
        
        # no @modules? In other words,
        # split ' ' returned only one entry
        # then this is not a valid command
        unless (@modules)
        {
            return;
        }

        $command = lc $command;
        my $modulehandler = $event->sophia->modulehandler;

        MODULE: for my $module (@modules)
        {
            # support aliases by resolving the command
            my $module_resolv = $modulehandler->resolve_command($module);
            if ($module_resolv)
            {
                $module = $module_resolv;
            }

            given ($command)
            {
                when (/load|reload/)
                {
                    # if loaded, reload it
                    if (Class::Inspector->loaded($module))
                    {
                        if ($modulehandler->reload_module($module))
                        {
                            $event->reply(sprintf('%s successfully reloaded.', $module));
                        }
                        else
                        {
                            $event->reply(sprintf('%s failed to reload.', $module));
                        }
                    }
                    else
                    {
                        if ($modulehandler->load_module($module))
                        {
                            $event->reply(sprintf('%s successfully loaded.', $module));
                        }
                        else
                        {
                            $event->reply(sprintf('%s failed to load.', $module));
                        }
                    }
                }

                when ('unload')
                {
                    # do not actually unload it, but rather remove the bot's access ot it.
                    # since sophia is now instance-based, unloading the module will remove
                    # access to another instance that may require it.
                    delete $modulehandler->modules->{$module};
                    $event->reply("$module successfully unloaded.");
                }
            }
        }
    }
}
