#!/bin/sh
set -e

usage() {
  echo "$0 <image> <signing url> <client cert> <private key> <ca chain> <expected dn>"
}

IMAGE="$1"
URL="$2"
CERT="$3"
KEY="$4"
CACHAIN="$5"
DN="$6"
UVERSION="$7"
OS_REPO="$8"
SNAPSHOT="$9"

[ ! -z "$IMAGE" ] || { usage; exit 1; }
[ ! -z "$URL" ] || { usage; exit 1; }
[ ! -z "$CERT" ] || { usage; exit 1; }
[ ! -z "$KEY" ] || { usage; exit 1; }
[ ! -z "$CACHAIN" ] || { usage; exit 1; }
[ ! -z "$DN" ] || { usage; exit 1; }
[ ! -z "$UVERSION" ] || { usage; exit 1; }
[ ! -z "$OS_REPO" ] || { usage; exit 1; }
[ ! -z "$SNAPSHOT" ] || { usage; exit 1; }

echo "--- Adding JSON meta-data to image ---"
cat << EOF > ${IMAGE}.json-metadata
{
  "ucernvm-version": "${UVERSION}",
  "os-repo": "${OS_REPO}",
  "snapshot": "${SNAPSHOT}"
}
EOF
cat ${IMAGE}.json-metadata /dev/zero | dd of=${IMAGE} conv=notrunc oflag=append bs=1 count=$((32*1024))
rm -f ${IMAGE}.json-metadata

echo "--- Sending image to sigining server ---"
curl --data-binary @${IMAGE} --cacert ${CACHAIN} --cert ${CERT} --key ${KEY} ${URL} > ${IMAGE}.signature-response
tail -1 ${IMAGE}.signature-response | base64 -d > ${IMAGE}.certificate
head -1 ${IMAGE}.signature-response | base64 -d > ${IMAGE}.signature
rm -f ${IMAGE}.signature-response

# Verify result
echo "--- Verifying signature ---"
openssl x509 -in ${IMAGE}.certificate -pubkey -noout > ${IMAGE}.pubkey
openssl verify -CAfile ${CACHAIN} ${IMAGE}.certificate
if [ "x$DN" != "x$(openssl x509 -in ${IMAGE}.certificate -subject -noout | awk '{print $2}')" ]; then
  rm -f ${IMAGE}.pubkey ${IMAGE}.signature ${IMAGE}.certificate
  exit 1
fi
openssl dgst -sha256 ${IMAGE}
openssl rsautl -verify -inkey ${IMAGE}.pubkey -pubin -in ${IMAGE}.signature | openssl asn1parse -inform der
openssl dgst -sha256 -verify ${IMAGE}.pubkey -signature ${IMAGE}.signature ${IMAGE}
rm -f ${IMAGE}.pubkey

# Create JSON signature artifact
echo "--- Creating JSON signature ---"
cat << EOF > ${IMAGE}.json-signature
{
  "certificate": "$(base64 -w0 ${IMAGE}.certificate)",
  "signature": "$(base64 -w0 ${IMAGE}.signature)",
  "howto-verify": [
    "base64 -d <certificate>",
    "base64 -d <signature>",
    "openssl verify -CAfile <CERN CA Chain cern.ch/ca> <certificate>",
    "openssl x509 -in <certificate> -subject -noout | awk '{print \$2}' == ${DN}",
    "openssl x509 -in <certificate> -pubkey -noout > <pubkey>",
    "openssl dgst -sha256 -verify <pubkey> -signature <signature> \$(head -c -$((32*1024)) <image>)"
  ]
}
EOF
rm -f ${IMAGE}.certificate ${IMAGE}.signature

# Append JSON
echo "--- Appending JSON signature to image ---"
cat ${IMAGE}.json-signature /dev/zero | dd of=${IMAGE} conv=notrunc oflag=append bs=1 count=$((32*1024))
rm -f ${IMAGE}.json-signature
