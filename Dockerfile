# 使用官方Node镜像作为构建环境
FROM node:latest as builder
MAINTAINER Kalo <ausitm2333@gmail.com>
# 设置临时目录
WORKDIR /root/src
COPY . /root/src
# 安装Hexo和依赖
RUN npm install hexo-cli -g && npm install
RUN npm install hexo-generator-searchdb
RUN wget https://github.com/jgm/pandoc/releases/download/3.1.1/pandoc-3.1.1-1-amd64.deb && \
           dpkg -i pandoc-3.1.1-1-amd64.deb; 
RUN chmod +x customization/alter_styles.sh && ./customization/alter_styles.sh
# 生成静态文件
RUN hexo generate
# 使用Nginx镜像作为生产环境
FROM nginx:alpine
COPY blog.kaloper.club_nginx/blog.kaloper.club_bundle.crt /etc/ssl/certs/
COPY blog.kaloper.club_nginx/blog.kaloper.club.key /etc/ssl/private/
COPY nginx.conf /etc/nginx/conf.d/hexosite.conf
RUN mkdir -p /var/logs && touch /var/logs/error.log && touch /var/logs/nginx.pid
RUN mkdir -p /usr/share/nginx/html/public
COPY --from=0 /root/src/public /usr/share/nginx/html/public
EXPOSE 4000
# 启动Nginx，使用默认命令
CMD ["/usr/sbin/nginx", "-g", "daemon off;"]
