# Hyperledger Fabric Client

> Straight connection to Fabric network, no middle layer

### Build
#### By electron-rebuild (faster)
``` bash
export npm_config_target=1.8.8
export npm_config_arch=x64
export npm_config_target_arch=x64
export npm_config_disturl=https://electronjs.org/headers
export npm_config_runtime=electron
export npm_config_build_from_source=true
rm -rf node_modules/
./node_modules/.bin/electron-rebuild -d https://electronjs.org/headers
```
---
#### By npm
``` bash
export npm_config_target=1.8.8
export npm_config_arch=x64
export npm_config_target_arch=x64
export npm_config_disturl=https://electronjs.org/headers
export npm_config_runtime=electron
export npm_config_build_from_source=true
rm -rf node_modules/
HOME=~/.electron-gyp npm install
```

