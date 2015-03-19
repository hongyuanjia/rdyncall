#ifndef DYNTYPE_H
#define DYNTYPE_H

#ifdef __cplusplus
extern "C" {
#endif

#include "stddef.h"

size_t     dtSize       (const char* signature);
size_t     dtAlign      (const char* signature);

#ifdef __cplusplus
}
#endif

#endif /* DYNTYPE_H */

