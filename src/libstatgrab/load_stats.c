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

#include "statgrab.h"
#include <stdio.h>
#include <stdlib.h>
#ifdef SOLARIS
#include <sys/loadavg.h>
#endif
#include "ukcprog.h"

load_stat_t *get_load_stats(){

	static load_stat_t load_stat;

	double loadav[3];
#if !defined(HAVE_GETLOADAVG) && defined(LINUX)
	FILE *f;
	char *loadavg;
	char *load_p;
#endif

#if !defined(HAVE_GETLOADAVG) && defined(LINUX)
	if ((f=fopen("/proc/loadavg", "r" ))==NULL) {
		errf("Failed to open load averages (%m)");
		return NULL;
	}

	if((fscanf(f,"%lf %lf %lf", &loadav[0], &loadav[1], &loadav[2])) != 3){
		errf("Failed to read in sufficent loads");
		return NULL;
	}

	if ((fclose(f)) != 0) {
		errf("Failed to close file (%m).");
		return NULL;
  	}
#else
  	if((getloadavg(loadav,3)) == -1){
    		errf("Failed to get load averages (%m)");
  	}
#endif

	load_stat.min1=loadav[0];
	load_stat.min5=loadav[1];
	load_stat.min15=loadav[2];

	return &load_stat;

}
