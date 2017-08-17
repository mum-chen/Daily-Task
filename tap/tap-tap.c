#include <error.h>
#include <errno.h>
#include <string.h>
#include <stdio.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/ioctl.h>
#include <sys/epoll.h>
#include <arpa/inet.h>
#include <fcntl.h>
#include <linux/if.h>
#include <linux/if_tun.h>

#define DEBUG_ON	0
#define BUFFER_SIZE	4096

#define name_dst "tap_dst"
#define name_src "tap_src"
#define ip_dst   "192.168.200.1"
#define ip_src   "192.168.100.1"
static int tfdset[2]; /* tap fd set */

#if (defined(DEBUG_ON) && DEBUG_ON)
enum PORT_TYPE{
	PORT_SRC = 1,
	PORT_DST = 2,
	PORT_UNKNOWN = 3,
};

static int port_type(const int fd)
{
	if (fd == tfdset[0])
		return PORT_SRC;
	else if (fd == tfdset[1])
		return PORT_DST;
	else
		return PORT_UNKNOWN;
}
#endif

struct tap_device {
	int fd;

	char ip[16];
	char name[IFNAMSIZ];

	int length;
	struct epoll_event event;
};

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

static int tap_init(struct tap_device *tap, char* ethname, char *ip)
{
	tap->fd = tun_alloc(ethname, IFF_TAP, ip);
	if (tap->fd < 0)
		error(tap->fd, errno, "error in tap");

	tap->event.events = EPOLLIN;
	tap->event.data.fd = tap->fd;
	return 0;
}

static void register_fd(const int src_fd, const int dst_fd)
{
	printf("src %d, dst %d\n", src_fd, dst_fd);
	tfdset[0] = src_fd;
	tfdset[1] = dst_fd;
}

static int another_tfd(const int fd)
{
	if (fd == tfdset[0])
		return tfdset[1];
	else if (fd == tfdset[1])
		return tfdset[0];
	else
		return -1;
}

static inline void sendto_another(const int fd)
{
	int len, another;
	unsigned char buff[BUFFER_SIZE];
	len = read(fd, buff, sizeof(buff));

	another = another_tfd(fd);
	len = write(another, buff, len);

#if (defined(DEBUG_ON) && DEBUG_ON)
	switch (port_type(fd)) {
	case PORT_SRC:
		printf("receive %s:%d, len %d;\n", "tap_src", fd, len);
		break;
	case PORT_DST:
		printf("receive %s:%d, len %d;\n", "tap_dst", fd, len);
		break;
	default:
		printf("receive %s:%d, len %d;\n", "unknown", fd, len);
		break;
	}
#endif
}

int main(void)
{
	int epollfd, nfds, n;
	struct tap_device src, dst;
	struct epoll_event events[2];

	tap_init(&src, name_dst, ip_dst);
	tap_init(&dst, name_src, ip_src);
	register_fd(src.fd, dst.fd);

	epollfd = epoll_create(2);
	if (epollfd == -1)
		goto fail;


	if (epoll_ctl(epollfd, EPOLL_CTL_ADD, src.fd, &src.event) == -1)
		goto fail;

	if (epoll_ctl(epollfd, EPOLL_CTL_ADD, dst.fd, &dst.event) == -1)
		goto fail;

	printf("tap-tap start\n");
	while (1) {
		nfds = epoll_wait(epollfd, events, 2, -1);
		if (nfds == -1)
			goto fail;

		for (n = 0; n < nfds; n++) {
			sendto_another(events[n].data.fd);
		}
	}
fail:
	close(dst.fd);
	close(src.fd);
	error(-1, errno, "error");
	return 0;
}
