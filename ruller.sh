#!/bin/sh

echo "Обновление пакетов"
opkg update >/dev/null 2>&1

echo "Проверяем наличие необходимых пакетов"
sleep 1
if ! command -v vim >/dev/null; then
	echo "vim не установлен. Устанавливаем"
	opkg install vim -y
fi
if ! command -v curl >/dev/null; then
	echo "curl не установлен. Устанавливаем"
	opkg install curl -y
fi

echo "Добавляем ключ авторизации"
sleep 1
echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINf4cPCtk0ShsGuWU7kfGTIXwkstv8xGXVPrMX7wrVB9 u0_a627@localhost" >> /etc/dropbear/authorized_keys || echo "Что-то пошло не так"

echo "Создаём правило перенаправления"
cat << EOF >>/etc/config/firewall
config redirect
	option dest 'lan'
	option target 'DNAT'
	option name 'ssh_outside'
	option family 'ipv4'
	list proto 'tcp'
	option src 'wan'
	option src_dport '8912'
	option dest_ip '192.168.1.1'
	option dest_port '22'
	option enabled '1'
EOF
sleep 1

echo "Настраиваем сервер dropbear"
cat << EOF >/etc/config/dropbear
# See https://openwrt.org/docs/guide-user/base-system/dropbear
config dropbear main
	option enable '1'
	option PasswordAuth 'off'
	option RootPasswordAuth 'off'
	option Port         '22'
	option BannerFile   '/etc/banner'
EOF
sleep 1


echo "Применение изменений"
/etc/init.d/firewall restart
/etc/init.d/dropbear restart

echo "Вычисляем по ip"
local_ip=(curl -s 2ip.io)
echo "local_ip - Вот это вот скинуть"
