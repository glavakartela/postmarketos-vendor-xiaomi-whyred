#!/bin/bash

if [ \! -d qca-swiss-army-knife ]; then
  git clone https://github.com/qca/qca-swiss-army-knife.git
  exit 0
fi

JSON="bdf/board-2.json"

iter=0
echo "[" >"${JSON}"
for file in bdf/bdwlan.*; do
  [[ $file == *.txt ]] && continue

  iter=$((iter + 1))
  [ $iter -ne 1 ] && echo "  }," >>"${JSON}"

  echo "  {" >>"${JSON}"
  echo "          \"data\": \"$file\"," >>"${JSON}"
  if [[ $file == */bdwlan.bin ]]; then
    file_ext="ff"
  else
    file_ext_1=$(basename "${file}" | sed -E 's:^.*\.b?([0-9a-f]*)$:0x\1:')
    file_ext="$(printf '%x\n' $file_ext_1)"
  fi
  echo "          \"names\": [\"bus=snoc,qmi-board-id=${file_ext}\"]" >>"${JSON}"
done

echo "  }" >>"${JSON}"
echo "]" >>"${JSON}"

python3 qca-swiss-army-knife/tools/scripts/ath10k/ath10k-bdencoder -c "${JSON}" -o board-2.bin
python3 qca-swiss-army-knife/tools/scripts/ath10k/ath10k-fwencoder --create \
                --features=wowlan,no-nwifi-decap-4addr-padding,allows-mesh-bcast,mgmt-tx-by-ref,non-bmi,single-chan-info-per-channel  \
                --set-wmi-op-version=tlv --set-htt-op-version=tlv \
                --set-fw-api=5
