#!/bin/bash
POD_NAME=$1
MAX_WAIT_TIME_IN_SECONDS=$2
URL=$3
SEARCH_STR=$4
POST_BODY=$5
EXPECT_EMPTY_LIST_RESPONSE=$6
EXPECT_EMPTY_RESPONSE=$7

OK_RESPONSE_CODE=200
EMPTY_LIST_RESPONSE='[]'

kubectl exec -it --namespace=performance-test $POD_NAME -- bash -c "curl --max-time $MAX_WAIT_TIME_IN_SECONDS -s -w '\n\n%{http_code}' -X POST '$URL' -H 'accept: application/json' -H 'Content-Type: application/json' -d '$POST_BODY'" > curl.out
RESPONSE_CODE=`tail -1 curl.out`
RESPONSE_BODY=`head -1 curl.out`
echo "THIS RESPONSE BODY"
echo "$RESPONSE_BODY"

if [ "$RESPONSE_CODE" != "$OK_RESPONSE_CODE" ]; then
    echo "Request failed with response code '$RESPONSE_CODE', expected '$OK_RESPONSE_CODE'"
    exit 1
else
    if [ "$EXPECT_EMPTY_LIST_RESPONSE" == "1" ] && [ "$RESPONSE_BODY" != "[]" ]; then
        echo "Request returned a non-empty response when we expect an empty list."
        exit 1
    fi
    if [ "$EXPECT_EMPTY_RESPONSE" == "1" ] && [ ! -z "$RESPONSE_BODY" ]; then
        echo "Request returned a non-empty response when we expect an empty response."
        exit 1
    fi
    if [ "$RESPONSE_BODY" == "$EMPTY_LIST_RESPONSE" ] || [ -z "$RESPONSE_BODY" ]; then
        echo "Request failed with empty response."
        exit 1
    else
        if [[ "$RESPONSE_BODY" != *"$SEARCH_STR"* ]]; then
           echo "Response did not contain search string '$SEARCH_STR'."
            exit 1
        fi
    fi
    exit 0
fi
