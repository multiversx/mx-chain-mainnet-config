<div style="text-align:center">
  <img
  src="https://raw.githubusercontent.com/ElrondNetwork/elrond-go/master/elrond_logo_01.svg"
  alt="Elrond Network">
</div>
<br>

<br>

[![](https://img.shields.io/badge/made%20by-Elrond%20Network-blue.svg?style=flat-square)](http://elrond.com/)
[![](https://img.shields.io/badge/project-Elrond%20Network%20Mainnet-blue.svg?style=flat-square)](http://elrond.com/)

# elrond-config for mainnet

Elrond mainnet configuration files used in conjunction with elrond-go project. 
For more info how to connect to the mainnet, please check [docs.elrond.com](https://docs.elrond.com/validators/mainnet/config-scripts/)

## run an elrond observer/validator with docker

### build docker image
```docker image build . -t elrond-node-image-last -f ./docker/Dockerfile```

### run node with docker
```
CONFIG_FOLDER=path/to/folder/with/pem/file
docker run --mount type=bind,source=${CONFIG_FOLDER}/,destination=/data elrond-node-image-last --validator-key-pem-file="/data/validatorKey.pem" --log-level *:DEBUG
```

