# kong

<https://github.com/Kong/kubernetes-ingress-controller>
<https://github.com/PGBI/kong-dashboard>
<https://docs.konghq.com/install/kubernetes/>

## all-in-one-postgres.yaml 文件调整

<github.com/Kong/kubernetes-ingress-controller/deploy/single/all-in-one-postgres.yaml>

- 镜像调整
- 由于没有 LoadBalance，将 kong-proxy 的 svc 修改 nodePort
  - Service:kong-proxy  type: LoadBalancer -> NodePort
- 由于 ceph 资源紧缺，将 pg 使用的 pv 修改为本地磁盘 emptydir
  - StatefulSet : postgres

```yaml
  volumeClaimTemplates:
  - metadata:
      name: datadir
    spec:
      accessModes:
      - "ReadWriteOnce"
      resources:
        requests:
          storage: 1Gi
```

```yaml
      volumes:
      - name: datadir
        emptyDir: {}
```

## 安装

```shell
# 安装
kubectl apply -f $GOPATH/src/github.com/kong/kubernetes-ingress-controller/deploy/single/all-in-one-postgres.yaml

# 验证
kubectl -n kong get pod -o wide
kubectl -n kong get svc -o wide
# 获取kong地址
kubectl -n kong get pod -l app=kong -o jsonpath="{.items[0].status.hostIP}"
kubectl -n kong get service kong-proxy -o jsonpath='{.spec.ports[?(@.name=="kong-proxy")].nodePort}'

# 卸载
kubectl delete -f $GOPATH/src/github.com/kong/kubernetes-ingress-controller/deploy/single/all-in-one-postgres.yaml
```

## 部署微服务

```shell
cd /Users/zhangbaohao/workspace/cloud-native
kubectl apply -f examples/httpbin/httpbin.yaml
kubectl apply -f examples/httpbin/httpbin-ingress.yaml

# 验证
kubectl get pod -o wide
kubectl get svc -o wide httpbin
kubectl get ing httpbin

curl -i -X GET --url http://172.17.8.102:30316/ip --header 'HOST: httpbin.sloth.com'
```

## postgres

```shell
kubectl -n kong get service postgres -o jsonpath='{.spec}'
# 暴露服务 type: NodePort
kubectl -n kong get pod -l app=postgres -o jsonpath="{.items[0].status.hostIP}"
kubectl -n kong patch service postgres -p '{"spec":{"type":"NodePort"}}'

# database:kong user:kong pass:kong
```

## kong-admin

```shell
kubectl -n kong get service kong-ingress-controller
kubectl -n kong get pod -l app=ingress-kong -o jsonpath="{.items[0].status.hostIP}"
```

## istio 集成

```shell
# 手动注入，注意修改image
istioctl kube-inject -f ~/repository/github.com/Kong/kubernetes-ingress-controller/deploy/manifests/kong.yaml > yaml/kong-inject.yaml

# 升级kong
kubectl apply -f yaml/kong-inject.yaml
kubectl delete -f yaml/kong-inject.yaml

# 升级kong
kubectl apply -f ~/repository/github.com/Kong/kubernetes-ingress-controller/deploy/manifests/kong.yaml
kubectl delete -f ~/repository/github.com/Kong/kubernetes-ingress-controller/deploy/manifests/kong.yaml
```

### 测试

```shell
kubectl -n istio-samples get pod -l app=productpage -o wide
kubectl -n istio-samples logs -f productpage-v1-76786b6bd7-n5shf istio-proxy

kubectl -n istio-samples get pod -l app=ratings -o wide
kubectl -n istio-samples logs -f ratings-v1-7b6c7bdcdf-xn5hs istio-proxy
kubectl -n istio-samples exec -it ratings-v1-7b6c7bdcdf-xn5hs /bin/bash

curl -i -X GET http://productpage.istio-samples.svc.cluster.local:9080
curl -i -X GET http://productpage.istio-samples:9080
curl -i -X GET http://productpage:9080
```

```shell
kubectl -n kong get pod -l app=kong -o wide
kubectl -n kong logs -f kong-6d9cb5c75c-t888b istio-proxy
kubectl -n kong exec -it kong-6d9cb5c75c-t888b -c kong-proxy sh

# 测试istio服务连通性
curl -i -X GET http://productpage.istio-samples:9080

# 规则测试
kubectl get DestinationRule --all-namespaces
kubectl get VirtualService --all-namespaces

kubectl apply -f yaml/bookinfo/fault-injection-productpage-v2.yaml
kubectl delete -f yaml/bookinfo/fault-injection-productpage-v2.yaml
```
