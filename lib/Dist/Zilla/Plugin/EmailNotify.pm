use strict;
use warnings;
package Dist::Zilla::Plugin::EmailNotify;
# ABSTRACT: send an email on dist release

use Moose;
with 'Dist::Zilla::Role::Releaser';

use Email::Stuff;

use namespace::autoclean;

has to => (
    is         => 'ro',
    isa        => 'Str',
    lazy_build => 1,
);

has recipient => (
    is        => 'ro',
    isa       => 'ArrayRef[Str]',
    predicate => 'has_recipient',
);

has from => (
    is       => 'ro',
    isa      => 'Str', 
    required => 1,
);

has cc => (
    is      => 'ro',
    isa     => 'ArrayRef[Str]',
    default => sub { [] },
);

has bcc => (
    is      => 'ro',
    isa     => 'ArrayRef[Str]',
    default => sub { [] },
);

sub mvp_multivalue_args { qw/recipient cc bcc/ }

sub _build_to {
    my $self = shift;

    $self->has_recipient
        or die "Must provide 'recipient' or 'to'\n";

    return join ', ', @{ $self->recipient };
}

sub release {
    my $self    = shift;
    my $archive = shift;
    my $name    = $self->zilla->name;
    my $to      = $self->to;
    my $from    = $self->from;
    my @authors = @{ $self->zilla->authors };
    my $cc      = join ', ', @{ $self->cc  };
    my $bcc     = join ', ', @{ $self->bcc };
    my $authors = join '', map { "  - $_\n" } @{ $self->zilla->authors };

    $name =~ s/\.tar\.gz$//;

    my $text_body = <<"    _END_TEXT";
A new version of $name is available!

Authors:
$authors
    _END_TEXT

    my $email = Email::Stuff->subject("$archive released!")
                            ->from($from)
                            ->to($to)
                            ->text_body($text_body);

    $cc  and $email->cc($cc);
    $bcc and $email->bcc($bcc);

    return $email->send;
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__

=head1 DESCRIPTION

This plugin allows to send an email when releasing.

=head1 FIELDS

=head2 from

Who is sending the email?

    [EmailNotify]
    from = xsawyerx@cpan.org

=head2 recipient

Multiple single recipients. These will compose the 'to' field.

    [EmailNotify]
    recipient = jack@myemail.com
    recipient = jill@myemail.com

=head2 to

Direct recipients string. This should be comma separated.

    [EmailNotify]
    to = jack@myemail.com, jill@myemail.com

=head2 cc

Any CC you may want. This should be comma separated.

    [EmailNotify]
    cc = myboss@myemail.com, jacksboss@myemail.com

=head2 bcc

Any BCC you may want. This should be comma separated.

    [EmailNotify]
    bcc = topgun@myemail.com

=head1 ATTRIBUTES

=head2 to(Str)

The 'to' email field.

=head2 recipient(ArrayRef[Str])

This array reference of strings will be used to compose the 'to' email field.

It is used in case you want to comfortably write down the recipients instead of
one long string. This is not provided for other fields.

=head2 from(Str)

The 'from' email field.

=head2 cc(Str)

The 'cc' email field.

=head2 bcc(Str)

The 'bcc' email field.

=head1 METHODS/SUBROUTINES

=head2 release

Method to actually do the 'release' process. Takes all the arguments, defines
a body message text and sends the email using L<Email::Stuff>.

=head2 _build_to

Builder to take all the recipient attribute values and create a single
string.

=head2 mvp_multivalue_args

Internal, L<Config::MVP> related. Creates a multivalue argument.

