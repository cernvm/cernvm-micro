#!/bin/sh

SCRATCH_DIR=${1:-/data/releases}
S3_REMOTE=${2:-cernvm-development:cvm-releases}

for d in $(find $SCRATCH_DIR -type d); do
  echo "Listing $d"
  cd $d
  tree -lhs -C -H '.' -L 1 --noreport --charset utf-8 | sed -e 's,>\t,><br />\n\t,g' | \
    sed -e 's/ \[recursive, not followed\]//' > list.html
done
rclone sync --progress --copy-links $SCRATCH_DIR $S3_REMOTE

