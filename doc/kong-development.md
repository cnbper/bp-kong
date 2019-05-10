# kong

<https://docs.konghq.com/install/source>

## OpenResty 1.13.6.2 开发环境搭建

```shell
# 源码安装
# https://openresty.org/cn/installation.html

# openssl pcre
export http_proxy="http://127.0.0.1:1087/"
export https_proxy="http://127.0.0.1:1087/"
brew install pcre openssl

# https://github.com/Kong/kong/issues/4471#issuecomment-481989146
brew edit pcre
# replace content with https://github.com/Homebrew/homebrew-core/blob/839adfb30f52a6e93d30d4fe2a8eb5f53f20dc4e/Formula/pcre.rb and save file
brew remove pcre
brew reinstall pcre -s

# openresty
cd /Users/zhangbaohao/workspace/cloud-native/kong/dep
tar -zxf openresty-1.13.6.2.tar.gz && cd openresty-1.13.6.2
./configure \
   --with-cc-opt="-I/usr/local/opt/openssl/include/ -I/usr/local/opt/pcre/include/" \
   --with-ld-opt="-L/usr/local/opt/openssl/lib/ -L/usr/local/opt/pcre/lib/" \
   --with-pcre-jit \
   --with-http_ssl_module \
   --with-http_realip_module \
   --with-http_stub_status_module \
   --with-http_v2_module
make
sudo make install

# 配置环境变量
export OPENRESTY_HOME=/usr/local/openresty
export PATH=$PATH:$OPENRESTY_HOME/bin

# 测试
openresty -v
# resty 命令
resty -e 'print("hello, world!")'
```

### HelloWorld

```shell
cd /Users/zhangbaohao/repository/github.com/openresty
mkdir work && cd work
mkdir logs/ conf/

cat >> conf/nginx.conf <<EOF
worker_processes  1;
error_log logs/error.log;
events {
    worker_connections 1024;
}
http {
    server {
        listen 8080;
        location / {
            default_type text/html;
            content_by_lua_block {
                ngx.say("<p>hello, world</p>")
            }
        }
    }
}
EOF

# 启动
openresty -p `pwd`/ -c conf/nginx.conf
# 测试
curl http://localhost:8080/

# 重新加载配置文件
openresty -p `pwd`/ -s reload
# 停止
openresty -p `pwd`/ -s stop
```

## Luarocks 2.4.4 环境搭建

```shell
# 源码安装 lua 5.1
cd /Users/zhangbaohao/workspace/cloud-native/kong/dep
tar -zxf lua-5.1.5.tar.gz && cd lua-5.1.5
make macosx test
sudo make install
# test
lua -v

# 源码安装 luarocks 2.4.4
cd /Users/zhangbaohao/workspace/cloud-native/kong/dep
tar -zxf luarocks-2.4.4.tar.gz && cd luarocks-2.4.4
./configure \
   --lua-suffix=jit \
   --with-lua=/usr/local/openresty/luajit \
   --with-lua-include=/usr/local/openresty/luajit/include/luajit-2.1
make build
sudo make install

# test
luarocks

# 卸载
cd /Users/zhangbaohao/workspace/cloud-native/kong/dep/luarocks-2.4.4
# 修改makefile文件 uninstall: +gmake -f GNUmakefile uninstall
sudo make uninstall
cd /Users/zhangbaohao/workspace/cloud-native/kong/dep/lua-5.1.5
sudo make uninstall
# 删除垃圾文件
sudo rm -rf /usr/local/etc/luarocks
sudo rm -rf /usr/local/share/lua
rm -rf ~/.luarocks
```

## PostgreSQL 搭建

```shell
brew install postgresql@9.5

echo 'export PATH="/usr/local/opt/postgresql@9.5/bin:$PATH"' >> ~/.bash_profile
source ~/.bash_profile

pg_ctl -V

# 后台启动
brew services start postgresql@9.5
brew services list
# 前台启动
pg_ctl -D /usr/local/var/postgresql@9.5 start

# 初始化数据库
psql postgres #访问缺省数据库
psql -U kong kong #以kong用户访问kong数据库
```

```sql
CREATE USER kong; CREATE DATABASE kong OWNER kong;

-- 退出
\q
```

## kong 开发环境搭建

<https://www.lijiaocn.com/%E9%97%AE%E9%A2%98/2018/09/29/kong-usage-problem-and-solution.html>

```shell
cd /Users/zhangbaohao/repository/github.com/Kong/kong

brew install libyaml

export http_proxy="http://127.0.0.1:1087/"
export https_proxy="http://127.0.0.1:1087/"
# 编译安装
sudo luarocks make OPENSSL_DIR=/usr/local/opt/openssl CRYPTO_DIR=/usr/local/opt/openssl YAML_DIR=/usr/local/opt/libyaml

./bin/kong version
```

```shell
cd /Users/zhangbaohao/repository/github.com/Kong/kong

WorkingDirectory=/Users/zhangbaohao/workspace/cloud-native/kong/local
cp kong.conf.default $WorkingDirectory/kong.conf

# 配置数据库
./bin/kong migrations bootstrap $WorkingDirectory/kong.conf
# 更新数据库
./bin/kong migrations up $WorkingDirectory/kong.conf

# 启动
./bin/kong start -c $WorkingDirectory/kong.conf
# 停止
./bin/kong stop -p $WorkingDirectory
# 重新加载lua文件
./bin/kong reload -p $WorkingDirectory

lsof -nP -i4TCP:8001 | grep LISTEN
curl -i http://localhost:8001/
```

## 数据库初始化

```shell
# 从kong 1.x开始操作数据库的代码全部都在kong/db中，kong/db/init.lua中的 DB.new()实例化一个DB对象。

# kong migrations bootstrap $WorkingDirectory/kong.conf
# /Users/zhangbaohao/repository/github.com/Kong/kong/kong/cmd/migrations.lua
```

## 插件开发

[Plugin Development Guide](https://docs.konghq.com/latest/plugin-development/)
[Plugin Development Kit (PDK) Reference](https://docs.konghq.com/latest/pdk/)

## 删除逻辑改造

services 表 添加 source 字段

- kube-ingress