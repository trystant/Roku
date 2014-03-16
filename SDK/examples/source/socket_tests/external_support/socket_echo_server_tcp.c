#include <sys/socket.h>
#include <netinet/in.h>
#include <stdio.h>
#include <string.h>
int main(int argc, char **argv) {
    if (argc==3) {

        int addr = inet_addr(argv[1]);
        int port = atoi(argv[2]);

        int s1 = socket(PF_INET, SOCK_STREAM, 0);
        struct sockaddr_in me, it;
        int melen = sizeof(me), itlen = sizeof(it);

        memset((char *) &me, 0, sizeof(me));
        me.sin_family = AF_INET;
        me.sin_addr.s_addr = addr;
        me.sin_port = htons(port);

        int optval = 1;
        int opt = setsockopt(s1,SOL_SOCKET,SO_REUSEADDR,&optval,sizeof(optval));
        int bound = bind(s1, (struct sockaddr*)&me, melen);
        if (bound<0) { perror("bind fails: "); return -1; }

        int listening = listen(s1,1);
        if (listening<0) { perror("listen fails: "); return -1;  }
        printf("listening on //%08x:%d/\n",addr,port);
        char buf[128];

        while (1) {
            int s2 = accept(s1, (struct sockaddr*)&it, &itlen);
            if (s2<0) { perror("accept fails: "); break;  }
            printf("accepted connection from //%08x/\n",it.sin_addr.s_addr);
            while (1) {
                memset((char *) &it, 0, sizeof(it));
                memset(buf, 0, sizeof(buf));
                int received = recv(s2, buf, sizeof(buf)-1, 0);
                if (received>0) { buf[received] = 0; printf("received '%s'\n",buf); }
                else if (received==0) { printf("peer closed\n"); break; }
                else { perror("receive fails: "); break; }
                int sent = send(s2, buf, received, 0);
                if (sent<0) { perror("send fails: "); break; }
            }
        }
    } else printf("ses <local ip> <local port>\n");
    return 0;
}
