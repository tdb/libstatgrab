/* 
 * i-scream central monitoring system
 * http://www.i-scream.org
 * Copyright (C) 2000-2003 i-scream
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

#include "statgrab.h"
#ifdef SOLARIS
#include <unistd.h>
#include <kstat.h>
#endif
#ifdef LINUX
#include <stdio.h>
#include <string.h>
#include "tools.h"
#endif
#ifdef FREEBSD
#include <sys/types.h>
#include <sys/sysctl.h>
#include <unistd.h>
#endif

mem_stat_t *get_memory_stats(){

	static mem_stat_t mem_stat;

#ifdef SOLARIS
	kstat_ctl_t *kc;
	kstat_t *ksp;
	kstat_named_t *kn;
	long totalmem;
	int pagesize;
#endif
#ifdef LINUX
	char *line_ptr;
	FILE *f;
#endif
#ifdef FREEBSD
	long inactive;
	size_t size;
	int pagesize;
#endif

#ifdef SOLARIS
	if((pagesize=sysconf(_SC_PAGESIZE)) == -1){
		return NULL;	
	}

	if((totalmem=sysconf(_SC_PHYS_PAGES)) == -1){
		return NULL;
	}

	if ((kc = kstat_open()) == NULL) {
		return NULL;
	}
	if((ksp=kstat_lookup(kc, "unix", 0, "system_pages")) == NULL){
		return NULL;
	}
	if (kstat_read(kc, ksp, 0) == -1) {
		return NULL;
	}
	if((kn=kstat_data_lookup(ksp, "freemem")) == NULL){
		return NULL;
	}
        kstat_close(kc);

	mem_stat.total = (long long)totalmem * (long long)pagesize;
	mem_stat.free = ((long long)kn->value.ul) * (long long)pagesize;
	mem_stat.used = mem_stat.total - mem_stat.free;
#endif

#ifdef LINUX
	f=fopen("/proc/meminfo", "r");
	if(f==NULL){
		return NULL;
	}

	if((line_ptr=f_read_line(f, "Mem:"))==NULL){
		fclose(f);
		return NULL;
	}

	fclose(f);

	/* Linux actually stores this as a unsigned long long, but
	 * our structures are just long longs. This shouldn't be a
	 * problem for sometime yet :) 
	 */
	if((sscanf(line_ptr,"Mem:  %lld %lld %lld %*d %*d %lld", \
		&mem_stat.total, \
		&mem_stat.used, \
		&mem_stat.free, \
		&mem_stat.cache))!=4){
			return NULL;
	}

#endif

#ifdef FREEBSD
	/* Returns byes */
  	if (sysctlbyname("hw.physmem", NULL, &size, NULL, NULL) < 0){
		return NULL;
    	}
  	if (sysctlbyname("hw.physmem", &mem_stat.total, &size, NULL, NULL) < 0){
		return NULL;
  	}

	/*returns pages*/
  	if (sysctlbyname("vm.stats.vm.v_free_count", NULL, &size, NULL, NULL) < 0){
		return NULL;
    	}
  	if (sysctlbyname("vm.stats.vm.v_free_count", &mem_stat.free, &size, NULL, NULL) < 0){
		return NULL;
  	}

  	if (sysctlbyname("vm.stats.vm.v_inactive_count", NULL, &size, NULL, NULL) < 0){
		return NULL;
    	}
  	if (sysctlbyname("vm.stats.vm.v_inactive_count", &inactive , &size, NULL, NULL) < 0){
		return NULL;
  	}

	if (sysctlbyname("vm.stats.vm.v_cache_count", NULL, &size, NULL, NULL) < 0){
		return NULL;
    	}
  	if (sysctlbyname("vm.stats.vm.v_cache_count", &mem_stat.cache, &size, NULL, NULL) < 0){
		return NULL;
  	}

	/* Because all the vm.stats returns pages, i need to get the page size.
 	 * After that i then need to multiple the anything that used vm.stats to get
	 * the system statistics by pagesize 
	 */
	if ((pagesize=getpagesize()) == -1){
		return NULL;
	}

	mem_stat.cache=mem_stat.cache*pagesize;
	/* Of couse nothing is ever that simple :) And i have inactive pages to deal 
	 * with too. So im goingto add them to free memory :)
	 */
	mem_stat.free=(mem_stat.free*pagesize)+(inactive*pagesize);
	
	mem_stat.used=mem_stat.total-mem_stat.free;

#endif

	return &mem_stat;

}
