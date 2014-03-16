// This Program demonstrates the roku:ecp or Roku External Control Protocol
// Our goal in this program is to be as simple as possible and run in as many
// environments, with as few dependencies as possible. So we chose the
// C language and simplified the socket code. You will definitely want to
//change this in a production app. We're also printing all the communication
//between this client program  and the Roku box. This is for tutorial purposes.

#include <stdlib.h>
#include <string.h>
#include <stdio.h>

#ifdef WIN32
#include <winsock2.h>
#include <ws2tcpip.h>
#include <winbase.h>
#pragma comment(lib, "ws2_32.lib")
#pragma comment(lib, "kernel32.lib")
#else
#include <unistd.h>
#include <sys/select.h>
#include <sys/time.h>
#include <sys/socket.h>
#include <netdb.h>
#endif

#define RESPONSE_BUFFER_LEN         8192
#define URL_BUFFER_LEN              1024

#define SSDP_MULTICAST              "239.255.255.250"
#define SSDP_PORT                   1900

#define BUTTON_HOME                 "Home"
#define BUTTON_REW                  "Rew"
#define BUTTON_FWD                  "Fwd"
#define BUTTON_PLAY                 "Play"
#define BUTTON_SELECT               "Select"
#define BUTTON_LEFT                 "Left"
#define BUTTON_RIGHT                "Right"
#define BUTTON_DOWN                 "Down"
#define BUTTON_UP                   "Up"
#define BUTTON_BACK                 "Back"
#define BUTTON_INSTANTREPLAY	    "InstantReplay"
#define BUTTON_INFO		    "Info"
#define BUTTON_BACKSPACE	    "Backspace"
#define BUTTON_SEARCH		    "Search"
#define BUTTON_Enter		    "Enter"
#define BUTTON_LIT		    "Lit_"


char buffer[RESPONSE_BUFFER_LEN];
unsigned int len = RESPONSE_BUFFER_LEN;

char url[URL_BUFFER_LEN];
char host[URL_BUFFER_LEN];

int main (int argc, const char * argv[])
{
  int i;
  size_t ret;
  char* hostbegin;
  char* hostend;
  char* portbegin;
  char* portend;
  char  portStr[10];
  int   port;

  char *resp;
  char queryApps[] = 
      "GET /query/apps HTTP/1.0\r\n"
      "\r\n";
  char homeKey[] = 
      "POST /keypress/" BUTTON_HOME  " HTTP/1.0\r\n"
      "\r\n";
  char leftKeyDown[] = 
      "POST /keydown/" BUTTON_LEFT " HTTP/1.0\r\n"
      "\r\n";
  char leftKeyUp[] =
      "POST /keyup/" BUTTON_LEFT " HTTP/1.0\r\n"
      "\r\n";
  char rightKey[] = 
      "POST /keypress/" BUTTON_RIGHT " HTTP/1.0\r\n"
      "\r\n";
  char launchApp[] = 
      "POST /launch/dev?url=http%3A%2F%2Fvideo.ted.com%2Ftalks%2Fpodcast%2FVilayanurRamachandran_2007_480.mp4"
      "&streamformat=mp4 HTTP/1.0\r\n"
      "\r\n";

#ifdef WIN32
  WORD wVersionRequested;
  WSADATA wsaData;
  int err;

  /* Use the MAKEWORD(lowbyte, highbyte) macro declared in Windef.h */
  wVersionRequested = MAKEWORD(2, 2);
  err = WSAStartup(wVersionRequested, &wsaData);
  if (err != 0) {
    /* Tell the user that we could not find a usable */
    /* Winsock DLL.                                  */
    printf("WSAStartup failed with error: %d\n", err);
    return 1;
  }
#endif

  /* Use SSDP to get URL of Roku box (roku:ecp service) */
  ret = ssdp_get_roku_ecp_url(url);

  printf("ret = %d", ret);

  /* Parse out Location url */
  hostbegin = strstr(buffer, "http://") + 7;
  hostend = strstr(hostbegin, ":");
  strncpy(host, hostbegin, hostend-hostbegin);
  host[hostend-hostbegin] = 0;

  portbegin = hostend+1;
  portend = strstr(portbegin, "/");
  strncpy(portStr, portbegin, portend-portbegin);
  portStr[portend-portbegin] = 0;
  port = atoi(portStr);

  ret = http_req_resp(host, port, queryApps, &resp);

  /* Move Cursor to highlight 3rd Icon in (Netflix) on Home screen and pause for 5 seconds */

  ret = http_req_resp(host, port, homeKey, &resp);

  ret = http_req_resp(host, port, leftKeyDown, &resp);

#ifdef WIN32
  Sleep(12000);
#else
  sleep(12);
#endif

  ret = http_req_resp(host, port, leftKeyUp, &resp);

  for (i=0; i<3; i++)
    ret = http_req_resp(host, port, rightKey, &resp);

#ifdef WIN32
  Sleep(5000);
#else
  sleep(5);
#endif

  /* Launch simpevideoplayer dev test App and play a TED mp4 URL */
  /* Must have previously installed simplevideoplayer as the Roku dev app */
  ret = http_req_resp(host, port, launchApp, &resp);

#ifdef WIN32
  WSACleanup();
#endif
}

#define DWORD int
int http_req_resp(char* host, int port, char* req, char** resp)
{
  int sock;
  size_t ret;
  unsigned int socklen;
  struct sockaddr_in sockname;
  struct sockaddr clientsock;
  struct hostent *hostname;
  fd_set fds;
  struct timeval timeout;

  hostname = gethostbyname(host);
  if (hostname == NULL) {
#ifdef WIN32
    DWORD dwError;
    dwError = WSAGetLastError();
    if (dwError != 0) {
      if (dwError == WSAHOST_NOT_FOUND) {
	printf("Host not found\n");
	return 1;
      } else if (dwError == WSANO_DATA) {
	printf("No data record found\n");
	return 1;
      } else {
	printf("Function failed with error: %ld\n", dwError);
	return 1;
      }
    }
#endif
    printf("gethostbyname returns null for host %s", host);
  }
  hostname->h_addrtype = AF_INET;

  if((sock = socket(PF_INET, SOCK_STREAM, 0)) == -1){
    printf("err: socket() failed");
    return -1;
  }

  memset((char*)&sockname, 0, sizeof(sockname));
  sockname.sin_family=AF_INET;
  sockname.sin_port=htons(port);
  sockname.sin_addr.s_addr=*((unsigned long*)(hostname->h_addr_list[0]));

  printf(">>>> %s %d >>>>\n",host,port);
  printf(req);
  printf(">>>>>>>>>>>>>>>>>>>>\n");
  ret=connect(sock, (struct sockaddr*) &sockname, sizeof(sockname));
  ret=send(sock, req, strlen(req), 0);
  if(ret != strlen(req)){
    // We're just returning an error here to make a simple example.
    // Your code will want a robust while loop around the send to account for partial sends
    printf("err:sendto");
    return -1;
  }

  // Your code will want a robust while loop around the recv to account for partial data returns
  FD_ZERO(&fds);
  FD_SET(sock, &fds);
  timeout.tv_sec=10;
  timeout.tv_usec=10;

  if(select(sock+1, &fds, NULL, NULL, &timeout) < 0){
    printf("err:select");
    return -1;
  }

  if(FD_ISSET(sock, &fds)){
    if((len = recv(sock, buffer, sizeof(buffer), 0)) == (size_t)-1){
      printf("err: recvfrom");
      return -1;
    }
    buffer[len]='\0';
    //    close(sock);

    if(strncmp(buffer+9, "200 OK", 6) != 0){
      printf("err: http req parsing ");
    }

    printf("<<<<<<<<<<<<<<<<<<<<\n");
    printf(buffer);
    printf("<<<<<<<<<<<<<<<<<<<<\n");
    resp = (char **)&buffer;
    return 0;

  }else{

    printf("err: no http answer");
    return -1;
  }
}


int ssdp_get_roku_ecp_url(char* url)
{
  int sock;
  size_t ret;
  unsigned int socklen;
  struct sockaddr_in sockname;
  struct sockaddr clientsock;
  struct hostent *hostname = 0;
  char ssdproku[] =
      "M-SEARCH * HTTP/1.1\r\n"
      "Host: 239.255.255.250:1900\r\n"
      "Man: \"ssdp:discover\"\r\n"
      "ST: roku:ecp\r\n"
      "\r\n";
  fd_set fds;
  struct timeval timeout;
  char* urlbegin;
  char* urlend;

  /* SSDP Request */
  hostname = gethostbyname(SSDP_MULTICAST);
  if (!hostname) {
#ifdef WIN32
    DWORD dwError;
    dwError = WSAGetLastError();
    if (dwError != 0) {
      if (dwError == WSAHOST_NOT_FOUND) {
	printf("Host not found\n");
	return 1;
      } else if (dwError == WSANO_DATA) {
	printf("No data record found\n");
	return 1;
      } else {
	printf("Function failed with error: %ld\n", dwError);
	return 1;
      }
    }
#endif
    printf("gethostbyname returns null for host %s", SSDP_MULTICAST);
  }
  hostname->h_addrtype = AF_INET;

  if((sock = socket(PF_INET, SOCK_DGRAM, 0)) == -1){
    printf("err: socket() failed");
    return -1;
  }

  memset((char*)&sockname, 0, sizeof(sockname));
  sockname.sin_family=AF_INET;
  sockname.sin_port=htons(SSDP_PORT);
  sockname.sin_addr.s_addr=*((unsigned long*)(hostname->h_addr_list[0]));

  printf(">>>>>>>>>>>>>>>>>>>>\n");
  printf(ssdproku);
  printf(">>>>>>>>>>>>>>>>>>>>\n");
  ret=sendto(sock, ssdproku, strlen(ssdproku), 0, (struct sockaddr*) &sockname, sizeof(sockname));
  if(ret != strlen(ssdproku)){
    printf("err:sendto");
    return -1;
  }

  /* SSDP Response */
  FD_ZERO(&fds);
  FD_SET(sock, &fds);
  timeout.tv_sec=10;
  timeout.tv_usec=10;

  if(select(sock+1, &fds, NULL, NULL, &timeout) < 0){
    printf("err:select");
    return -1;
  }
  if(FD_ISSET(sock, &fds)){
    socklen=sizeof(clientsock);
    if((len = recvfrom(sock, buffer, len, MSG_PEEK, &clientsock, &socklen)) == (size_t)-1){
      printf("err: recvfrom");
      return -1;
    }
    buffer[len]='\0';
    //    close(sock);

    if(strncmp(buffer, "HTTP/1.1 200 OK", 12) != 0){
      printf("err: ssdp parsing ");
      return -1;
    }

    printf("<<<<<<<<<<<<<<<<<<<<\n");
    printf(buffer);
    printf("<<<<<<<<<<<<<<<<<<<<\n");

    /* Parse out Location url */
    urlbegin = strstr(buffer, "Location: ") + 10;
    urlend = strstr(urlbegin, "/\r\n");
    strncpy(url, urlbegin, urlend-urlbegin);
    url[urlend-urlbegin] = 0;
  } else {
    printf("err: no ssdp answer");
    return -1;
  }
  return 0;
}


