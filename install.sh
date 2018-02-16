#!/bin/bash
#================================================
#FileName   :install.sh.sh
#Author     :zhaojiedi
#Description:
#DateTime   :2018-01-16 08:25:27
#Version    :V1.0
#Other      :
#================================================

source /etc/rc.d/init.d/functions

# 变量设置
download_data_dir=/usr/src/lamp
download_log_dir=/usr/src/log
compile_log_dir=/usr/src/compile
cpu_count=4
php_prefix=/usr/local/php
mysql_prefix=/usr/local/mysql
datadir=/data/mysql/data
http_prefix=/usr/local/httpd24

apr_url="http://download.linuxpanda.tech/lamp/apr-1.6.3.tar.bz2"
apr_util_url="http://download.linuxpanda.tech/lamp/apr-util-1.6.1.tar.bz2"
httpd_url="http://download.linuxpanda.tech/lamp/httpd-2.4.29.tar.bz2"
mariadb_url="http://download.linuxpanda.tech/lamp/mariadb-10.2.12.tar.gz"
php_url="http://download.linuxpanda.tech/lamp/php-7.2.1.tar.bz2"
app_url="http://download.linuxpanda.tech/lamp/index.php.sample"

## 不需要设置的

# 主程序
main(){
	setenforce 0
	install_packages
	mkdir -pv ${download_data_dir}
	mkdir -pv ${download_log_dir}
	mkdir -pv ${compile_log_dir}
	action "data and down log dir and compile log dir" 
	useradd -r  -s /sbin/nologin -c "apache" apache
	useradd -r -s /sbin/nologin -c "mysql" mysql
	download_all_files
	compile_all_source
	install_app
	#other_work
	#test_lamp
}
print_info(){
	local return_code=$1
	local message=$2
	local exit_code=$3
	if [ "$return_code" -eq 0 ] ; then 
		action "$message" true
	else	
		action "$message" false
		exit  $exit_code
	fi
}
# 下载需要的文件
download_all_files(){
	download_one_file ${apr_url}
	download_one_file ${apr_util_url}
	download_one_file ${httpd_url}
	download_one_file ${php_url}
	download_one_file ${mariadb_url}
	download_one_file ${app_url}
}
install_packages(){
	yum -y -q groupinstall "Development Tools" &> /dev/null
	yum -y -q install cmake pcre-devel openssl-devel expat-devel ncurses-devel libxml2-devel bzip2-devel libmcrypt-devel wget bzip2 &>/dev/null
	ret=$?
	print_info    $ret  "install package" 2
}
compile_all_source(){
	compile_httpd
	compile_mariadb
	compile_php

}
other_work(){
	echo "ok"
}
test_lamp(){
	echo "okk"
}
get_filename_without_tarext() { 
	a=`basename $1`
	b=${a%.tar.bz2*}
	c=${b%.tar.gz*}
	echo $c
}
# 下载单个文件
download_one_file(){
	local url=$1
	local log=${download_log_dir}/$(basename $url).log
	local localfile=${download_data_dir}/$(basename $url)
	wget --no-check-certificate -c -o $log -O $localfile $url
	print_info "$?" "$url" 4
}
# 校验所有文件
checksum_all_files(){
	echo "ok"	
}
compile_httpd(){
	echo "start httpd"
	cd $download_data_dir

	rm -rf ${download_data_dir}/$(get_filename_without_tarext $httpd_url)
	rm -rf ${download_data_dir}/$(get_filename_without_tarext $apr_url)
	rm -rf ${download_data_dir}/$(get_filename_without_tarext $apr_util_url)
	print_info 0  " clean httpd,apr,apr-util dir" 5

	tar xf ${download_data_dir}/$(basename ${apr_url})
	tar xf ${download_data_dir}/$(basename $apr_util_url)
	tar xf ${download_data_dir}/$(basename $httpd_url)
	print_info  0 "tar httpd, apr,apr-util dir " 5
	mv -v $(get_filename_without_tarext $apr_url) $(get_filename_without_tarext $httpd_url)/srclib/apr
	mv -v $(get_filename_without_tarext  $apr_util_url) $(get_filename_without_tarext  $httpd_url)/srclib/apr-util
	cd $(get_filename_without_tarext $httpd_url)
	./configure \
		--prefix=$http_prefix       \
	   	--enable-mods-shared=most   \
       	        --enable-headers            \
    		--enable-mime-magic         \
   		--enable-proxy              \
    		--enable-so                 \
    		--enable-rewrite            \
    		--with-ssl                  \
    		--enable-ssl                \
   		--enable-deflate            \
    		--with-pcre                 \
    		--with-included-apr         \
    		--with-apr-util             \
    		--enable-mpms-shared=all    \
    		--with-mpm=prefork          \
    		--enable-remoteip     > ${compile_log_dir}/httpd_configure.log

	make -j $cpu_count &>> ${compile_log_dir}/httpd_make.log && make install  &>> ${compile_log_dir}/httpd_makeinstall.log
	print_info $? "httpd make and make install" 6
	echo "PATH=$http_prefix/bin:"'$PATH'  > /etc/profile.d/lamp.sh
	cd $http_prefix
	sed -i 's@User daemon@User apache@'  conf/httpd.conf
	sed -i 's@Group daemon@Group apache@' conf/httpd.conf
	echo "$httpd_prefix/bin/apachectl start"   >> /etc/rc.d/rc.local
 	bin/apachectl start 
 	ss -tnl | grep ":80" &>/dev/null
 	print_info $? "start httpd " 7 

}
compile_mariadb() { 
	echo "start mariadb"
	cd $download_data_dir
	rm -rf ${download_data_dir}/$(get_filename_without_tarext $mariadb_url)
	tar xf ${download_data_dir}/$(basename $mariadb_url)
	cd $(get_filename_without_tarext $mariadb_url) 
	cmake . \
		-DCMAKE_INSTALL_PREFIX=$mysql_prefix \
		-DMYSQL_DATADIR=/data/mysql/data \
		-DSYSCONFDIR=/etc \
		-DMYSQL_USER=mysql \
		-DWITH_INNOBASE_STORAGE_ENGINE=1 \
		-DWITH_ARCHIVE_STORAGE_ENGINE=1 \
		-DWITH_BLACKHOLE_STORAGE_ENGINE=1 \
		-DWITH_READLINE=1 \
		-DWITH_SSL=system \
		-DWITH_ZLIB=system \
		-DWITH_LIBWRAP=0 \
		-DMYSQL_UNIX_ADDR=/data/mysql/mysql.sock \
		-DDEFAULT_CHARSET=utf8 \
		-DDEFAULT_COLLATION=utf8_general_ci \
		-DENABLED_LOCAL_INFILE=1 \
		-DWITH_PARTITION_STORAGE_ENGINE=1 \
		-DWITH_DEBUG=0 \
		-DWITHOUT_MROONGA_STORAGE_ENGINE=1     &> $compile_log_dir/mairadb_cmake.log
	make -j $cpu_count &> $compile_log_dir/mariadb_make.log && make install &> $compile_log_dir/make_install.log
	print_info $? "make and make install "  7
 	cd $mysql_prefix 
 	scripts/mysql_install_db --datadir=$datadir --user mysql --basedir=$mysql_prefix
 	cp support-files/my-innodb-heavy-4G.cnf /etc/my.cnf
 	sed -i "/\[mysqld\]/ adatadir=$datadir" /etc/my.cnf
	chown mysql.mysql $(dirname $datadir) -R
 	chown mysql.mysql $mysql_prefix -R
 	cp support-files/mysql.server  /etc/rc.d/init.d/mysqld
 	chmod a+x /etc/rc.d/init.d/mysqld 
 	sed -i '/innodb_additional_mem_pool_size/ d' /etc/my.cnf
 	chkconfig --add mysqld
 	chkconfig mysqld on
 	service mysqld start
	echo "PATH=$mysql_prefix/bin:"'$PATH' >> /etc/profile.d/lamp.sh 
 	ss -tunl |grep 3306 
 	print_info $?  "mysql " 8 
}

compile_php(){
	echo "start php"
	cd $download_data_dir
	rm -rf ${download_data_dir}/$(get_filename_without_tarext $php_url)
	tar xf ${download_data_dir}/$(basename $php_url)
	cd $(get_filename_without_tarext $php_url)
	./configure       \
		--prefix=/usr/local/php \
		--enable-mysqlnd \
		--with-mysqli=mysqlnd \
		--with-openssl \
		--with-pdo-mysql=mysqlnd \
		--enable-mbstring \
		--with-freetype-dir \
		--with-jpeg-dir \
		--with-png-dir \
		--with-zlib \
		--with-libxml-dir=/usr \
		--enable-xml \
		--enable-sockets \
		--enable-fpm \
		--with-config-file-path=/etc \
		--with-config-file-scan-dir=/etc/php.d \
		--enable-maintainer-zts \
		--disable-fileinfo     &>$compile_log_dir/php_configure.log
	make -j $cpu_count &>$compile_log_dir/php_make.log && make install &> $compile_log_dir/php_makeinstall.log
	cp php.ini-production  /etc/php.ini
	cp sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm
	chmod a+x /etc/init.d/php-fpm
	chkconfig --add php-fpm
	chkconfig php-fpm on
	cd /usr/local/php/etc
	cp php-fpm.conf.default  php-fpm.conf
	cp php-fpm.d/www.conf.default  php-fpm.d/www.conf
	service php-fpm start
	ss -tunl |grep 9000
	print_info $? "php-fpm" 10
	sed -r -i  's@#(LoadModule.*mod_proxy.so)@\1@' /usr/local/httpd24/conf/httpd.conf
	sed -r -i  's@#(LoadModule.*mod_proxy_fcgi.so)@\1@' /usr/local/httpd24/conf/httpd.conf
	sed -r -i 's@DirectoryIndex index.html@DirectoryIndex index.php index.html@' /usr/local/httpd24/conf/httpd.conf
	echo "AddType application/x-httpd-php .php" >> /usr/local/httpd24/conf/httpd.conf
	echo "AddType application/x-httpd-php-source .phps" >> /usr/local/httpd24/conf/httpd.conf
	echo "ProxyRequests Off" >> /usr/local/httpd24/conf/httpd.conf
	echo 'ProxyPassMatch ^/(.*\.php)$ fcgi://127.0.0.1:9000/usr/local/httpd24/htdocs/$1' >> /usr/local/httpd24/conf/httpd.conf
	$http_prefix/bin/apachectl restart 
	ss -tunl |grep 80
	print_info $? "httpd restart" 11
}
install_app(){
	echo "start app" 
	cd $download_data_dir
	cp $download_data_dir/$(basename $app_url) $http_prefix/htdocs/index.php
	curl 127.0.0.1
	exit 0

}
main 
