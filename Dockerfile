FROM ghcr.io/dfinity/icp-dev-env:18

WORKDIR /app

RUN mkdir -p /app

COPY . /app

RUN npm install -g npm@11.1.0 && npm i -g ic-mops

CMD ["sh", "-c", "dfx start --clean"]
