#include <sys/socket.h>
#include <netinet/in.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define ADDRSIZE sizeof(struct sockaddr_in)

struct sockaddr *makeAddr(const char* addr, const char* port) {
    struct sockaddr_in * this_sockaddr = (struct sockaddr_in *)malloc(ADDRSIZE);
    if (this_sockaddr) {
        int this_addr = inet_addr(addr);
        short this_port = htons(atoi(port));
        memset((char *) this_sockaddr, 0, ADDRSIZE);
        this_sockaddr->sin_family = AF_INET;
        this_sockaddr->sin_addr.s_addr = this_addr;
        this_sockaddr->sin_port = this_port;
    }
    return (struct sockaddr*)this_sockaddr;
}

const char * displayAddr(struct sockaddr * saddr) {
    static char strAddr[128];
    struct sockaddr_in *in = (struct sockaddr_in *)saddr;
    int port = ntohs(in->sin_port);
    int addr = ntohl(in->sin_addr.s_addr);
    sprintf(strAddr,"%d.%d.%d.%d:%d",
        (addr&0xff000000)>>24, (addr&0x00ff0000)>>16, (addr&0x0000ff00)>>8, (addr&0x000000ff), port);
    return strAddr;
}

int main(int argc, char **argv) {
    if (argc!=3 && argc!=5) { printf("sect <remote ip> <remote port> [<local ip> <local port>]\n"); return 0; }

    struct sockaddr* it = makeAddr(argv[1],argv[2]);
    if (!it) { perror("creating remote address fails"); return -1; }

    struct sockaddr* me = 0;
    if (argc==5) {
        me = makeAddr(argv[3],argv[4]);
        if (!me) { perror("creating local address fails"); return -1; }
    }

    const char* title = "TCP echo client";
    char buf[128];
    int buf_len = sizeof(buf)-1;

    int connect_count = 0;

    while (1) {
        int s = socket(PF_INET, SOCK_STREAM, 0);
        if (s<0) { perror("creating socket fails"); break; }

        if (me) {
            int optval = 1;
            int opt = setsockopt(s, SOL_SOCKET, SO_REUSEADDR, &optval, sizeof(optval));
            int bound = bind(s, me, ADDRSIZE);
            if (bound<0) { perror("bind fails"); break; }
            printf("bound on %s\n",displayAddr(me));
        }

        int connected = connect(s, it, ADDRSIZE);
        sprintf(buf,"connection on %s ", displayAddr(it));
        if (connected<0) { strncat(buf,"fails",sizeof(buf)); perror(buf); break;  }
        strncat(buf,"succeeds",sizeof(buf)); printf("%s\n", buf);
        ++connect_count;

        int message_count = 0;

        while (1) {
            sprintf(buf,"%s: connection #%d, message #%d", title, connect_count, ++message_count);
            printf("sending '%s'\n",buf);
            int sent = send(s, buf, strlen(buf), 0);
            if (sent<0) { perror("send fails"); break; }
            printf("sent '%s'\n",buf);

            int received = recv(s, buf, buf_len, 0);
            if (received<0) { perror("receive fails"); break; }
            if (received==0) { printf("peer closed\n"); break; }
            buf[received] = 0; printf("received '%s'\n",buf);

            sleep(1);
        }
        close(s);
    }
    free(it);
    if (me) free(me);
    return 0;
}
