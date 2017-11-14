#!/bin/sh
#
# Make tar for git repo w/ one level of sub modules.
#
set -e

TOPREV="$1"
FINALTAR="$2"
PREFIX="$3"

if ! [ "$TOPREV" ]
then
   cat <<EOF >&2
usage: $0 [rev] [outfile.tar.gz] [prefix/]

  "<rev>" may be any git revision spec. (tag, branch, or commit id).

  Output file may be .tar.gz, .tar.bz2, or any extension supported by "tar -a".
  If output file name is omitted, then "<rev>.tar.gz" is the default.
  If prefix is omitted, then the default is "<rev>/".
EOF
   exit 1
fi

[ "$FINALTAR" ] || FINALTAR="$TOPREV.tar.gz"
[ "PREFIX" ] || PREFIX="$TOPREV/"

# temporary directory w/ automatic cleanup
TDIR=`mktemp -d`
trap 'rm -rf "$TDIR"' EXIT INT QUIT TERM

mkdir "$TDIR"/tar

echo "Export revision $TOPREV as $FINALTAR with prefix $PREFIX"

# Use git-archive to copy files at the given revision into our temp. dir.
# Respects 'export-exclude' in .gitattributes files.

git archive --prefix=$PREFIX $TOPREV | tar -C "$TDIR"/tar -x

# use ls-tree instead of submodule-foreach to capture submodule revision associated with supermodule rev.
#
# sub-modules appear in tree as eg.:
#  160000 commit c3a6cfcf0dad4a4eeecf59b474710d06ff3eb68a  modules/ca
git ls-tree -r $TOPREV | awk '/^[0-9]+ commit / {print $3, $4}' | \
while read HASH MODDIR
do
    echo "visit $HASH $MODDIR"
    (cd $MODDIR && git archive --prefix=${PREFIX}${MODDIR}/ $HASH) | tar -C "$TDIR"/tar -x
done

# make a list of files copied and filter out undesirables

(cd "$TDIR"/tar && find .) > "$TDIR"/list.1

sed \
-e '/.*ci$/d' \
-e '/.*ci\//d' \
-e '/.*jenkins$/d' \
-e '/.*jenkins\//d' \
-e '/\.git/d' \
-e '/\.project/d' \
-e '/.*\.travis\.yml$/d' \
-e '/.*\.appveyor\.yml$/d' \
"$TDIR"/list.1 > "$TDIR"/list.2

if ! diff -u "$TDIR"/list.1 "$TDIR"/list.2
then
  echo "Warning: prohibited files being ignored"
fi

# Use the filtered list to build the final tar
#  The -a option chooses compression automatically based on output file name.

tar -C "$TDIR"/tar --files-from="$TDIR"/list.2 -caf "$FINALTAR"

echo "Wrote $FINALTAR"
