/**********
Copyright 1990 Regents of the University of California.  All rights reserved.
Author: 1985 Hong J. Park, Thomas L. Quarles
**********/

#include "ngspice/ngspice.h"
#include "bsim2def.h"
#include "ngspice/suffix.h"


void
B2destroy(GENmodel **inModel)
{
    B2model *mod = *(B2model**) inModel;

    while (mod) {
        B2model *next_mod = mod->B2nextModel;
        B2instance *inst = mod->B2instances;
        while (inst) {
            B2instance *next_inst = inst->B2nextInstance;
            FREE(inst);
            inst = next_inst;
        }
        FREE(mod);
        mod = next_mod;
    }

    *inModel = NULL;
}
