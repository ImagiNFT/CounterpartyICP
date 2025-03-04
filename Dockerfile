FROM ghcr.io/dfinity/icp-dev-env:latest

WORKDIR /app

RUN mkdir -p /app

COPY . /app

RUN npm install -g npm@11.1.0 && npm i -g ic-mops

CMD ["sh", "-c", "dfx start --clean"]
