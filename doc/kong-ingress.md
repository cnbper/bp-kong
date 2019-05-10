# kong-ingress

## 开发环境搭建

```shell
## 下载依赖
cd $GOPATH/src/github.com/kong/kubernetes-ingress-controller

export http_proxy="http://127.0.0.1:1087/"
export https_proxy="http://127.0.0.1:1087/"
GO111MODULE=on go mod download

rm -rf local/cache/*
cp -r $GOPATH/pkg/mod/cache/ local/cache/
```

### Build a raw server binary

```shell
make build
```

### Build a local container image

```shell
TAG=DEV REGISTRY=registry.sloth.com/kong make container

docker images | grep registry.sloth.com/kong
docker push registry.sloth.com/kong/kong-ingress-controller:DEV

cd /Users/zhangbaohao/workspace/cloud-native

kubectl apply -f kong/yaml/kong-ingress.yaml
kubectl apply -f examples/httpbin

kubectl delete -f examples/httpbin
kubectl delete -f kong/yaml/kong-ingress.yaml
```

## 业务

- 入口: cli/ingress-controller/main.go
