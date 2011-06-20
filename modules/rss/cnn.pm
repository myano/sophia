use strict;
use warnings;

my $CNN_LastDate = '';
my @CNN_Channels = ('#sophia');
my $CNN_Timer = 60;   # in seconds

sophia_module_add("rss.cnn:popular", "1.0", \&init_rss_cnn, \&deinit_rss_cnn);

sub init_rss_cnn {
    sophia_timer_add("cnn_popular_hook", \&cnn_popular_hook, $CNN_Timer);

    return 1;
}

sub deinit_rss_cnn {
    delete_sub "init_rss_cnn";
    delete_sub "cnn_latest_init";
    delete_sub "cnn_latest_hook";
    sophia_command_del "rss.cnn:latest";
    delete_sub "deinit_rss_cnn";
}

sub cnn_popular_init {
    my $objXML = loadXML("http://rss.cnn.com/rss/cnn_latest.rss");
    $objRSS = ${$objXML};

    my ($desc, $first) = ('', 0);

    FEED: for ($objRSS->get_item) {
        last FEED if $CNN_LastDate eq $_->pubDate();
        $CNN_LastDate = $_->pubDate() unless $first;
        
        $desc = $_->description();
        $desc =~ s/\r\n|\n//g;
        $desc =~ s/<[^>]+>//g;
        $desc =~ s/^\s+//;
        $desc =~ s/\s+$//;
        next FEED unless $desc;

        
        sophia_write( \@CNN_Channels, \sprintf($bold . 'CNN Latest:' . $bold . ' %s  Read more: %s', $desc, $_->link()));

        last FEED if ++$first > 2;
    }
}

sub cnn_popular_hook {
    &cnn_popular_init;
    $_[KERNEL]->alarm( 'cnn_popular_hook' => time() + $CNN_Timer );
}

1;
