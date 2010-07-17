package Dist::Zilla::Plugin::ModuleBuild::XSOrPP;
BEGIN {
  $Dist::Zilla::Plugin::ModuleBuild::XSOrPP::VERSION = '0.02';
}

use strict;
use warnings;

use Moose;

extends 'Dist::Zilla::Plugin::ModuleBuild';

my $pp_check = <<'EOF';
if ( grep { $_ eq '--pp' } @ARGV ) {
    $build->build_elements(
        [ grep { $_ ne 'xs' } @{ $build->build_elements() } ] );
}

EOF

after setup_installer => sub {
    my $self = shift;

    my ($file) = grep { $_->name() eq 'Build.PL' } @{ $self->zilla()->files() };

    my $content = $file->content();

    $content =~ s/(\$build->create_build_script;)/$pp_check$1/;

    $file->content($content);

    return;
};

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: Add a --pp option to your Build.PL to force an XS-less build



=pod

=head1 NAME

Dist::Zilla::Plugin::ModuleBuild::XSOrPP - Add a --pp option to your Build.PL to force an XS-less build

=head1 VERSION

version 0.02

=head1 SYNOPSIS

In your F<dist.ini>:

   [ModuleBuild::XSOrPP]

=head1 DESCRIPTION

Use this plugin instead of the regular C<ModuleBuild> plugin. It generates a
F<Build.PL> which accepts a C<--pp> flag to forcible disable XS
compilation. Obviously, this is only useful if your module can work without
its XS component.

=head1 SUPPORT

Please report any bugs or feature requests to
C<bug-dist-zilla-plugin-modulebuild-xsorpp@rt.cpan.org>, or through the web
interface at L<http://rt.cpan.org>. I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 DONATIONS

If you'd like to thank me for the work I've done on this module, please
consider making a "donation" to me via PayPal. I spend a lot of free time
creating free software, and would appreciate any support you'd care to offer.

Please note that B<I am not suggesting that you must do this> in order for me
to continue working on this particular software. I will continue to do so,
inasmuch as I have in the past, for as long as it interests me.

Similarly, a donation made in this way will probably not make me work on this
software much more, unless I get so many donations that I can consider working
on free software full time, which seems unlikely at best.

To donate, log into PayPal and send money to autarch@urth.org or use the
button on this page: L<http://www.urth.org/~autarch/fs-donation.html>

=head1 AUTHOR

  Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2010 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0

=cut


__END__

