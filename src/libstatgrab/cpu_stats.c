/* 
 * i-scream central monitoring system
 * http://www.i-scream.org.uk
 * Copyright (C) 2000-2002 i-scream
 * 
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#include <stdio.h>
#include <ukcprog.h>
#include <unistd.h>
#include <stdlib.h>
#include <sys/types.h>
#include <time.h>
#include <string.h>
#include "statgrab.h"
#ifdef SOLARIS
#include <kstat.h>
#include <sys/sysinfo.h>
#endif
#ifdef FREEBSD
#include <sys/sysctl.h>
#include <sys/dkstat.h>
#endif

static cpu_states_t cpu_now;
static int cpu_now_uninit=1;


cpu_states_t *get_cpu_totals(){

#ifdef SOLARIS
        kstat_ctl_t *kc;
        kstat_t *ksp;
        cpu_stat_t cs;

	cpu_now.user=0;
	cpu_now.iowait=0;
	cpu_now.kernel=0;
	cpu_now.idle=0;
	cpu_now.swap=0;
	cpu_now.total=0;
	/* Not stored in solaris */
	cpu_now.nice=0;

        if ((kc = kstat_open()) == NULL) {
                return NULL;
        }
        for (ksp = kc->kc_chain; ksp!=NULL; ksp = ksp->ks_next) {
                if ((strcmp(ksp->ks_module, "cpu_stat")) != 0) continue;
                if (kstat_read(kc, ksp, &cs) == -1) {
                        continue;
                }
		cpu_now.user+=cs.cpu_sysinfo.cpu[CPU_USER];
		cpu_now.iowait+=cs.cpu_sysinfo.cpu[CPU_WAIT];
		cpu_now.kernel+=cs.cpu_sysinfo.cpu[CPU_KERNEL];
		cpu_now.idle+=cs.cpu_sysinfo.cpu[CPU_IDLE];
		cpu_now.swap+=cs.cpu_sysinfo.cpu[CPU_STATES];
	}

	cpu_now.total=cpu_now.user+cpu_now.iowait+cpu_now.kernel+cpu_now.idle+cpu_now.swap;
	cpu_now_uninit=0;

        if((kstat_close(kc)) != 0){
                return NULL;
        }

#endif

	cpu_now.systime=time(NULL);

	return &cpu_now;
}

cpu_states_t *get_cpu_diff(){
	static cpu_states_t cpu_diff;
	cpu_states_t cpu_then, *cpu_tmp;

	if (cpu_now_uninit){
		if((cpu_tmp=get_cpu_totals())==NULL){
		/* Should get_cpu_totals fail */
			return NULL;
		}
		return cpu_tmp;
	}


        cpu_then.user=cpu_now.user;
        cpu_then.kernel=cpu_now.kernel;
        cpu_then.idle=cpu_now.idle;
        cpu_then.iowait=cpu_now.iowait;
        cpu_then.swap=cpu_now.swap;
        cpu_then.nice=cpu_now.nice;
        cpu_then.total=cpu_now.total;
        cpu_then.systime=cpu_now.systime;

	if((cpu_tmp=get_cpu_totals())==NULL){
		return NULL;
	}

	cpu_diff.user = cpu_now.user - cpu_then.user;
	cpu_diff.kernel = cpu_now.kernel - cpu_then.kernel;
	cpu_diff.idle = cpu_now.idle - cpu_then.idle;
	cpu_diff.iowait = cpu_now.iowait - cpu_then.iowait;
	cpu_diff.swap = cpu_now.swap - cpu_then.swap;
	cpu_diff.nice = cpu_now.nice - cpu_then.nice;
	cpu_diff.total = cpu_now.total - cpu_then.total;
	cpu_diff.systime = cpu_now.systime - cpu_then.systime;

	return &cpu_diff;
}

cpu_percent_t *cpu_percent_usage(){
	static cpu_percent_t cpu_usage;
	cpu_states_t *cs_ptr;

	cs_ptr=get_cpu_diff();
	if(cs_ptr==NULL){
		return NULL;
	}

	cpu_usage.user =  ((float)cs_ptr->user / (float)cs_ptr->total)*100;
	cpu_usage.kernel =  ((float)cs_ptr->kernel / (float)cs_ptr->total)*100;
	cpu_usage.idle = ((float)cs_ptr->idle / (float)cs_ptr->total)*100;
	cpu_usage.iowait = ((float)cs_ptr->iowait / (float)cs_ptr->total)*100;
	cpu_usage.swap = ((float)cs_ptr->swap / (float)cs_ptr->total)*100;
	cpu_usage.nice = ((float)cs_ptr->nice / (float)cs_ptr->total)*100;
	cpu_usage.time_taken = cs_ptr->systime;

	return &cpu_usage;

}

