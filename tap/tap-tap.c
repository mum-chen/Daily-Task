#include <error.h>
#include <errno.h>
#include <string.h>
#include <stdio.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/ioctl.h>
#include <arpa/inet.h>
#include <fcntl.h>
#include <linux/if.h>
#include <linux/if_tun.h>

/*
 * dev:		char ifname[IFNAMSIZ]
 * flags	IFF_TAP | IFF_TUN
 */
int tun_alloc(char *dev, int flags, char *ip_str) {

	struct ifreq ifr;
	int fd, sockfd;
	struct sockaddr_in ip_addr;
	char *clonedev = "/dev/net/tun";

	/* open the clone device */
	if( (fd = open(clonedev, O_RDWR)) < 0 )
		goto fail;

	memset(&ifr, 0, sizeof(ifr));


	ifr.ifr_flags = flags;
	if (*dev) strncpy(ifr.ifr_name, dev, IFNAMSIZ);

	/* try to create the device */
	if (ioctl(fd, TUNSETIFF, (void *) &ifr) < 0 ) goto close_tun;

	/* config ethnet interface */
	if((sockfd = socket(AF_INET, SOCK_DGRAM, 0)) < 0) goto close_tun;

	/* setup IFF UP */
	if (ioctl(sockfd, SIOCGIFFLAGS, &ifr) < 0 ) goto close_sock;

	ifr.ifr_flags = IFF_UP | IFF_RUNNING | IFF_PROMISC;
	if (ioctl(sockfd, SIOCSIFFLAGS, &ifr) < 0 ) goto close_sock;

	if (!ip_str) goto success;

	/* setup IFF ip addr */
	ip_addr.sin_family = AF_INET;
	if(inet_pton(AF_INET, ip_str, &ip_addr.sin_addr) < 1) goto close_sock;

	memcpy(&ifr.ifr_addr, &ip_addr, sizeof(struct sockaddr_in));
	if(ioctl(sockfd, SIOCSIFADDR, &ifr) < 0) goto close_sock;

success:
	return fd;
close_sock:
	close(sockfd);
close_tun:
	close(fd);
fail:
	return -1;
}

int main(void)
{
	char name_dst[IFNAMSIZ] = "tap_dst";
	char name_src[IFNAMSIZ] = "tap_src";
	char *ip_dst = "192.168.200.1";
	char *ip_src = "192.168.100.1";

	int tap_dst = tun_alloc(name_dst, IFF_TAP, ip_dst);
	if (tap_dst < 0)
		error(tap_dst, errno, "error in tap_dst");

	int tap_src = tun_alloc(name_src, IFF_TAP, ip_src);
	if (tap_src < 0)
		error(tap_src, errno, "error in tap_src");

	while (1) { }
	return 0;
}
