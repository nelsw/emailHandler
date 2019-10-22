NAME=
ROLE=
SGID=
SNID1=
SNID2=
EVJ={ "": "" }
EVNT=email-confirmation

.PHONY: clean install test build invoke package update create

clean:
	rm -f handler;
	rm -f handler.zip;

install:
	go get -t ./...

test:
	go test -coverprofile cp.out ./...

build:
	GOOS=linux GOARCH=amd64 go build -o handler ./cmd/handler.go

invoke: build
	sam local invoke -e testdata/${EVNT}.json ${NAME} \
	| jq '. | {StatusCode: .statusCode, Headers: .headers, Body: .body|fromjson}'

package: build
	zip handler.zip handler

update: package
	aws lambda update-function-code --function-name ${NAME} --zip-file fileb://./cmd/handler.zip;\
	aws lambda update-function-configuration --function-name ${NAME} ;\

create: build
	aws lambda create-function \
	--function-name ${NAME} \
	--role ${ROLE} \
	--environment '{ "Variables": ${EVJ} }' \
	--vpc-config '{ "SubnetIds": ["${SNID1}","${SNID2}"], "SecurityGroupIds": ["${SGID}"] }' \
	--zip-file fileb://./cmd/handler.zip \
	--handler handler \
	--runtime go1.x \
	--memory-size 512 \
	--timeout 30;
