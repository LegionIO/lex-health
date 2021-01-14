FROM ruby:2.7-alpine
LABEL maintainer="Matthew Iverson <matthewdiverson@gmail.com>"

RUN mkdir /etc/legionio
RUN apk update && apk add build-base postgresql-dev mysql-client mariadb-dev tzdata gcc git

COPY . ./
RUN gem install legionio legion-data mysql2 tzinfo-data tzinfo --no-document --no-prerelease
RUN gem install lex-health --no-document --no-prerelease
CMD legionio
