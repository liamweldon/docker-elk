#!/usr/bin/env bash

set -eu
set -o pipefail


source "${BASH_SOURCE[0]%/*}"/lib/testing.sh


cid_es="$(container_id elasticsearch)"
cid_en="$(container_id enterprise-search)"

ip_es="$(service_ip elasticsearch)"
ip_en="$(service_ip enterprise-search)"

grouplog 'Wait for readiness of Elasticsearch'
poll_ready "$cid_es" 'http://elasticsearch:9201/' --resolve "elasticsearch:9201:${ip_es}" -u 'elastic:testpasswd'
endgroup

grouplog 'Wait for readiness of Enterprise Search'
poll_ready "$cid_en" 'http://enterprise-search:3002/api/ent/v1/internal/health' --resolve "enterprise-search:3002:${ip_en}" -u 'elastic:testpasswd'
endgroup

log 'Ensuring that App Search API keys were created in Elasticsearch'
response="$(curl 'http://elasticsearch:9201/.ent-search-actastic-app_search_api_tokens_v3/_search?q=*:*&pretty' -s --resolve "elasticsearch:9201:${ip_es}" -u elastic:testpasswd)"
echo "$response"
declare -i count
count="$(jq -rn --argjson data "${response}" '$data.hits.total.value')"
if (( count != 2)); then
	echo "Expected search and private keys, got ${count} result(s)"
	exit 1
fi
