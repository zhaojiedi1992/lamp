# lamp的脚本编译安装脚本
centos6下lamp的编译安装

## 安装

```bash
curl https://raw.githubusercontent.com/zhaojiedi1992/lamp/master/install.sh  | bash 
```

## 安装后的主要目录

```text
/usr/src/lamp     lamp的下载文件目录
/usr/src/log      lamp文件的下载日志
/usr/src/compile  lamp的编译日志文件
/usr/src/
```
## 下载文件和日志文件的结构

```
[root@localhost src]# tree compile/  log lamp2
compile/
├── httpd_configure.log
├── httpd_makeinstall.log
├── httpd_make.log
├── mairadb_cmake.log
├── make_install.log
├── mariadb_make.log
├── php_configure.log
├── php_makeinstall.log
└── php_make.log
log
├── apr-1.6.3.tar.bz2.log
├── apr-util-1.6.1.tar.bz2.log
├── httpd-2.4.29.tar.bz2.log
├── index.php.sample.log
├── mariadb-10.2.12.tar.gz.log
└── php-7.2.1.tar.bz2.log
lamp
├── apr-1.6.3.tar.bz2
├── apr-util-1.6.1.tar.bz2
├── httpd-2.4.29.tar.bz2
├── index.php.sample
├── mariadb-10.2.12.tar.gz
└── php-7.2.1.tar.bz2

0 directories, 21 files
```
