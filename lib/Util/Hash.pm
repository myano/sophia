use MooseX::Declare;
use Method::Signatures::Modifiers;

class Util::Hash
{
    # merge all hash values in @hashes into $main_hash
    # @hashes is an array of one or more hashrefs
    method merge ($main_hash, @hashes)
    {
        for my $hash (@hashes)
        {
            $main_hash = $self->merge_recursive($main_hash, $hash);
        }

        return $main_hash;
    }

    method merge_recursive ($main_hash, $hash)
    {
        LOOP: while (my ($key, $value) = each %$hash)
        {
            unless (exists $main_hash->{$key})
            {
                $main_hash->{$key} = $value;
                next LOOP;
            }

            if (ref $value eq 'HASH')
            {
                $main_hash->{$key} = $self->merge_recursive($main_hash->{$key}, $value);
                next LOOP;
            }

            # everything else can just be replaced
            $main_hash->{$key} = $value;
        }

        return $main_hash;
    }
}
