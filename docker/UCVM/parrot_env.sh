export PARROT_ALLOW_SWITCHING_CVMFS_REPOSITORIES=yes
export PARROT_CVMFS_REPO="${PARROT_CVMFS_REPO} \
cernvm-prod.cern.ch:url=http://cvmfs-stratum-one.cern.ch/cvmfs/cernvm-prod.cern.ch,pubkey=/UCVM/keys/cern.ch.pub \
cernvm-testing.cern.ch:url=http://hepvm.cern.ch/cvmfs/cernvm-testing.cern.ch,pubkey=/UCVM/keys/cernvm-testing.cern.ch.pub \
cernvm-devel.cern.ch:url=http://hepvm.cern.ch/cvmfs/cernvm-devel.cern.ch,pubkey=/UCVM/keys/cernvm-devel.cern.ch.pub \
cernvm-slc4.cern.ch:url=http://hepvm.cern.ch/cvmfs/cernvm-slc4.cern.ch,pubkey=/UCVM/keys/cernvm-slc4.cern.ch.pub \
cernvm-slc5.cern.ch:url=http://hepvm.cern.ch/cvmfs/cernvm-slc5.cern.ch,pubkey=/UCVM/keys/cernvm-slc5.cern.ch.pub \
cernvm-sl7.cern.ch:url=http://hepvm.cern.ch/cvmfs/cernvm-sl7.cern.ch,pubkey=/UCVM/keys/cernvm-sl7.cern.ch.pub \
alice.cern.ch:url=http://cvmfs-stratum-one.cern.ch/cvmfs/alice.cern.ch,pubkey=/UCVM/keys/cern.ch.pub \
alice-ocdb.cern.ch:url=http://cvmfs-stratum-one.cern.ch/cvmfs/alice-ocdb.cern.ch,pubkey=/UCVM/keys/cern-it1.cern.ch.pub \
atlas.cern.ch:url=http://cvmfs-stratum-one.cern.ch/cvmfs/atlas.cern.ch,pubkey=/UCVM/keys/cern.ch.pub \
atlas-condb.cern.ch:url=http://cvmfs-stratum-one.cern.ch/cvmfs/atlas-condb.cern.ch,pubkey=/UCVM/keys/cern.ch.pub \
cms.cern.ch:url=http://cvmfs-stratum-one.cern.ch/cvmfs/cms.cern.ch,pubkey=/UCVM/keys/cern.ch.pub \
lhcb.cern.ch:url=http://cvmfs-stratum-one.cern.ch/cvmfs/lhcb.cern.ch,pubkey=/UCVM/keys/cern.ch.pub \
sft.cern.ch:url=http://cvmfs-stratum-one.cern.ch/cvmfs/sft.cern.ch,pubkey=/UCVM/keys/cern.ch.pub \
grid.cern.ch:url=http://cvmfs-stratum-one.cern.ch/cvmfs/grid.cern.ch,pubkey=/UCVM/keys/cern.ch.pub \
clicdp.cern.ch:url=http://cvmfs-stratum-one.cern.ch/cvmfs/clicdp.cern.ch,pubkey=/UCVM/keys/cern-it1.cern.ch.pub"
if [ -f /UCVM/PARROT_CVMFS_REPO ]; then
  export PARROT_CVMFS_REPO="${PARROT_CVMFS_REPO} $($BB cat /UCVM/PARROT_CVMFS_REPO)"
fi
PARROT_OPTIONS="${PARROT_OPTIONS} --fake-setuid"
if [ -f /UCVM/PARROT_OPTIONS ]; then
  export PARROT_OPTIONS="${PARROT_OPTIONS} $($BB cat /UCVM/PARROT_OPTIONS)"
fi
export HTTP_PROXY="${HTTP_PROXY:="DIRECT;DIRECT"}"
