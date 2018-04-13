/**********
Copyright 1992 Regents of the University of California.  All rights
reserved.
Author: 1992 Charles Hough
**********/

#include "ngspice/ngspice.h"
#include "txldefs.h"
#include "ngspice/suffix.h"


void
TXLdestroy(GENmodel **inModel)
{
    TXLmodel *mod = *(TXLmodel **) inModel;

    while (mod) {
        TXLmodel *next_mod = mod->TXLnextModel;
        TXLinstance *inst = mod->TXLinstances;
        while (inst) {
            TXLinstance *next_inst = inst->TXLnextInstance;
            FREE(inst);
            inst = next_inst;
        }
        FREE(mod);
        mod = next_mod;
    }

    *inModel = NULL;
}
