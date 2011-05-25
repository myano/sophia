use strict;
use warnings;

sub sophia_event_join_hook {
    sophia_event_hook($sophia::EVENTSCONF{join}, \@_); 
}

sub sophia_event_kick_hook {
    sophia_event_hook($sophia::EVENTSCONF{kick}, \@_);
}

sub sophia_event_nick_hook {
    sophia_event_hook($sophia::EVENTSCONF{nick}, \@_);
}

sub sophia_event_notice_hook {
    sophia_event_hook($sophia::EVENTSCONF{notice}, \@_);
}

sub sophia_event_part_hook {
    sophia_event_hook($sophia::EVENTSCONF{part}, \@_);
}

sub sophia_event_privmsg_hook {
    sophia_event_hook($sophia::EVENTSCONF{privmsg}, \@_);
}

sub sophia_event_public_hook {
    sophia_event_hook($sophia::EVENTSCONF{public}, \@_);
}

sub sophia_event_quit_hook {
    sophia_event_hook($sophia::EVENTSCONF{quit}, \@_);
}

sub sophia_event_hook {
    my ($event, $vals) = @_;
    my ($mod_cmd, $cmd_hook, $cmd_desc, $cmd_help, $cmd_access) = @{$vals};
    return unless $event && $mod_cmd;

    my ($module, $command) = split /\./, $mod_cmd;
    $cmd_access ||= 0x0;

    $sophia::EVENTS->{$event}{$module}{$command}{init} = $cmd_hook;
    $sophia::EVENTS->{$event}{$module}{$command}{desc} = $cmd_desc;
    $sophia::EVENTS->{$event}{$module}{$command}{help} = $cmd_help;
    $sophia::EVENTS->{$event}{$module}{$command}{access} = $cmd_access;
}

sub sophia_event_join_dehook {
    sophia_event_dehook($sophia::EVENTSCONF{join}, $_[0]); 
}

sub sophia_event_kick_dehook {
    sophia_event_dehook($sophia::EVENTSCONF{kick}, $_[0]);
}

sub sophia_event_nick_dehook {
    sophia_event_dehook($sophia::EVENTSCONF{nick}, $_[0]);
}

sub sophia_event_notice_dehook {
    sophia_event_dehook($sophia::EVENTSCONF{notice}, $_[0]);
}

sub sophia_event_part_dehook {
    sophia_event_dehook($sophia::EVENTSCONF{part}, $_[0]);
}

sub sophia_event_privmsg_dehook {
    sophia_event_dehook($sophia::EVENTSCONF{privmsg}, $_[0]);
}

sub sophia_event_public_dehook {
    sophia_event_dehook($sophia::EVENTSCONF{public}, $_[0]);
}

sub sophia_event_quit_dehook {
    sophia_event_dehook($sophia::EVENTSCONF{quit}, $_[0]);
}

sub sophia_event_dehook {
    my ($event, $mod_cmd) = @_;
    return unless $event && $mod_cmd;

    my ($module, $command) = split /\./, $mod_cmd;

    delete $sophia::EVENTS->{$event}{$module}{$command};
}

1;
