# 部署docker服务器文档

## 需要额外做以下操作：

### 上传config.js和settings.js文件到deploy目录下
### 代码目录下clone好REST API代码
### 代码目录下的相关目录clone好前端相关代码
### Nginx配置：修改目录及域名
### 注意确认服务器本来的nginx服务已经关掉
### 注意从github上clone的deploy代码，需要修改deploy.sh和pre-setup.sh的执行权限
### MongoDB映射到主机的端口号：修改deploy.sh:87行: `--publish=127.0.0.1:${mongod_port:-xxxxx}:27017 \`
### 部署docker：运行命令 $ ./deploy.sh -d xxx.xxx.com -p /dir_of_rest -e server.js
### 配置mongo安全权限：运行命令 $ mongo auth.js --port xxxxx
### 注意跨域访问问题：修改config相关网址数组
### 注意图片访问地址问题