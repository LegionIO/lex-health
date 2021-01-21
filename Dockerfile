FROM legionio/legion:latest
LABEL maintainer="Matthew Iverson <matthewdiverson@gmail.com>"

COPY . ./
RUN gem install lex-health --no-document --no-prerelease
CMD ruby --jit $(which legionio)
