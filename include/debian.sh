function bootstrap {
	mkdir $INSTALL/etc
	echo nameserver 8.8.8.8 > $INSTALL/etc/resolv.conf
	debootstrap --include locales --arch amd64 $RELNAME $INSTALL $BASEURL
}

function configure-debian {
	configure-append <<EOF
fakefiles="initctl invoke-rc.d restart start stop start-stop-daemon service"
for f in \$fakefiles; do
	ln -s /bin/true /tmp/\$f
done
export DEBIAN_FRONTEND=noninteractive;

[ -f /etc/locale.gen ] && echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen

locale-gen en_US.UTF-8
dpkg-reconfigure locales

PATH=/tmp/:\$PATH apt-get update
PATH=/tmp/:\$PATH apt-get upgrade -y
PATH=/tmp/:\$PATH apt-get install -y vim openssh-server ca-certificates man net-tools less
PATH=/tmp/:\$PATH apt-get purge -y ureadahead eject ntpdate resolvconf
usermod -L root

if [ "$DISTNAME" == "devuan" ] || [ $RELVER -lt 9 ]; then

rm -f /etc/ssh/ssh_host_*
cat > /etc/init.d/generate_ssh_keys <<"GENSSH"
#!/bin/bash
ssh-keygen -f /etc/ssh/ssh_host_rsa_key -t rsa -N ''
ssh-keygen -f /etc/ssh/ssh_host_dsa_key -t dsa -N ''
ssh-keygen -f /etc/ssh/ssh_host_ecdsa_key -t ecdsa -N ''
ssh-keygen -f /etc/ssh/ssh_host_ed25519_key -t ed25519 -N ''
rm -f /etc/init.d/generate_ssh_keys
GENSSH

chmod a+x /etc/init.d/generate_ssh_keys
update-rc.d generate_ssh_keys defaults

fi

> /etc/resolv.conf

apt-get clean
for f in \$fakefiles; do
	rm -f /tmp/\$f
done

if [ -f /etc/systemd/system.conf ] ; then
	sed -i 's/#DefaultTimeoutStartSec=90s/DefaultTimeoutStartSec=900s/' /etc/systemd/system.conf
fi
EOF
}
