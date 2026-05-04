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

  snprintf(User, sizeof(User), "%s", username);
  snprintf(Password, sizeof(Password), "%s", password);
  /* set workgroup only when set */
  if (workgroup && *workgroup) {
#ifdef VERBOSE
    printf("Workgroup is set to %s\n", workgroup);
#endif
    snprintf(Workgroup, sizeof(Workgroup), "%s", workgroup);
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
  if (*Workgroup && workgroup) {
#ifdef VERBOSE
    printf("Workgroup is set to %s\n", Workgroup);
#endif
    snprintf(workgroup, wgmaxlen, "%s", Workgroup);
  }
  if (username) snprintf(username, unmaxlen, "%s", User);
  if (password) snprintf(password, pwmaxlen, "%s", Password);

#ifdef VERBOSE
  fprintf(stdout, "username: [%s]\n", username ? username : "(null)");
  fprintf(stdout, "password: [%s]\n", password ? password : "(null)");
  fprintf(stdout, "workgroup: [%s]\n", workgroup ? workgroup : "(null)");
#endif


}
