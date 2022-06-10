#!/bin/bash

RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
PLAIN="\033[0m"

red(){
    echo -e "\033[31m\033[01m$1\033[0m"
}

green(){
    echo -e "\033[32m\033[01m$1\033[0m"
}

yellow(){
    echo -e "\033[33m\033[01m$1\033[0m"
}

open_ports(){
    systemctl stop firewalld.service 2>/dev/null
    systemctl disable firewalld.service 2>/dev/null
    setenforce 0 2>/dev/null
    ufw disable 2>/dev/null
    iptables -P INPUT ACCEPT 2>/dev/null
    iptables -P FORWARD ACCEPT 2>/dev/null
    iptables -P OUTPUT ACCEPT 2>/dev/null
    iptables -t nat -F 2>/dev/null
    iptables -t mangle -F 2>/dev/null
    iptables -F 2>/dev/null
    iptables -X 2>/dev/null
    netfilter-persistent save 2>/dev/null
    green "VPS的防火墙端口已放行！"
}

bbr_script(){
    virt=$(systemd-detect-virt)
    TUN=$(cat /dev/net/tun 2>&1 | tr '[:upper:]' '[:lower:]')
    if [ ${virt} =~ "kvm"|"zvm"|"microsoft"|"xen"|"vmware" ]; then
        wget -N --no-check-certificate "https://raw.githubusercontents.com/chiakge/Linux-NetSpeed/master/tcp.sh" && chmod +x tcp.sh && ./tcp.sh
    elif [ ${virt} == "openvz" ]; then
        if [[ ! $TUN =~ 'in bad state' ]] && [[ ! $TUN =~ '处于错误状态' ]] && [[ ! $TUN =~ 'Die Dateizugriffsnummer ist in schlechter Verfassung' ]]; then
            wget -N --no-check-certificate https://raw.githubusercontents.com/Misaka-blog/tun-script/master/tun.sh && bash tun.sh
        else
            wget -N --no-check-certificate https://raw.githubusercontents.com/mzz2017/lkl-haproxy/master/lkl-haproxy.sh && bash lkl-haproxy.sh
        fi
    else
        red "抱歉，你的VPS虚拟化架构暂时不支持bbr加速脚本"
    fi
}

v6_dns64(){
    wg-quick down wgcf 2>/dev/null
    v66=`curl -s6m8 https://ip.gs -k`
    v44=`curl -s4m8 https://ip.gs -k`
    if [[ -z $v44 && -n $v66 ]]; then
        echo -e "nameserver 2a01:4f8:c2c:123f::1" > /etc/resolv.conf
        green "设置DNS64服务器成功！"
    else
        red "非纯IPv6 VPS，设置DNS64服务器失败！"
    fi
    wg-quick up wgcf 2>/dev/null
}

warp_script(){
    green "请选择你接下来使用的脚本"
    echo "1. Misaka-WARP"
    echo "2. fscarmen"
    echo "3. fscarmen-docker"
    echo "4. fscarmen warp解锁奈飞流媒体脚本"
    echo "5. P3TERX"
    echo "0. 返回主菜单"
    echo ""
    read -rp "请输入选项:" warpNumberInput
	case $warpNumberInput in
        1) wget -N https://raw.githubusercontents.com/Misaka-blog/Misaka-WARP-Script/master/misakawarp.sh && bash misakawarp.sh ;;
        2) wget -N https://raw.githubusercontents.com/fscarmen/warp/main/menu.sh && bash menu.sh ;;
        3) wget -N https://raw.githubusercontents.com/fscarmen/warp/main/docker.sh && bash docker.sh ;;
        4) bash <(curl -sSL https://raw.githubusercontents.com/fscarmen/warp_unlock/main/unlock.sh) ;;
        5) bash <(curl -fsSL https://raw.githubusercontents.com/P3TERX/warp.sh/main/warp.sh) menu ;;
        0) menu ;;
    esac
}

setChinese(){
    chattr -i /etc/locale.gen
    cat > '/etc/locale.gen' << EOF
zh_CN.UTF-8 UTF-8
zh_TW.UTF-8 UTF-8
en_US.UTF-8 UTF-8
ja_JP.UTF-8 UTF-8
EOF
    locale-gen
    update-locale
    chattr -i /etc/default/locale
    cat > '/etc/default/locale' << EOF
LANGUAGE="zh_CN.UTF-8"
LANG="zh_CN.UTF-8"
LC_ALL="zh_CN.UTF-8"
EOF
    export LANGUAGE="zh_CN.UTF-8"
    export LANG="zh_CN.UTF-8"
    export LC_ALL="zh_CN.UTF-8"
}

aapanel(){
    if [[ $SYSTEM = "CentOS" ]]; then
        yum install -y wget && wget -O install.sh http://www.aapanel.com/script/install_6.0_en.sh && bash install.sh forum
    elif [[ $SYSTEM = "Debian" ]]; then
        wget -O install.sh http://www.aapanel.com/script/install-ubuntu_6.0_en.sh && bash install.sh forum
    else
        wget -O install.sh http://www.aapanel.com/script/install-ubuntu_6.0_en.sh && sudo bash install.sh forum
    fi
}

xui() {
    echo "                            "
    green "请选择你接下来使用的X-ui面板版本"
    echo "1. 使用X-ui官方原版"
    echo "2. 使用Misaka魔改版"
    echo "3. 使用FranzKafkaYu魔改版"
    echo "0. 返回主菜单"
    read -rp "请输入选项:" xuiNumberInput
    case "$xuiNumberInput" in
        1) bash <(curl -Ls https://raw.githubusercontents.com/vaxilu/x-ui/master/install.sh) ;;
        2) wget -N --no-check-certificate https://raw.githubusercontents.com/Misaka-blog/x-ui/master/install.sh && bash install.sh ;;
        3) bash <(curl -Ls https://raw.githubusercontents.com/FranzKafkaYu/x-ui/master/install.sh) ;;
        0) menu ;;
    esac
}

qlpanel(){
    [[ -z $(docker -v 2>/dev/null) ]] && curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun
    read -rp "请输入将要安装的青龙面板容器名称：" qlPanelName
    read -rp "请输入外网访问端口：" qlHTTPPort
    docker run -dit --name $qlPanelName --hostname $qlPanelName --restart always -p $qlHTTPPort:5700 -v $PWD/QL/config:/ql/config -v $PWD/QL/log:/ql/log -v $PWD/QL/db:/ql/db -v $PWD/QL/scripts:/ql/scripts -v $PWD/QL/jbot:/ql/jbot whyour/qinglong:latest
    wg-quick down wgcf 2>/dev/null
    v66=`curl -s6m8 https://ip.gs -k`
    v44=`curl -s4m8 https://ip.gs -k`
    yellow "青龙面板安装成功！！！"
    if [[ -n $v44 && -z $v66 ]]; then
        green "IPv4访问地址为：http://$v44:$qlHTTPPort"
    elif [[ -n $v66 && -z $v44 ]]; then
        green "IPv6访问地址为：http://[$v66]:$qlHTTPPort"
    elif [[ -n $v44 && -n $v66 ]]; then
        green "IPv4访问地址为：http://$v44:$qlHTTPPort"
        green "IPv6访问地址为：http://[$v66]:$qlHTTPPort"
    fi
    yellow "请稍等1-3分钟，等待青龙面板容器启动"
    wg-quick up wgcf 2>/dev/null
}

serverstatus() {
    wget -N https://raw.githubusercontents.com/cokemine/ServerStatus-Hotaru/master/status.sh
    echo "                            "
    green "请选择你需要安装探针的客户端类型"
    echo "1. 服务端"
    echo "2. 监控端"
    echo "0. 返回主页"
    echo "                            "
	read -rp "请输入选项:" menuNumberInput1
    case "$menuNumberInput1" in
        1) bash status.sh s ;;
        2) bash status.sh c ;;
        0) menu ;;
    esac
}

menu(){
    clear
    echo "#############################################################"
    echo -e "#                 ${RED}Misaka Linux Toolbox${PLAIN}                     #"
    echo -e "# ${GREEN}作者${PLAIN}: Misaka No                                           #"
    echo -e "# ${GREEN}网址${PLAIN}: https://owo.misaka.rest                             #"
    echo -e "# ${GREEN}论坛${PLAIN}: https://vpsgo.co                                    #"
    echo -e "# ${GREEN}TG群${PLAIN}: https://t.me/misakanetcn                            #"
    echo -e "# ${GREEN}GitHub${PLAIN}: https://github.com/Misaka-blog                    #"
    echo -e "# ${GREEN}Bitbucket${PLAIN}: https://bitbucket.org/misakano7545             #"
    echo -e "# ${GREEN}GitLab${PLAIN}: https://gitlab.com/misaka-blog                    #"
    echo "#############################################################"
    echo ""
    echo -e " ${GREEN}1.${PLAIN} 系统相关"
    echo -e " ${GREEN}2.${PLAIN} 面板相关"
    echo -e " ${GREEN}3.${PLAIN} 节点相关"
    echo -e " ${GREEN}4.${PLAIN} 性能测试"
    echo -e " ${GREEN}5.${PLAIN} VPS探针"
    echo " -------------"
    echo -e " ${GREEN}9.${PLAIN} 更新脚本"
    echo -e " ${GREEN}0.${PLAIN} 退出脚本"
    echo ""
    read -rp " 请输入选项 [0-9]:" menuInput
    case $menuInput in
        1) menu1 ;;
        2) menu2 ;;
        3) menu3 ;;
        4) menu4 ;;
        5) menu5 ;;
        *) exit 1 ;;
    esac
}

menu1(){
    clear
    echo "#############################################################"
    echo -e "#                 ${RED}Misaka Linux Toolbox${PLAIN}                     #"
    echo -e "# ${GREEN}作者${PLAIN}: Misaka No                                           #"
    echo -e "# ${GREEN}网址${PLAIN}: https://owo.misaka.rest                             #"
    echo -e "# ${GREEN}论坛${PLAIN}: https://vpsgo.co                                    #"
    echo -e "# ${GREEN}TG群${PLAIN}: https://t.me/misakanetcn                            #"
    echo -e "# ${GREEN}GitHub${PLAIN}: https://github.com/Misaka-blog                    #"
    echo -e "# ${GREEN}Bitbucket${PLAIN}: https://bitbucket.org/misakano7545             #"
    echo -e "# ${GREEN}GitLab${PLAIN}: https://gitlab.com/misaka-blog                    #"
    echo "#############################################################"
    echo ""
    echo -e " ${GREEN}1.${PLAIN} 开放系统防火墙端口"
    echo -e " ${GREEN}2.${PLAIN} 修改登录方式为 root + 密码"
    echo -e " ${GREEN}3.${PLAIN} Screen 后台任务管理"
    echo -e " ${GREEN}4.${PLAIN} BBR加速系列脚本"
    echo -e " ${GREEN}5.${PLAIN} 纯IPv6 VPS设置DNS64服务器"
    echo -e " ${GREEN}6.${PLAIN} 设置CloudFlare WARP"
    echo -e " ${GREEN}7.${PLAIN} 下载并安装Docker"
    echo -e " ${GREEN}8.${PLAIN} Acme.sh 证书申请"
    echo -e " ${GREEN}9.${PLAIN} CF Argo Tunnel隧道穿透"
    echo -e " ${GREEN}10.${PLAIN} Ngrok 内网穿透"
    echo -e " ${GREEN}11.${PLAIN} 修改Linux系统软件源"
    echo -e " ${GREEN}12.${PLAIN} 切换系统语言为中文"
    echo -e " ${GREEN}13.${PLAIN} OpenVZ VPS启用TUN模块"
    echo " -------------"
    echo -e " ${GREEN}0.${PLAIN} 返回主菜单"
    echo ""
    read -rp " 请输入选项 [0-13]:" menuInput
    case $menuInput in
        1) open_ports ;;
        2) wget -N --no-check-certificate https://raw.githubusercontents.com/Misaka-blog/rootLogin/master/root.sh && bash root.sh ;;
        3) wget -N --no-check-certificate https://raw.githubusercontents.com/Misaka-blog/screenManager/master/screen.sh && bash screen.sh ;;
        4) bbr_script ;;
        5) v6_dns64 ;;
        6) warp_script ;;
        7) curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun ;;
        8) wget -N --no-check-certificate https://raw.githubusercontents.com/Misaka-blog/acme-1key/master/acme1key.sh && bash acme1key.sh ;;
        9) wget -N --no-check-certificate https://raw.githubusercontents.com/Misaka-blog/argo-tunnel-script/master/argo.sh && bash argo.sh ;;
        10) wget -N --no-check-certificate https://raw.githubusercontents.com/Misaka-blog/Ngrok-1key/master/ngrok.sh && bash ngrok.sh ;;
        11) bash <(curl -sSL https://cdn.jsdelivr.net/gh/SuperManito/LinuxMirrors@main/ChangeMirrors.sh) ;;
        12) setChinese ;;
        13) wget -N --no-check-certificate https://raw.githubusercontents.com/Misaka-blog/tun-script/master/tun.sh && bash tun.sh ;;
        *) exit 1 ;;
    esac
}

menu2(){
    clear
    echo "#############################################################"
    echo -e "#                 ${RED}Misaka Linux Toolbox${PLAIN}                     #"
    echo -e "# ${GREEN}作者${PLAIN}: Misaka No                                           #"
    echo -e "# ${GREEN}网址${PLAIN}: https://owo.misaka.rest                             #"
    echo -e "# ${GREEN}论坛${PLAIN}: https://vpsgo.co                                    #"
    echo -e "# ${GREEN}TG群${PLAIN}: https://t.me/misakanetcn                            #"
    echo -e "# ${GREEN}GitHub${PLAIN}: https://github.com/Misaka-blog                    #"
    echo -e "# ${GREEN}Bitbucket${PLAIN}: https://bitbucket.org/misakano7545             #"
    echo -e "# ${GREEN}GitLab${PLAIN}: https://gitlab.com/misaka-blog                    #"
    echo "#############################################################"
    echo ""
    echo -e " ${GREEN}1.${PLAIN} aapanel面板"
    echo -e " ${GREEN}2.${PLAIN} x-ui面板"
    echo -e " ${GREEN}3.${PLAIN} aria2(面板为远程链接)"
    echo -e " ${GREEN}4.${PLAIN} CyberPanel面板"
    echo -e " ${GREEN}5.${PLAIN} 青龙面板"
    echo -e " ${GREEN}6.${PLAIN} Trojan面板"
    echo " -------------"
    echo -e " ${GREEN}0.${PLAIN} 返回主菜单"
    echo ""
    read -rp " 请输入选项 [0-6]:" menuInput
    case $menuInput in
        1) aapanel ;;
        2) xui ;;
        3) ${PACKAGE_INSTALL[int]} ca-certificates && wget -N git.io/aria2.sh && chmod +x aria2.sh && bash aria2.sh ;;
        4) sh <(curl https://cyberpanel.net/install.sh || wget -O - https://cyberpanel.net/install.sh) ;;
        5) qlpanel ;;
        6) source <(curl -sL https://git.io/trojan-install) ;;
        0) menu ;;
        *) exit 1 ;;
    esac
}

menu3(){
    clear
    echo "#############################################################"
    echo -e "#                 ${RED}Misaka Linux Toolbox${PLAIN}                     #"
    echo -e "# ${GREEN}作者${PLAIN}: Misaka No                                           #"
    echo -e "# ${GREEN}网址${PLAIN}: https://owo.misaka.rest                             #"
    echo -e "# ${GREEN}论坛${PLAIN}: https://vpsgo.co                                    #"
    echo -e "# ${GREEN}TG群${PLAIN}: https://t.me/misakanetcn                            #"
    echo -e "# ${GREEN}GitHub${PLAIN}: https://github.com/Misaka-blog                    #"
    echo -e "# ${GREEN}Bitbucket${PLAIN}: https://bitbucket.org/misakano7545             #"
    echo -e "# ${GREEN}GitLab${PLAIN}: https://gitlab.com/misaka-blog                    #"
    echo "#############################################################"
    echo ""
    echo -e " ${GREEN}1.${PLAIN} mack-a"
    echo -e " ${GREEN}2.${PLAIN} wulabing v2ray"
    echo -e " ${GREEN}3.${PLAIN} wulabing xray (Nginx前置)"
    echo -e " ${GREEN}4.${PLAIN} wulabing xray (Xray前置)"
    echo -e " ${GREEN}5.${PLAIN} misaka xray"
    echo -e " ${GREEN}6.${PLAIN} teddysun shadowsocks"
    echo -e " ${GREEN}7.${PLAIN} telegram mtproxy"
    echo " -------------"
    echo -e " ${GREEN}0.${PLAIN} 返回主菜单"
    echo ""
    read -rp " 请输入选项 [0-6]:" menuInput
    case $menuInput in
        1) wget -P /root -N --no-check-certificate "https://raw.githubusercontents.com/mack-a/v2ray-agent/master/install.sh" && chmod 700 /root/install.sh && /root/install.sh ;;
        2) wget -N --no-check-certificate -q -O install.sh "https://raw.githubusercontents.com/wulabing/V2Ray_ws-tls_bash_onekey/master/install.sh" && chmod +x install.sh && bash install.sh ;;
        3) wget -N --no-check-certificate -q -O install.sh "https://raw.githubusercontents.com/wulabing/Xray_onekey/nginx_forward/install.sh" && chmod +x install.sh && bash install.sh ;;
        4) wget -N --no-check-certificate -q -O install.sh "https://raw.githubusercontents.com/wulabing/Xray_onekey/main/install.sh" && chmod +x install.sh && bash install.sh ;;
        5) wget -N --no-check-certificate https://raw.githubusercontents.com/Misaka-blog/Xray-script/master/xray.sh && bash xray.sh ;;
        6) wget --no-check-certificate -O shadowsocks-all.sh https://raw.githubusercontents.com/teddysun/shadowsocks_install/master/shadowsocks-all.sh && chmod +x shadowsocks-all.sh && ./shadowsocks-all.sh 2>&1 | tee shadowsocks-all.log ;;
        7) mkdir /home/mtproxy && cd /home/mtproxy && curl -s -o mtproxy.sh https://raw.githubusercontents.com/sunpma/mtp/master/mtproxy.sh && chmod +x mtproxy.sh && bash mtproxy.sh && bash mtproxy.sh start
        0) menu ;;
        *) exit 1 ;;
    esac
}

menu4(){
    clear
    echo "#############################################################"
    echo -e "#                 ${RED}Misaka Linux Toolbox${PLAIN}                     #"
    echo -e "# ${GREEN}作者${PLAIN}: Misaka No                                           #"
    echo -e "# ${GREEN}网址${PLAIN}: https://owo.misaka.rest                             #"
    echo -e "# ${GREEN}论坛${PLAIN}: https://vpsgo.co                                    #"
    echo -e "# ${GREEN}TG群${PLAIN}: https://t.me/misakanetcn                            #"
    echo -e "# ${GREEN}GitHub${PLAIN}: https://github.com/Misaka-blog                    #"
    echo -e "# ${GREEN}Bitbucket${PLAIN}: https://bitbucket.org/misakano7545             #"
    echo -e "# ${GREEN}GitLab${PLAIN}: https://gitlab.com/misaka-blog                    #"
    echo "#############################################################"
    echo ""
    echo -e " ${GREEN}1.${PLAIN} VPS测试 (misakabench)"
    echo -e " ${GREEN}2.${PLAIN} VPS测试 (bench.sh)"
    echo -e " ${GREEN}3.${PLAIN} VPS测试 (superbench)"
    echo -e " ${GREEN}4.${PLAIN} VPS测试 (lemonbench)"
    echo -e " ${GREEN}5.${PLAIN} VPS测试 (融合怪全测)"
    echo -e " ${GREEN}6.${PLAIN} 流媒体检测"
    echo -e " ${GREEN}7.${PLAIN} 三网测速"
    echo " -------------"
    echo -e " ${GREEN}0.${PLAIN} 返回主菜单"
    echo ""
    read -rp " 请输入选项 [0-7]:" menuInput
    case $menuInput in
        1) bash <(curl -Lso- https://cdn.jsdelivr.net/gh/Misaka-blog/misakabench@master/misakabench.sh) ;;
        2) wget -qO- bench.sh | bash ;;
        3) wget -qO- --no-check-certificate https://raw.githubusercontents.com/oooldking/script/master/superbench.sh | bash ;;
        4) curl -fsL https://ilemonra.in/LemonBenchIntl | bash -s fast ;;
        5) bash <(wget -qO- --no-check-certificate https://gitlab.com/spiritysdx/za/-/raw/main/ecs.sh) ;;
        6) bash <(curl -L -s https://raw.githubusercontents.com/lmc999/RegionRestrictionCheck/main/check.sh) ;;
        7) bash <(curl -Lso- https://git.io/superspeed.sh) ;;
        0) menu ;;
        *) exit 1 ;;
    esac
}

menu5(){
    clear
    echo "#############################################################"
    echo -e "#                 ${RED}Misaka Linux Toolbox${PLAIN}                     #"
    echo -e "# ${GREEN}作者${PLAIN}: Misaka No                                           #"
    echo -e "# ${GREEN}网址${PLAIN}: https://owo.misaka.rest                             #"
    echo -e "# ${GREEN}论坛${PLAIN}: https://vpsgo.co                                    #"
    echo -e "# ${GREEN}TG群${PLAIN}: https://t.me/misakanetcn                            #"
    echo -e "# ${GREEN}GitHub${PLAIN}: https://github.com/Misaka-blog                    #"
    echo -e "# ${GREEN}Bitbucket${PLAIN}: https://bitbucket.org/misakano7545             #"
    echo -e "# ${GREEN}GitLab${PLAIN}: https://gitlab.com/misaka-blog                    #"
    echo "#############################################################"
    echo ""
    echo -e " ${GREEN}1.${PLAIN} 哪吒面板"
    echo -e " ${GREEN}2.${PLAIN} 可乐ServerStatus-Horatu"
    echo " -------------"
    echo -e " ${GREEN}0.${PLAIN} 返回主菜单"
    echo ""
    read -rp " 请输入选项 [0-2]:" menuInput
    case $menuInput in
        1) curl -L https://raw.githubusercontents.com/naiba/nezha/master/script/install.sh -o nezha.sh && chmod +x nezha.sh && bash nezha.sh ;;
        0) menu ;;
        *) exit 1 ;;
    esac
}

menu