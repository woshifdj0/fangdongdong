#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#=================================================
#	System Required: CentOS 7/8,Debian/ubuntu,oraclelinux
#	Description: BBR+BBRplus+Lotserver+doubissr+docker+xray
#	Version: 1.3.2.97
#	Author: 千影,cx9208,YLX
#	更新内容及反馈:  https://blog.ylx.me/archives/783.html
#=================================================

# RED='\033[0;31m'
# GREEN='\033[0;32m'
# YELLOW='\033[0;33m'
# SKYBLUE='\033[0;36m'
# PLAIN='\033[0m'

sh_ver="1.3.2.97"
github="raw.githubusercontent.com/ylx2016/Linux-NetSpeed/master"

imgurl=""
headurl=""

Green_font_prefix="\033[32m"
Red_font_prefix="\033[31m"
Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[信息]${Font_color_suffix}"
Error="${Red_font_prefix}[错误]${Font_color_suffix}"
Tip="${Green_font_prefix}[注意]${Font_color_suffix}"

if [ -f "/etc/sysctl.d/bbr.conf" ]; then
  rm -rf /etc/sysctl.d/bbr.conf
fi

#检查连接
checkurl() {
  url=$(curl --max-time 5 --retry 3 --retry-delay 2 --connect-timeout 2 -s --head $1 | head -n 1)
  if [[ ${url} == *200* || ${url} == *302* || ${url} == *308* ]]; then
    echo "下载地址检查OK，继续！"
  else
    echo "下载地址检查出错，退出！"
    exit 1
  fi
}

#安装BBR内核
installbbr() {
  kernel_version="5.9.6"
  bit=$(uname -m)
  rm -rf bbr
  mkdir bbr && cd bbr || exit

  if [[ "${release}" == "centos" ]]; then
    if [[ ${version} == "7" ]]; then
      if [[ ${bit} == "x86_64" ]]; then
        echo -e "如果下载地址出错，可能当前正在更新，超过半天还是出错请反馈，大陆自行解决污染问题"
        #github_ver=$(curl -s 'https://api.github.com/repos/ylx2016/kernel/releases' | grep ${github_tag} | head -n 1 | awk -F '"' '{print $4}' | awk -F '[/]' '{print $8}' | awk -F '[_]' '{print $3}')
        github_tag=$(curl -s 'https://api.github.com/repos/ylx2016/kernel/releases' | grep 'Centos_Kernel' | grep '_latest_bbr_' | head -n 1 | awk -F '"' '{print $4}' | awk -F '[/]' '{print $8}')
        github_ver=$(curl -s 'https://api.github.com/repos/ylx2016/kernel/releases' | grep ${github_tag} | grep 'rpm' | grep 'headers' | awk -F '"' '{print $4}' | awk -F '[/]' '{print $9}' | awk -F '[-]' '{print $3}')
        echo -e "获取的版本号为:${github_ver}"
        kernel_version=$github_ver
        detele_kernel_head
        headurl=$(curl -s 'https://api.github.com/repos/ylx2016/kernel/releases' | grep ${github_tag} | grep 'rpm' | grep 'headers' | awk -F '"' '{print $4}')
        imgurl=$(curl -s 'https://api.github.com/repos/ylx2016/kernel/releases' | grep ${github_tag} | grep 'rpm' | grep -v 'headers' | grep -v 'devel' | awk -F '"' '{print $4}')
        #headurl=https://github.com/ylx2016/kernel/releases/download/$github_tag/kernel-headers-${github_ver}-1.x86_64.rpm
        #imgurl=https://github.com/ylx2016/kernel/releases/download/$github_tag/kernel-${github_ver}-1.x86_64.rpm
        echo -e "正在检查headers下载连接...."
        checkurl $headurl
        echo -e "正在检查内核下载连接...."
        checkurl $imgurl
        wget -N -O kernel-headers-c7.rpm $headurl
        wget -N -O kernel-c7.rpm $imgurl
        yum install -y kernel-c7.rpm
        yum install -y kernel-headers-c7.rpm
      else
        echo -e "${Error} 不支持x86_64以外的系统 !" && exit 1
      fi
    fi

  elif [[ "${release}" == "ubuntu" || "${release}" == "debian" ]]; then
    if [[ ${bit} == "x86_64" ]]; then
      echo -e "如果下载地址出错，可能当前正在更新，超过半天还是出错请反馈，大陆自行解决污染问题"
      github_tag=$(curl -s 'https://api.github.com/repos/ylx2016/kernel/releases' | grep 'Ubuntu_Kernel' | grep '_latest_bbr_' | head -n 1 | awk -F '"' '{print $4}' | awk -F '[/]' '{print $8}')
      github_ver=$(curl -s 'https://api.github.com/repos/ylx2016/kernel/releases' | grep ${github_tag} | grep 'deb' | grep 'headers' | awk -F '"' '{print $4}' | awk -F '[/]' '{print $9}' | awk -F '[-]' '{print $3}' | awk -F '[_]' '{print $1}')
      echo -e "获取的版本号为:${github_ver}"
      kernel_version=$github_ver
      detele_kernel_head
      headurl=$(curl -s 'https://api.github.com/repos/ylx2016/kernel/releases' | grep ${github_tag} | grep 'deb' | grep 'headers' | awk -F '"' '{print $4}')
      imgurl=$(curl -s 'https://api.github.com/repos/ylx2016/kernel/releases' | grep ${github_tag} | grep 'deb' | grep -v 'headers' | grep -v 'devel' | awk -F '"' '{print $4}')
      #headurl=https://github.com/ylx2016/kernel/releases/download/$github_tag/linux-headers-${github_ver}_${github_ver}-1_amd64.deb
      #imgurl=https://github.com/ylx2016/kernel/releases/download/$github_tag/linux-image-${github_ver}_${github_ver}-1_amd64.deb
      echo -e "正在检查headers下载连接...."
      checkurl $headurl
      echo -e "正在检查内核下载连接...."
      checkurl $imgurl
      wget -N -O linux-headers-d10.deb $headurl
      wget -N -O linux-image-d10.deb $imgurl
      dpkg -i linux-image-d10.deb
      dpkg -i linux-headers-d10.deb
    elif [[ ${bit} == "aarch64" ]]; then
      echo -e "如果下载地址出错，可能当前正在更新，超过半天还是出错请反馈，大陆自行解决污染问题"
      github_tag=$(curl -s 'https://api.github.com/repos/ylx2016/kernel/releases' | grep 'Ubuntu_Kernel' | grep '_arm64_' | grep '_bbr_' | head -n 1 | awk -F '"' '{print $4}' | awk -F '[/]' '{print $8}')
      github_ver=$(curl -s 'https://api.github.com/repos/ylx2016/kernel/releases' | grep ${github_tag} | grep 'deb' | grep 'headers' | awk -F '"' '{print $4}' | awk -F '[/]' '{print $9}' | awk -F '[-]' '{print $3}' | awk -F '[_]' '{print $1}')
      echo -e "获取的版本号为:${github_ver}"
      kernel_version=$github_ver
      detele_kernel_head
      headurl=$(curl -s 'https://api.github.com/repos/ylx2016/kernel/releases' | grep ${github_tag} | grep 'deb' | grep 'headers' | awk -F '"' '{print $4}')
      imgurl=$(curl -s 'https://api.github.com/repos/ylx2016/kernel/releases' | grep ${github_tag} | grep 'deb' | grep -v 'headers' | grep -v 'devel' | awk -F '"' '{print $4}')
      #headurl=https://github.com/ylx2016/kernel/releases/download/$github_tag/linux-headers-${github_ver}_${github_ver}-1_amd64.deb
      #imgurl=https://github.com/ylx2016/kernel/releases/download/$github_tag/linux-image-${github_ver}_${github_ver}-1_amd64.deb
      echo -e "正在检查headers下载连接...."
      checkurl $headurl
      echo -e "正在检查内核下载连接...."
      checkurl $imgurl
      wget -N -O linux-headers-d10.deb $headurl
      wget -N -O linux-image-d10.deb $imgurl
      dpkg -i linux-image-d10.deb
      dpkg -i linux-headers-d10.deb
    else
      echo -e "${Error} 不支持x86_64及arm64/aarch64以外的系统 !" && exit 1
    fi
  fi

  cd .. && rm -rf bbr

  BBR_grub
  echo -e "${Tip} 内核安装完毕，请参考上面的信息检查是否安装成功,默认从排第一的高版本内核启动"
  check_kernel
}

#安装BBRplus内核 4.14.129
installbbrplus() {
  kernel_version="4.14.160-bbrplus"
  bit=$(uname -m)
  rm -rf bbrplus
  mkdir bbrplus && cd bbrplus || exit
  if [[ "${release}" == "centos" ]]; then
    if [[ ${version} == "7" ]]; then
      if [[ ${bit} == "x86_64" ]]; then
        kernel_version="4.14.129_bbrplus"
        detele_kernel_head
        headurl=http://185.173.224.22/kernel-headers-4.14.129-bbrplus.rpm
        imgurl=http://185.173.224.22/kernel-4.14.129-bbrplus.rpm
        echo -e "正在检查headers下载连接...."
        checkurl $headurl
        echo -e "正在检查内核下载连接...."
        checkurl $imgurl
        wget -N -O kernel-headers-c7.rpm $headurl
        wget -N -O kernel-c7.rpm $imgurl
        yum install -y kernel-c7.rpm
        yum install -y kernel-headers-c7.rpm
      else
        echo -e "${Error} 不支持x86_64以外的系统 !" && exit 1
      fi
    fi

  elif [[ "${release}" == "debian" || "${release}" == "ubuntu" ]]; then
    if [[ ${bit} == "x86_64" ]]; then
      kernel_version="4.14.129-bbrplus"
      detele_kernel_head
      headurl=http://185.173.224.22/linux-headers-4.14.129-bbrplus.deb
      imgurl=http://185.173.224.22/linux-image-4.14.129-bbrplus.deb
      echo -e "正在检查headers下载连接...."
      checkurl $headurl
      echo -e "正在检查内核下载连接...."
      checkurl $imgurl
      wget -N -O linux-headers.deb $headurl
      wget -N -O linux-image.deb $imgurl

      dpkg -i linux-image.deb
      dpkg -i linux-headers.deb
    else
      echo -e "${Error} 不支持x86_64以外的系统 !" && exit 1
    fi
  fi

  cd .. && rm -rf bbrplus
  BBR_grub
  echo -e "${Tip} 内核安装完毕，请参考上面的信息检查是否安装成功,默认从排第一的高版本内核启动"
  check_kernel
}

#安装Lotserver内核
installlot() {
  bit=$(uname -m)
  if [[ ${bit} != "x86_64" ]]; then
    echo -e "${Error} 不支持x86_64以外的系统 !" && exit 1
  fi
  if [[ ${bit} == "x86_64" ]]; then
    bit='x64'
  fi
  if [[ ${bit} == "i386" ]]; then
    bit='x32'
  fi
  if [[ "${release}" == "centos" ]]; then
    rpm --import http://${github}/lotserver/${release}/RPM-GPG-KEY-elrepo.org
    yum remove -y kernel-firmware
    yum install -y http://${github}/lotserver/${release}/${version}/${bit}/kernel-firmware-${kernel_version}.rpm
    yum install -y http://${github}/lotserver/${release}/${version}/${bit}/kernel-${kernel_version}.rpm
    yum remove -y kernel-headers
    yum install -y http://${github}/lotserver/${release}/${version}/${bit}/kernel-headers-${kernel_version}.rpm
    yum install -y http://${github}/lotserver/${release}/${version}/${bit}/kernel-devel-${kernel_version}.rpm
  fi

  if [[ "${release}" == "debian" || "${release}" == "ubuntu" ]]; then
    deb_issue="$(cat /etc/issue)"
    deb_relese="$(echo $deb_issue | grep -io 'Ubuntu\|Debian' | sed -r 's/(.*)/\L\1/')"
    os_ver="$(dpkg --print-architecture)"
    [ -n "$os_ver" ] || exit 1
    if [ "$deb_relese" == 'ubuntu' ]; then
      deb_ver="$(echo $deb_issue | grep -o '[0-9]*\.[0-9]*' | head -n1)"
      if [ "$deb_ver" == "14.04" ]; then
        kernel_version="3.16.0-77-generic" && item="3.16.0-77-generic" && ver='trusty'
      elif [ "$deb_ver" == "16.04" ]; then
        kernel_version="4.8.0-36-generic" && item="4.8.0-36-generic" && ver='xenial'
      elif [ "$deb_ver" == "18.04" ]; then
        kernel_version="4.15.0-30-generic" && item="4.15.0-30-generic" && ver='bionic'
      else
        exit 1
      fi
      url='archive.ubuntu.com'
      urls='security.ubuntu.com'
    elif [ "$deb_relese" == 'debian' ]; then
      deb_ver="$(echo $deb_issue | grep -o '[0-9]*' | head -n1)"
      if [ "$deb_ver" == "7" ]; then
        kernel_version="3.2.0-4-${os_ver}" && item="3.2.0-4-${os_ver}" && ver='wheezy' && url='archive.debian.org' && urls='archive.debian.org'
      elif [ "$deb_ver" == "8" ]; then
        kernel_version="3.16.0-4-${os_ver}" && item="3.16.0-4-${os_ver}" && ver='jessie' && url='archive.debian.org' && urls='deb.debian.org'
      elif [ "$deb_ver" == "9" ]; then
        kernel_version="4.9.0-4-${os_ver}" && item="4.9.0-4-${os_ver}" && ver='stretch' && url='deb.debian.org' && urls='deb.debian.org'
      else
        exit 1
      fi
    fi
    [ -n "$item" ] && [ -n "$urls" ] && [ -n "$url" ] && [ -n "$ver" ] || exit 1
    if [ "$deb_relese" == 'ubuntu' ]; then
      echo "deb http://${url}/${deb_relese} ${ver} main restricted universe multiverse" >/etc/apt/sources.list
      echo "deb http://${url}/${deb_relese} ${ver}-updates main restricted universe multiverse" >>/etc/apt/sources.list
      echo "deb http://${url}/${deb_relese} ${ver}-backports main restricted universe multiverse" >>/etc/apt/sources.list
      echo "deb http://${urls}/${deb_relese} ${ver}-security main restricted universe multiverse" >>/etc/apt/sources.list

      apt-get update || apt-get --allow-releaseinfo-change update
      apt-get install --no-install-recommends -y linux-image-${item}
    elif [ "$deb_relese" == 'debian' ]; then
      echo "deb http://${url}/${deb_relese} ${ver} main" >/etc/apt/sources.list
      echo "deb-src http://${url}/${deb_relese} ${ver} main" >>/etc/apt/sources.list
      echo "deb http://${urls}/${deb_relese}-security ${ver}/updates main" >>/etc/apt/sources.list
      echo "deb-src http://${urls}/${deb_relese}-security ${ver}/updates main" >>/etc/apt/sources.list

      if [ "$deb_ver" == "8" ]; then
        dpkg -l | grep -q 'linux-base' || {
          wget --no-check-certificate -qO '/tmp/linux-base_3.5_all.deb' 'http://snapshot.debian.org/archive/debian/20120304T220938Z/pool/main/l/linux-base/linux-base_3.5_all.deb'
          dpkg -i '/tmp/linux-base_3.5_all.deb'
        }
        wget --no-check-certificate -qO '/tmp/linux-image-3.16.0-4-amd64_3.16.43-2+deb8u5_amd64.deb' 'http://snapshot.debian.org/archive/debian/20171008T163152Z/pool/main/l/linux/linux-image-3.16.0-4-amd64_3.16.43-2+deb8u5_amd64.deb'
        dpkg -i '/tmp/linux-image-3.16.0-4-amd64_3.16.43-2+deb8u5_amd64.deb'

        if [ $? -ne 0 ]; then
          exit 1
        fi
      elif [ "$deb_ver" == "9" ]; then
        dpkg -l | grep -q 'linux-base' || {
          wget --no-check-certificate -qO '/tmp/linux-base_4.5_all.deb' 'http://snapshot.debian.org/archive/debian/20160917T042239Z/pool/main/l/linux-base/linux-base_4.5_all.deb'
          dpkg -i '/tmp/linux-base_4.5_all.deb'
        }
        wget --no-check-certificate -qO '/tmp/linux-image-4.9.0-4-amd64_4.9.65-3+deb9u1_amd64.deb' 'http://snapshot.debian.org/archive/debian/20171224T175424Z/pool/main/l/linux/linux-image-4.9.0-4-amd64_4.9.65-3+deb9u1_amd64.deb'
        dpkg -i '/tmp/linux-image-4.9.0-4-amd64_4.9.65-3+deb9u1_amd64.deb'
        ##备选
        #https://sys.if.ci/download/linux-image-4.9.0-4-amd64_4.9.65-3+deb9u1_amd64.deb
        #http://mirror.cs.uchicago.edu/debian-security/pool/updates/main/l/linux/linux-image-4.9.0-4-amd64_4.9.65-3+deb9u1_amd64.deb
        #https://debian.sipwise.com/debian-security/pool/main/l/linux/linux-image-4.9.0-4-amd64_4.9.65-3+deb9u1_amd64.deb
        #http://srv24.dsidata.sk/security.debian.org/pool/updates/main/l/linux/linux-image-4.9.0-4-amd64_4.9.65-3+deb9u1_amd64.deb
        #https://pubmirror.plutex.de/debian-security/pool/updates/main/l/linux/linux-image-4.9.0-4-amd64_4.9.65-3+deb9u1_amd64.deb
        #https://packages.mendix.com/debian/pool/main/l/linux/linux-image-4.9.0-4-amd64_4.9.65-3_amd64.deb
        #http://snapshot.debian.org/archive/debian/20171224T175424Z/pool/main/l/linux/linux-image-4.9.0-4-amd64_4.9.65-3+deb9u1_amd64.deb
        #http://snapshot.debian.org/archive/debian/20171231T180144Z/pool/main/l/linux/linux-image-4.9.0-4-amd64_4.9.65-3_amd64.deb
        if [ $? -ne 0 ]; then
          exit 1
        fi
      else
        exit 1
      fi
    fi
    apt-get autoremove -y
    [ -d '/var/lib/apt/lists' ] && find /var/lib/apt/lists -type f -delete
  fi

  BBR_grub
  echo -e "${Tip} 内核安装完毕，请参考上面的信息检查是否安装成功,默认从排第一的高版本内核启动"
  check_kernel
}

#安装xanmod内核  from xanmod.org
installxanmod() {
  kernel_version="5.5.1-xanmod1"
  bit=$(uname -m)
  if [[ ${bit} != "x86_64" ]]; then
    echo -e "${Error} 不支持x86_64以外的系统 !" && exit 1
  fi
  rm -rf xanmod
  mkdir xanmod && cd xanmod || exit
  if [[ "${release}" == "centos" ]]; then
    if [[ ${version} == "7" ]]; then
      if [[ ${bit} == "x86_64" ]]; then
        echo -e "如果下载地址出错，可能当前正在更新，超过半天还是出错请反馈，大陆自行解决污染问题"
        github_tag=$(curl -s 'https://api.github.com/repos/ylx2016/kernel/releases' | grep 'Centos_Kernel' | grep '_lts_latest_' | grep 'xanmod' | head -n 1 | awk -F '"' '{print $4}' | awk -F '[/]' '{print $8}')
        github_ver=$(curl -s 'https://api.github.com/repos/ylx2016/kernel/releases' | grep ${github_tag} | grep 'rpm' | grep 'headers' | awk -F '"' '{print $4}' | awk -F '[/]' '{print $9}' | awk -F '[-]' '{print $3}')
        echo -e "获取的版本号为:${github_ver}"
        kernel_version=$github_ver
        detele_kernel_head
        headurl=$(curl -s 'https://api.github.com/repos/ylx2016/kernel/releases' | grep ${github_tag} | grep 'rpm' | grep 'headers' | awk -F '"' '{print $4}')
        imgurl=$(curl -s 'https://api.github.com/repos/ylx2016/kernel/releases' | grep ${github_tag} | grep 'rpm' | grep -v 'headers' | grep -v 'devel' | awk -F '"' '{print $4}')
        echo -e "正在检查headers下载连接...."
        checkurl $headurl
        echo -e "正在检查内核下载连接...."
        checkurl $imgurl
        wget -N -O kernel-headers-c7.rpm $headurl
        wget -N -O kernel-c7.rpm $imgurl
        yum install -y kernel-c7.rpm
        yum install -y kernel-headers-c7.rpm
      else
        echo -e "${Error} 不支持x86_64以外的系统 !" && exit 1
      fi
    elif [[ ${version} == "8" ]]; then
      echo -e "如果下载地址出错，可能当前正在更新，超过半天还是出错请反馈，大陆自行解决污染问题"
      github_tag=$(curl -s 'https://api.github.com/repos/ylx2016/kernel/releases' | grep 'Centos_Kernel' | grep '_lts_C8_latest_' | grep 'xanmod' | head -n 1 | awk -F '"' '{print $4}' | awk -F '[/]' '{print $8}')
      github_ver=$(curl -s 'https://api.github.com/repos/ylx2016/kernel/releases' | grep ${github_tag} | grep 'rpm' | grep 'headers' | awk -F '"' '{print $4}' | awk -F '[/]' '{print $9}' | awk -F '[-]' '{print $3}')
      echo -e "获取的版本号为:${github_ver}"
      kernel_version=$github_ver
      detele_kernel_head
      headurl=$(curl -s 'https://api.github.com/repos/ylx2016/kernel/releases' | grep ${github_tag} | grep 'rpm' | grep 'headers' | awk -F '"' '{print $4}')
      imgurl=$(curl -s 'https://api.github.com/repos/ylx2016/kernel/releases' | grep ${github_tag} | grep 'rpm' | grep -v 'headers' | grep -v 'devel' | awk -F '"' '{print $4}')
      echo -e "正在检查headers下载连接...."
      checkurl $headurl
      echo -e "正在检查内核下载连接...."
      checkurl $imgurl
      wget -N -O kernel-headers-c8.rpm $headurl
      wget -N -O kernel-c8.rpm $imgurl
      yum install -y kernel-c8.rpm
      yum install -y kernel-headers-c8.rpm
    fi

  elif [[ "${release}" == "debian" || "${release}" == "ubuntu" ]]; then

    if [[ ${bit} == "x86_64" ]]; then
      # kernel_version="5.11.4-xanmod"
      # xanmod_ver_b=$(rm -rf /tmp/url.tmp && curl -o /tmp/url.tmp 'https://dl.xanmod.org/dl/changelog/?C=N;O=D' && grep folder.gif /tmp/url.tmp | head -n 1 | awk -F "[/]" '{print $5}' | awk -F "[>]" '{print $2}')
      # xanmod_ver_s=$(rm -rf /tmp/url.tmp && curl -o /tmp/url.tmp 'https://dl.xanmod.org/changelog/${xanmod_ver_b}/?C=M;O=D' && grep $xanmod_ver_b /tmp/url.tmp | head -n 3 | awk -F "[-]" '{print $2}')
      sourceforge_xanmod_lts_ver=$(curl -s https://sourceforge.net/projects/xanmod/files/releases/lts/ | grep 'class="folder ">' | head -n 1 | awk -F '"' '{print $2}')
      sourceforge_xanmod_lts_file_img=$(curl -s https://sourceforge.net/projects/xanmod/files/releases/lts/${sourceforge_xanmod_lts_ver}/ | grep 'linux-image' | head -n 1 | awk -F '"' '{print $2}')
      sourceforge_xanmod_lts_file_head=$(curl -s https://sourceforge.net/projects/xanmod/files/releases/lts/${sourceforge_xanmod_lts_ver}/ | grep 'linux-headers' | head -n 1 | awk -F '"' '{print $2}')
      # sourceforge_xanmod_stable_ver=$(curl -s https://sourceforge.net/projects/xanmod/files/releases/stable/ | grep 'class="folder ">' | head -n 1 | awk -F '"' '{print $2}')
      # sourceforge_xanmod_stable_file_img=$(curl -s https://sourceforge.net/projects/xanmod/files/releases/stable/${sourceforge_xanmod_stable_ver}/ | grep 'linux-image' | head -n 1 | awk -F '"' '{print $2}')
      # sourceforge_xanmod_stable_file_head=$(curl -s https://sourceforge.net/projects/xanmod/files/releases/stable/${sourceforge_xanmod_stable_ver}/ | grep 'linux-headers' | head -n 1 | awk -F '"' '{print $2}')
      # sourceforge_xanmod_cacule_ver=$(curl -s https://sourceforge.net/projects/xanmod/files/releases/cacule/ | grep 'class="folder ">' | head -n 1 | awk -F '"' '{print $2}')
      # sourceforge_xanmod_cacule_file_img=$(curl -s https://sourceforge.net/projects/xanmod/files/releases/cacule/${sourceforge_xanmod_cacule_ver}/ | grep 'linux-image' | head -n 1 | awk -F '"' '{print $2}')
      # sourceforge_xanmod_cacule_file_head=$(curl -s https://sourceforge.net/projects/xanmod/files/releases/cacule/${sourceforge_xanmod_cacule_ver}/ | grep 'linux-headers' | head -n 1 | awk -F '"' '{print $2}')
      echo -e "获取的xanmod lts版本号为:${sourceforge_xanmod_lts_ver}"
      # kernel_version=$sourceforge_xanmod_stable_ver
      # detele_kernel_head
      # headurl=https://sourceforge.net/projects/xanmod/files/releases/stable/${sourceforge_xanmod_stable_ver}/${sourceforge_xanmod_stable_file_head}/download
      # imgurl=https://sourceforge.net/projects/xanmod/files/releases/stable/${sourceforge_xanmod_stable_ver}/${sourceforge_xanmod_stable_file_img}/download
      kernel_version=$sourceforge_xanmod_lts_ver
      detele_kernel_head
      #headurl=https://sourceforge.net/projects/xanmod/files/releases/cacule/${sourceforge_xanmod_cacule_ver}/${sourceforge_xanmod_cacule_file_head}/download
      #imgurl=https://sourceforge.net/projects/xanmod/files/releases/cacule/${sourceforge_xanmod_cacule_ver}/${sourceforge_xanmod_cacule_file_img}/download
      headurl=https://sourceforge.net/projects/xanmod/files/releases/lts/${sourceforge_xanmod_lts_ver}/${sourceforge_xanmod_lts_file_head}/download
      imgurl=https://sourceforge.net/projects/xanmod/files/releases/lts/${sourceforge_xanmod_lts_ver}/${sourceforge_xanmod_lts_file_img}/download
      echo -e "正在检查headers下载连接...."
      checkurl $headurl
      echo -e "正在检查内核下载连接...."
      checkurl $imgurl
      wget -N -O linux-headers-d10.deb $headurl
      wget -N -O linux-image-d10.deb $imgurl
      dpkg -i linux-image-d10.deb
      dpkg -i linux-headers-d10.deb
    else
      echo -e "${Error} 不支持x86_64以外的系统 !" && exit 1
    fi
  fi

  cd .. && rm -rf xanmod
  BBR_grub
  echo -e "${Tip} 内核安装完毕，请参考上面的信息检查是否安装成功,默认从排第一的高版本内核启动"
  check_kernel
}

#安装bbr2内核 集成到xanmod内核了
#安装bbrplus 新内核
#2021.3.15 开始由https://github.com/UJX6N/bbrplus-5.10 替换bbrplusnew
#2021.4.12 地址更新为https://github.com/ylx2016/kernel/releases
#2021.9.2 再次改为https://github.com/UJX6N/bbrplus-5.10

installbbrplusnew() {
  github_ver_plus=$(curl -s https://api.github.com/repos/UJX6N/bbrplus-5.10/releases | grep /bbrplus-5.10/releases/tag/ | head -1 | awk -F "[/]" '{print $8}' | awk -F "[\"]" '{print $1}')
  github_ver_plus_num=$(curl -s https://api.github.com/repos/UJX6N/bbrplus-5.10/releases | grep /bbrplus-5.10/releases/tag/ | head -1 | awk -F "[/]" '{print $8}' | awk -F "[\"]" '{print $1}' | awk -F "[-]" '{print $1}')
  echo -e "获取的UJX6N的bbrplus-5.10版本号为:${github_ver_plus}"
  echo -e "如果下载地址出错，可能当前正在更新，超过半天还是出错请反馈，大陆自行解决污染问题"
  echo -e "安装失败这边反馈，内核问题给UJX6N反馈"
  # kernel_version=$github_ver_plus

  bit=$(uname -m)
  #if [[ ${bit} != "x86_64" ]]; then
  #  echo -e "${Error} 不支持x86_64以外的系统 !" && exit 1
  #fi
  rm -rf bbrplusnew
  mkdir bbrplusnew && cd bbrplusnew || exit
  if [[ "${release}" == "centos" ]]; then
    if [[ ${version} == "7" ]]; then
      if [[ ${bit} == "x86_64" ]]; then
        #github_tag=$(curl -s 'https://api.github.com/repos/ylx2016/kernel/releases' | grep 'Centos_Kernel' | grep '_latest_bbrplus_' | head -n 1 | awk -F '"' '{print $4}' | awk -F '[/]' '{print $8}')
        #github_ver=$(curl -s 'https://api.github.com/repos/ylx2016/kernel/releases' | grep ${github_tag} | grep 'rpm' | grep 'headers' | awk -F '"' '{print $4}' | awk -F '[/]' '{print $9}' | awk -F '[-]' '{print $3}' | awk -F '[_]' '{print $1}')
        #echo -e "获取的版本号为:${github_ver}"
        kernel_version=${github_ver_plus_num}_bbrplus
        detele_kernel_head
        headurl=$(curl -s 'https://api.github.com/repos/UJX6N/bbrplus-5.10/releases' | grep ${github_ver_plus} | grep 'rpm' | grep 'headers' | grep 'el7' | awk -F '"' '{print $4}')
        imgurl=$(curl -s 'https://api.github.com/repos/UJX6N/bbrplus-5.10/releases' | grep ${github_ver_plus} | grep 'rpm' | grep -v 'devel' | grep -v 'headers' | grep -v 'Source' | grep 'el7' | awk -F '"' '{print $4}')
        echo -e "正在检查headers下载连接...."
        checkurl $headurl
        echo -e "正在检查内核下载连接...."
        checkurl $imgurl
        wget -N -O kernel-c7.rpm $headurl
        wget -N -O kernel-headers-c7.rpm $imgurl
        yum install -y kernel-c7.rpm
        yum install -y kernel-headers-c7.rpm
      else
        echo -e "${Error} 不支持x86_64以外的系统 !" && exit 1
      fi
    fi
    if [[ ${version} == "8" ]]; then
      if [[ ${bit} == "x86_64" ]]; then
        #github_tag=$(curl -s 'https://api.github.com/repos/ylx2016/kernel/releases' | grep 'Centos_Kernel' | grep '_latest_bbrplus_' | head -n 1 | awk -F '"' '{print $4}' | awk -F '[/]' '{print $8}')
        #github_ver=$(curl -s 'https://api.github.com/repos/ylx2016/kernel/releases' | grep ${github_tag} | grep 'rpm' | grep 'headers' | awk -F '"' '{print $4}' | awk -F '[/]' '{print $9}' | awk -F '[-]' '{print $3}' | awk -F '[_]' '{print $1}')
        #echo -e "获取的版本号为:${github_ver}"
        kernel_version=${github_ver_plus_num}_bbrplus
        detele_kernel_head
        headurl=$(curl -s 'https://api.github.com/repos/UJX6N/bbrplus-5.10/releases' | grep ${github_ver_plus} | grep 'rpm' | grep 'headers' | grep 'el8' | awk -F '"' '{print $4}')
        imgurl=$(curl -s 'https://api.github.com/repos/UJX6N/bbrplus-5.10/releases' | grep ${github_ver_plus} | grep 'rpm' | grep -v 'devel' | grep -v 'headers' | grep -v 'Source' | grep 'el8' | awk -F '"' '{print $4}')
        echo -e "正在检查headers下载连接...."
        checkurl $headurl
        echo -e "正在检查内核下载连接...."
        checkurl $imgurl
        wget -N -O kernel-c8.rpm $headurl
        wget -N -O kernel-headers-c8.rpm $imgurl
        yum install -y kernel-c8.rpm
        yum install -y kernel-headers-c8.rpm
      else
        echo -e "${Error} 不支持x86_64以外的系统 !" && exit 1
      fi
    fi
  elif [[ "${release}" == "debian" || "${release}" == "ubuntu" ]]; then
    if [[ ${bit} == "x86_64" ]]; then
      #github_tag=$(curl -s 'https://api.github.com/repos/ylx2016/kernel/releases' | grep 'Ubuntu_Kernel' | grep '_latest_bbrplus_' | head -n 1 | awk -F '"' '{print $4}' | awk -F '[/]' '{print $8}')
      #github_ver=$(curl -s 'http s://api.github.com/repos/ylx2016/kernel/releases' | grep ${github_tag} | grep 'deb' | grep 'headers' | awk -F '"' '{print $4}' | awk -F '[/]' '{print $9}' | awk -F '[-]' '{print $3}' | awk -F '[_]' '{print $1}')
      #echo -e "获取的版本号为:${github_ver}"
      kernel_version=${github_ver_plus_num}-bbrplus
      detele_kernel_head
      headurl=$(curl -s 'https://api.github.com/repos/UJX6N/bbrplus-5.10/releases' | grep ${github_ver_plus} | grep 'https' | grep 'amd64.deb' | grep 'headers' | awk -F '"' '{print $4}')
      imgurl=$(curl -s 'https://api.github.com/repos/UJX6N/bbrplus-5.10/releases' | grep ${github_ver_plus} | grep 'https' | grep 'amd64.deb' | grep 'image' | awk -F '"' '{print $4}')
      echo -e "正在检查headers下载连接...."
      checkurl $headurl
      echo -e "正在检查内核下载连接...."
      checkurl $imgurl
      wget -N -O linux-headers-d10.deb $headurl
      wget -N -O linux-image-d10.deb $imgurl
      dpkg -i linux-image-d10.deb
      dpkg -i linux-headers-d10.deb
    elif [[ ${bit} == "aarch64" ]]; then
      #github_tag=$(curl -s 'https://api.github.com/repos/ylx2016/kernel/releases' | grep 'Ubuntu_Kernel' | grep '_latest_bbrplus_' | head -n 1 | awk -F '"' '{print $4}' | awk -F '[/]' '{print $8}')
      #github_ver=$(curl -s 'http s://api.github.com/repos/ylx2016/kernel/releases' | grep ${github_tag} | grep 'deb' | grep 'headers' | awk -F '"' '{print $4}' | awk -F '[/]' '{print $9}' | awk -F '[-]' '{print $3}' | awk -F '[_]' '{print $1}')
      #echo -e "获取的版本号为:${github_ver}"
      kernel_version=${github_ver_plus_num}-bbrplus
      detele_kernel_head
      headurl=$(curl -s 'https://api.github.com/repos/UJX6N/bbrplus-5.10/releases' | grep ${github_ver_plus} | grep 'https' | grep 'arm64.deb' | grep 'headers' | awk -F '"' '{print $4}')
      imgurl=$(curl -s 'https://api.github.com/repos/UJX6N/bbrplus-5.10/releases' | grep ${github_ver_plus} | grep 'https' | grep 'arm64.deb' | grep 'image' | awk -F '"' '{print $4}')
      echo -e "正在检查headers下载连接...."
      checkurl $headurl
      echo -e "正在检查内核下载连接...."
      checkurl $imgurl
      wget -N -O linux-headers-d10.deb $headurl
      wget -N -O linux-image-d10.deb $imgurl
      dpkg -i linux-image-d10.deb
      dpkg -i linux-headers-d10.deb
    else
      echo -e "${Error} 不支持x86_64及arm64/aarch64以外的系统 !" && exit 1
    fi
  fi

  cd .. && rm -rf bbrplusnew
  BBR_grub
  echo -e "${Tip} 内核安装完毕，请参考上面的信息检查是否安装成功,默认从排第一的高版本内核启动"
  check_kernel

}

#启用BBR+fq
startbbrfq() {
  remove_bbr_lotserver
  echo "net.core.default_qdisc=fq" >>/etc/sysctl.d/99-sysctl.conf
  echo "net.ipv4.tcp_congestion_control=bbr" >>/etc/sysctl.d/99-sysctl.conf
  sysctl --system
  echo -e "${Info}BBR+FQ修改成功，重启生效！"
}

#启用BBR+fq_pie
startbbrfqpie() {
  remove_bbr_lotserver
  echo "net.core.default_qdisc=fq_pie" >>/etc/sysctl.d/99-sysctl.conf
  echo "net.ipv4.tcp_congestion_control=bbr" >>/etc/sysctl.d/99-sysctl.conf
  sysctl --system
  echo -e "${Info}BBR+FQ_PIE修改成功，重启生效！"
}

#启用BBR+cake
startbbrcake() {
  remove_bbr_lotserver
  echo "net.core.default_qdisc=cake" >>/etc/sysctl.d/99-sysctl.conf
  echo "net.ipv4.tcp_congestion_control=bbr" >>/etc/sysctl.d/99-sysctl.conf
  sysctl --system
  echo -e "${Info}BBR+cake修改成功，重启生效！"
}

#启用BBRplus
startbbrplus() {
  remove_bbr_lotserver
  echo "net.core.default_qdisc=fq" >>/etc/sysctl.d/99-sysctl.conf
  echo "net.ipv4.tcp_congestion_control=bbrplus" >>/etc/sysctl.d/99-sysctl.conf
  sysctl --system
  echo -e "${Info}BBRplus修改成功，自动重启后生效！"
  sleep 3
  reboot
}

#启用Lotserver
startlotserver() {
  remove_bbr_lotserver
  if [[ "${release}" == "centos" ]]; then
    yum install ethtool -y
  else
    apt-get update || apt-get --allow-releaseinfo-change update
    apt-get install ethtool -y
  fi
  #bash <(wget -qO- https://git.io/lotServerInstall.sh) install
  echo | bash <(wget --no-check-certificate -qO- https://github.com/xidcn/LotServer_Vicer/raw/master/Install.sh) install
  sed -i '/advinacc/d' /appex/etc/config
  sed -i '/maxmode/d' /appex/etc/config
  echo -e "advinacc=\"1\"
maxmode=\"1\"" >>/appex/etc/config
  /appex/bin/lotServer.sh restart
  start_menu
}

#启用BBR2+FQ
startbbr2fq() {
  remove_bbr_lotserver
  echo "net.core.default_qdisc=fq" >>/etc/sysctl.d/99-sysctl.conf
  echo "net.ipv4.tcp_congestion_control=bbr2" >>/etc/sysctl.d/99-sysctl.conf
  sysctl --system
  echo -e "${Info}BBR2修改成功，重启生效！"
}

#启用BBR2+FQ_PIE
startbbr2fqpie() {
  remove_bbr_lotserver
  echo "net.core.default_qdisc=fq_pie" >>/etc/sysctl.d/99-sysctl.conf
  echo "net.ipv4.tcp_congestion_control=bbr2" >>/etc/sysctl.d/99-sysctl.conf
  sysctl --system
  echo -e "${Info}BBR2修改成功，重启生效！"
}

#启用BBR2+CAKE
startbbr2cake() {
  remove_bbr_lotserver
  echo "net.core.default_qdisc=cake" >>/etc/sysctl.d/99-sysctl.conf
  echo "net.ipv4.tcp_congestion_control=bbr2" >>/etc/sysctl.d/99-sysctl.conf
  sysctl --system
  echo -e "${Info}BBR2修改成功，重启生效！"
}

#开启ecn
startecn() {
  sed -i '/net.ipv4.tcp_ecn/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv4.tcp_ecn/d' /etc/sysctl.conf

  echo "net.ipv4.tcp_ecn=1" >>/etc/sysctl.d/99-sysctl.conf
  sysctl --system
  echo -e "${Info}开启ecn结束！"
}

dnsnf() {
  yum -y install dnsmasq
  read -p " 输入解锁鸡IP：" nfip
  echo 'server=8.8.8.8' >> /etc/dnsmasq.d/custom.netflix.conf
  echo "server=/fast.com/${nfip}" >> /etc/dnsmasq.d/custom.netflix.conf
  echo "server=/netflix.ca/${nfip}" >> /etc/dnsmasq.d/custom.netflix.conf
  echo "server=/netflix.com/${nfip}" >> /etc/dnsmasq.d/custom.netflix.conf
  echo "server=/netflix.net/${nfip}" >> /etc/dnsmasq.d/custom.netflix.conf
  echo "server=/netflixinvestor.com/${nfip}" >> /etc/dnsmasq.d/custom.netflix.conf
  echo "server=/netflixtechblog.com/${nfip}" >> /etc/dnsmasq.d/custom.netflix.conf
  echo "server=/nflxext.com/${nfip}" >> /etc/dnsmasq.d/custom.netflix.conf
  echo "server=/nflximg.com/${nfip}" >> /etc/dnsmasq.d/custom.netflix.conf
  echo "server=/nflximg.net/${nfip}" >> /etc/dnsmasq.d/custom.netflix.conf
  echo "server=/nflxsearch.net/${nfip}" >> /etc/dnsmasq.d/custom.netflix.conf
  echo "server=/nflxso.net/${nfip}" >> /etc/dnsmasq.d/custom.netflix.conf
  echo "server=/nflxvideo.net/${nfip}" >> /etc/dnsmasq.d/custom.netflix.conf
  sed -i 'END' /etc/dnsmasq.d/custom.netflix.conf
  sleep 3
  sed -i '1 i nameserver 127.0.0.1' /etc/resolv.conf
  systemctl restart dnsmasq
  sleep 3
  nslookup netflix.com
}

#DNS解锁主
ndnsnf() {
  wget --no-check-certificate -O dnsmasq_sniproxy.sh https://bash.ocloud.live/nBash/dnsmasq_sniproxy.sh && bash dnsmasq_sniproxy.sh -f
}

#docker管理
dockerhome() {
echo -e "\e[36m 选择你想操作的一个项目（如果需要删除或重建请先暂停 \e[0m"
select name in "启动" "重启" "停止" "重建" "删除"
do
    case $name in
        "启动")
            echo "正在启动这台服务器上的docker"
            docker start v2ray
            break
            ;;
        "重启")
            echo "正在重启这台服务器上的docker"
            docker restart v2ray
            break
            ;;
        "停止")
            echo "正在停止这台服务器上的docker"
            docker stop v2ray
            break
            ;;
        "删除")
            echo "正在删除这台服务器上的Docker"
            docker stop v2ray && docker rm v2ray
            break
            ;;
        *)
            echo "输入错误。"
    esac
done
}
#安装docker
installdocker() {
  curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun
  sleep 3 
  systemctl start docker
  echo -e "${Info}docker安装并启动"
}
dockerxray() {
  echo -e "\e[36m 选择你想操作的一个项目（如果需要删除或重建请先暂停 \e[0m"
select name in "V2ray" "SS" "SSR" "Trojan"
do
    case $name in
        "V2ray")
            echo "正在安装V2ray"
            docker run -d --name v2ray -p 888:888 -e node_id=0 -e node_type=V2ray -e sspanel_url=http://apitoken.91nop.com -e key=ceshi -e CF_Key=0e277857d2cbacda9477fbe562a10386f768c -e CF_Email=994971291@qq.com  -l CATID=DA5C965C-6169-46B0-8466-4288AC90CD01 --restart=always --memory="300m" --memory-swap="1g" --log-opt max-size=10m --log-opt max-file=5 servercat/xrayr:v0.8.2.2   echo -e "正在启动"
            docker ps
            echo -e "${Info}xray安装成功"
            break
            ;;
        "SS")
            echo "正在安装Shadowsocks"
            docker run -d --name v2ray -p 443:443 -e node_id=0 -e node_type=Shadowsocks -e sspanel_url=http://apitoken.91nop.com -e key=ceshi -e CF_Key=0e277857d2cbacda9477fbe562a10386f768c -e CF_Email=994971291@qq.com  -l CATID=DA5C965C-6169-46B0-8466-4288AC90CD01 --restart=always --memory="300m" --memory-swap="1g" --log-opt max-size=10m --log-opt max-file=5 servercat/xrayr:v0.8.2.2   echo -e "正在启动"
            docker ps
            echo -e "${Info}xray安装成功"
            break
            ;;
        "Shadowsocks-Plugin")
            echo "正在安装Shadowsocks-Plugin"
            docker run -d --name v2ray -p 443:443 -e node_id=0 -e node_type=Shadowsocks-Plugin -e sspanel_url=http://apitoken.91nop.com -e key=ceshi -e CF_Key=0e277857d2cbacda9477fbe562a10386f768c -e CF_Email=994971291@qq.com  -l CATID=DA5C965C-6169-46B0-8466-4288AC90CD01 --restart=always --memory="300m" --memory-swap="1g" --log-opt max-size=10m --log-opt max-file=5 servercat/xrayr:v0.8.2.2   echo -e "正在启动"
            docker ps
            echo -e "${Info}xray安装成功"
            break
            ;;
        "Trojan")
            echo "正在安装Trojan"
            docker run -d --name v2ray -p 443:443 -e node_id=0 -e node_type=Trojan -e sspanel_url=http://apitoken.91nop.com -e key=ceshi -e CF_Key=0e277857d2cbacda9477fbe562a10386f768c -e CF_Email=994971291@qq.com  -l CATID=DA5C965C-6169-46B0-8466-4288AC90CD01 --restart=always --memory="300m" --memory-swap="1g" --log-opt max-size=10m --log-opt max-file=5 servercat/xrayr:v0.8.2.2   echo -e "正在启动"
            docker ps
            echo -e "${Info}xray安装成功"
            break
            ;;
        "V2ray")
            echo "正在安装V2ray"
            read -p " 请输入端口 :" port
            read -p " 请输入docker名,默认（v2ray） :" v2ray
            docker  run -d --name ${v2ray} -p ${port}:${port} -e node_id=0 -e node_type=V2ray -e sspanel_url=http://apitoken.91nop.com -e key=ceshi -e CF_Key=0e277857d2cbacda9477fbe562a10386f768c -e CF_Email=994971291@qq.com  -l CATID=DA5C965C-6169-46B0-8466-4288AC90CD01 --restart=always --memory="300m" --memory-swap="1g" --log-opt max-size=10m --log-opt max-file=5 servercat/xrayr:v0.8.2.2   echo -e "正在启动"
            echo -e "${Info}xray安装成功"
            docker ps
            break
            ;;
        *)
            echo "输入错误。"
    esac
  done
}

#bzd
bzd() {
  suijishu=`cat /dev/urandom | tr -dc '0-9a-z' | head -c 15`
  git clone https://github.com/HIM01/docker_XrayR /etc/$suijishu && cd /etc/$suijishu
  sleep 5s
  file="./config.yml"
  link="http://127.0.0.1:667"
  docker_compose_file="./docker-compose.yml"
#输入信息
  docker_name="V2ray_XrayR"
  apihost="http://api.91nop.cc/"
  apikey="ceshi"
  read -p "请输入节点ID：" nodeid
#写入信息
  sed -i "s|$link|$apihost|" $file
  sed -i "s|123|$apikey|" $file
  sed -i "s|41|$nodeid|" $file
  sed -i "s|HIM|$docker_name|" $docker_compose_file
  echo "配置完成"
  echo "正在启动XrayR Docker Compose" && docker-compose up -d
}
#docker-compos
docker-compos() {
curl -fsSL https://get.docker.com | bash -s docker
curl -L "https://github.com/docker/compose/releases/download/1.26.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
}
#流媒体
lmt() {
wget https://raw.githubusercontent.com/iamsaltedfish/check-stream-media/main/csm.sh
bash csm.sh
}
#DNS
#ssrdoubi
ssrdoubi() {
sh_ver="2.0.38"
filepath=$(cd "$(dirname "$0")"; pwd)
file=$(echo -e "${filepath}"|awk -F "$0" '{print $1}')
ssr_folder="/usr/local/shadowsocksr"
ssr_ss_file="${ssr_folder}/shadowsocks"
config_file="${ssr_folder}/config.json"
config_folder="/etc/shadowsocksr"
config_user_file="${config_folder}/user-config.json"
ssr_log_file="${ssr_ss_file}/ssserver.log"
Libsodiumr_file="/usr/local/lib/libsodium.so"
Libsodiumr_ver_backup="1.0.13"
Server_Speeder_file="/serverspeeder/bin/serverSpeeder.sh"
LotServer_file="/appex/bin/serverSpeeder.sh"
BBR_file="${file}/bbr.sh"
jq_file="${ssr_folder}/jq"
Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[信息]${Font_color_suffix}"
Error="${Red_font_prefix}[错误]${Font_color_suffix}"
Tip="${Green_font_prefix}[注意]${Font_color_suffix}"
Separator_1="——————————————————————————————"

check_sys(){
	if [[ -f /etc/redhat-release ]]; then
		release="centos"
	elif cat /etc/issue | grep -q -E -i "debian"; then
		release="debian"
	elif cat /etc/issue | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
	elif cat /proc/version | grep -q -E -i "debian"; then
		release="debian"
	elif cat /proc/version | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
    fi
	bit=`uname -m`
}
check_pid(){
	PID=`ps -ef |grep -v grep | grep server.py |awk '{print $2}'`
}
SSR_installation_status(){
	[[ ! -e ${config_user_file} ]] && echo -e "${Error} 没有发现 ShadowsocksR 配置文件，请检查 !" && exit 1
	[[ ! -e ${ssr_folder} ]] && echo -e "${Error} 没有发现 ShadowsocksR 文件夹，请检查 !" && exit 1
}
Server_Speeder_installation_status(){
	[[ ! -e ${Server_Speeder_file} ]] && echo -e "${Error} 没有安装 锐速(Server Speeder)，请检查 !" && exit 1
}
LotServer_installation_status(){
	[[ ! -e ${LotServer_file} ]] && echo -e "${Error} 没有安装 LotServer，请检查 !" && exit 1
}
BBR_installation_status(){
	if [[ ! -e ${BBR_file} ]]; then
		echo -e "${Error} 没有发现 BBR脚本，开始下载..."
		cd "${file}"
		if ! wget -N --no-check-certificate https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/bbr.sh; then
			echo -e "${Error} BBR 脚本下载失败 !" && exit 1
		else
			echo -e "${Info} BBR 脚本下载完成 !"
			chmod +x bbr.sh
		fi
	fi
}
# 设置 防火墙规则
Add_iptables(){
	iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport ${ssr_port} -j ACCEPT
	iptables -I INPUT -m state --state NEW -m udp -p udp --dport ${ssr_port} -j ACCEPT
	ip6tables -I INPUT -m state --state NEW -m tcp -p tcp --dport ${ssr_port} -j ACCEPT
	ip6tables -I INPUT -m state --state NEW -m udp -p udp --dport ${ssr_port} -j ACCEPT
}
Del_iptables(){
	iptables -D INPUT -m state --state NEW -m tcp -p tcp --dport ${port} -j ACCEPT
	iptables -D INPUT -m state --state NEW -m udp -p udp --dport ${port} -j ACCEPT
	ip6tables -D INPUT -m state --state NEW -m tcp -p tcp --dport ${port} -j ACCEPT
	ip6tables -D INPUT -m state --state NEW -m udp -p udp --dport ${port} -j ACCEPT
}
Save_iptables(){
	if [[ ${release} == "centos" ]]; then
		service iptables save
		service ip6tables save
	else
		iptables-save > /etc/iptables.up.rules
		ip6tables-save > /etc/ip6tables.up.rules
	fi
}
Set_iptables(){
	if [[ ${release} == "centos" ]]; then
		service iptables save
		service ip6tables save
		chkconfig --level 2345 iptables on
		chkconfig --level 2345 ip6tables on
	else
		iptables-save > /etc/iptables.up.rules
		ip6tables-save > /etc/ip6tables.up.rules
		echo -e '#!/bin/bash\n/sbin/iptables-restore < /etc/iptables.up.rules\n/sbin/ip6tables-restore < /etc/ip6tables.up.rules' > /etc/network/if-pre-up.d/iptables
		chmod +x /etc/network/if-pre-up.d/iptables
	fi
}
# 读取 配置信息
Get_IP(){
	ip=$(wget -qO- -t1 -T2 ipinfo.io/ip)
	if [[ -z "${ip}" ]]; then
		ip=$(wget -qO- -t1 -T2 api.ip.sb/ip)
		if [[ -z "${ip}" ]]; then
			ip=$(wget -qO- -t1 -T2 members.3322.org/dyndns/getip)
			if [[ -z "${ip}" ]]; then
				ip="VPS_IP"
			fi
		fi
	fi
}
Get_User(){
	[[ ! -e ${jq_file} ]] && echo -e "${Error} JQ解析器 不存在，请检查 !" && exit 1
	port=`${jq_file} '.server_port' ${config_user_file}`
	password=`${jq_file} '.password' ${config_user_file} | sed 's/^.//;s/.$//'`
	method=`${jq_file} '.method' ${config_user_file} | sed 's/^.//;s/.$//'`
	protocol=`${jq_file} '.protocol' ${config_user_file} | sed 's/^.//;s/.$//'`
	obfs=`${jq_file} '.obfs' ${config_user_file} | sed 's/^.//;s/.$//'`
	protocol_param=`${jq_file} '.protocol_param' ${config_user_file} | sed 's/^.//;s/.$//'`
	speed_limit_per_con=`${jq_file} '.speed_limit_per_con' ${config_user_file}`
	speed_limit_per_user=`${jq_file} '.speed_limit_per_user' ${config_user_file}`
	connect_verbose_info=`${jq_file} '.connect_verbose_info' ${config_user_file}`
}
urlsafe_base64(){
	date=$(echo -n "$1"|base64|sed ':a;N;s/\n/ /g;ta'|sed 's/ //g;s/=//g;s/+/-/g;s/\//_/g')
	echo -e "${date}"
}
ss_link_qr(){
	SSbase64=$(urlsafe_base64 "${method}:${password}@${ip}:${port}")
	SSurl="ss://${SSbase64}"
	SSQRcode="http://doub.pw/qr/qr.php?text=${SSurl}"
	ss_link=" SS    链接 : ${Green_font_prefix}${SSurl}${Font_color_suffix} \n SS  二维码 : ${Green_font_prefix}${SSQRcode}${Font_color_suffix}"
}
ssr_link_qr(){
	SSRprotocol=$(echo ${protocol} | sed 's/_compatible//g')
	SSRobfs=$(echo ${obfs} | sed 's/_compatible//g')
	SSRPWDbase64=$(urlsafe_base64 "${password}")
	SSRbase64=$(urlsafe_base64 "${ip}:${port}:${SSRprotocol}:${method}:${SSRobfs}:${SSRPWDbase64}")
	SSRurl="ssr://${SSRbase64}"
	SSRQRcode="http://doub.pw/qr/qr.php?text=${SSRurl}"
	ssr_link=" SSR   链接 : ${Red_font_prefix}${SSRurl}${Font_color_suffix} \n SSR 二维码 : ${Red_font_prefix}${SSRQRcode}${Font_color_suffix} \n "
}
ss_ssr_determine(){
	protocol_suffix=`echo ${protocol} | awk -F "_" '{print $NF}'`
	obfs_suffix=`echo ${obfs} | awk -F "_" '{print $NF}'`
	if [[ ${protocol} = "origin" ]]; then
		if [[ ${obfs} = "plain" ]]; then
			ss_link_qr
			ssr_link=""
		else
			if [[ ${obfs_suffix} != "compatible" ]]; then
				ss_link=""
			else
				ss_link_qr
			fi
		fi
	else
		if [[ ${protocol_suffix} != "compatible" ]]; then
			ss_link=""
		else
			if [[ ${obfs_suffix} != "compatible" ]]; then
				if [[ ${obfs_suffix} = "plain" ]]; then
					ss_link_qr
				else
					ss_link=""
				fi
			else
				ss_link_qr
			fi
		fi
	fi
	ssr_link_qr
}
# 显示 配置信息
View_User(){
	SSR_installation_status
	Get_IP
	Get_User
	now_mode=$(cat "${config_user_file}"|grep '"port_password"')
	[[ -z ${protocol_param} ]] && protocol_param="0(无限)"
	if [[ -z "${now_mode}" ]]; then
		ss_ssr_determine
		clear && echo "===================================================" && echo
		echo -e " ShadowsocksR账号 配置信息：" && echo
		echo -e " I  P\t    : ${Green_font_prefix}${ip}${Font_color_suffix}"
		echo -e " 端口\t    : ${Green_font_prefix}${port}${Font_color_suffix}"
		echo -e " 密码\t    : ${Green_font_prefix}${password}${Font_color_suffix}"
		echo -e " 加密\t    : ${Green_font_prefix}${method}${Font_color_suffix}"
		echo -e " 协议\t    : ${Red_font_prefix}${protocol}${Font_color_suffix}"
		echo -e " 混淆\t    : ${Red_font_prefix}${obfs}${Font_color_suffix}"
		echo -e " 设备数限制 : ${Green_font_prefix}${protocol_param}${Font_color_suffix}"
		echo -e " 单线程限速 : ${Green_font_prefix}${speed_limit_per_con} KB/S${Font_color_suffix}"
		echo -e " 端口总限速 : ${Green_font_prefix}${speed_limit_per_user} KB/S${Font_color_suffix}"
		echo -e "${ss_link}"
		echo -e "${ssr_link}"
		echo -e " ${Green_font_prefix} 提示: ${Font_color_suffix}
 在浏览器中，打开二维码链接，就可以看到二维码图片。
 协议和混淆后面的[ _compatible ]，指的是 兼容原版协议/混淆。"
		echo && echo "==================================================="
	else
		user_total=`${jq_file} '.port_password' ${config_user_file} | sed '$d' | sed "1d" | wc -l`
		[[ ${user_total} = "0" ]] && echo -e "${Error} 没有发现 多端口用户，请检查 !" && exit 1
		clear && echo "===================================================" && echo
		echo -e " ShadowsocksR账号 配置信息：" && echo
		echo -e " I  P\t    : ${Green_font_prefix}${ip}${Font_color_suffix}"
		echo -e " 加密\t    : ${Green_font_prefix}${method}${Font_color_suffix}"
		echo -e " 协议\t    : ${Red_font_prefix}${protocol}${Font_color_suffix}"
		echo -e " 混淆\t    : ${Red_font_prefix}${obfs}${Font_color_suffix}"
		echo -e " 设备数限制 : ${Green_font_prefix}${protocol_param}${Font_color_suffix}"
		echo -e " 单线程限速 : ${Green_font_prefix}${speed_limit_per_con} KB/S${Font_color_suffix}"
		echo -e " 端口总限速 : ${Green_font_prefix}${speed_limit_per_user} KB/S${Font_color_suffix}" && echo
		for((integer = ${user_total}; integer >= 1; integer--))
		do
			port=`${jq_file} '.port_password' ${config_user_file} | sed '$d' | sed "1d" | awk -F ":" '{print $1}' | sed -n "${integer}p" | sed -r 's/.*\"(.+)\".*/\1/'`
			password=`${jq_file} '.port_password' ${config_user_file} | sed '$d' | sed "1d" | awk -F ":" '{print $2}' | sed -n "${integer}p" | sed -r 's/.*\"(.+)\".*/\1/'`
			ss_ssr_determine
			echo -e ${Separator_1}
			echo -e " 端口\t    : ${Green_font_prefix}${port}${Font_color_suffix}"
			echo -e " 密码\t    : ${Green_font_prefix}${password}${Font_color_suffix}"
			echo -e "${ss_link}"
			echo -e "${ssr_link}"
		done
		echo -e " ${Green_font_prefix} 提示: ${Font_color_suffix}
 在浏览器中，打开二维码链接，就可以看到二维码图片。
 协议和混淆后面的[ _compatible ]，指的是 兼容原版协议/混淆。"
		echo && echo "==================================================="
	fi
}
# 设置 配置信息
Set_config_port(){
	while true
	do
	echo -e "请输入要设置的ShadowsocksR账号 端口"
	read -e -p "(默认: 2333):" ssr_port
	[[ -z "$ssr_port" ]] && ssr_port="2333"
	echo $((${ssr_port}+0)) &>/dev/null
	if [[ $? == 0 ]]; then
		if [[ ${ssr_port} -ge 1 ]] && [[ ${ssr_port} -le 65535 ]]; then
			echo && echo ${Separator_1} && echo -e "	端口 : ${Green_font_prefix}${ssr_port}${Font_color_suffix}" && echo ${Separator_1} && echo
			break
		else
			echo -e "${Error} 请输入正确的数字(1-65535)"
		fi
	else
		echo -e "${Error} 请输入正确的数字(1-65535)"
	fi
	done
}
Set_config_password(){
	echo "请输入要设置的ShadowsocksR账号 密码"
	read -e -p "(默认: doub.io):" ssr_password
	[[ -z "${ssr_password}" ]] && ssr_password="doub.io"
	echo && echo ${Separator_1} && echo -e "	密码 : ${Green_font_prefix}${ssr_password}${Font_color_suffix}" && echo ${Separator_1} && echo
}
Set_config_method(){
	echo -e "请选择要设置的ShadowsocksR账号 加密方式
	
 ${Green_font_prefix} 1.${Font_color_suffix} none
 ${Tip} 如果使用 auth_chain_a 协议，请加密方式选择 none，混淆随意(建议 plain)
 
 ${Green_font_prefix} 2.${Font_color_suffix} rc4
 ${Green_font_prefix} 3.${Font_color_suffix} rc4-md5
 ${Green_font_prefix} 4.${Font_color_suffix} rc4-md5-6
 
 ${Green_font_prefix} 5.${Font_color_suffix} aes-128-ctr
 ${Green_font_prefix} 6.${Font_color_suffix} aes-192-ctr
 ${Green_font_prefix} 7.${Font_color_suffix} aes-256-ctr
 
 ${Green_font_prefix} 8.${Font_color_suffix} aes-128-cfb
 ${Green_font_prefix} 9.${Font_color_suffix} aes-192-cfb
 ${Green_font_prefix}10.${Font_color_suffix} aes-256-cfb
 
 ${Green_font_prefix}11.${Font_color_suffix} aes-128-cfb8
 ${Green_font_prefix}12.${Font_color_suffix} aes-192-cfb8
 ${Green_font_prefix}13.${Font_color_suffix} aes-256-cfb8
 
 ${Green_font_prefix}14.${Font_color_suffix} salsa20
 ${Green_font_prefix}15.${Font_color_suffix} chacha20
 ${Green_font_prefix}16.${Font_color_suffix} chacha20-ietf
 ${Tip} salsa20/chacha20-*系列加密方式，需要额外安装依赖 libsodium ，否则会无法启动ShadowsocksR !" && echo
	read -e -p "(默认: 5. aes-128-ctr):" ssr_method
	[[ -z "${ssr_method}" ]] && ssr_method="5"
	if [[ ${ssr_method} == "1" ]]; then
		ssr_method="none"
	elif [[ ${ssr_method} == "2" ]]; then
		ssr_method="rc4"
	elif [[ ${ssr_method} == "3" ]]; then
		ssr_method="rc4-md5"
	elif [[ ${ssr_method} == "4" ]]; then
		ssr_method="rc4-md5-6"
	elif [[ ${ssr_method} == "5" ]]; then
		ssr_method="aes-128-ctr"
	elif [[ ${ssr_method} == "6" ]]; then
		ssr_method="aes-192-ctr"
	elif [[ ${ssr_method} == "7" ]]; then
		ssr_method="aes-256-ctr"
	elif [[ ${ssr_method} == "8" ]]; then
		ssr_method="aes-128-cfb"
	elif [[ ${ssr_method} == "9" ]]; then
		ssr_method="aes-192-cfb"
	elif [[ ${ssr_method} == "10" ]]; then
		ssr_method="aes-256-cfb"
	elif [[ ${ssr_method} == "11" ]]; then
		ssr_method="aes-128-cfb8"
	elif [[ ${ssr_method} == "12" ]]; then
		ssr_method="aes-192-cfb8"
	elif [[ ${ssr_method} == "13" ]]; then
		ssr_method="aes-256-cfb8"
	elif [[ ${ssr_method} == "14" ]]; then
		ssr_method="salsa20"
	elif [[ ${ssr_method} == "15" ]]; then
		ssr_method="chacha20"
	elif [[ ${ssr_method} == "16" ]]; then
		ssr_method="chacha20-ietf"
	else
		ssr_method="aes-128-ctr"
	fi
	echo && echo ${Separator_1} && echo -e "	加密 : ${Green_font_prefix}${ssr_method}${Font_color_suffix}" && echo ${Separator_1} && echo
}
Set_config_protocol(){
	echo -e "请选择要设置的ShadowsocksR账号 协议插件
	
 ${Green_font_prefix}1.${Font_color_suffix} origin
 ${Green_font_prefix}2.${Font_color_suffix} auth_sha1_v4
 ${Green_font_prefix}3.${Font_color_suffix} auth_aes128_md5
 ${Green_font_prefix}4.${Font_color_suffix} auth_aes128_sha1
 ${Green_font_prefix}5.${Font_color_suffix} auth_chain_a
 ${Green_font_prefix}6.${Font_color_suffix} auth_chain_b
 ${Tip} 如果使用 auth_chain_a 协议，请加密方式选择 none，混淆随意(建议 plain)" && echo
	read -e -p "(默认: 2. auth_sha1_v4):" ssr_protocol
	[[ -z "${ssr_protocol}" ]] && ssr_protocol="2"
	if [[ ${ssr_protocol} == "1" ]]; then
		ssr_protocol="origin"
	elif [[ ${ssr_protocol} == "2" ]]; then
		ssr_protocol="auth_sha1_v4"
	elif [[ ${ssr_protocol} == "3" ]]; then
		ssr_protocol="auth_aes128_md5"
	elif [[ ${ssr_protocol} == "4" ]]; then
		ssr_protocol="auth_aes128_sha1"
	elif [[ ${ssr_protocol} == "5" ]]; then
		ssr_protocol="auth_chain_a"
	elif [[ ${ssr_protocol} == "6" ]]; then
		ssr_protocol="auth_chain_b"
	else
		ssr_protocol="auth_sha1_v4"
	fi
	echo && echo ${Separator_1} && echo -e "	协议 : ${Green_font_prefix}${ssr_protocol}${Font_color_suffix}" && echo ${Separator_1} && echo
	if [[ ${ssr_protocol} != "origin" ]]; then
		if [[ ${ssr_protocol} == "auth_sha1_v4" ]]; then
			read -e -p "是否设置 协议插件兼容原版(_compatible)？[Y/n]" ssr_protocol_yn
			[[ -z "${ssr_protocol_yn}" ]] && ssr_protocol_yn="y"
			[[ $ssr_protocol_yn == [Yy] ]] && ssr_protocol=${ssr_protocol}"_compatible"
			echo
		fi
	fi
}
Set_config_obfs(){
	echo -e "请选择要设置的ShadowsocksR账号 混淆插件
	
 ${Green_font_prefix}1.${Font_color_suffix} plain
 ${Green_font_prefix}2.${Font_color_suffix} http_simple
 ${Green_font_prefix}3.${Font_color_suffix} http_post
 ${Green_font_prefix}4.${Font_color_suffix} random_head
 ${Green_font_prefix}5.${Font_color_suffix} tls1.2_ticket_auth
 ${Tip} 如果使用 ShadowsocksR 加速游戏，请选择 混淆兼容原版或 plain 混淆，然后客户端选择 plain，否则会增加延迟 !
 另外, 如果你选择了 tls1.2_ticket_auth，那么客户端可以选择 tls1.2_ticket_fastauth，这样即能伪装又不会增加延迟 !
 如果你是在日本、美国等热门地区搭建，那么选择 plain 混淆可能被墙几率更低 !" && echo
	read -e -p "(默认: 1. plain):" ssr_obfs
	[[ -z "${ssr_obfs}" ]] && ssr_obfs="1"
	if [[ ${ssr_obfs} == "1" ]]; then
		ssr_obfs="plain"
	elif [[ ${ssr_obfs} == "2" ]]; then
		ssr_obfs="http_simple"
	elif [[ ${ssr_obfs} == "3" ]]; then
		ssr_obfs="http_post"
	elif [[ ${ssr_obfs} == "4" ]]; then
		ssr_obfs="random_head"
	elif [[ ${ssr_obfs} == "5" ]]; then
		ssr_obfs="tls1.2_ticket_auth"
	else
		ssr_obfs="plain"
	fi
	echo && echo ${Separator_1} && echo -e "	混淆 : ${Green_font_prefix}${ssr_obfs}${Font_color_suffix}" && echo ${Separator_1} && echo
	if [[ ${ssr_obfs} != "plain" ]]; then
			read -e -p "是否设置 混淆插件兼容原版(_compatible)？[Y/n]" ssr_obfs_yn
			[[ -z "${ssr_obfs_yn}" ]] && ssr_obfs_yn="y"
			[[ $ssr_obfs_yn == [Yy] ]] && ssr_obfs=${ssr_obfs}"_compatible"
			echo
	fi
}
Set_config_protocol_param(){
	while true
	do
	echo -e "请输入要设置的ShadowsocksR账号 欲限制的设备数 (${Green_font_prefix} auth_* 系列协议 不兼容原版才有效 ${Font_color_suffix})"
	echo -e "${Tip} 设备数限制：每个端口同一时间能链接的客户端数量(多端口模式，每个端口都是独立计算)，建议最少 2个。"
	read -e -p "(默认: 无限):" ssr_protocol_param
	[[ -z "$ssr_protocol_param" ]] && ssr_protocol_param="" && echo && break
	echo $((${ssr_protocol_param}+0)) &>/dev/null
	if [[ $? == 0 ]]; then
		if [[ ${ssr_protocol_param} -ge 1 ]] && [[ ${ssr_protocol_param} -le 9999 ]]; then
			echo && echo ${Separator_1} && echo -e "	设备数限制 : ${Green_font_prefix}${ssr_protocol_param}${Font_color_suffix}" && echo ${Separator_1} && echo
			break
		else
			echo -e "${Error} 请输入正确的数字(1-9999)"
		fi
	else
		echo -e "${Error} 请输入正确的数字(1-9999)"
	fi
	done
}
Set_config_speed_limit_per_con(){
	while true
	do
	echo -e "请输入要设置的每个端口 单线程 限速上限(单位：KB/S)"
	echo -e "${Tip} 单线程限速：每个端口 单线程的限速上限，多线程即无效。"
	read -e -p "(默认: 无限):" ssr_speed_limit_per_con
	[[ -z "$ssr_speed_limit_per_con" ]] && ssr_speed_limit_per_con=0 && echo && break
	echo $((${ssr_speed_limit_per_con}+0)) &>/dev/null
	if [[ $? == 0 ]]; then
		if [[ ${ssr_speed_limit_per_con} -ge 1 ]] && [[ ${ssr_speed_limit_per_con} -le 131072 ]]; then
			echo && echo ${Separator_1} && echo -e "	单线程限速 : ${Green_font_prefix}${ssr_speed_limit_per_con} KB/S${Font_color_suffix}" && echo ${Separator_1} && echo
			break
		else
			echo -e "${Error} 请输入正确的数字(1-131072)"
		fi
	else
		echo -e "${Error} 请输入正确的数字(1-131072)"
	fi
	done
}
Set_config_speed_limit_per_user(){
	while true
	do
	echo
	echo -e "请输入要设置的每个端口 总速度 限速上限(单位：KB/S)"
	echo -e "${Tip} 端口总限速：每个端口 总速度 限速上限，单个端口整体限速。"
	read -e -p "(默认: 无限):" ssr_speed_limit_per_user
	[[ -z "$ssr_speed_limit_per_user" ]] && ssr_speed_limit_per_user=0 && echo && break
	echo $((${ssr_speed_limit_per_user}+0)) &>/dev/null
	if [[ $? == 0 ]]; then
		if [[ ${ssr_speed_limit_per_user} -ge 1 ]] && [[ ${ssr_speed_limit_per_user} -le 131072 ]]; then
			echo && echo ${Separator_1} && echo -e "	端口总限速 : ${Green_font_prefix}${ssr_speed_limit_per_user} KB/S${Font_color_suffix}" && echo ${Separator_1} && echo
			break
		else
			echo -e "${Error} 请输入正确的数字(1-131072)"
		fi
	else
		echo -e "${Error} 请输入正确的数字(1-131072)"
	fi
	done
}
Set_config_all(){
	Set_config_port
	Set_config_password
	Set_config_method
	Set_config_protocol
	Set_config_obfs
	Set_config_protocol_param
	Set_config_speed_limit_per_con
	Set_config_speed_limit_per_user
}
# 修改 配置信息
Modify_config_port(){
	sed -i 's/"server_port": '"$(echo ${port})"'/"server_port": '"$(echo ${ssr_port})"'/g' ${config_user_file}
}
Modify_config_password(){
	sed -i 's/"password": "'"$(echo ${password})"'"/"password": "'"$(echo ${ssr_password})"'"/g' ${config_user_file}
}
Modify_config_method(){
	sed -i 's/"method": "'"$(echo ${method})"'"/"method": "'"$(echo ${ssr_method})"'"/g' ${config_user_file}
}
Modify_config_protocol(){
	sed -i 's/"protocol": "'"$(echo ${protocol})"'"/"protocol": "'"$(echo ${ssr_protocol})"'"/g' ${config_user_file}
}
Modify_config_obfs(){
	sed -i 's/"obfs": "'"$(echo ${obfs})"'"/"obfs": "'"$(echo ${ssr_obfs})"'"/g' ${config_user_file}
}
Modify_config_protocol_param(){
	sed -i 's/"protocol_param": "'"$(echo ${protocol_param})"'"/"protocol_param": "'"$(echo ${ssr_protocol_param})"'"/g' ${config_user_file}
}
Modify_config_speed_limit_per_con(){
	sed -i 's/"speed_limit_per_con": '"$(echo ${speed_limit_per_con})"'/"speed_limit_per_con": '"$(echo ${ssr_speed_limit_per_con})"'/g' ${config_user_file}
}
Modify_config_speed_limit_per_user(){
	sed -i 's/"speed_limit_per_user": '"$(echo ${speed_limit_per_user})"'/"speed_limit_per_user": '"$(echo ${ssr_speed_limit_per_user})"'/g' ${config_user_file}
}
Modify_config_connect_verbose_info(){
	sed -i 's/"connect_verbose_info": '"$(echo ${connect_verbose_info})"'/"connect_verbose_info": '"$(echo ${ssr_connect_verbose_info})"'/g' ${config_user_file}
}
Modify_config_all(){
	Modify_config_port
	Modify_config_password
	Modify_config_method
	Modify_config_protocol
	Modify_config_obfs
	Modify_config_protocol_param
	Modify_config_speed_limit_per_con
	Modify_config_speed_limit_per_user
}
Modify_config_port_many(){
	sed -i 's/"'"$(echo ${port})"'":/"'"$(echo ${ssr_port})"'":/g' ${config_user_file}
}
Modify_config_password_many(){
	sed -i 's/"'"$(echo ${password})"'"/"'"$(echo ${ssr_password})"'"/g' ${config_user_file}
}
# 写入 配置信息
Write_configuration(){
	cat > ${config_user_file}<<-EOF
{
    "server": "0.0.0.0",
    "server_ipv6": "::",
    "server_port": ${ssr_port},
    "local_address": "127.0.0.1",
    "local_port": 1080,

    "password": "${ssr_password}",
    "method": "${ssr_method}",
    "protocol": "${ssr_protocol}",
    "protocol_param": "${ssr_protocol_param}",
    "obfs": "${ssr_obfs}",
    "obfs_param": "",
    "speed_limit_per_con": ${ssr_speed_limit_per_con},
    "speed_limit_per_user": ${ssr_speed_limit_per_user},

    "additional_ports" : {},
    "timeout": 120,
    "udp_timeout": 60,
    "dns_ipv6": false,
    "connect_verbose_info": 0,
    "redirect": "",
    "fast_open": false
}
EOF
}
Write_configuration_many(){
	cat > ${config_user_file}<<-EOF
{
    "server": "0.0.0.0",
    "server_ipv6": "::",
    "local_address": "127.0.0.1",
    "local_port": 1080,

    "port_password":{
        "${ssr_port}":"${ssr_password}"
    },
    "method": "${ssr_method}",
    "protocol": "${ssr_protocol}",
    "protocol_param": "${ssr_protocol_param}",
    "obfs": "${ssr_obfs}",
    "obfs_param": "",
    "speed_limit_per_con": ${ssr_speed_limit_per_con},
    "speed_limit_per_user": ${ssr_speed_limit_per_user},

    "additional_ports" : {},
    "timeout": 120,
    "udp_timeout": 60,
    "dns_ipv6": false,
    "connect_verbose_info": 0,
    "redirect": "",
    "fast_open": false
}
EOF
}
Check_python(){
	python_ver=`python -h`
	if [[ -z ${python_ver} ]]; then
		echo -e "${Info} 没有安装Python，开始安装..."
		if [[ ${release} == "centos" ]]; then
			yum install -y python
		else
			apt-get install -y python
		fi
	fi
}
Centos_yum(){
	yum update
	cat /etc/redhat-release |grep 7\..*|grep -i centos>/dev/null
	if [[ $? = 0 ]]; then
		yum install -y vim unzip net-tools
	else
		yum install -y vim unzip
	fi
}
Debian_apt(){
	apt-get update
	cat /etc/issue |grep 9\..*>/dev/null
	if [[ $? = 0 ]]; then
		apt-get install -y vim unzip net-tools
	else
		apt-get install -y vim unzip
	fi
}
# 下载 ShadowsocksR
Download_SSR(){
	cd "/usr/local/"
	wget -N --no-check-certificate "https://github.com/ToyoDAdoubiBackup/shadowsocksr/archive/manyuser.zip"
	#git config --global http.sslVerify false
	#env GIT_SSL_NO_VERIFY=true git clone -b manyuser https://github.com/ToyoDAdoubiBackup/shadowsocksr.git
	#[[ ! -e ${ssr_folder} ]] && echo -e "${Error} ShadowsocksR服务端 下载失败 !" && exit 1
	[[ ! -e "manyuser.zip" ]] && echo -e "${Error} ShadowsocksR服务端 压缩包 下载失败 !" && rm -rf manyuser.zip && exit 1
	unzip "manyuser.zip"
	[[ ! -e "/usr/local/shadowsocksr-manyuser/" ]] && echo -e "${Error} ShadowsocksR服务端 解压失败 !" && rm -rf manyuser.zip && exit 1
	mv "/usr/local/shadowsocksr-manyuser/" "/usr/local/shadowsocksr/"
	[[ ! -e "/usr/local/shadowsocksr/" ]] && echo -e "${Error} ShadowsocksR服务端 重命名失败 !" && rm -rf manyuser.zip && rm -rf "/usr/local/shadowsocksr-manyuser/" && exit 1
	rm -rf manyuser.zip
	[[ -e ${config_folder} ]] && rm -rf ${config_folder}
	mkdir ${config_folder}
	[[ ! -e ${config_folder} ]] && echo -e "${Error} ShadowsocksR配置文件的文件夹 建立失败 !" && exit 1
	echo -e "${Info} ShadowsocksR服务端 下载完成 !"
}
Service_SSR(){
	if [[ ${release} = "centos" ]]; then
		if ! wget --no-check-certificate https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/service/ssr_centos -O /etc/init.d/ssr; then
			echo -e "${Error} ShadowsocksR服务 管理脚本下载失败 !" && exit 1
		fi
		chmod +x /etc/init.d/ssr
		chkconfig --add ssr
		chkconfig ssr on
	else
		if ! wget --no-check-certificate https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/service/ssr_debian -O /etc/init.d/ssr; then
			echo -e "${Error} ShadowsocksR服务 管理脚本下载失败 !" && exit 1
		fi
		chmod +x /etc/init.d/ssr
		update-rc.d -f ssr defaults
	fi
	echo -e "${Info} ShadowsocksR服务 管理脚本下载完成 !"
}
# 安装 JQ解析器
JQ_install(){
	if [[ ! -e ${jq_file} ]]; then
		cd "${ssr_folder}"
		if [[ ${bit} = "x86_64" ]]; then
			mv "jq-linux64" "jq"
			#wget --no-check-certificate "https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64" -O ${jq_file}
		else
			mv "jq-linux32" "jq"
			#wget --no-check-certificate "https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux32" -O ${jq_file}
		fi
		[[ ! -e ${jq_file} ]] && echo -e "${Error} JQ解析器 重命名失败，请检查 !" && exit 1
		chmod +x ${jq_file}
		echo -e "${Info} JQ解析器 安装完成，继续..." 
	else
		echo -e "${Info} JQ解析器 已安装，继续..."
	fi
}
# 安装 依赖
Installation_dependency(){
	if [[ ${release} == "centos" ]]; then
		Centos_yum
	else
		Debian_apt
	fi
	[[ ! -e "/usr/bin/unzip" ]] && echo -e "${Error} 依赖 unzip(解压压缩包) 安装失败，多半是软件包源的问题，请检查 !" && exit 1
	Check_python
	#echo "nameserver 8.8.8.8" > /etc/resolv.conf
	#echo "nameserver 8.8.4.4" >> /etc/resolv.conf
	\cp -f /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
}
Install_SSR(){
	check_root
	[[ -e ${config_user_file} ]] && echo -e "${Error} ShadowsocksR 配置文件已存在，请检查( 如安装失败或者存在旧版本，请先卸载 ) !" && exit 1
	[[ -e ${ssr_folder} ]] && echo -e "${Error} ShadowsocksR 文件夹已存在，请检查( 如安装失败或者存在旧版本，请先卸载 ) !" && exit 1
	echo -e "${Info} 开始设置 ShadowsocksR账号配置..."
	Set_config_all
	echo -e "${Info} 开始安装/配置 ShadowsocksR依赖..."
	Installation_dependency
	echo -e "${Info} 开始下载/安装 ShadowsocksR文件..."
	Download_SSR
	echo -e "${Info} 开始下载/安装 ShadowsocksR服务脚本(init)..."
	Service_SSR
	echo -e "${Info} 开始下载/安装 JSNO解析器 JQ..."
	JQ_install
	echo -e "${Info} 开始写入 ShadowsocksR配置文件..."
	Write_configuration
	echo -e "${Info} 开始设置 iptables防火墙..."
	Set_iptables
	echo -e "${Info} 开始添加 iptables防火墙规则..."
	Add_iptables
	echo -e "${Info} 开始保存 iptables防火墙规则..."
	Save_iptables
	echo -e "${Info} 所有步骤 安装完毕，开始启动 ShadowsocksR服务端..."
	Start_SSR
}
Update_SSR(){
	SSR_installation_status
	echo -e "因破娃暂停更新ShadowsocksR服务端，所以此功能临时禁用。"
	#cd ${ssr_folder}
	#git pull
	#Restart_SSR
}
Uninstall_SSR(){
	[[ ! -e ${config_user_file} ]] && [[ ! -e ${ssr_folder} ]] && echo -e "${Error} 没有安装 ShadowsocksR，请检查 !" && exit 1
	echo "确定要 卸载ShadowsocksR？[y/N]" && echo
	read -e -p "(默认: n):" unyn
	[[ -z ${unyn} ]] && unyn="n"
	if [[ ${unyn} == [Yy] ]]; then
		check_pid
		[[ ! -z "${PID}" ]] && kill -9 ${PID}
		if [[ -z "${now_mode}" ]]; then
			port=`${jq_file} '.server_port' ${config_user_file}`
			Del_iptables
			Save_iptables
		else
			user_total=`${jq_file} '.port_password' ${config_user_file} | sed '$d' | sed "1d" | wc -l`
			for((integer = 1; integer <= ${user_total}; integer++))
			do
				port=`${jq_file} '.port_password' ${config_user_file} | sed '$d' | sed "1d" | awk -F ":" '{print $1}' | sed -n "${integer}p" | sed -r 's/.*\"(.+)\".*/\1/'`
				Del_iptables
			done
			Save_iptables
		fi
		if [[ ${release} = "centos" ]]; then
			chkconfig --del ssr
		else
			update-rc.d -f ssr remove
		fi
		rm -rf ${ssr_folder} && rm -rf ${config_folder} && rm -rf /etc/init.d/ssr
		echo && echo " ShadowsocksR 卸载完成 !" && echo
	else
		echo && echo " 卸载已取消..." && echo
	fi
}
Check_Libsodium_ver(){
	echo -e "${Info} 开始获取 libsodium 最新版本..."
	Libsodiumr_ver=$(wget -qO- "https://github.com/jedisct1/libsodium/tags"|grep "/jedisct1/libsodium/releases/tag/"|head -1|sed -r 's/.*tag\/(.+)\">.*/\1/')
	[[ -z ${Libsodiumr_ver} ]] && Libsodiumr_ver=${Libsodiumr_ver_backup}
	echo -e "${Info} libsodium 最新版本为 ${Green_font_prefix}${Libsodiumr_ver}${Font_color_suffix} !"
}
Install_Libsodium(){
	if [[ -e ${Libsodiumr_file} ]]; then
		echo -e "${Error} libsodium 已安装 , 是否覆盖安装(更新)？[y/N]"
		read -e -p "(默认: n):" yn
		[[ -z ${yn} ]] && yn="n"
		if [[ ${yn} == [Nn] ]]; then
			echo "已取消..." && exit 1
		fi
	else
		echo -e "${Info} libsodium 未安装，开始安装..."
	fi
	Check_Libsodium_ver
	if [[ ${release} == "centos" ]]; then
		yum update
		echo -e "${Info} 安装依赖..."
		yum -y groupinstall "Development Tools"
		echo -e "${Info} 下载..."
		wget  --no-check-certificate -N "https://github.com/jedisct1/libsodium/releases/download/${Libsodiumr_ver}-RELEASE/libsodium-${Libsodiumr_ver}.tar.gz"
		echo -e "${Info} 解压..."
		tar -xzf libsodium-${Libsodiumr_ver}.tar.gz && cd libsodium-${Libsodiumr_ver}
		echo -e "${Info} 编译安装..."
		./configure --disable-maintainer-mode && make -j2 && make install
		echo /usr/local/lib > /etc/ld.so.conf.d/usr_local_lib.conf
	else
		apt-get update
		echo -e "${Info} 安装依赖..."
		apt-get install -y build-essential
		echo -e "${Info} 下载..."
		wget  --no-check-certificate -N "https://github.com/jedisct1/libsodium/releases/download/${Libsodiumr_ver}-RELEASE/libsodium-${Libsodiumr_ver}.tar.gz"
		echo -e "${Info} 解压..."
		tar -xzf libsodium-${Libsodiumr_ver}.tar.gz && cd libsodium-${Libsodiumr_ver}
		echo -e "${Info} 编译安装..."
		./configure --disable-maintainer-mode && make -j2 && make install
	fi
	ldconfig
	cd .. && rm -rf libsodium-${Libsodiumr_ver}.tar.gz && rm -rf libsodium-${Libsodiumr_ver}
	[[ ! -e ${Libsodiumr_file} ]] && echo -e "${Error} libsodium 安装失败 !" && exit 1
	echo && echo -e "${Info} libsodium 安装成功 !" && echo
}
# 显示 连接信息
debian_View_user_connection_info(){
	format_1=$1
	if [[ -z "${now_mode}" ]]; then
		now_mode="单端口" && user_total="1"
		IP_total=`netstat -anp |grep 'ESTABLISHED' |grep 'python' |grep 'tcp6' |awk '{print $5}' |awk -F ":" '{print $1}' |sort -u |grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}" |wc -l`
		user_port=`${jq_file} '.server_port' ${config_user_file}`
		user_IP_1=`netstat -anp |grep 'ESTABLISHED' |grep 'python' |grep 'tcp6' |grep ":${user_port} " |awk '{print $5}' |awk -F ":" '{print $1}' |sort -u |grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}" `
		if [[ -z ${user_IP_1} ]]; then
			user_IP_total="0"
		else
			user_IP_total=`echo -e "${user_IP_1}"|wc -l`
			if [[ ${format_1} == "IP_address" ]]; then
				get_IP_address
			else
				user_IP=`echo -e "\n${user_IP_1}"`
			fi
		fi
		user_list_all="端口: ${Green_font_prefix}"${user_port}"${Font_color_suffix}\t 链接IP总数: ${Green_font_prefix}"${user_IP_total}"${Font_color_suffix}\t 当前链接IP: ${Green_font_prefix}${user_IP}${Font_color_suffix}\n"
		user_IP=""
		echo -e "当前模式: ${Green_background_prefix} "${now_mode}" ${Font_color_suffix} 链接IP总数: ${Green_background_prefix} "${IP_total}" ${Font_color_suffix}"
		echo -e "${user_list_all}"
	else
		now_mode="多端口" && user_total=`${jq_file} '.port_password' ${config_user_file} |sed '$d;1d' | wc -l`
		IP_total=`netstat -anp |grep 'ESTABLISHED' |grep 'python' |grep 'tcp6' |awk '{print $5}' |awk -F ":" '{print $1}' |sort -u |grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}" |wc -l`
		user_list_all=""
		for((integer = ${user_total}; integer >= 1; integer--))
		do
			user_port=`${jq_file} '.port_password' ${config_user_file} |sed '$d;1d' |awk -F ":" '{print $1}' |sed -n "${integer}p" |sed -r 's/.*\"(.+)\".*/\1/'`
			user_IP_1=`netstat -anp |grep 'ESTABLISHED' |grep 'python' |grep 'tcp6' |grep "${user_port}" |awk '{print $5}' |awk -F ":" '{print $1}' |sort -u |grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}"`
			if [[ -z ${user_IP_1} ]]; then
				user_IP_total="0"
			else
				user_IP_total=`echo -e "${user_IP_1}"|wc -l`
				if [[ ${format_1} == "IP_address" ]]; then
					get_IP_address
				else
					user_IP=`echo -e "\n${user_IP_1}"`
				fi
			fi
			user_list_all=${user_list_all}"端口: ${Green_font_prefix}"${user_port}"${Font_color_suffix}\t 链接IP总数: ${Green_font_prefix}"${user_IP_total}"${Font_color_suffix}\t 当前链接IP: ${Green_font_prefix}${user_IP}${Font_color_suffix}\n"
			user_IP=""
		done
		echo -e "当前模式: ${Green_background_prefix} "${now_mode}" ${Font_color_suffix} 用户总数: ${Green_background_prefix} "${user_total}" ${Font_color_suffix} 链接IP总数: ${Green_background_prefix} "${IP_total}" ${Font_color_suffix} "
		echo -e "${user_list_all}"
	fi
}
centos_View_user_connection_info(){
	format_1=$1
	if [[ -z "${now_mode}" ]]; then
		now_mode="单端口" && user_total="1"
		IP_total=`netstat -anp |grep 'ESTABLISHED' |grep 'python' |grep 'tcp' |grep '::ffff:' |awk '{print $5}' |awk -F ":" '{print $4}' |sort -u |grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}" |wc -l`
		user_port=`${jq_file} '.server_port' ${config_user_file}`
		user_IP_1=`netstat -anp |grep 'ESTABLISHED' |grep 'python' |grep 'tcp' |grep ":${user_port} " | grep '::ffff:' |awk '{print $5}' |awk -F ":" '{print $4}' |sort -u |grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}"`
		if [[ -z ${user_IP_1} ]]; then
			user_IP_total="0"
		else
			user_IP_total=`echo -e "${user_IP_1}"|wc -l`
			if [[ ${format_1} == "IP_address" ]]; then
				get_IP_address
			else
				user_IP=`echo -e "\n${user_IP_1}"`
			fi
		fi
		user_list_all="端口: ${Green_font_prefix}"${user_port}"${Font_color_suffix}\t 链接IP总数: ${Green_font_prefix}"${user_IP_total}"${Font_color_suffix}\t 当前链接IP: ${Green_font_prefix}${user_IP}${Font_color_suffix}\n"
		user_IP=""
		echo -e "当前模式: ${Green_background_prefix} "${now_mode}" ${Font_color_suffix} 链接IP总数: ${Green_background_prefix} "${IP_total}" ${Font_color_suffix}"
		echo -e "${user_list_all}"
	else
		now_mode="多端口" && user_total=`${jq_file} '.port_password' ${config_user_file} |sed '$d;1d' | wc -l`
		IP_total=`netstat -anp |grep 'ESTABLISHED' |grep 'python' |grep 'tcp' | grep '::ffff:' |awk '{print $5}' |awk -F ":" '{print $4}' |sort -u |grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}" |wc -l`
		user_list_all=""
		for((integer = 1; integer <= ${user_total}; integer++))
		do
			user_port=`${jq_file} '.port_password' ${config_user_file} |sed '$d;1d' |awk -F ":" '{print $1}' |sed -n "${integer}p" |sed -r 's/.*\"(.+)\".*/\1/'`
			user_IP_1=`netstat -anp |grep 'ESTABLISHED' |grep 'python' |grep 'tcp' |grep "${user_port}"|grep '::ffff:' |awk '{print $5}' |awk -F ":" '{print $4}' |sort -u |grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}" `
			if [[ -z ${user_IP_1} ]]; then
				user_IP_total="0"
			else
				user_IP_total=`echo -e "${user_IP_1}"|wc -l`
				if [[ ${format_1} == "IP_address" ]]; then
					get_IP_address
				else
					user_IP=`echo -e "\n${user_IP_1}"`
				fi
			fi
			user_list_all=${user_list_all}"端口: ${Green_font_prefix}"${user_port}"${Font_color_suffix}\t 链接IP总数: ${Green_font_prefix}"${user_IP_total}"${Font_color_suffix}\t 当前链接IP: ${Green_font_prefix}${user_IP}${Font_color_suffix}\n"
			user_IP=""
		done
		echo -e "当前模式: ${Green_background_prefix} "${now_mode}" ${Font_color_suffix} 用户总数: ${Green_background_prefix} "${user_total}" ${Font_color_suffix} 链接IP总数: ${Green_background_prefix} "${IP_total}" ${Font_color_suffix} "
		echo -e "${user_list_all}"
	fi
}
View_user_connection_info(){
	SSR_installation_status
	echo && echo -e "请选择要显示的格式：
 ${Green_font_prefix}1.${Font_color_suffix} 显示 IP 格式
 ${Green_font_prefix}2.${Font_color_suffix} 显示 IP+IP归属地 格式" && echo
	read -e -p "(默认: 1):" ssr_connection_info
	[[ -z "${ssr_connection_info}" ]] && ssr_connection_info="1"
	if [[ ${ssr_connection_info} == "1" ]]; then
		View_user_connection_info_1 ""
	elif [[ ${ssr_connection_info} == "2" ]]; then
		echo -e "${Tip} 检测IP归属地(ipip.net)，如果IP较多，可能时间会比较长..."
		View_user_connection_info_1 "IP_address"
	else
		echo -e "${Error} 请输入正确的数字(1-2)" && exit 1
	fi
}
View_user_connection_info_1(){
	format=$1
	if [[ ${release} = "centos" ]]; then
		cat /etc/redhat-release |grep 7\..*|grep -i centos>/dev/null
		if [[ $? = 0 ]]; then
			debian_View_user_connection_info "$format"
		else
			centos_View_user_connection_info "$format"
		fi
	else
		debian_View_user_connection_info "$format"
	fi
}
get_IP_address(){
	#echo "user_IP_1=${user_IP_1}"
	if [[ ! -z ${user_IP_1} ]]; then
	#echo "user_IP_total=${user_IP_total}"
		for((integer_1 = ${user_IP_total}; integer_1 >= 1; integer_1--))
		do
			IP=`echo "${user_IP_1}" |sed -n "$integer_1"p`
			#echo "IP=${IP}"
			IP_address=`wget -qO- -t1 -T2 http://freeapi.ipip.net/${IP}|sed 's/\"//g;s/,//g;s/\[//g;s/\]//g'`
			#echo "IP_address=${IP_address}"
			user_IP="${user_IP}\n${IP}(${IP_address})"
			#echo "user_IP=${user_IP}"
			sleep 1s
		done
	fi
}
# 修改 用户配置
Modify_Config(){
	SSR_installation_status
	if [[ -z "${now_mode}" ]]; then
		echo && echo -e "当前模式: 单端口，你要做什么？
 ${Green_font_prefix}1.${Font_color_suffix} 修改 用户端口
 ${Green_font_prefix}2.${Font_color_suffix} 修改 用户密码
 ${Green_font_prefix}3.${Font_color_suffix} 修改 加密方式
 ${Green_font_prefix}4.${Font_color_suffix} 修改 协议插件
 ${Green_font_prefix}5.${Font_color_suffix} 修改 混淆插件
 ${Green_font_prefix}6.${Font_color_suffix} 修改 设备数限制
 ${Green_font_prefix}7.${Font_color_suffix} 修改 单线程限速
 ${Green_font_prefix}8.${Font_color_suffix} 修改 端口总限速
 ${Green_font_prefix}9.${Font_color_suffix} 修改 全部配置" && echo
		read -e -p "(默认: 取消):" ssr_modify
		[[ -z "${ssr_modify}" ]] && echo "已取消..." && exit 1
		Get_User
		if [[ ${ssr_modify} == "1" ]]; then
			Set_config_port
			Modify_config_port
			Add_iptables
			Del_iptables
			Save_iptables
		elif [[ ${ssr_modify} == "2" ]]; then
			Set_config_password
			Modify_config_password
		elif [[ ${ssr_modify} == "3" ]]; then
			Set_config_method
			Modify_config_method
		elif [[ ${ssr_modify} == "4" ]]; then
			Set_config_protocol
			Modify_config_protocol
		elif [[ ${ssr_modify} == "5" ]]; then
			Set_config_obfs
			Modify_config_obfs
		elif [[ ${ssr_modify} == "6" ]]; then
			Set_config_protocol_param
			Modify_config_protocol_param
		elif [[ ${ssr_modify} == "7" ]]; then
			Set_config_speed_limit_per_con
			Modify_config_speed_limit_per_con
		elif [[ ${ssr_modify} == "8" ]]; then
			Set_config_speed_limit_per_user
			Modify_config_speed_limit_per_user
		elif [[ ${ssr_modify} == "9" ]]; then
			Set_config_all
			Modify_config_all
		else
			echo -e "${Error} 请输入正确的数字(1-9)" && exit 1
		fi
	else
		echo && echo -e "当前模式: 多端口，你要做什么？
 ${Green_font_prefix}1.${Font_color_suffix}  添加 用户配置
 ${Green_font_prefix}2.${Font_color_suffix}  删除 用户配置
 ${Green_font_prefix}3.${Font_color_suffix}  修改 用户配置
——————————
 ${Green_font_prefix}4.${Font_color_suffix}  修改 加密方式
 ${Green_font_prefix}5.${Font_color_suffix}  修改 协议插件
 ${Green_font_prefix}6.${Font_color_suffix}  修改 混淆插件
 ${Green_font_prefix}7.${Font_color_suffix}  修改 设备数限制
 ${Green_font_prefix}8.${Font_color_suffix}  修改 单线程限速
 ${Green_font_prefix}9.${Font_color_suffix}  修改 端口总限速
 ${Green_font_prefix}10.${Font_color_suffix} 修改 全部配置" && echo
		read -e -p "(默认: 取消):" ssr_modify
		[[ -z "${ssr_modify}" ]] && echo "已取消..." && exit 1
		Get_User
		if [[ ${ssr_modify} == "1" ]]; then
			Add_multi_port_user
		elif [[ ${ssr_modify} == "2" ]]; then
			Del_multi_port_user
		elif [[ ${ssr_modify} == "3" ]]; then
			Modify_multi_port_user
		elif [[ ${ssr_modify} == "4" ]]; then
			Set_config_method
			Modify_config_method
		elif [[ ${ssr_modify} == "5" ]]; then
			Set_config_protocol
			Modify_config_protocol
		elif [[ ${ssr_modify} == "6" ]]; then
			Set_config_obfs
			Modify_config_obfs
		elif [[ ${ssr_modify} == "7" ]]; then
			Set_config_protocol_param
			Modify_config_protocol_param
		elif [[ ${ssr_modify} == "8" ]]; then
			Set_config_speed_limit_per_con
			Modify_config_speed_limit_per_con
		elif [[ ${ssr_modify} == "9" ]]; then
			Set_config_speed_limit_per_user
			Modify_config_speed_limit_per_user
		elif [[ ${ssr_modify} == "10" ]]; then
			Set_config_method
			Set_config_protocol
			Set_config_obfs
			Set_config_protocol_param
			Set_config_speed_limit_per_con
			Set_config_speed_limit_per_user
			Modify_config_method
			Modify_config_protocol
			Modify_config_obfs
			Modify_config_protocol_param
			Modify_config_speed_limit_per_con
			Modify_config_speed_limit_per_user
		else
			echo -e "${Error} 请输入正确的数字(1-9)" && exit 1
		fi
	fi
	Restart_SSR
}
# 显示 多端口用户配置
List_multi_port_user(){
	user_total=`${jq_file} '.port_password' ${config_user_file} | sed '$d' | sed "1d" | wc -l`
	[[ ${user_total} = "0" ]] && echo -e "${Error} 没有发现 多端口用户，请检查 !" && exit 1
	user_list_all=""
	for((integer = ${user_total}; integer >= 1; integer--))
	do
		user_port=`${jq_file} '.port_password' ${config_user_file} | sed '$d' | sed "1d" | awk -F ":" '{print $1}' | sed -n "${integer}p" | sed -r 's/.*\"(.+)\".*/\1/'`
		user_password=`${jq_file} '.port_password' ${config_user_file} | sed '$d' | sed "1d" | awk -F ":" '{print $2}' | sed -n "${integer}p" | sed -r 's/.*\"(.+)\".*/\1/'`
		user_list_all=${user_list_all}"端口: "${user_port}" 密码: "${user_password}"\n"
	done
	echo && echo -e "用户总数 ${Green_font_prefix}"${user_total}"${Font_color_suffix}"
	echo -e ${user_list_all}
}
# 添加 多端口用户配置
Add_multi_port_user(){
	Set_config_port
	Set_config_password
	sed -i "8 i \"        \"${ssr_port}\":\"${ssr_password}\"," ${config_user_file}
	sed -i "8s/^\"//" ${config_user_file}
	Add_iptables
	Save_iptables
	echo -e "${Info} 多端口用户添加完成 ${Green_font_prefix}[端口: ${ssr_port} , 密码: ${ssr_password}]${Font_color_suffix} "
}
# 修改 多端口用户配置
Modify_multi_port_user(){
	List_multi_port_user
	echo && echo -e "请输入要修改的用户端口"
	read -e -p "(默认: 取消):" modify_user_port
	[[ -z "${modify_user_port}" ]] && echo -e "已取消..." && exit 1
	del_user=`cat ${config_user_file}|grep '"'"${modify_user_port}"'"'`
	if [[ ! -z "${del_user}" ]]; then
		port="${modify_user_port}"
		password=`echo -e ${del_user}|awk -F ":" '{print $NF}'|sed -r 's/.*\"(.+)\".*/\1/'`
		Set_config_port
		Set_config_password
		sed -i 's/"'$(echo ${port})'":"'$(echo ${password})'"/"'$(echo ${ssr_port})'":"'$(echo ${ssr_password})'"/g' ${config_user_file}
		Del_iptables
		Add_iptables
		Save_iptables
		echo -e "${Inof} 多端口用户修改完成 ${Green_font_prefix}[旧: ${modify_user_port}  ${password} , 新: ${ssr_port}  ${ssr_password}]${Font_color_suffix} "
	else
		echo -e "${Error} 请输入正确的端口 !" && exit 1
	fi
}
# 删除 多端口用户配置
Del_multi_port_user(){
	List_multi_port_user
	user_total=`${jq_file} '.port_password' ${config_user_file} | sed '$d' | sed "1d" | wc -l`
	[[ "${user_total}" = "1" ]] && echo -e "${Error} 多端口用户仅剩 1个，不能删除 !" && exit 1
	echo -e "请输入要删除的用户端口"
	read -e -p "(默认: 取消):" del_user_port
	[[ -z "${del_user_port}" ]] && echo -e "已取消..." && exit 1
	del_user=`cat ${config_user_file}|grep '"'"${del_user_port}"'"'`
	if [[ ! -z ${del_user} ]]; then
		port=${del_user_port}
		Del_iptables
		Save_iptables
		del_user_determine=`echo ${del_user:((${#del_user} - 1))}`
		if [[ ${del_user_determine} != "," ]]; then
			del_user_num=$(sed -n -e "/${port}/=" ${config_user_file})
			echo $((${ssr_protocol_param}+0)) &>/dev/null
			del_user_num=$(echo $((${del_user_num}-1)))
			sed -i "${del_user_num}s/,//g" ${config_user_file}
		fi
		sed -i "/${port}/d" ${config_user_file}
		echo -e "${Info} 多端口用户删除完成 ${Green_font_prefix} ${del_user_port} ${Font_color_suffix} "
	else
		echo "${Error} 请输入正确的端口 !" && exit 1
	fi
}
# 手动修改 用户配置
Manually_Modify_Config(){
	SSR_installation_status
	port=`${jq_file} '.server_port' ${config_user_file}`
	vi ${config_user_file}
	if [[ -z "${now_mode}" ]]; then
		ssr_port=`${jq_file} '.server_port' ${config_user_file}`
		Del_iptables
		Add_iptables
	fi
	Restart_SSR
}
# 切换端口模式
Port_mode_switching(){
	SSR_installation_status
	if [[ -z "${now_mode}" ]]; then
		echo && echo -e "	当前模式: ${Green_font_prefix}单端口${Font_color_suffix}" && echo
		echo -e "确定要切换为 多端口模式？[y/N]"
		read -e -p "(默认: n):" mode_yn
		[[ -z ${mode_yn} ]] && mode_yn="n"
		if [[ ${mode_yn} == [Yy] ]]; then
			port=`${jq_file} '.server_port' ${config_user_file}`
			Set_config_all
			Write_configuration_many
			Del_iptables
			Add_iptables
			Save_iptables
			Restart_SSR
		else
			echo && echo "	已取消..." && echo
		fi
	else
		echo && echo -e "	当前模式: ${Green_font_prefix}多端口${Font_color_suffix}" && echo
		echo -e "确定要切换为 单端口模式？[y/N]"
		read -e -p "(默认: n):" mode_yn
		[[ -z ${mode_yn} ]] && mode_yn="n"
		if [[ ${mode_yn} == [Yy] ]]; then
			user_total=`${jq_file} '.port_password' ${config_user_file} | sed '$d' | sed "1d" | wc -l`
			for((integer = 1; integer <= ${user_total}; integer++))
			do
				port=`${jq_file} '.port_password' ${config_user_file} | sed '$d' | sed "1d" | awk -F ":" '{print $1}' | sed -n "${integer}p" | sed -r 's/.*\"(.+)\".*/\1/'`
				Del_iptables
			done
			Set_config_all
			Write_configuration
			Add_iptables
			Restart_SSR
		else
			echo && echo "	已取消..." && echo
		fi
	fi
}
Start_SSR(){
	SSR_installation_status
	check_pid
	[[ ! -z ${PID} ]] && echo -e "${Error} ShadowsocksR 正在运行 !" && exit 1
	/etc/init.d/ssr start
	check_pid
	[[ ! -z ${PID} ]] && View_User
}
Stop_SSR(){
	SSR_installation_status
	check_pid
	[[ -z ${PID} ]] && echo -e "${Error} ShadowsocksR 未运行 !" && exit 1
	/etc/init.d/ssr stop
}
Restart_SSR(){
	SSR_installation_status
	check_pid
	[[ ! -z ${PID} ]] && /etc/init.d/ssr stop
	/etc/init.d/ssr start
	check_pid
	[[ ! -z ${PID} ]] && View_User
}
View_Log(){
	SSR_installation_status
	[[ ! -e ${ssr_log_file} ]] && echo -e "${Error} ShadowsocksR日志文件不存在 !" && exit 1
	echo && echo -e "${Tip} 按 ${Red_font_prefix}Ctrl+C${Font_color_suffix} 终止查看日志" && echo -e "如果需要查看完整日志内容，请用 ${Red_font_prefix}cat ${ssr_log_file}${Font_color_suffix} 命令。" && echo
	tail -f ${ssr_log_file}
}
# 锐速
Configure_Server_Speeder(){
	echo && echo -e "你要做什么？
 ${Green_font_prefix}1.${Font_color_suffix} 安装 锐速
 ${Green_font_prefix}2.${Font_color_suffix} 卸载 锐速
————————
 ${Green_font_prefix}3.${Font_color_suffix} 启动 锐速
 ${Green_font_prefix}4.${Font_color_suffix} 停止 锐速
 ${Green_font_prefix}5.${Font_color_suffix} 重启 锐速
 ${Green_font_prefix}6.${Font_color_suffix} 查看 锐速 状态
 
 注意： 锐速和LotServer不能同时安装/启动！" && echo
	read -e -p "(默认: 取消):" server_speeder_num
	[[ -z "${server_speeder_num}" ]] && echo "已取消..." && exit 1
	if [[ ${server_speeder_num} == "1" ]]; then
		Install_ServerSpeeder
	elif [[ ${server_speeder_num} == "2" ]]; then
		Server_Speeder_installation_status
		Uninstall_ServerSpeeder
	elif [[ ${server_speeder_num} == "3" ]]; then
		Server_Speeder_installation_status
		${Server_Speeder_file} start
		${Server_Speeder_file} status
	elif [[ ${server_speeder_num} == "4" ]]; then
		Server_Speeder_installation_status
		${Server_Speeder_file} stop
	elif [[ ${server_speeder_num} == "5" ]]; then
		Server_Speeder_installation_status
		${Server_Speeder_file} restart
		${Server_Speeder_file} status
	elif [[ ${server_speeder_num} == "6" ]]; then
		Server_Speeder_installation_status
		${Server_Speeder_file} status
	else
		echo -e "${Error} 请输入正确的数字(1-6)" && exit 1
	fi
}
Install_ServerSpeeder(){
	[[ -e ${Server_Speeder_file} ]] && echo -e "${Error} 锐速(Server Speeder) 已安装 !" && exit 1
	cd /root
	#借用91yun.rog的开心版锐速
	wget -N --no-check-certificate https://raw.githubusercontent.com/91yun/serverspeeder/master/serverspeeder.sh
	[[ ! -e "serverspeeder.sh" ]] && echo -e "${Error} 锐速安装脚本下载失败 !" && exit 1
	bash serverspeeder.sh
	sleep 2s
	PID=`ps -ef |grep -v grep |grep "serverspeeder" |awk '{print $2}'`
	if [[ ! -z ${PID} ]]; then
		rm -rf /root/serverspeeder.sh
		rm -rf /root/91yunserverspeeder
		rm -rf /root/91yunserverspeeder.tar.gz
		echo -e "${Info} 锐速(Server Speeder) 安装完成 !" && exit 1
	else
		echo -e "${Error} 锐速(Server Speeder) 安装失败 !" && exit 1
	fi
}
Uninstall_ServerSpeeder(){
	echo "确定要卸载 锐速(Server Speeder)？[y/N]" && echo
	read -e -p "(默认: n):" unyn
	[[ -z ${unyn} ]] && echo && echo "已取消..." && exit 1
	if [[ ${unyn} == [Yy] ]]; then
		chattr -i /serverspeeder/etc/apx*
		/serverspeeder/bin/serverSpeeder.sh uninstall -f
		echo && echo "锐速(Server Speeder) 卸载完成 !" && echo
	fi
}
# LotServer
Configure_LotServer(){
	echo && echo -e "你要做什么？
 ${Green_font_prefix}1.${Font_color_suffix} 安装 LotServer
 ${Green_font_prefix}2.${Font_color_suffix} 卸载 LotServer
————————
 ${Green_font_prefix}3.${Font_color_suffix} 启动 LotServer
 ${Green_font_prefix}4.${Font_color_suffix} 停止 LotServer
 ${Green_font_prefix}5.${Font_color_suffix} 重启 LotServer
 ${Green_font_prefix}6.${Font_color_suffix} 查看 LotServer 状态
 
 注意： 锐速和LotServer不能同时安装/启动！" && echo
	read -e -p "(默认: 取消):" lotserver_num
	[[ -z "${lotserver_num}" ]] && echo "已取消..." && exit 1
	if [[ ${lotserver_num} == "1" ]]; then
		Install_LotServer
	elif [[ ${lotserver_num} == "2" ]]; then
		LotServer_installation_status
		Uninstall_LotServer
	elif [[ ${lotserver_num} == "3" ]]; then
		LotServer_installation_status
		${LotServer_file} start
		${LotServer_file} status
	elif [[ ${lotserver_num} == "4" ]]; then
		LotServer_installation_status
		${LotServer_file} stop
	elif [[ ${lotserver_num} == "5" ]]; then
		LotServer_installation_status
		${LotServer_file} restart
		${LotServer_file} status
	elif [[ ${lotserver_num} == "6" ]]; then
		LotServer_installation_status
		${LotServer_file} status
	else
		echo -e "${Error} 请输入正确的数字(1-6)" && exit 1
	fi
}
Install_LotServer(){
	[[ -e ${LotServer_file} ]] && echo -e "${Error} LotServer 已安装 !" && exit 1
	#Github: https://github.com/0oVicero0/serverSpeeder_Install
	wget --no-check-certificate -qO /tmp/appex.sh "https://raw.githubusercontent.com/0oVicero0/serverSpeeder_Install/master/appex.sh"
	[[ ! -e "/tmp/appex.sh" ]] && echo -e "${Error} LotServer 安装脚本下载失败 !" && exit 1
	bash /tmp/appex.sh 'install'
	sleep 2s
	PID=`ps -ef |grep -v grep |grep "appex" |awk '{print $2}'`
	if [[ ! -z ${PID} ]]; then
		echo -e "${Info} LotServer 安装完成 !" && exit 1
	else
		echo -e "${Error} LotServer 安装失败 !" && exit 1
	fi
}
Uninstall_LotServer(){
	echo "确定要卸载 LotServer？[y/N]" && echo
	read -e -p "(默认: n):" unyn
	[[ -z ${unyn} ]] && echo && echo "已取消..." && exit 1
	if [[ ${unyn} == [Yy] ]]; then
		wget --no-check-certificate -qO /tmp/appex.sh "https://raw.githubusercontent.com/0oVicero0/serverSpeeder_Install/master/appex.sh" && bash /tmp/appex.sh 'uninstall'
		echo && echo "LotServer 卸载完成 !" && echo
	fi
}
# BBR
Configure_BBR(){
	echo && echo -e "  你要做什么？
	
 ${Green_font_prefix}1.${Font_color_suffix} 安装 BBR
————————
 ${Green_font_prefix}2.${Font_color_suffix} 启动 BBR
 ${Green_font_prefix}3.${Font_color_suffix} 停止 BBR
 ${Green_font_prefix}4.${Font_color_suffix} 查看 BBR 状态" && echo
echo -e "${Green_font_prefix} [安装前 请注意] ${Font_color_suffix}
1. 安装开启BBR，需要更换内核，存在更换失败等风险(重启后无法开机)
2. 本脚本仅支持 Debian / Ubuntu 系统更换内核，OpenVZ和Docker 不支持更换内核
3. Debian 更换内核过程中会提示 [ 是否终止卸载内核 ] ，请选择 ${Green_font_prefix} NO ${Font_color_suffix}" && echo
	read -e -p "(默认: 取消):" bbr_num
	[[ -z "${bbr_num}" ]] && echo "已取消..." && exit 1
	if [[ ${bbr_num} == "1" ]]; then
		Install_BBR
	elif [[ ${bbr_num} == "2" ]]; then
		Start_BBR
	elif [[ ${bbr_num} == "3" ]]; then
		Stop_BBR
	elif [[ ${bbr_num} == "4" ]]; then
		Status_BBR
	else
		echo -e "${Error} 请输入正确的数字(1-4)" && exit 1
	fi
}
Install_BBR(){
	[[ ${release} = "centos" ]] && echo -e "${Error} 本脚本不支持 CentOS系统安装 BBR !" && exit 1
	BBR_installation_status
	bash "${BBR_file}"
}
Start_BBR(){
	BBR_installation_status
	bash "${BBR_file}" start
}
Stop_BBR(){
	BBR_installation_status
	bash "${BBR_file}" stop
}
Status_BBR(){
	BBR_installation_status
	bash "${BBR_file}" status
}
# 其他功能
Other_functions(){
	echo && echo -e "  你要做什么？
	
  ${Green_font_prefix}1.${Font_color_suffix} 配置 BBR
  ${Green_font_prefix}2.${Font_color_suffix} 配置 锐速(ServerSpeeder)
  ${Green_font_prefix}3.${Font_color_suffix} 配置 LotServer(锐速母公司)
  注意： 锐速/LotServer/BBR 不支持 OpenVZ！
  注意： 锐速/LotServer/BBR 不能共存！
————————————
  ${Green_font_prefix}4.${Font_color_suffix} 一键封禁 BT/PT/SPAM (iptables)
  ${Green_font_prefix}5.${Font_color_suffix} 一键解封 BT/PT/SPAM (iptables)
  ${Green_font_prefix}6.${Font_color_suffix} 切换 ShadowsocksR日志输出模式
  ——说明：SSR默认只输出错误日志，此项可切换为输出详细的访问日志" && echo
	read -e -p "(默认: 取消):" other_num
	[[ -z "${other_num}" ]] && echo "已取消..." && exit 1
	if [[ ${other_num} == "1" ]]; then
		Configure_BBR
	elif [[ ${other_num} == "2" ]]; then
		Configure_Server_Speeder
	elif [[ ${other_num} == "3" ]]; then
		Configure_LotServer
	elif [[ ${other_num} == "4" ]]; then
		BanBTPTSPAM
	elif [[ ${other_num} == "5" ]]; then
		UnBanBTPTSPAM
	elif [[ ${other_num} == "6" ]]; then
		Set_config_connect_verbose_info
	else
		echo -e "${Error} 请输入正确的数字 [1-6]" && exit 1
	fi
}
# 封禁 BT PT SPAM
BanBTPTSPAM(){
	wget -N --no-check-certificate https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/ban_iptables.sh && chmod +x ban_iptables.sh && bash ban_iptables.sh banall
	rm -rf ban_iptables.sh
}
# 解封 BT PT SPAM
UnBanBTPTSPAM(){
	wget -N --no-check-certificate https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/ban_iptables.sh && chmod +x ban_iptables.sh && bash ban_iptables.sh unbanall
	rm -rf ban_iptables.sh
}
Set_config_connect_verbose_info(){
	SSR_installation_status
	Get_User
	if [[ ${connect_verbose_info} = "0" ]]; then
		echo && echo -e "当前日志模式: ${Green_font_prefix}简单模式（只输出错误日志）${Font_color_suffix}" && echo
		echo -e "确定要切换为 ${Green_font_prefix}详细模式（输出详细连接日志+错误日志）${Font_color_suffix}？[y/N]"
		read -e -p "(默认: n):" connect_verbose_info_ny
		[[ -z "${connect_verbose_info_ny}" ]] && connect_verbose_info_ny="n"
		if [[ ${connect_verbose_info_ny} == [Yy] ]]; then
			ssr_connect_verbose_info="1"
			Modify_config_connect_verbose_info
			Restart_SSR
		else
			echo && echo "	已取消..." && echo
		fi
	else
		echo && echo -e "当前日志模式: ${Green_font_prefix}详细模式（输出详细连接日志+错误日志）${Font_color_suffix}" && echo
		echo -e "确定要切换为 ${Green_font_prefix}简单模式（只输出错误日志）${Font_color_suffix}？[y/N]"
		read -e -p "(默认: n):" connect_verbose_info_ny
		[[ -z "${connect_verbose_info_ny}" ]] && connect_verbose_info_ny="n"
		if [[ ${connect_verbose_info_ny} == [Yy] ]]; then
			ssr_connect_verbose_info="0"
			Modify_config_connect_verbose_info
			Restart_SSR
		else
			echo && echo "	已取消..." && echo
		fi
	fi
}
Update_Shell(){
	sh_new_ver=$(wget --no-check-certificate -qO- -t1 -T3 "https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/ssr.sh"|grep 'sh_ver="'|awk -F "=" '{print $NF}'|sed 's/\"//g'|head -1) && sh_new_type="github"
	[[ -z ${sh_new_ver} ]] && echo -e "${Error} 无法链接到 Github !" && exit 0
	if [[ -e "/etc/init.d/ssr" ]]; then
		rm -rf /etc/init.d/ssr
		Service_SSR
	fi
	wget -N --no-check-certificate "https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/ssr.sh" && chmod +x ssr.sh
	echo -e "脚本已更新为最新版本[ ${sh_new_ver} ] !(注意：因为更新方式为直接覆盖当前运行的脚本，所以可能下面会提示一些报错，无视即可)" && exit 0
}
# 显示 菜单状态
menu_status(){
	if [[ -e ${config_user_file} ]]; then
		check_pid
		if [[ ! -z "${PID}" ]]; then
			echo -e " 当前状态: ${Green_font_prefix}已安装${Font_color_suffix} 并 ${Green_font_prefix}已启动${Font_color_suffix}"
		else
			echo -e " 当前状态: ${Green_font_prefix}已安装${Font_color_suffix} 但 ${Red_font_prefix}未启动${Font_color_suffix}"
		fi
		now_mode=$(cat "${config_user_file}"|grep '"port_password"')
		if [[ -z "${now_mode}" ]]; then
			echo -e " 当前模式: ${Green_font_prefix}单端口${Font_color_suffix}"
		else
			echo -e " 当前模式: ${Green_font_prefix}多端口${Font_color_suffix}"
		fi
	else
		echo -e " 当前状态: ${Red_font_prefix}未安装${Font_color_suffix}"
	fi
}
check_sys
[[ ${release} != "debian" ]] && [[ ${release} != "ubuntu" ]] && [[ ${release} != "centos" ]] && echo -e "${Error} 本脚本不支持当前系统 ${release} !" && exit 1
echo -e "  ShadowsocksR 一键管理脚本 ${Red_font_prefix}[v${sh_ver}]${Font_color_suffix}
  ---- Toyo | doub.io/ss-jc42 ----

  ${Green_font_prefix}1.${Font_color_suffix} 安装 ShadowsocksR
  ${Green_font_prefix}2.${Font_color_suffix} 更新 ShadowsocksR
  ${Green_font_prefix}3.${Font_color_suffix} 卸载 ShadowsocksR
  ${Green_font_prefix}4.${Font_color_suffix} 安装 libsodium(chacha20)
————————————
  ${Green_font_prefix}5.${Font_color_suffix} 查看 账号信息
  ${Green_font_prefix}6.${Font_color_suffix} 显示 连接信息
  ${Green_font_prefix}7.${Font_color_suffix} 设置 用户配置
  ${Green_font_prefix}8.${Font_color_suffix} 手动 修改配置
  ${Green_font_prefix}9.${Font_color_suffix} 切换 端口模式
————————————
 ${Green_font_prefix}10.${Font_color_suffix} 启动 ShadowsocksR
 ${Green_font_prefix}11.${Font_color_suffix} 停止 ShadowsocksR
 ${Green_font_prefix}12.${Font_color_suffix} 重启 ShadowsocksR
 ${Green_font_prefix}13.${Font_color_suffix} 查看 ShadowsocksR 日志
————————————
 ${Green_font_prefix}14.${Font_color_suffix} 其他功能
 ${Green_font_prefix}15.${Font_color_suffix} 升级脚本
 "
menu_status
echo && read -e -p "请输入数字 [1-15]：" num
case "$num" in
	1)
	Install_SSR
	;;
	2)
	Update_SSR
	;;
	3)
	Uninstall_SSR
	;;
	4)
	Install_Libsodium
	;;
	5)
	View_User
	;;
	6)
	View_user_connection_info
	;;
	7)
	Modify_Config
	;;
	8)
	Manually_Modify_Config
	;;
	9)
	Port_mode_switching
	;;
	10)
	Start_SSR
	;;
	11)
	Stop_SSR
	;;
	12)
	Restart_SSR
	;;
	13)
	View_Log
	;;
	14)
	Other_functions
	;;
	15)
	Update_Shell
	;;
	*)
	echo -e "${Error} 请输入正确的数字 [1-15]"
	;;
esac
}

#关闭ecn
closeecn() {
  sed -i '/net.ipv4.tcp_ecn/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv4.tcp_ecn/d' /etc/sysctl.conf

  echo "net.ipv4.tcp_ecn=0" >>/etc/sysctl.d/99-sysctl.conf
  sysctl --system
  echo -e "${Info}关闭ecn结束！"
}

#卸载bbr+锐速
remove_bbr_lotserver() {
  sed -i '/net.ipv4.tcp_ecn/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.core.default_qdisc/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv4.tcp_congestion_control/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv4.tcp_ecn/d' /etc/sysctl.conf
  sed -i '/net.core.default_qdisc/d' /etc/sysctl.conf
  sed -i '/net.ipv4.tcp_congestion_control/d' /etc/sysctl.conf
  sysctl --system

  rm -rf bbrmod

  if [[ -e /appex/bin/lotServer.sh ]]; then
    echo | bash <(wget -qO- https://git.io/lotServerInstall.sh) uninstall
  fi
  clear
  # echo -e "${Info}:清除bbr/lotserver加速完成。"
  # sleep 1s
}

#卸载全部加速
remove_all() {
  rm -rf /etc/sysctl.d/*.conf
  #rm -rf /etc/sysctl.conf
  #touch /etc/sysctl.conf
  if [ ! -f "/etc/sysctl.conf" ]; then
    touch /etc/sysctl.conf
  else
    cat /dev/null >/etc/sysctl.conf
  fi
  sysctl --system
  sed -i '/DefaultTimeoutStartSec/d' /etc/systemd/system.conf
  sed -i '/DefaultTimeoutStopSec/d' /etc/systemd/system.conf
  sed -i '/DefaultRestartSec/d' /etc/systemd/system.conf
  sed -i '/DefaultLimitCORE/d' /etc/systemd/system.conf
  sed -i '/DefaultLimitNOFILE/d' /etc/systemd/system.conf
  sed -i '/DefaultLimitNPROC/d' /etc/systemd/system.conf

  sed -i '/soft nofile/d' /etc/security/limits.conf
  sed -i '/hard nofile/d' /etc/security/limits.conf
  sed -i '/soft nproc/d' /etc/security/limits.conf
  sed -i '/hard nproc/d' /etc/security/limits.conf

  sed -i '/ulimit -SHn/d' /etc/profile
  sed -i '/ulimit -SHn/d' /etc/profile
  sed -i '/required pam_limits.so/d' /etc/pam.d/common-session

  systemctl daemon-reload

  rm -rf bbrmod
  sed -i '/net.ipv4.tcp_retries2/d' /etc/sysctl.conf
  sed -i '/net.ipv4.tcp_slow_start_after_idle/d' /etc/sysctl.conf
  sed -i '/net.ipv4.tcp_fastopen/d' /etc/sysctl.conf
  sed -i '/net.ipv4.tcp_ecn/d' /etc/sysctl.conf
  sed -i '/net.core.default_qdisc/d' /etc/sysctl.conf
  sed -i '/net.ipv4.tcp_congestion_control/d' /etc/sysctl.conf
  sed -i '/fs.file-max/d' /etc/sysctl.conf
  sed -i '/net.core.rmem_max/d' /etc/sysctl.conf
  sed -i '/net.core.wmem_max/d' /etc/sysctl.conf
  sed -i '/net.core.rmem_default/d' /etc/sysctl.conf
  sed -i '/net.core.wmem_default/d' /etc/sysctl.conf
  sed -i '/net.core.netdev_max_backlog/d' /etc/sysctl.conf
  sed -i '/net.core.somaxconn/d' /etc/sysctl.conf
  sed -i '/net.ipv4.tcp_syncookies/d' /etc/sysctl.conf
  sed -i '/net.ipv4.tcp_tw_reuse/d' /etc/sysctl.conf
  sed -i '/net.ipv4.tcp_tw_recycle/d' /etc/sysctl.conf
  sed -i '/net.ipv4.tcp_fin_timeout/d' /etc/sysctl.conf
  sed -i '/net.ipv4.tcp_keepalive_time/d' /etc/sysctl.conf
  sed -i '/net.ipv4.ip_local_port_range/d' /etc/sysctl.conf
  sed -i '/net.ipv4.tcp_max_syn_backlog/d' /etc/sysctl.conf
  sed -i '/net.ipv4.tcp_max_tw_buckets/d' /etc/sysctl.conf
  sed -i '/net.ipv4.tcp_rmem/d' /etc/sysctl.conf
  sed -i '/net.ipv4.tcp_wmem/d' /etc/sysctl.conf
  sed -i '/net.ipv4.tcp_mtu_probing/d' /etc/sysctl.conf
  sed -i '/net.ipv4.ip_forward/d' /etc/sysctl.conf
  sed -i '/fs.inotify.max_user_instances/d' /etc/sysctl.conf
  sed -i '/net.ipv4.tcp_syncookies/d' /etc/sysctl.conf
  sed -i '/net.ipv4.tcp_fin_timeout/d' /etc/sysctl.conf
  sed -i '/net.ipv4.tcp_tw_reuse/d' /etc/sysctl.conf
  sed -i '/net.ipv4.tcp_max_syn_backlog/d' /etc/sysctl.conf
  sed -i '/net.ipv4.ip_local_port_range/d' /etc/sysctl.conf
  sed -i '/net.ipv4.tcp_max_tw_buckets/d' /etc/sysctl.conf
  sed -i '/net.ipv4.route.gc_timeout/d' /etc/sysctl.conf
  sed -i '/net.ipv4.tcp_synack_retries/d' /etc/sysctl.conf
  sed -i '/net.ipv4.tcp_syn_retries/d' /etc/sysctl.conf
  sed -i '/net.core.somaxconn/d' /etc/sysctl.conf
  sed -i '/net.core.netdev_max_backlog/d' /etc/sysctl.conf
  sed -i '/net.ipv4.tcp_timestamps/d' /etc/sysctl.conf
  sed -i '/net.ipv4.tcp_max_orphans/d' /etc/sysctl.conf
  if [[ -e /appex/bin/lotServer.sh ]]; then
    bash <(wget -qO- https://git.io/lotServerInstall.sh) uninstall
  fi
  clear
  echo -e "${Info}:清除加速完成。"
  sleep 1s
}

#优化系统配置
optimizing_system() {
  if [ ! -f "/etc/sysctl.conf" ]; then
    touch /etc/sysctl.conf
  fi
  sed -i '/net.ipv4.tcp_retries2/d' /etc/sysctl.conf
  sed -i '/net.ipv4.tcp_slow_start_after_idle/d' /etc/sysctl.conf
  sed -i '/net.ipv4.tcp_fastopen/d' /etc/sysctl.conf
  sed -i '/fs.file-max/d' /etc/sysctl.conf
  sed -i '/fs.inotify.max_user_instances/d' /etc/sysctl.conf
  sed -i '/net.ipv4.tcp_syncookies/d' /etc/sysctl.conf
  sed -i '/net.ipv4.tcp_fin_timeout/d' /etc/sysctl.conf
  sed -i '/net.ipv4.tcp_tw_reuse/d' /etc/sysctl.conf
  sed -i '/net.ipv4.tcp_max_syn_backlog/d' /etc/sysctl.conf
  sed -i '/net.ipv4.ip_local_port_range/d' /etc/sysctl.conf
  sed -i '/net.ipv4.tcp_max_tw_buckets/d' /etc/sysctl.conf
  sed -i '/net.ipv4.route.gc_timeout/d' /etc/sysctl.conf
  sed -i '/net.ipv4.tcp_synack_retries/d' /etc/sysctl.conf
  sed -i '/net.ipv4.tcp_syn_retries/d' /etc/sysctl.conf
  sed -i '/net.core.somaxconn/d' /etc/sysctl.conf
  sed -i '/net.core.netdev_max_backlog/d' /etc/sysctl.conf
  sed -i '/net.ipv4.tcp_timestamps/d' /etc/sysctl.conf
  sed -i '/net.ipv4.tcp_max_orphans/d' /etc/sysctl.conf
  sed -i '/net.ipv4.ip_forward/d' /etc/sysctl.conf

  echo "net.ipv4.tcp_retries2 = 8
net.ipv4.tcp_slow_start_after_idle = 0
fs.file-max = 1000000
fs.inotify.max_user_instances = 8192
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_tw_reuse = 1
net.ipv4.ip_local_port_range = 1024 65000
net.ipv4.tcp_max_syn_backlog = 16384
net.ipv4.tcp_max_tw_buckets = 6000
net.ipv4.route.gc_timeout = 100
net.ipv4.tcp_syn_retries = 1
net.ipv4.tcp_synack_retries = 1
net.core.somaxconn = 32768
net.core.netdev_max_backlog = 32768
net.ipv4.tcp_timestamps = 0
net.ipv4.tcp_max_orphans = 32768
# forward ipv4
#net.ipv4.ip_forward = 1" >>/etc/sysctl.conf
  sysctl -p
  echo "*               soft    nofile           1000000
*               hard    nofile          1000000" >/etc/security/limits.conf
  echo "ulimit -SHn 1000000" >>/etc/profile
  read -p "需要重启VPS后，才能生效系统优化配置，是否现在重启 ? [Y/n] :" yn
  [ -z "${yn}" ] && yn="y"
  if [[ $yn == [Yy] ]]; then
    echo -e "${Info} VPS 重启中..."
    reboot
  fi
}

optimizing_system_johnrosen1() {
  if [ ! -f "/etc/sysctl.d/99-sysctl.conf" ]; then
    touch /etc/sysctl.d/99-sysctl.conf
  fi
  sed -i '/kernel.pid_max/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/vm.nr_hugepages/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.core.optmem_max/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv4.conf.all.route_localnet/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv4.ip_forward/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv4.conf.all.forwarding/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv4.conf.default.forwarding/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv6.conf.all.forwarding/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv6.conf.default.forwarding/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv6.conf.lo.forwarding/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv6.conf.all.disable_ipv6/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv6.conf.default.disable_ipv6/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv6.conf.lo.disable_ipv6/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv6.conf.all.accept_ra/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv6.conf.default.accept_ra/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv6.conf.default.accept_ra/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.core.netdev_max_backlog/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.core.netdev_budget/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.core.netdev_budget_usecs/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/fs.file-max /d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.core.rmem_max/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.core.wmem_max/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.core.rmem_default/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.core.wmem_default/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.core.somaxconn/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv4.icmp_echo_ignore_all/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv4.icmp_echo_ignore_broadcasts/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv4.icmp_ignore_bogus_error_responses/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv4.conf.all.accept_redirects/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv4.conf.default.accept_redirects/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv4.conf.all.secure_redirects/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv4.conf.default.secure_redirects/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv4.conf.all.send_redirects/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv4.conf.default.send_redirects/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv4.conf.default.rp_filter/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv4.conf.all.rp_filter/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv4.tcp_keepalive_time/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv4.tcp_keepalive_intvl/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv4.tcp_keepalive_probes/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv4.tcp_synack_retries/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv4.tcp_syncookies/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv4.tcp_rfc1337/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv4.tcp_timestamps/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv4.tcp_tw_reuse/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv4.tcp_fin_timeout/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv4.ip_local_port_range/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv4.tcp_max_tw_buckets/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv4.tcp_fastopen/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv4.tcp_rmem/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv4.tcp_wmem/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv4.udp_rmem_min/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv4.udp_wmem_min/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv4.tcp_mtu_probing/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv4.conf.all.arp_ignore /d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv4.conf.default.arp_ignore/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv4.conf.all.arp_announce/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv4.conf.default.arp_announce/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv4.tcp_autocorking/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv4.tcp_slow_start_after_idle/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv4.tcp_max_syn_backlog/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.core.default_qdisc/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv4.tcp_congestion_control/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv4.tcp_notsent_lowat/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv4.tcp_no_metrics_save/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv4.tcp_ecn/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv4.tcp_ecn_fallback/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv4.tcp_frto/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv6.conf.all.accept_redirects/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv6.conf.default.accept_redirects/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/vm.swappiness/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv4.ip_unprivileged_port_start/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/vm.overcommit_memory/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv4.neigh.default.gc_thresh3/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv4.neigh.default.gc_thresh2/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv4.neigh.default.gc_thresh1/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv6.neigh.default.gc_thresh3/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv6.neigh.default.gc_thresh2/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv6.neigh.default.gc_thresh1/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.netfilter.nf_conntrack_max/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.nf_conntrack_max/d' /etc/sysctl.d/99-sysctl.conf

  cat >'/etc/sysctl.d/99-sysctl.conf' <<EOF
#!!! Do not change these settings unless you know what you are doing !!!
net.ipv4.conf.all.route_localnet=1
net.ipv4.ip_forward = 1
net.ipv4.conf.all.forwarding = 1
net.ipv4.conf.default.forwarding = 1

net.ipv6.conf.all.forwarding = 1
net.ipv6.conf.default.forwarding = 1
net.ipv6.conf.lo.forwarding = 1

net.ipv6.conf.all.disable_ipv6 = 0
net.ipv6.conf.default.disable_ipv6 = 0
net.ipv6.conf.lo.disable_ipv6 = 0

net.ipv6.conf.all.accept_ra = 2
net.ipv6.conf.default.accept_ra = 2

net.core.netdev_max_backlog = 100000
net.core.netdev_budget = 50000
net.core.netdev_budget_usecs = 5000
#fs.file-max = 51200
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
net.core.rmem_default = 67108864
net.core.wmem_default = 67108864
net.core.optmem_max = 65536
net.core.somaxconn = 10000

net.ipv4.icmp_echo_ignore_all = 0
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.default.secure_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.default.rp_filter = 0
net.ipv4.conf.all.rp_filter = 0
net.ipv4.tcp_keepalive_time = 1200
net.ipv4.tcp_keepalive_intvl = 15
net.ipv4.tcp_keepalive_probes = 5
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_syncookies = 0
net.ipv4.tcp_rfc1337 = 0
net.ipv4.tcp_timestamps = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 15
net.ipv4.ip_local_port_range = 1024 65535
net.ipv4.tcp_max_tw_buckets = 2000000
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864
net.ipv4.udp_rmem_min = 8192
net.ipv4.udp_wmem_min = 8192
net.ipv4.tcp_mtu_probing = 0

#net.ipv4.conf.all.arp_ignore = 2
#net.ipv4.conf.default.arp_ignore = 2
#net.ipv4.conf.all.arp_announce = 2
#net.ipv4.conf.default.arp_announce = 2

net.ipv4.tcp_autocorking = 0
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_max_syn_backlog = 30000
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_notsent_lowat = 16384
net.ipv4.tcp_no_metrics_save = 1
net.ipv4.tcp_ecn = 2
net.ipv4.tcp_ecn_fallback = 1
net.ipv4.tcp_frto = 0

net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0
vm.swappiness = 1
#net.ipv4.ip_unprivileged_port_start = 0
vm.overcommit_memory = 1
#vm.nr_hugepages=1280
kernel.pid_max=64000
net.ipv4.neigh.default.gc_thresh3=8192
net.ipv4.neigh.default.gc_thresh2=4096
net.ipv4.neigh.default.gc_thresh1=2048
net.ipv6.neigh.default.gc_thresh3=8192
net.ipv6.neigh.default.gc_thresh2=4096
net.ipv6.neigh.default.gc_thresh1=2048
net.ipv4.tcp_max_syn_backlog = 262144
net.netfilter.nf_conntrack_max = 262144
net.nf_conntrack_max = 262144
EOF
  sysctl --system
  echo madvise >/sys/kernel/mm/transparent_hugepage/enabled

  sed -i '/DefaultTimeoutStartSec/d' /etc/systemd/system.conf
  sed -i '/DefaultTimeoutStopSec/d' /etc/systemd/system.conf
  sed -i '/DefaultRestartSec/d' /etc/systemd/system.conf
  sed -i '/DefaultLimitCORE/d' /etc/systemd/system.conf
  sed -i '/DefaultLimitNOFILE/d' /etc/systemd/system.conf
  sed -i '/DefaultLimitNPROC/d' /etc/systemd/system.conf

  cat >'/etc/systemd/system.conf' <<EOF
[Manager]
#DefaultTimeoutStartSec=90s
DefaultTimeoutStopSec=30s
#DefaultRestartSec=100ms
DefaultLimitCORE=infinity
DefaultLimitNOFILE=65535
DefaultLimitNPROC=65535
EOF

  sed -i '/soft nofile/d' /etc/security/limits.conf
  sed -i '/hard nofile/d' /etc/security/limits.conf
  sed -i '/soft nproc/d' /etc/security/limits.conf
  sed -i '/hard nproc/d' /etc/security/limits.conf
  cat >'/etc/security/limits.conf' <<EOF
* soft nofile 65535
* hard nofile 65535
* soft nproc 65535
* hard nproc 65535
EOF
  if grep -q "ulimit" /etc/profile; then
    :
  else
    sed -i '/ulimit -SHn/d' /etc/profile
    sed -i '/ulimit -SHn/d' /etc/profile
    echo "ulimit -SHn 65535" >>/etc/profile
    echo "ulimit -SHu 65535" >>/etc/profile
  fi
  if grep -q "pam_limits.so" /etc/pam.d/common-session; then
    :
  else
    sed -i '/required pam_limits.so/d' /etc/pam.d/common-session
    echo "session required pam_limits.so" >>/etc/pam.d/common-session
  fi
  systemctl daemon-reload
  echo -e "${Info}johnrosen1优化方案应用结束，可能需要重启！"
}

#更新脚本
Update_Shell() {
  echo -e "当前版本为 [ ${sh_ver} ]，开始检测最新版本..."
  sh_new_ver=$(wget -qO- "https://git.io/JYxKU" | grep 'sh_ver="' | awk -F "=" '{print $NF}' | sed 's/\"//g' | head -1)
  [[ -z ${sh_new_ver} ]] && echo -e "${Error} 检测最新版本失败 !" && start_menu
  if [ ${sh_new_ver} != ${sh_ver} ]; then
    echo -e "发现新版本[ ${sh_new_ver} ]，是否更新？[Y/n]"
    read -p "(默认: y):" yn
    [[ -z "${yn}" ]] && yn="y"
    if [[ ${yn} == [Yy] ]]; then
      wget -N "https://${github}/tcpx.sh" && chmod +x tcpx.sh && ./tcpx.sh
      echo -e "脚本已更新为最新版本[ ${sh_new_ver} ] !"
    else
      echo && echo "	已取消..." && echo
    fi
  else
    echo -e "当前已是最新版本[ ${sh_new_ver} ] !"
    sleep 2s && ./tcpx.sh
  fi
}

#切换到卸载内核版本
gototcp() {
  clear
  wget -O tcp.sh "https://git.io/coolspeeda" && chmod +x tcp.sh && ./tcp.sh
}

#切换到秋水逸冰BBR安装脚本
gototeddysun_bbr() {
  clear
  wget https://github.com/teddysun/across/raw/master/bbr.sh && chmod +x bbr.sh && ./bbr.sh
}

#切换到一键DD安装系统脚本 新手勿入
gotodd() {
  clear
  wget -qO ~/Network-Reinstall-System-Modify.sh 'https://github.com/ylx2016/reinstall/raw/master/Network-Reinstall-System-Modify.sh' && chmod a+x ~/Network-Reinstall-System-Modify.sh && bash ~/Network-Reinstall-System-Modify.sh -UI_Options
}

#禁用IPv6
closeipv6() {
  clear
  sed -i '/net.ipv6.conf.all.disable_ipv6/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv6.conf.default.disable_ipv6/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv6.conf.lo.disable_ipv6/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv6.conf.all.disable_ipv6/d' /etc/sysctl.conf
  sed -i '/net.ipv6.conf.default.disable_ipv6/d' /etc/sysctl.conf
  sed -i '/net.ipv6.conf.lo.disable_ipv6/d' /etc/sysctl.conf

  echo "net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1" >>/etc/sysctl.d/99-sysctl.conf
  sysctl --system
  echo -e "${Info}禁用IPv6结束，可能需要重启！"
}

#开启IPv6
openipv6() {
  clear
  sed -i '/net.ipv6.conf.all.disable_ipv6/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv6.conf.default.disable_ipv6/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv6.conf.lo.disable_ipv6/d' /etc/sysctl.d/99-sysctl.conf
  sed -i '/net.ipv6.conf.all.disable_ipv6/d' /etc/sysctl.conf
  sed -i '/net.ipv6.conf.default.disable_ipv6/d' /etc/sysctl.conf
  sed -i '/net.ipv6.conf.lo.disable_ipv6/d' /etc/sysctl.conf

  echo "net.ipv6.conf.all.disable_ipv6 = 0
net.ipv6.conf.default.disable_ipv6 = 0
net.ipv6.conf.lo.disable_ipv6 = 0" >>/etc/sysctl.d/99-sysctl.conf
  sysctl --system
  echo -e "${Info}开启IPv6结束，可能需要重启！"
}

#开始菜单
start_menu() {
  clear
  echo && echo -e " TCP加速 一键安装管理脚本 ${Red_font_prefix}[v${sh_ver}] 不卸内核${Font_color_suffix} from blog.ylx.me 母鸡慎用
 ${Green_font_prefix}0.${Font_color_suffix} 升级脚本
 ${Green_font_prefix}9.${Font_color_suffix} 切换到卸载内核版本		${Green_font_prefix}10.${Font_color_suffix} 切换到一键DD系统脚本
 ${Green_font_prefix}1.${Font_color_suffix} 安装 BBR原版内核
 ${Green_font_prefix}2.${Font_color_suffix} 安装 BBRplus版内核		${Green_font_prefix}5.${Font_color_suffix} 安装 BBRplus新版内核
 ${Green_font_prefix}3.${Font_color_suffix} 安装 Lotserver(锐速)内核	${Green_font_prefix}6.${Font_color_suffix} 安装 Zen官方内核
 ${Green_font_prefix}30.${Font_color_suffix} 安装 官方稳定内核		${Green_font_prefix}31.${Font_color_suffix} 安装 官方最新内核 backports/elrepo
 ${Green_font_prefix}32.${Font_color_suffix} 安装 XANMOD官方内核	${Green_font_prefix}33.${Font_color_suffix} 安装 XANMOD官方高响应内核
 ${Green_font_prefix}11.${Font_color_suffix} 使用BBR+FQ加速		${Green_font_prefix}12.${Font_color_suffix} 使用BBR+FQ_PIE加速 
 ${Green_font_prefix}13.${Font_color_suffix} 使用BBR+CAKE加速
 ${Green_font_prefix}14.${Font_color_suffix} 使用BBR2+FQ加速	 	${Green_font_prefix}15.${Font_color_suffix} 使用BBR2+FQ_PIE加速 
 ${Green_font_prefix}16.${Font_color_suffix} 使用BBR2+CAKE加速  
 ${Green_font_prefix}66.${Font_color_suffix} 关闭ECN
 ${Green_font_prefix}17.${Font_color_suffix} 开启ECN	 		${Green_font_prefix}18.${Font_color_suffix} 关闭ECN
 ${Green_font_prefix}19.${Font_color_suffix} 使用BBRplus+FQ版加速       ${Green_font_prefix}20.${Font_color_suffix} 使用Lotserver(锐速)加速
 ${Green_font_prefix}21.${Font_color_suffix} 系统配置优化	 	${Green_font_prefix}22.${Font_color_suffix} 应用johnrosen1的优化方案
 ${Green_font_prefix}23.${Font_color_suffix} 禁用IPv6	 		${Green_font_prefix}24.${Font_color_suffix} 开启IPv6
 ${Green_font_prefix}51.${Font_color_suffix} 查看排序内核               ${Green_font_prefix}52.${Font_color_suffix} 删除保留指定内核
 ${Green_font_prefix}25.${Font_color_suffix} 卸载全部加速	 	${Green_font_prefix}99.${Font_color_suffix} 退出脚本 
 ----------------------软件专区------------------------------
 ${Green_font_prefix}630.${Font_color_suffix} 安装DNS解锁被解锁端
 ${Green_font_prefix}631.${Font_color_suffix} 安装DNS解锁解锁端
 ${Green_font_prefix}66.${Font_color_suffix} 安装docker+启动
 ${Green_font_prefix}69.${Font_color_suffix} 安装xray0.7.5 ws+tls
 ${Green_font_prefix}690.${Font_color_suffix} 安装xray0.7.5 ws+tls （自选端口）
 ${Green_font_prefix}77.${Font_color_suffix} 不知道什么东西
 ${Green_font_prefix}78.${Font_color_suffix} 安装docker-compos
 ${Green_font_prefix}79.${Font_color_suffix} 安装流媒体lmt
 ${Green_font_prefix}699.${Font_color_suffix} 安装Superior Super Rare（doubi）
 ${Green_font_prefix}698.${Font_color_suffix} Docker管理界面（方便小白）
————————————————————————————————————————————————————————————————" &&
    check_status
  get_system_info
  echo -e " 系统信息: ${Font_color_suffix}$opsy ${Green_font_prefix}$virtual${Font_color_suffix} $arch ${Green_font_prefix}$kern${Font_color_suffix} "
  if [[ ${kernel_status} == "noinstall" ]]; then
    echo -e " 当前状态: ${Green_font_prefix}未安装${Font_color_suffix} 加速内核 ${Red_font_prefix}请先安装内核${Font_color_suffix}"
  else
    echo -e " 当前状态: ${Green_font_prefix}已安装${Font_color_suffix} ${Red_font_prefix}${kernel_status}${Font_color_suffix} 加速内核 , ${Green_font_prefix}${run_status}${Font_color_suffix}"

  fi

  echo -e " 当前拥塞控制算法为: ${Green_font_prefix}${net_congestion_control}${Font_color_suffix} 当前队列算法为: ${Green_font_prefix}${net_qdisc}${Font_color_suffix} "

  read -p " 请输入数字 :" num
  case "$num" in
  0)
    Update_Shell
    ;;
  1)
    check_sys_bbr
    ;;
  2)
    check_sys_bbrplus
    ;;
  3)
    check_sys_Lotsever
    ;;
  5)
    check_sys_bbrplusnew
    ;;
  6)
    check_sys_official_zen
    ;;
  30)
    check_sys_official
    ;;
  31)
    check_sys_official_bbr
    ;;
  32)
    check_sys_official_xanmod
    ;;
  33)
    check_sys_official_xanmod_cacule
    ;;
  9)
    gototcp
    ;;
  10)
    gotodd
    ;;
  11)
    startbbrfq
    ;;
  12)
    startbbrfqpie
    ;;
  13)
    startbbrcake
    ;;
  14)
    startbbr2fq
    ;;
  15)
    startbbr2fqpie
    ;;
  16)
    startbbr2cake
    ;;
  17)
    startecn
    ;;
  18)
    closeecn
    ;;
  19)
    startbbrplus
    ;;
  66)
    installdocker
    ;;
  69)
    dockerxray
    ;;
  690)
    dockerxrayport
    ;;
  699)
    ssrdoubi
    ;;  
  698)
    dockerhome
    ;;  
  77)
    bzd
    ;;
  78)
    docker-compos
    ;;
  79)
    lmt
    ;;   
  20)
    startlotserver
    ;;
  21)
    optimizing_system
    ;;
  630)
    dnsnf
    ;;
  631)
    ndnsnf
    ;;
  22)
    optimizing_system_johnrosen1
    ;;
  23)
    closeipv6
    ;;
  24)
    openipv6
    ;;
  25)
    remove_all
    ;;
  51)
    BBR_grub
    ;;
  52)
    detele_kernel_custom
    ;;
  99)
    exit 1
    ;;
  *)
    clear
    echo -e "${Error}:请输入正确数字 [0-99]"
    sleep 5s
    start_menu
    ;;
  esac
}
#############内核管理组件#############

#删除多余内核
detele_kernel() {
  if [[ "${release}" == "centos" ]]; then
    rpm_total=$(rpm -qa | grep kernel | grep -v "${kernel_version}" | grep -v "noarch" | wc -l)
    if [ "${rpm_total}" ] >"1"; then
      echo -e "检测到 ${rpm_total} 个其余内核，开始卸载..."
      for ((integer = 1; integer <= ${rpm_total}; integer++)); do
        rpm_del=$(rpm -qa | grep kernel | grep -v "${kernel_version}" | grep -v "noarch" | head -${integer})
        echo -e "开始卸载 ${rpm_del} 内核..."
        rpm --nodeps -e ${rpm_del}
        echo -e "卸载 ${rpm_del} 内核卸载完成，继续..."
      done
      echo --nodeps -e "内核卸载完毕，继续..."
    else
      echo -e " 检测到 内核 数量不正确，请检查 !" && exit 1
    fi
  elif [[ "${release}" == "debian" || "${release}" == "ubuntu" ]]; then
    deb_total=$(dpkg -l | grep linux-image | awk '{print $2}' | grep -v "${kernel_version}" | wc -l)
    if [ "${deb_total}" ] >"1"; then
      echo -e "检测到 ${deb_total} 个其余内核，开始卸载..."
      for ((integer = 1; integer <= ${deb_total}; integer++)); do
        deb_del=$(dpkg -l | grep linux-image | awk '{print $2}' | grep -v "${kernel_version}" | head -${integer})
        echo -e "开始卸载 ${deb_del} 内核..."
        apt-get purge -y ${deb_del}
        echo -e "卸载 ${deb_del} 内核卸载完成，继续..."
      done
      echo -e "内核卸载完毕，继续..."
    else
      echo -e " 检测到 内核 数量不正确，请检查 !" && exit 1
    fi
  fi
}

detele_kernel_head() {
  if [[ "${release}" == "centos" ]]; then
    rpm_total=$(rpm -qa | grep kernel-headers | grep -v "${kernel_version}" | grep -v "noarch" | wc -l)
    if [ "${rpm_total}" ] >"1"; then
      echo -e "检测到 ${rpm_total} 个其余head内核，开始卸载..."
      for ((integer = 1; integer <= ${rpm_total}; integer++)); do
        rpm_del=$(rpm -qa | grep kernel-headers | grep -v "${kernel_version}" | grep -v "noarch" | head -${integer})
        echo -e "开始卸载 ${rpm_del} headers内核..."
        rpm --nodeps -e ${rpm_del}
        echo -e "卸载 ${rpm_del} 内核卸载完成，继续..."
      done
      echo --nodeps -e "内核卸载完毕，继续..."
    else
      echo -e " 检测到 内核 数量不正确，请检查 !" && exit 1
    fi
  elif [[ "${release}" == "debian" || "${release}" == "ubuntu" ]]; then
    deb_total=$(dpkg -l | grep linux-headers | awk '{print $2}' | grep -v "${kernel_version}" | wc -l)
    if [ "${deb_total}" ] >"1"; then
      echo -e "检测到 ${deb_total} 个其余head内核，开始卸载..."
      for ((integer = 1; integer <= ${deb_total}; integer++)); do
        deb_del=$(dpkg -l | grep linux-headers | awk '{print $2}' | grep -v "${kernel_version}" | head -${integer})
        echo -e "开始卸载 ${deb_del} headers内核..."
        apt-get purge -y ${deb_del}
        echo -e "卸载 ${deb_del} 内核卸载完成，继续..."
      done
      echo -e "内核卸载完毕，继续..."
    else
      echo -e " 检测到 内核 数量不正确，请检查 !" && exit 1
    fi
  fi
}

detele_kernel_custom() {
  BBR_grub
  read -p " 查看上面内核，请输入需要保留的内核关键词 :" kernel_version
  detele_kernel
  detele_kernel_head
  BBR_grub
}


#更新引导
BBR_grub() {
  if [[ "${release}" == "centos" ]]; then
    if [[ ${version} == "6" ]]; then
      if [ -f "/boot/grub/grub.conf" ]; then
        sed -i 's/^default=.*/default=0/g' /boot/grub/grub.conf
      elif [ -f "/boot/grub/grub.cfg" ]; then
        grub-mkconfig -o /boot/grub/grub.cfg
        grub-set-default 0
      elif [ -f "/boot/efi/EFI/centos/grub.cfg" ]; then
        grub-mkconfig -o /boot/efi/EFI/centos/grub.cfg
        grub-set-default 0
      elif [ -f "/boot/efi/EFI/redhat/grub.cfg" ]; then
        grub-mkconfig -o /boot/efi/EFI/redhat/grub.cfg
        grub-set-default 0
      else
        echo -e "${Error} grub.conf/grub.cfg 找不到，请检查."
        exit
      fi
    elif [[ ${version} == "7" ]]; then
      if [ -f "/boot/grub2/grub.cfg" ]; then
        grub2-mkconfig -o /boot/grub2/grub.cfg
        grub2-set-default 0
      elif [ -f "/boot/efi/EFI/centos/grub.cfg" ]; then
        grub2-mkconfig -o /boot/efi/EFI/centos/grub.cfg
        grub2-set-default 0
      elif [ -f "/boot/efi/EFI/redhat/grub.cfg" ]; then
        grub2-mkconfig -o /boot/efi/EFI/redhat/grub.cfg
        grub2-set-default 0
      else
        echo -e "${Error} grub.cfg 找不到，请检查."
        exit
      fi
    elif [[ ${version} == "8" ]]; then
      if [ -f "/boot/grub2/grub.cfg" ]; then
        grub2-mkconfig -o /boot/grub2/grub.cfg
        grub2-set-default 0
      elif [ -f "/boot/efi/EFI/centos/grub.cfg" ]; then
        grub2-mkconfig -o /boot/efi/EFI/centos/grub.cfg
        grub2-set-default 0
      elif [ -f "/boot/efi/EFI/redhat/grub.cfg" ]; then
        grub2-mkconfig -o /boot/efi/EFI/redhat/grub.cfg
        grub2-set-default 0
      else
        echo -e "${Error} grub.cfg 找不到，请检查."
        exit
      fi
      grubby --info=ALL | awk -F= '$1=="kernel" {print i++ " : " $2}'
    fi
  elif [[ "${release}" == "debian" || "${release}" == "ubuntu" ]]; then
    /usr/sbin/update-grub
    #exit 1
  fi
}

#简单的检查内核
check_kernel() {
  echo -e "${Tip} 鉴于1次人工检查有人不看，下面是2次脚本简易检查内核，开始匹配 /boot/vmlinuz-* 文件"
  ls /boot/vmlinuz-* -I rescue -1 || echo -e "${Error} 没有匹配到 /boot/vmlinuz-* 文件，很有可能没有内核，谨慎重启，在确认没有内核的情况下，你可以尝试按9切换到不卸载内核选择30安装默认内核救急，此时你应该给我反馈！"
}

#############内核管理组件#############

#############系统检测组件#############

#检查系统
check_sys() {
  if [[ -f /etc/redhat-release ]]; then
    release="centos"
  elif cat /etc/issue | grep -q -E -i "debian"; then
    release="debian"
  elif cat /etc/issue | grep -q -E -i "ubuntu"; then
    release="ubuntu"
  elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
    release="centos"
  elif cat /proc/version | grep -q -E -i "debian"; then
    release="debian"
  elif cat /proc/version | grep -q -E -i "ubuntu"; then
    release="ubuntu"
  elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
    release="centos"
  fi

  #from https://github.com/oooldking
  get_opsy() {
    [ -f /etc/redhat-release ] && awk '{print ($1,$3~/^[0-9]/?$3:$4)}' /etc/redhat-release && return
    [ -f /etc/os-release ] && awk -F'[= "]' '/PRETTY_NAME/{print $3,$4,$5}' /etc/os-release && return
    [ -f /etc/lsb-release ] && awk -F'[="]+' '/DESCRIPTION/{print $2}' /etc/lsb-release && return
  }
  get_system_info() {
    cname=$(awk -F: '/model name/ {name=$2} END {print name}' /proc/cpuinfo | sed 's/^[ \t]*//;s/[ \t]*$//')
    #cores=$(awk -F: '/model name/ {core++} END {print core}' /proc/cpuinfo)
    #freq=$(awk -F: '/cpu MHz/ {freq=$2} END {print freq}' /proc/cpuinfo | sed 's/^[ \t]*//;s/[ \t]*$//')
    #corescache=$(awk -F: '/cache size/ {cache=$2} END {print cache}' /proc/cpuinfo | sed 's/^[ \t]*//;s/[ \t]*$//')
    #tram=$(free -m | awk '/Mem/ {print $2}')
    #uram=$(free -m | awk '/Mem/ {print $3}')
    #bram=$(free -m | awk '/Mem/ {print $6}')
    #swap=$(free -m | awk '/Swap/ {print $2}')
    #uswap=$(free -m | awk '/Swap/ {print $3}')
    #up=$(awk '{a=$1/86400;b=($1%86400)/3600;c=($1%3600)/60} {printf("%d days %d hour %d min\n",a,b,c)}' /proc/uptime)
    #load=$(w | head -1 | awk -F'load average:' '{print $2}' | sed 's/^[ \t]*//;s/[ \t]*$//')
    opsy=$(get_opsy)
    arch=$(uname -m)
    #lbit=$(getconf LONG_BIT)
    kern=$(uname -r)

    # disk_size1=$( LANG=C df -hPl | grep -wvE '\-|none|tmpfs|overlay|shm|udev|devtmpfs|by-uuid|chroot|Filesystem' | awk '{print $2}' )
    # disk_size2=$( LANG=C df -hPl | grep -wvE '\-|none|tmpfs|overlay|shm|udev|devtmpfs|by-uuid|chroot|Filesystem' | awk '{print $3}' )
    # disk_total_size=$( calc_disk ${disk_size1[@]} )
    # disk_used_size=$( calc_disk ${disk_size2[@]} )

    #tcpctrl=$(sysctl net.ipv4.tcp_congestion_control | awk -F ' ' '{print $3}')

    virt_check
  }
  virt_check() {
    # if hash ifconfig 2>/dev/null; then
    # eth=$(ifconfig)
    # fi

    virtualx=$(dmesg) 2>/dev/null

    if [[ $(which dmidecode) ]]; then
      sys_manu=$(dmidecode -s system-manufacturer) 2>/dev/null
      sys_product=$(dmidecode -s system-product-name) 2>/dev/null
      sys_ver=$(dmidecode -s system-version) 2>/dev/null
    else
      sys_manu=""
      sys_product=""
      sys_ver=""
    fi

    if grep docker /proc/1/cgroup -qa; then
      virtual="Docker"
    elif grep lxc /proc/1/cgroup -qa; then
      virtual="Lxc"
    elif grep -qa container=lxc /proc/1/environ; then
      virtual="Lxc"
    elif [[ -f /proc/user_beancounters ]]; then
      virtual="OpenVZ"
    elif [[ "$virtualx" == *kvm-clock* ]]; then
      virtual="KVM"
    elif [[ "$cname" == *KVM* ]]; then
      virtual="KVM"
    elif [[ "$cname" == *QEMU* ]]; then
      virtual="KVM"
    elif [[ "$virtualx" == *"VMware Virtual Platform"* ]]; then
      virtual="VMware"
    elif [[ "$virtualx" == *"Parallels Software International"* ]]; then
      virtual="Parallels"
    elif [[ "$virtualx" == *VirtualBox* ]]; then
      virtual="VirtualBox"
    elif [[ -e /proc/xen ]]; then
      virtual="Xen"
    elif [[ "$sys_manu" == *"Microsoft Corporation"* ]]; then
      if [[ "$sys_product" == *"Virtual Machine"* ]]; then
        if [[ "$sys_ver" == *"7.0"* || "$sys_ver" == *"Hyper-V" ]]; then
          virtual="Hyper-V"
        else
          virtual="Microsoft Virtual Machine"
        fi
      fi
    else
      virtual="Dedicated母鸡"
    fi
  }

  #检查依赖
  if [[ "${release}" == "centos" ]]; then
    if (yum list installed ca-certificates | grep '202'); then
      echo 'CA证书检查OK'
    else
      echo 'CA证书检查不通过，处理中'
      yum install ca-certificates -y
      update-ca-trust force-enable
    fi
    if ! type curl >/dev/null 2>&1; then
      echo 'curl 未安装 安装中'
      yum install curl -y
    else
      echo 'curl 已安装，继续'
    fi

    if ! type wget >/dev/null 2>&1; then
      echo 'wget 未安装 安装中'
      yum -y install wget
      yum install curl -y
    else
      echo 'wget 已安装，继续'
    fi

    if ! type dmidecode >/dev/null 2>&1; then
      echo 'dmidecode 未安装 安装中'
      yum install dmidecode -y
    else
      echo 'dmidecode 已安装，继续'
    fi

  elif [[ "${release}" == "debian" || "${release}" == "ubuntu" ]]; then
    if (apt list --installed | grep 'ca-certificates' | grep '202'); then
      echo 'CA证书检查OK'
    else
      echo 'CA证书检查不通过，处理中'
      apt-get update || apt-get --allow-releaseinfo-change update && apt-get install ca-certificates -y
      update-ca-certificates
    fi
    if ! type curl >/dev/null 2>&1; then
      echo 'curl 未安装 安装中'
      apt-get update || apt-get --allow-releaseinfo-change update && apt-get install curl -y
    else
      echo 'curl 已安装，继续'
    fi

    if ! type wget >/dev/null 2>&1; then
      echo 'wget 未安装 安装中'
      apt-get update || apt-get --allow-releaseinfo-change update && apt-get install wget -y
    else
      echo 'wget 已安装，继续'
    fi

    if ! type dmidecode >/dev/null 2>&1; then
      echo 'dmidecode 未安装 安装中'
      apt-get update || apt-get --allow-releaseinfo-change update && apt-get install dmidecode -y
    else
      echo 'dmidecode 已安装，继续'
    fi
  fi
}

#检查Linux版本
check_version() {
  if [[ -s /etc/redhat-release ]]; then
    version=$(grep -oE "[0-9.]+" /etc/redhat-release | cut -d . -f 1)
  else
    version=$(grep -oE "[0-9.]+" /etc/issue | cut -d . -f 1)
  fi
  bit=$(uname -m)
  # if [[ ${bit} = "x86_64" ]]; then
  # bit="x64"
  # else
  # bit="x32"
  # fi
}

#检查安装bbr的系统要求
check_sys_bbr() {
  check_version
  if [[ "${release}" == "centos" ]]; then
    if [[ ${version} == "7" ]]; then
      installbbr
    else
      echo -e "${Error} BBR内核不支持当前系统 ${release} ${version} ${bit} !" && exit 1
    fi
  elif [[ "${release}" == "debian" || "${release}" == "ubuntu" ]]; then
    apt-get --fix-broken install -y && apt-get autoremove -y
    installbbr
  else
    echo -e "${Error} BBR内核不支持当前系统 ${release} ${version} ${bit} !" && exit 1
  fi
}

check_sys_bbrplus() {
  check_version
  if [[ "${release}" == "centos" ]]; then
    if [[ ${version} == "7" ]]; then
      installbbrplus
    else
      echo -e "${Error} BBRplus内核不支持当前系统 ${release} ${version} ${bit} !" && exit 1
    fi
  elif [[ "${release}" == "debian" || "${release}" == "ubuntu" ]]; then
    apt-get --fix-broken install -y && apt-get autoremove -y
    installbbrplus
  else
    echo -e "${Error} BBRplus内核不支持当前系统 ${release} ${version} ${bit} !" && exit 1
  fi
}

check_sys_bbrplusnew() {
  check_version
  yum -y install wget
  if [[ "${release}" == "centos" ]]; then
    #if [[ ${version} == "7" ]]; then
    if [[ ${version} == "7" || ${version} == "8" ]]; then
      installbbrplusnew
    else
      echo -e "${Error} BBRplusNew内核不支持当前系统 ${release} ${version} ${bit} !" && exit 1
    fi
  elif [[ "${release}" == "debian" || "${release}" == "ubuntu" ]]; then
    apt-get --fix-broken install -y && apt-get autoremove -y
    installbbrplusnew
  else
    echo -e "${Error} BBRplusNew内核不支持当前系统 ${release} ${version} ${bit} !" && exit 1
  fi
}

check_sys_xanmod() {
  check_version
  if [[ "${release}" == "centos" ]]; then
    if [[ ${version} == "7" || ${version} == "8" ]]; then
      installxanmod
    else
      echo -e "${Error} xanmod内核不支持当前系统 ${release} ${version} ${bit} !" && exit 1
    fi
  elif [[ "${release}" == "debian" || "${release}" == "ubuntu" ]]; then
    apt-get --fix-broken install -y && apt-get autoremove -y
    installxanmod
  else
    echo -e "${Error} xanmod内核不支持当前系统 ${release} ${version} ${bit} !" && exit 1
  fi
}

#检查安装Lotsever的系统要求
check_sys_Lotsever() {
  check_version
  bit=$(uname -m)
  if [[ ${bit} != "x86_64" ]]; then
    echo -e "${Error} 不支持x86_64以外的系统 !" && exit 1
  fi
  if [[ "${release}" == "centos" ]]; then
    if [[ ${version} == "6" ]]; then
      kernel_version="2.6.32-504"
      installlot
    elif [[ ${version} == "7" ]]; then
      yum -y install net-tools
      kernel_version="4.11.2-1"
      installlot
    else
      echo -e "${Error} Lotsever不支持当前系统 ${release} ${version} ${bit} !" && exit 1
    fi
  elif [[ "${release}" == "debian" ]]; then
    if [[ ${version} == "7" || ${version} == "8" ]]; then
      if [[ ${bit} == "x86_64" ]]; then
        kernel_version="3.16.0-4"
        installlot
      elif [[ ${bit} == "i386" ]]; then
        kernel_version="3.2.0-4"
        installlot
      fi
    elif [[ ${version} == "9" ]]; then
      if [[ ${bit} == "x86_64" ]]; then
        kernel_version="4.9.0-4"
        installlot
      fi
    else
      echo -e "${Error} Lotsever不支持当前系统 ${release} ${version} ${bit} !" && exit 1
    fi
  elif [[ "${release}" == "ubuntu" ]]; then
    if [[ ${version} -ge "12" ]]; then
      if [[ ${bit} == "x86_64" ]]; then
        kernel_version="4.4.0-47"
        installlot
      elif [[ ${bit} == "i386" ]]; then
        kernel_version="3.13.0-29"
        installlot
      fi
    else
      echo -e "${Error} Lotsever不支持当前系统 ${release} ${version} ${bit} !" && exit 1
    fi
  else
    echo -e "${Error} Lotsever不支持当前系统 ${release} ${version} ${bit} !" && exit 1
  fi
}

#检查官方稳定内核并安装
check_sys_official() {
  check_version
  bit=$(uname -m)
  if [[ "${release}" == "centos" ]]; then
    if [[ ${bit} != "x86_64" ]]; then
      echo -e "${Error} 不支持x86_64以外的系统 !" && exit 1
    fi
    if [[ ${version} == "7" ]]; then
      yum install kernel kernel-headers -y --skip-broken
    elif [[ ${version} == "8" ]]; then
      yum install kernel kernel-core kernel-headers -y --skip-broken
    else
      echo -e "${Error} 不支持当前系统 ${release} ${version} ${bit} !" && exit 1
    fi
  elif [[ "${release}" == "debian" ]]; then
    if [[ ${bit} == "x86_64" ]]; then
      apt-get install linux-image-amd64 linux-headers-amd64 -y
    elif [[ ${bit} == "aarch64" ]]; then
      apt-get install linux-image-arm64 linux-headers-arm64 -y
    fi
  elif [[ "${release}" == "ubuntu" ]]; then
    apt-get install linux-image-generic linux-headers-generic -y
  else
    echo -e "${Error} 不支持当前系统 ${release} ${version} ${bit} !" && exit 1
  fi

  BBR_grub
  echo -e "${Tip} 内核安装完毕，请参考上面的信息检查是否安装成功,默认从排第一的高版本内核启动"
}

#检查官方最新内核并安装
check_sys_official_bbr() {
  check_version
  bit=$(uname -m)
  if [[ "${release}" == "centos" ]]; then
    if [[ ${bit} != "x86_64" ]]; then
      echo -e "${Error} 不支持x86_64以外的系统 !" && exit 1
    fi
    rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
    if [[ ${version} == "7" ]]; then
      yum install https://www.elrepo.org/elrepo-release-7.el7.elrepo.noarch.rpm -y
      yum --enablerepo=elrepo-kernel install kernel-ml kernel-ml-headers -y --skip-broken
    elif [[ ${version} == "8" ]]; then
      yum install https://www.elrepo.org/elrepo-release-8.el8.elrepo.noarch.rpm -y
      yum --enablerepo=elrepo-kernel install kernel-ml kernel-ml-headers -y --skip-broken
    else
      echo -e "${Error} 不支持当前系统 ${release} ${version} ${bit} !" && exit 1
    fi
  elif [[ "${release}" == "debian" ]]; then
    if [[ ${version} == "9" ]]; then
      echo "deb http://deb.debian.org/debian stretch-backports main" >/etc/apt/sources.list.d/stretch-backports.list
      apt update
      if [[ ${bit} == "x86_64" ]]; then
        apt -t stretch-backports install linux-image-amd64 linux-headers-amd64 -y
      elif [[ ${bit} == "aarch64" ]]; then
        apt -t stretch-backports install linux-image-arm64 linux-headers-arm64 -y
      fi
    elif [[ ${version} == "10" ]]; then
      echo "deb http://deb.debian.org/debian buster-backports main" >/etc/apt/sources.list.d/buster-backports.list
      apt update
      if [[ ${bit} == "x86_64" ]]; then
        apt -t buster-backports install linux-image-amd64 linux-headers-amd64 -y
      elif [[ ${bit} == "aarch64" ]]; then
        apt -t buster-backports install linux-image-arm64 linux-headers-arm64 -y
      fi
    elif [[ ${version} == "11" ]]; then
      echo "deb http://deb.debian.org/debian bullseye-backports main" >/etc/apt/sources.list.d/bullseye-backports.list
      apt update
      if [[ ${bit} == "x86_64" ]]; then
        apt -t bullseye-backports install linux-image-amd64 linux-headers-amd64 -y
      elif [[ ${bit} == "aarch64" ]]; then
        echo -e "${Error} 暂时不支持aarch64的系统 !" && exit 1
      fi
    else
      echo -e "${Error} 不支持当前系统 ${release} ${version} ${bit} !" && exit 1
    fi
  elif [[ "${release}" == "ubuntu" ]]; then
    echo -e "${Error} ubuntu不会写，你来吧" && exit 1
  else
    echo -e "${Error} 不支持当前系统 ${release} ${version} ${bit} !" && exit 1
  fi

  BBR_grub
  echo -e "${Tip} 内核安装完毕，请参考上面的信息检查是否安装成功,默认从排第一的高版本内核启动"
}

#检查官方xanmod内核并安装
check_sys_official_xanmod() {
  check_version
  if [[ ${bit} != "x86_64" ]]; then
    echo -e "${Error} 不支持x86_64以外的系统 !" && exit 1
  fi
  if [[ "${release}" == "debian" || "${release}" == "ubuntu" ]]; then
    apt-get install gnupg gnupg2 gnupg1 sudo -y
    echo 'deb http://deb.xanmod.org releases main' | sudo tee /etc/apt/sources.list.d/xanmod-kernel.list
    wget -qO - https://dl.xanmod.org/gpg.key | sudo apt-key --keyring /etc/apt/trusted.gpg.d/xanmod-kernel.gpg add -
    apt update && apt install linux-xanmod -y
  else
    echo -e "${Error} 不支持当前系统 ${release} ${version} ${bit} !" && exit 1
  fi

  BBR_grub
  echo -e "${Tip} 内核安装完毕，请参考上面的信息检查是否安装成功,默认从排第一的高版本内核启动"
}

#检查官方xanmod高响应内核并安装
check_sys_official_xanmod_cacule() {
  check_version
  if [[ ${bit} != "x86_64" ]]; then
    echo -e "${Error} 不支持x86_64以外的系统 !" && exit 1
  fi
  if [[ "${release}" == "debian" || "${release}" == "ubuntu" ]]; then
    apt-get install gnupg gnupg2 gnupg1 sudo -y
    echo 'deb http://deb.xanmod.org releases main' | sudo tee /etc/apt/sources.list.d/xanmod-kernel.list
    wget -qO - https://dl.xanmod.org/gpg.key | sudo apt-key --keyring /etc/apt/trusted.gpg.d/xanmod-kernel.gpg add -
    apt update && apt install linux-xanmod-cacule -y
  else
    echo -e "${Error} 不支持当前系统 ${release} ${version} ${bit} !" && exit 1
  fi

  BBR_grub
  echo -e "${Tip} 内核安装完毕，请参考上面的信息检查是否安装成功,默认从排第一的高版本内核启动"
}

#检查debian官方cloud内核并安装
# check_sys_official_debian_cloud() {
# check_version
# if [[ "${release}" == "debian" ]]; then
# if [[ ${version} == "9" ]]; then
# echo "deb http://deb.debian.org/debian stretch-backports main" >/etc/apt/sources.list.d/stretch-backports.list
# apt update
# apt -t stretch-backports install linux-image-cloud-amd64 linux-headers-cloud-amd64 -y
# elif [[ ${version} == "10" ]]; then
# echo "deb http://deb.debian.org/debian buster-backports main" >/etc/apt/sources.list.d/buster-backports.list
# apt update
# apt -t buster-backports install linux-image-cloud-amd64 linux-headers-cloud-amd64 -y
# else
# echo -e "${Error} 不支持当前系统 ${release} ${version} ${bit} !" && exit 1
# fi
# else
# echo -e "${Error} 不支持当前系统 ${release} ${version} ${bit} !" && exit 1
# fi

# BBR_grub
# echo -e "${Tip} 内核安装完毕，请参考上面的信息检查是否安装成功,默认从排第一的高版本内核启动"
# }
#检查cloud内核并安装
# check_sys_cloud(){
# check_version
# if [[ "${release}" == "centos" ]]; then
# if [[ ${version} = "7" ]]; then
# installcloud
# else
# echo -e "${Error} 不支持当前系统 ${release} ${version} ${bit} !" && exit 1
# fi
# elif [[ "${release}" == "debian" || "${release}" == "ubuntu" ]]; then
# installcloud
# else
# echo -e "${Error} 不支持当前系统 ${release} ${version} ${bit} !" && exit 1
# fi
# }

#检查Zen官方内核并安装
check_sys_official_zen() {
  check_version
  if [[ ${bit} != "x86_64" ]]; then
    echo -e "${Error} 不支持x86_64以外的系统 !" && exit 1
  fi
  if [[ "${release}" == "debian" ]]; then
    curl 'https://liquorix.net/add-liquorix-repo.sh' | sudo bash
    apt-get install linux-image-liquorix-amd64 linux-headers-liquorix-amd64 -y
  elif [[ "${release}" == "ubuntu" ]]; then
    add-apt-repository ppa:damentz/liquorix && sudo apt-get update
    apt-get install linux-image-liquorix-amd64 linux-headers-liquorix-amd64 -y
  else
    echo -e "${Error} 不支持当前系统 ${release} ${version} ${bit} !" && exit 1
  fi

  BBR_grub
  echo -e "${Tip} 内核安装完毕，请参考上面的信息检查是否安装成功,默认从排第一的高版本内核启动"
}

#检查系统当前状态
check_status() {
  kernel_version=$(uname -r | awk -F "-" '{print $1}')
  kernel_version_full=$(uname -r)
  net_congestion_control=$(cat /proc/sys/net/ipv4/tcp_congestion_control | awk '{print $1}')
  net_qdisc=$(cat /proc/sys/net/core/default_qdisc | awk '{print $1}')
  #kernel_version_r=$(uname -r | awk '{print $1}')
  # if [[ ${kernel_version_full} = "4.14.182-bbrplus" || ${kernel_version_full} = "4.14.168-bbrplus" || ${kernel_version_full} = "4.14.98-bbrplus" || ${kernel_version_full} = "4.14.129-bbrplus" || ${kernel_version_full} = "4.14.160-bbrplus" || ${kernel_version_full} = "4.14.166-bbrplus" || ${kernel_version_full} = "4.14.161-bbrplus" ]]; then
  if [[ ${kernel_version_full} == *bbrplus* ]]; then
    kernel_status="BBRplus"
    # elif [[ ${kernel_version} = "3.10.0" || ${kernel_version} = "3.16.0" || ${kernel_version} = "3.2.0" || ${kernel_version} = "4.4.0" || ${kernel_version} = "3.13.0"  || ${kernel_version} = "2.6.32" || ${kernel_version} = "4.9.0" || ${kernel_version} = "4.11.2" || ${kernel_version} = "4.15.0" ]]; then
    # kernel_status="Lotserver"
  elif [[ ${kernel_version_full} == *4.9.0-4* || ${kernel_version_full} == *4.15.0-30* || ${kernel_version_full} == *4.8.0-36* || ${kernel_version_full} == *3.16.0-77* || ${kernel_version_full} == *3.16.0-4* || ${kernel_version_full} == *3.2.0-4* || ${kernel_version_full} == *4.11.2-1* || ${kernel_version_full} == *2.6.32-504* || ${kernel_version_full} == *4.4.0-47* || ${kernel_version_full} == *3.13.0-29 || ${kernel_version_full} == *4.4.0-47* ]]; then
    kernel_status="Lotserver"
  elif [[ $(echo ${kernel_version} | awk -F'.' '{print $1}') == "4" ]] && [[ $(echo ${kernel_version} | awk -F'.' '{print $2}') -ge 9 ]] || [[ $(echo ${kernel_version} | awk -F'.' '{print $1}') == "5" ]]; then
    kernel_status="BBR"
  else
    kernel_status="noinstall"
  fi

  if [[ ${kernel_status} == "BBR" ]]; then
    run_status=$(cat /proc/sys/net/ipv4/tcp_congestion_control | awk '{print $1}')
    if [[ ${run_status} == "bbr" ]]; then
      run_status=$(cat /proc/sys/net/ipv4/tcp_congestion_control | awk '{print $1}')
      if [[ ${run_status} == "bbr" ]]; then
        run_status="BBR启动成功"
      else
        run_status="BBR启动失败"
      fi
    elif [[ ${run_status} == "bbr2" ]]; then
      run_status=$(cat /proc/sys/net/ipv4/tcp_congestion_control | awk '{print $1}')
      if [[ ${run_status} == "bbr2" ]]; then
        run_status="BBR2启动成功"
      else
        run_status="BBR2启动失败"
      fi
    elif [[ ${run_status} == "tsunami" ]]; then
      run_status=$(lsmod | grep "tsunami" | awk '{print $1}')
      if [[ ${run_status} == "tcp_tsunami" ]]; then
        run_status="BBR魔改版启动成功"
      else
        run_status="BBR魔改版启动失败"
      fi
    elif [[ ${run_status} == "nanqinlang" ]]; then
      run_status=$(lsmod | grep "nanqinlang" | awk '{print $1}')
      if [[ ${run_status} == "tcp_nanqinlang" ]]; then
        run_status="暴力BBR魔改版启动成功"
      else
        run_status="暴力BBR魔改版启动失败"
      fi
    else
      run_status="未安装加速模块"
    fi

  elif [[ ${kernel_status} == "Lotserver" ]]; then
    if [[ -e /appex/bin/lotServer.sh ]]; then
      run_status=$(bash /appex/bin/lotServer.sh status | grep "LotServer" | awk '{print $3}')
      if [[ ${run_status} == "running!" ]]; then
        run_status="启动成功"
      else
        run_status="启动失败"
      fi
    else
      run_status="未安装加速模块"
    fi
  elif [[ ${kernel_status} == "BBRplus" ]]; then
    run_status=$(cat /proc/sys/net/ipv4/tcp_congestion_control | awk '{print $1}')
    if [[ ${run_status} == "bbrplus" ]]; then
      run_status=$(cat /proc/sys/net/ipv4/tcp_congestion_control | awk '{print $1}')
      if [[ ${run_status} == "bbrplus" ]]; then
        run_status="BBRplus启动成功"
      else
        run_status="BBRplus启动失败"
      fi
    elif [[ ${run_status} == "bbr" ]]; then
      run_status="BBR启动成功"
    else
      run_status="未安装加速模块"
    fi
  fi
}

#############系统检测组件#############
check_sys
check_version
[[ ${release} != "debian" ]] && [[ ${release} != "ubuntu" ]] && [[ ${release} != "centos" ]] && echo -e "${Error} 本脚本不支持当前系统 ${release} !" && exit 1
start_menu