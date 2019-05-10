docker pull kong:1.1
docker pull kong:1.1-centos
docker pull postgres:9.5
docker pull busybox
docker pull kong-docker-kubernetes-ingress-controller.bintray.io/kong-ingress-controller:0.3.0
docker pull kennethreitz/httpbin

# 推送镜像
docker tag kong:1.1 registry.sloth.com/kong/kong:1.1
docker push registry.sloth.com/kong/kong:1.1
docker rmi registry.sloth.com/kong/kong:1.1