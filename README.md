# Bash scripts for audit-proof archiving (apa)

The purpose of this repository is to facilitate audit-proof archiving of files with bash scripts.
"Audit-proof" in this case means that you can prove

  1. that the files in the archive weren't manipulated,
  2. who made the archive, and
  3. the exact time when the files were archived.

The scripts use well established Open Standards and reliable Free Software tools to accomplish this:

  1. SHA256 and SHA512 checksums
      * *if a single file changes its checksum will fail*
  2. GnuPG for OpenPGP signatures
      * *if a checksum is changed the OpenPGP signature will break (as will the time stamp)*
  3. OpenSSL with RFC3161 compliant time stamping authority (TSA) servers
      * *if the signature is changed the time stamp will become invalid*

Hence the only way to get an apa archive to pass all tests after changing a file is by updating checksums, signature and time stamp,
which would inevitably change the archive's date. Meaning, it's no longer possible to change the past.

## Archive format

I designed my own archive format to ensure i'm also able to verify the integrity of those archives by script.
I use the file extension `*.apa.txz` for it, which already tells you that technically it's a tar archive with XZ compression.
An apa archive always includes another uncompresed tarball called `data.tar` which contains the actual content.
It also always includes a file called `checksums`, which provides the SHA256 and SHA512 checksums for each file in `data.tar`,
and was clearsigned by GnuPG (meaning the signature is part of the file itself). This means that the tasks 1. (manipulation check)
and 2. (authentication of the archivist) are always possible. The structure of the `checksums` file is very similar to `InRelease` files of Debian package repositories.

If requested during archive generation, the archive also provides one or more files ending in `*.tsr`, which are the time stamps for the `checksums` file.
They enable you to prove the exact time when the archive was generated, and thereby the time when you were in possession of the archived documents.

This cryptographic chain makes it possible to reliably archive an arbitrary number of documents with a single digital signature and time stamp.
That's a feature because many TSA services limit the number of time stamps you can request or charge for each one.

## Dependencies

The scripts use a collection of tools that must already be installed and in path so they are found.
If a needed tool is missing, the respective script should fail with an error explaining what it was missing.

Make sure you have these installed:

 * `tar`
 * `pxz`
 * `curl`
 * `openssl`
 * `gpg2`
 * `sha256sum`
 * `sha512sum`

You also need a private OpenPGP key for generating signatures and public OpenPGP keys for archives you want to verify.

## Usage

There are three callable bash scripts, `archive_auditproof.sh`, `archive_timestamp.sh` and `archive_verify.sh`. A fourth bash script file called `_archive_functions.sh` is a collection of bash functions that are used in the scripts and is not supposed to be used by itself; think of it more as a library.

`archive_auditproof.sh` and `archive_timestamp.sh` create their own configuration file in `~/.config/bash_scripts_$USER/` so that you can change useful default settings without touching the scripts.
All scripts also show a usage message when you call them without any parameters, which is hopefully elaborate enough to understand what you should do.

### `archive_auditproof.sh`

This script generates archives from all files in a given directory, including hashes and OpenPGP signature. If you want you can also request time stamps from one or more of the configured TSA servers.

### `archive_timestamp.sh`

This script is capable of both generating a digital time stamp for a given file as well as validating a given time stamp. You can use it separately from `archive_auditproof.sh`.

### `archive_verify.sh`

Finally, this script examines a given apa archive and verifies that checksums, OpenPGP signature and time stamps are valid.

## Status

I consider these scripts to be in beta status. Feel free to check them out, but i can not guarantee that they behave like you expect.
However, i would appreciate feedback and bug reports to be able to improve them so that they can become useful for everyone.

### Planned features

One feature i would like to add is a central SQLite database to register all archives and make them searchable for specific files.
The database should be able to store different types of content, beginning with files and e-mails.
The latter would have more metadata to search for, like subject or sender.

Also, to be compliant with GDPR requirements, a method for purging single files from an archive must be possible, without breaking signatures or time stamps
(likely by adding new signatures and timestamps but keeping the old ones for reference).

## Contributing

To ask for help, report bugs, suggest feature improvements, or discuss the global
development of the package, please use the [issue tracker](https://github.com/unDocUMeantIt/apa/issues) on GitHub.

### Branches

Please note that all development happens in the `develop` branch. Pull requests against the `master`
branch will be rejected, as it is reserved for the current stable release.

## License

Copyright 2018 Meik Michalke <meik.michalke@hhu.de>

apa is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

apa is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with apa.  If not, see <http://www.gnu.org/licenses/>.
