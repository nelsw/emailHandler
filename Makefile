# https://docs.aws.amazon.com/cli/latest/reference/lambda/index.html
# https://stedolan.github.io/jq/
# https://mikefarah.github.io/yq/

.PHONY: it bld zip test create update run

# make it -e TEST=email-confirmation
TEST=email-confirmation
FN=
ROLE=
SGID=
SNID1=
SNID2=
EVJ={ "": "" }

MJ=jq '. | {StatusCode: .statusCode, Headers: .headers, Body: .body|fromjson}'

it: test

bld:
	GOOS=linux GOARCH=amd64 go build -o handler

zip: bld
	zip handler.zip handler

test: bld
	sam local invoke -e testdata/${TEST}.json ${FN} | ${MJ}

update: zip
	aws lambda update-function-code --function-name ${FN} --zip-file fileb://./handler.zip;\
	aws lambda update-function-configuration --function-name ${FN} ;\

create: bld
	aws lambda create-function \
	--function-name ${FN} \
	--role ${ROLE} \
	--environment '{ "Variables": ${EVJ} }' \
	--vpc-config '{ "SubnetIds": ["${SNID1}","${SNID2}"], "SecurityGroupIds": ["${SGID}"] }' \
	--zip-file fileb://./handler.zip \
	--handler handler \
	--runtime go1.x \
	--memory-size 512 \
	--timeout 30;
