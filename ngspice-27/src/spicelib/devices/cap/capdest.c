/**********
Copyright 1990 Regents of the University of California.  All rights reserved.
Author: 1985 Thomas L. Quarles
Modified: September 2003 Paolo Nenzi
**********/

#include "ngspice/ngspice.h"
#include "capdefs.h"
#include "ngspice/suffix.h"


void
CAPdestroy(GENmodel **inModel)
{
    CAPmodel *mod = *(CAPmodel**) inModel;

    while (mod) {
        CAPmodel *next_mod = mod->CAPnextModel;
        CAPinstance *inst = mod->CAPinstances;
        while (inst) {
            CAPinstance *next_inst = inst->CAPnextInstance;
            FREE(inst);
            inst = next_inst;
        }
        FREE(mod);
        mod = next_mod;
    }

    *inModel = NULL;
}
