#ifndef HFMU_HFMU_INCLUDED
#define HFMU_HFMU_INCLUDED

#include "HsFFI.h"
#include <stdio.h>
#include "hfmu_stub.h"
#include "fmi/fmi2Functions.h"
#define EXPORT __attribute__((visibility("default")))


static void loaded(void) __attribute__((constructor));
static void loaded(void)
{
  static char *argv[] = { "libHFMU.so", 0 }, **argv_ = argv;
  static int argc = 1;
  hs_init(&argc, &argv_);

  //setup();
}


//WORKS
fmi2Component fmi2Instantiate(fmi2String a , fmi2Type b, fmi2String c, fmi2String d, const fmi2CallbackFunctions* e, fmi2Boolean f, fmi2Boolean g)
{
  printf("hfmu.c: fmi2instantiate\n");
  void* x = fmi2Instantiatee(a, b, c, d, e, f, g);
  if(x == NULL)
    printf("PTR IS NULL\n");
  else
    printf("PTR IS NOT NULL\n");
  return x;
}


// WORKS NOT
//extern fmi2SetupExperimentTYPE fmi2SetupExperiment;

static void unloaded(void) __attribute__((destructor));
static void unloaded(void)
{
  hs_exit();
}

#endif
