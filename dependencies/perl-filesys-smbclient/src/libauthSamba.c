#include <stdio.h>
#include <string.h>
#include "libauthSamba.h"

char User[100];
char Password[100];
char Workgroup[100];

/*-----------------------------------------------------------------------------
 * set_fn
 *---------------------------------------------------------------------------*/
void set_fn(char *workgroup,
	    char *username,
	    char *password)
{  
#ifdef VERBOSE
  printf("set_fn\n");
#endif

  strcpy(User, username);
  strcpy(Password, password);
  /* set workgroup only when set */
  if (workgroup[0] && workgroup[0] != 0) {
#ifdef VERBOSE
    fprintf("Workgroup is set to %s", workgroup);
#endif
    strcpy(Workgroup, workgroup);
  }
}

/*-----------------------------------------------------------------------------
 * auth_fn
 *---------------------------------------------------------------------------*/
void auth_fn(const char *server, 
	     const char *share,
	     char *workgroup, int wgmaxlen,
	     char *username, int unmaxlen,
	     char *password, int pwmaxlen) {

#ifdef VERBOSE
  printf("auth_fn\n");
#endif

  /* set workgroup only when set */
  if (Workgroup[0] && Workgroup[0] != 0) {
#ifdef VERBOSE
    fprintf("Workgroup is set to %s", Workgroup);
#endif
    strcpy(workgroup, Workgroup);
    wgmaxlen = 100;
  }
  strcpy(username, User);
  unmaxlen = 100;
  strcpy(password, Password);
  pwmaxlen = 100;

#ifdef VERBOSE
  fprintf(stdout, "username: [%s]\n", username);
  fprintf(stdout, "password: [%s]\n", password);
  fprintf(stdout, "workgroup: [%s]\n", workgroup);
#endif


}
