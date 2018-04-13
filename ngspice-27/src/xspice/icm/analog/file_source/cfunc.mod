/*.......1.........2.........3.........4.........5.........6.........7.........8
================================================================================

FILE filesource/cfunc.mod

Copyright 2011
Thomas Sailer

              

AUTHORS                      

    20 May 2011     Thomas Sailer
    03 Sep 2012     Holger Vogt
    27 Feb 2017     Marcel Hendrix


MODIFICATIONS   


SUMMARY

    This file contains the model-specific routines used to
    functionally describe the file source code model used
    to read an array of analog values per time step from a file.


INTERFACES       

    FILE                 ROUTINE CALLED     

    N/A                  N/A                     


REFERENCED FILES

    Inputs from and outputs to ARGS structure.
                     

NON-STANDARD FEATURES

    NONE

===============================================================================*/

/*=== INCLUDE FILES ====================*/

#include <stdio.h>
#include <ctype.h>
#include <stdlib.h>
#include <string.h>

/*=== CONSTANTS ========================*/




/*=== MACROS ===========================*/

#if defined(__MINGW32__) || defined(_MSC_VER)
#define DIR_PATHSEP    "\\"
#else
#define DIR_PATHSEP    "/"
#endif

#if defined(_MSC_VER)
#define strdup _strdup
#define snprintf _snprintf
#endif
  
/*=== LOCAL VARIABLES & TYPEDEFS =======*/                         

struct filesource_state {
    FILE *fp;
    unsigned char atend;
};


typedef struct {

    double   *amplinterval;   /* the storage array for the
                                   amplitude offsets   */

    double   *timeinterval;   /* the storage array for the
                                   time offset   */

    struct filesource_state  *state;   /* the storage array for the
                                          filesource status.    */

} Local_Data_t;

           
/*=== FUNCTION PROTOTYPE DEFINITIONS ===*/




                   
/*==============================================================================

FUNCTION void cm_filesource()

AUTHORS                      

    20 May 2011     Thomas Sailer

MODIFICATIONS   

    07 Sept 2012    Holger Vogt
    27 Feb  2017    Marcel Hendrix

SUMMARY

    This function implements the filesource code model.

INTERFACES       

    FILE                 ROUTINE CALLED     

    N/A                  N/A


RETURNED VALUE
    
    Returns inputs and outputs via ARGS structure.

GLOBAL VARIABLES
    
    NONE

NON-STANDARD FEATURES

    NONE

==============================================================================*/


/*=== CM_FILESOURCE ROUTINE ===*/
                                                   

static void
cm_filesource_callback(ARGS, Mif_Callback_Reason_t reason)
{
    switch (reason) {
    case MIF_CB_DESTROY: {
        Local_Data_t *loc = STATIC_VAR (locdata);
        fclose(loc->state->fp);
        free(loc->state);
        free(loc->amplinterval);
        free(loc->timeinterval);
        free(loc);
        break;
    }
    }
}


void cm_filesource(ARGS)   /* structure holding parms, inputs, outputs, etc.     */
{
    int size = PORT_SIZE(out);
    int amplscalesize;
    int amploffssize;

    Local_Data_t *loc;        /* Pointer to local static data, not to be included
                                       in the state vector */

    if(ANALYSIS == MIF_AC) {
        return;
    }
    if (INIT == 1) {

        int i;

        CALLBACK = cm_filesource_callback;

        /*** allocate static storage for *loc ***/
        STATIC_VAR (locdata) = calloc (1 , sizeof ( Local_Data_t ));
        loc = STATIC_VAR (locdata);

        /* Allocate storage for internal state */
        loc->timeinterval = (double*)calloc(2, sizeof(double));
        loc->amplinterval = (double*)calloc(2 * (size_t) size, sizeof(double));
        loc->state = (struct filesource_state*)malloc(sizeof(struct filesource_state));        

        loc->timeinterval[0] = loc->timeinterval[1] = PARAM_NULL(timeoffset) ? 0.0 : PARAM(timeoffset);
        for (i = 0; i < size; ++i)
            loc->amplinterval[2 * i] = loc->amplinterval[2 * i + 1] = PARAM_NULL(amploffset) ? 0.0 : PARAM(amploffset[i]);
        loc->state->fp = fopen_with_path(PARAM(file), "r");
        loc->state->atend = 0;
        if (!loc->state->fp) {
            char *lbuffer, *p;
            lbuffer = getenv("NGSPICE_INPUT_DIR");
            if (lbuffer && *lbuffer) {
                p = (char*) malloc(strlen(lbuffer) + strlen(DIR_PATHSEP) + strlen(PARAM(file)) + 1);
                sprintf(p, "%s%s%s", lbuffer, DIR_PATHSEP, PARAM(file));
                loc->state->fp = fopen(p, "r");
                free(p);
            } 
            if (!loc->state->fp) {
                cm_message_printf("cannot open file %s", PARAM(file));
                loc->state->atend = 1;
            }
        }
    }

    amplscalesize = PARAM_NULL(amplscale) ? 0 : PARAM_SIZE(amplscale);
    amploffssize = PARAM_NULL(amploffset) ? 0 : PARAM_SIZE(amploffset);
    loc = STATIC_VAR (locdata);

    /* The file pointer is at the same position it was for the last simulator TIME ...
     * If TIME steps backward, for example due to a second invocation of a 'tran' analysis
     *   then we need to rewind the file to start from the beginning.
     */

    if (TIME < loc->timeinterval[0]) {
        rewind(loc->state->fp);
        loc->timeinterval[0] = loc->timeinterval[1] = PARAM_NULL(timeoffset) ? 0.0 : PARAM(timeoffset);
    }

    while (TIME >= loc->timeinterval[1] && !loc->state->atend) {
        char line[512];
        char *cp, *cpdel;
        char *cp2;
        double t;
        int i;

        if (!fgets(line, sizeof(line), loc->state->fp)) {
            loc->state->atend = 1;
            break;
        }
        cpdel = cp = strdup(line);

        /* read the time channel; update the time difference */
        while (*cp && isspace_c(*cp))
            ++cp;
        if (*cp == '#' || *cp == ';') {
            free(cpdel);
            continue;
        }
        t = strtod(cp, &cp2);
        if (cp2 == cp) {
            free(cpdel);
            continue;
        }
        cp = cp2;
        if (!PARAM_NULL(timescale))
            t *= PARAM(timescale);
        if (!PARAM_NULL(timerelative) && PARAM(timerelative) == MIF_TRUE)
            t += loc->timeinterval[1];
        else if (!PARAM_NULL(timeoffset))
            t += PARAM(timeoffset);
        loc->timeinterval[0] = loc->timeinterval[1];
        loc->timeinterval[1] = t;

        /* read the channels; update the amplitude difference of each channel */
        for (i = 0; i < size; ++i)
            loc->amplinterval[2 * i] = loc->amplinterval[2 * i + 1];
        for (i = 0; i < size; ++i) {
            while (*cp && (isspace_c(*cp) || *cp == ','))
                ++cp;
            t = strtod(cp, &cp2);
            if (cp2 == cp)
                break;
            cp = cp2;
            if (i < amplscalesize)
                t *= PARAM(amplscale[i]);
            if (i < amploffssize)
                t += PARAM(amploffset[i]);
            loc->amplinterval[2 * i + 1] = t;
        }
        free(cpdel);
    }
    if (!loc->state->atend && loc->timeinterval[0] <= TIME && TIME <= loc->timeinterval[1]) {
        if (!PARAM_NULL(amplstep) && PARAM(amplstep) == MIF_TRUE) {
            int i;
            for (i = 0; i < size; ++i)
                OUTPUT(out[i]) = loc->amplinterval[2 * i];
        } else {
            double mul0 = (loc->timeinterval[1] - TIME) / (loc->timeinterval[1] - loc->timeinterval[0]);
            double mul1 = 1.0 - mul0;
            int i;
            for (i = 0; i < size; ++i)
                OUTPUT(out[i]) = mul0 * loc->amplinterval[2 * i] + mul1 * loc->amplinterval[2 * i + 1];
        }
    } else {
        int i;
        for (i = 0; i < size; ++i)
            OUTPUT(out[i]) = loc->amplinterval[2 * i + 1];
    }
}
