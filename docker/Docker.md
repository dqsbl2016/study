

#                 Docker



## 定义

Docker 中文手册上解释说：Docker 是一个开源的引擎，可以轻松的为任
何应用创建一个轻量级的、可移植的、自给自足的容器。开发者在笔记本上编译
测试通过的容器可以批量地在生产环境中部署，包括 VMs（虚拟机）、bare metal、
OpenStack 集群和其他的基础应用平台。
从这里我们可以看出，Docker 并非是容器，而是管理容器的引擎。Docker
为应用打包、部署的平台，而非单纯的虚拟化技术。
![1536132225854](https://github.com/dqsbl2016/study/blob/master/docker/img/1536132225854.png)



## Docker 与虚拟化争锋

![1536133340013](https://github.com/dqsbl2016/study/blob/master/docker/img/1536133340013.png)  

谈到虚拟化，很多人又发问了。Docker 和虚拟化有什么区别？Docker（或者说是容器）的出现是否会取代传统的虚拟化技术。
说起虚拟化，大家首先想到的必然是 VM 一类的虚机。这类虚拟机完美的
运行了另一套系统，能够使应用程序，操作系统和硬件三者之间的逻辑不变。
但在惜时如金的现在，这类虚机也面临着一定的问题，比如：启动时间太长，
你有没有过在启动虚拟机后，点开其他页面继续操作，过了一分钟才回来的经历？
还有虚拟镜像体积太大（一般都是几十 GB）等问题。相比之下，Docker 的镜
像一般只有二三百兆。并且启动速度超快， Docker 的启动时间为毫秒级。
还有一个最大的问题是价格问题，据 StackEngine 调查分析，有 43.8%的
企业使用 Docker 的原因是 VMvire 太贵

![1536133617338](https://github.com/dqsbl2016/study/blob/master/docker/img/1536133617338.png) 

但是，传统的虚拟技术还不会被取代。Docker 或者说容器技术和虚拟机并
非简单的取舍关系。
目前，很多企业仍在使用虚拟机技术，原因很简单，他们需要一个高效，安
全且高可用的构架。然而，刚刚面世两年的 Docker 还没有经历沙场考验，CaaS
（Container as a Service，容器即服务）概念也是近两年才刚刚出现。无论是
应用管理还是运行维护方面，Docker 都还处于发展与完善阶段。



## Docker：我为什么与众不同

Solomon Hykes：成功的要素之一是在正确的时间做了正确的事，我们一
直坚信这个理念。Docker 就好比传统的货运集装箱。但是创新可不仅仅是在这
个盒子里，而且还包括如何自动管理呈现上万个这样的箱子。这才是问题的关键。
站在未来的角度，Docker 解决了三大现存问题。
Docker 让开发者可以打包他们的应用以及依赖包到一个可移植的容器中，
然后发布到任何流行的 Linux 机器上，便可以实现虚拟化。
俗话说：天下武学为快不破；在更新迭代如此之快的 IT 更是如此。所有成
功的 IT 公司都必须走在时代的前列，他们的产品应该来自未来。他们有必要要
站在未来的角度解决现存的问题

Solomon Hykes 曾经说过，自己在开发 dotCloud 的 PaaS 云时，就发现
一个让人头痛的问题：应用开发工程师和系统工程师两者之间无法轻松协作发布
产品。Docker 解决了难题。让开发者能专心写好程序；让系统工程师专注在应
用的水平扩展、稳定发布的解决方案上。

1、简化程序：Docker 让开发者可以打包他们的应用以及依赖包到一个可
移植的容器中，然后发布到任何流行的 Linux 机器上，便可以实现虚拟化。
Docker 改变了虚拟化的方式，使开发者可以直接将自己的成果放入 Docker
中进行管理。方便快捷已经是 Docker 的最大优势，过去需要用数天乃至数周的
任务，在 Docker 容器的处理下，只需要数秒就能完成。
2、避免选择恐惧症：如果你有选择恐惧症，还是资深患者。Docker 帮你
打包你的纠结！比如 Docker 镜像；Docker 镜像中包含了运行环境和配置，所
以 Docker 可以简化部署多种应用实例工作。比如 Web 应用、后台应用、数据
库应用、大数据应用比如 Hadoop 集群、消息队列等等都可以打包成一个镜像
部署。
3、节省开支：一方面，云计算时代到来，使开发者不必为了追求效果而配
置高额的硬件，Docker 改变了高性能必然高价格的思维定势。Docker 与云的
结合，让云空间得到更充分的利用。不仅解决了硬件管理的问题，也改变了虚拟
化的方式。

另一方面，Docker 能够是自愿额达到充分利用。举个简单地例子
点的时候只有很少的人会去访问你的网站，同时你需要比较多的资源执
批处理任务，通过 Docker 可以很简单的便实现资源的交换。
Docker 的这些优势，让各大 IT 巨头纷纷对 Docker 看好。

## Docker下载安装

如果系统已经有Docker，则需要先删除它们：

yum remove docker docker-common docker-selinux docker-engine

1）脚本方法

  \1. 更新yum源： yum update

  2.跑shell : curl -sSL https://get.docker.com/ | sh    

  3.启动服务: service docker start

2）使用Docker repository

1. 安装yum工具

yum install -y yum-utils device-mapper-persistent-data lvm2 

1. 添加Docker repo

yum-config-manager \     --add-repo \     https://download.docker.com/linux/centos/docker-ce.repo 

1. 更新yum缓存

yum makecache fast

1. 安装Docker-ce

yum install docker-ce

3)使用rpm包进行安装

1. 下载Docker的rpm包: [RMP下载地址](https://link.jianshu.com?t=https://download.docker.com/linux/centos/7/x86_64/stable/Packages/)

1. 安装

yum install /path/to/package.rpm



## Docker启动关闭

systemctl docker start 

systemctl docker stop



## 构建Doker应用

首先清楚几个关键词的含义

- Docker：最早是dotCloud公司出品的一套容器管理工具，但后来Docker慢慢火起来了，连公司名字都从dotCloud改成Docker。
- Dockerfile： 它是Docker镜像的描述文件，可以理解成火箭发射的A、B、C、D……的步骤。
- Docker镜像： 通过Dockerfile做出来的，包含操作系统基础文件和软件运行环境，它使用分层的存储方式。
- 容器： 是运行起来的镜像，简单理解，Docker镜像相当于程序，容器相当于进程。



我们正常操作的是docker镜像，那么镜像是由Dockerfile文件生成的，那么首先是要学习Dockerfile文件是如何构建的，

#### Dockerfile的文件结构形式如下

FROM

基于哪个镜像

RUN

安装软件用

MAINTAINER

镜像创建者

#### Dockerfile的关键字描述如下

指令的一般格式为INSTRUCTION arguments，指令包括FROM、MAINTAINER、RUN等。

FROM

格式为FROM <image>或FROM <image>:<tag>。

第一条指令必须为FROM指令。并且，如果在同一个Dockerfile中创建多个镜像时，可以使用多个FROM指令（每个镜像一次）。

MAINTAINER

格式为MAINTAINER <name>，指定维护者信息。

RUN

格式为RUN <command>或RUN ["executable", "param1", "param2"]。

前者将在shell终端中运行命令，即/bin/sh -c；后者则使用exec执行。指定使用其它终端可以通过第二种方式实现，例如RUN ["/bin/bash", "-c", "echo hello"]。

每条RUN指令将在当前镜像基础上执行指定命令，并提交为新的镜像。当命令较长时可以使用\来换行。

CMD

支持三种格式

- CMD ["executable","param1","param2"]使用exec执行，推荐方式；
- CMD command param1 param2在/bin/sh中执行，提供给需要交互的应用；
- CMD ["param1","param2"]提供给ENTRYPOINT的默认参数；

指定启动容器时执行的命令，每个Dockerfile只能有一条CMD命令。如果指定了多条命令，只有最后一条会被执行。

如果用户启动容器时候指定了运行的命令，则会覆盖掉CMD指定的命令。

EXPOSE

格式为EXPOSE <port> [<port>...]。

告诉Docker服务端容器暴露的端口号，供互联系统使用。

ENV

格式为ENV <key> <value>。 指定一个环境变量，会被后续RUN指令使用，并在容器运行时保持。

例如

ENV PG_MAJOR 9.3 ENV PG_VERSION 9.3.4 RUN curl -SL http://example.com/postgres-$PG_VERSION.tar.xz | tar -xJC /usr/src/postgress && … ENV PATH /usr/local/postgres-$PG_MAJOR/bin:$PATH 

ADD

格式为ADD <src> <dest>。

该命令将复制指定的<src>到容器中的<dest>。 其中<src>可以是Dockerfile所在目录的一个相对路径；也可以是一个URL；还可以是一个tar文件（自动解压为目录）。则。

COPY

格式为COPY <src> <dest>。

复制本地主机的<src>（为Dockerfile所在目录的相对路径）到容器中的<dest>。

当使用本地目录为源目录时，推荐使用COPY。

ENTRYPOINT

两种格式：

- ENTRYPOINT ["executable", "param1", "param2"]
- ENTRYPOINT command param1 param2（shell中执行）。

配置容器启动后执行的命令，并且不可被docker run提供的参数覆盖。

每个Dockerfile中只能有一个ENTRYPOINT，当指定多个时，只有最后一个起效。

VOLUME

格式为VOLUME ["/data"]。

创建一个可以从本地主机或其他容器挂载的挂载点，一般用来存放数据库和需要保持的数据等。

USER

格式为USER daemon。

指定运行容器时的用户名或UID，后续的RUN也会使用指定用户。

当服务不需要管理员权限时，可以通过该命令指定运行用户。并且可以在之前创建所需要的用户，例如：RUN groupadd -r postgres && useradd -r -g postgres postgres。要临时获取管理员权限可以使用gosu，而不推荐sudo。

WORKDIR

格式为WORKDIR /path/to/workdir。

为后续的RUN、CMD、ENTRYPOINT指令配置工作目录。

可以使用多个WORKDIR指令，后续命令如果参数是相对路径，则会基于之前命令指定的路径。例如

WORKDIR /a WORKDIR b WORKDIR c RUN pwd 

则最终路径为/a/b/c。

ONBUILD

格式为ONBUILD [INSTRUCTION]。

配置当所创建的镜像作为其它新创建镜像的基础镜像时，所执行的操作指令。

例如，Dockerfile使用如下的内容创建了镜像image-A。

[...] ONBUILD ADD . /app/src ONBUILD RUN /usr/local/bin/python-build --dir /app/src [...] 

如果基于A创建新的镜像时，新的Dockerfile中使用FROM image-A指定基础镜像时，会自动执行ONBUILD指令内容，等价于在后面添加了两条指令。

FROM image-A  #Automatically run the following ADD . /app/src RUN /usr/local/bin/python-build --dir /app/src 

使用ONBUILD指令的镜像，推荐在标签中注明，例如ruby:1.9-onbuild。

#### 构建Docker镜像

##### 创建编辑DockerFile文件

vim DockerFile

##### 构建jdk镜像

from centos

run mkdir /usr/java

ADD jdk-8u121-linux-x64.rpm /usr/java

run cd /usr/java && \

rpm -ih jdk-8u121-linux-x64.rpm && \

run rm -rf jdk-8u121-linux-x64.rpm

ENV JAVA_HOME=/usr/java/jdk1.8.0_121 

ENV JAVA_BIN=/usr/java/jdk1.8.0_121/bin 

ENV PATH=$PATH:$JAVA_HOME/bin 

ENV CLASSPATH=.:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar



上面主要是创建一个基于centos系统的包含jdk的镜像，

centos是docker hub提供的一个centos系统的基础镜像

其它命令的含义在上面已经有详细解释，可以对照上面的去理解



##### 基于jdk镜像构建tomcat镜像

from centosjdk 

add  tomcat80.tar.gz /usr/local

ENV CATALIN_HOME  /usr/local/apache-tomcat-8.0.41

run cd /usr/local/apache-tomcat-8.0.41/bin && \

chmod a+x catalina.sh

CMD /usr/local/apache-tomcat-8.0.41/bin/catalina.sh run

##### 构建nginx镜像

from centos

run yum install -y gcc-c++ && \

yum install -y pcre pcre-devel && \

yum install -y zlib zlib-devel && \

yum install -y openssl openssl-devel && \

mkdir /var/temp && \

mkdir /var/temp/nginx   

add nginx-1.8.0.tar.gz  /opt 

run cd /opt/nginx-1.8.0 && \

./configure \

--prefix=/usr/local/nginx \

--pid-path=/var/run/nginx/nginx.pid \

--lock-path=/var/lock/nginx.lock \

--error-log-path=/var/log/nginx/error.log \

--http-log-path=/var/log/nginx/access.log \

--with-http_gzip_static_module \

--http-client-body-temp-path=/var/temp/nginx/client \

--http-proxy-temp-path=/var/temp/nginx/proxy \

--http-fastcgi-temp-path=/var/temp/nginx/fastcgi \

--http-uwsgi-temp-path=/var/temp/nginx/uwsgi \

--http-scgi-temp-path=/var/temp/nginx/scgi \

--with-ipv6 && \

make && \

make install

EXPOSE 80 443

CMD ["/usr/local/nginx/sbin/nginx", "-g", "daemon off;"]



##### docker中运行springboot项目

使用命令：

sudo docker run -w /usr/data/ -d -p 8090:8050 -v /usr/data/docker/giftservice/tomcat1/:/usr/data/ --name giftservice-1 centosjdk  java -jar cloud-DaorongGiftService-0.0.1-SNAPSHOT.jar

上面的命令中参数的含义

-w  指定工作目录，就是基目录，这样在你程序中使用的相对路径都会基于这个工作目录下进行创建

-v   挂载本地指定目录到docker中的指定目录下，就是将docker中指定目录指定为本地的一个目录，即操作的指定的本地目录

想要扩展运行多个springboot项目 对上面的命令进行简单的修改就可以完成



sudo docker run -w /usr/data/ -d -p 8092:8050 -v /usr/data/docker/giftservice/tomcat2/:/usr/data/ --name giftservice-2 centosjdk  java -jar cloud-DaorongGiftService-0.0.1-SNAPSHOT.jar



只要更改红色部分 即可

##### docker中运行nginx 挂载两个springboot项目

sudo docker run -p 81:80 -v /usr/data/docker/nginx/nginx1/conf/nginx.conf:/usr/local/nginx/conf/nginx.conf \

-v /usr/data/docker/nginx/nginx1/log/:/var/log/nginx/ \

--link giftservice-1:giftservice-1 --link giftservice-2:giftservice-2 --name nginx1 -d centos-nginx



参数解释

-v 是把本地的目录挂载到docker的指定目录下

--link 是指docker之间的关联  这样就是把nginx容器和giftservice-1容器和giftservice-2容器进行关联 这样就可以直接访问容器的内容 ，同时在nginx容器中的hosts中 加入这两个容器的映射关系，这样就可以直接用主机名进行访问，当其中一个容器重启后会把最新的host内容更新到nginx容器中去，这样不管容器的ip怎么变化都能进行访问



##### 开发服务器上建立私有仓库，生成服务器可以进行下载镜像，进行部署

待续



#####  生产环境部署

生产环境中 建议nginx安装到linux系统中，对于一些具体的web应用 则可以用docker进行构建 如spring boot项目，普通web项目都可以用docker进行构建运行

应用使用大于一个nginx进行负载

高可用可以用 keeplived

负载均衡 可以使用lvs

nginx代理的应用数量 可以设置3个及以上

##### 



