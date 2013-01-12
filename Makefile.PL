use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    "NAME"                => "Sophia",
    "VERSION"             => "3.0",
    "AUTHOR"              => "Kenneth K. Sham (Kays), Michael S. Yanovich (yano)",

    "ABSTRACT"            => "sophia - Perl IRC bot",
    #"BUILD_REQUIRES"      => {
        #"Test::Differences"     => "0.61",
        #"Test::More"            => "0.47"
    #},
    "CONFIGURE_REQUIRES"    => {
        "ExtUtils::MakeMaker"   => "6.30"
    },
    "LICENSE"             => "gpl",
    "MIN_PERL_VERSION"    => "5.10.0",
    "PREREQ_PM"           => {
        "Class::Inspector"                  => 0,
        "Class::Refresh"                    => 0,
        "Getopt::Long"                      => 0,
        "Method::Signatures::Modifiers"     => 0,
        "MooseX::Declare"                   => 0,
        "POE::Component::IRC"               => 0,
        "Try::Tiny"                         => 0,
        "WWW::Curl"                         => "4.14",
        #"XML::LibXML"                       => 0,
        "YAML::Tiny"                        => 0,
    },
);
