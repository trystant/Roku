#include <sys/socket.h>
#include <netinet/in.h>
#include <stdio.h>
#include <string.h>
int main(int argc, char **argv) {
    if (argc==3) {

        int s = socket(PF_INET, SOCK_DGRAM, 0);

        struct sockaddr_in me, it;
        int melen = sizeof(me), itlen = sizeof(it);
        memset((char *) &me, 0, sizeof(me));
        me.sin_family = AF_INET;
        me.sin_addr.s_addr = inet_addr(argv[1]);
        me.sin_port = htons(atoi(argv[2]));

        int bound = bind(s, (struct sockaddr*)&me, melen);
        if (bound<0) { perror("bind fails: "); return -1; }
        printf("bound to //%08x:%d/\n",me.sin_addr.s_addr,(int)ntohs(me.sin_port));

        char buf[128];
        while (1) {

            memset((char *) &it, 0, sizeof(it));
            memset(buf, 0, sizeof(buf));

            int received = recvfrom(s, buf, sizeof(buf)-1, 0, (struct sockaddr*)&it, &itlen);
            if (received<0) { perror("receive fails: "); break; }
            else { buf[received] = 0; printf("received from //%08x/ '%s'\n",it.sin_addr.s_addr,buf); }

            int sent = sendto(s, buf, received, 0, (struct sockaddr*)&it, itlen);
            if (sent<0) { perror("send fails: "); break; }
        }
    } else printf("ses <local ip> <local port>\n");
    return 0;
}
