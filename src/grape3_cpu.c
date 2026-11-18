/*
 * Experimental GRAPE-3 Fortran ABI compatibility shim.
 * Implements CPU direct-summation gravity and per-chip neighbour lists.
 * NOT a hardware-accurate emulator. Test/validation use only.
 * Copyright (c) 2026. MIT License, see LICENSE.
 */
#include <math.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAX_PARTICLES 131073
#define MAX_CHIPS 32
#define NEIGHBOUR_UNION_LIMIT 1022

static double xj[MAX_PARTICLES][3];
static double mj[MAX_PARTICLES];
static double h2[MAX_CHIPS];
static double eps2;
static int nj;
static int ni_last;
static int nbl_count[MAX_CHIPS];
static int nbl[MAX_CHIPS][MAX_PARTICLES];
static int union_count;
static bool initialized;

static void die(const char *message) {
    fprintf(stderr, "GRAPE-3 CPU compatibility error: %s\n", message);
    exit(EXIT_FAILURE);
}
static void check_initialized(void) {
    if (!initialized) die("call g3init before using the interface");
}

/* Note the trailing underscores: these are gfortran's conventional F77 symbols. */
void g3init_(void) {
    nj = 0;
    ni_last = 0;
    union_count = 0;
    eps2 = 0.0;
    memset(xj, 0, sizeof(xj));
    memset(mj, 0, sizeof(mj));
    memset(h2, 0, sizeof(h2));
    memset(nbl_count, 0, sizeof(nbl_count));
    initialized = true;
}

void g3free_(void) { initialized = false; }
int g3nchips_(void) { return MAX_CHIPS; }

void g3setscales_(const double *xscale, const double *mscale) {
    check_initialized();
    if (!isfinite(*xscale) || !isfinite(*mscale) || *xscale <= 0 || *mscale <= 0)
        die("invalid scales");
    /* Scale arguments accepted; this shim deliberately does NOT quantize to GRAPE-3 fixed point. */
}

void g3seteps2_(const double *value) {
    check_initialized();
    if (!isfinite(*value) || *value < 0) die("eps2 must be finite and non-negative");
    eps2 = *value;
}

void g3setn_(const int *count) {
    check_initialized();
    if (*count < 0 || *count > MAX_PARTICLES)
        die("g3setn particle count out of bounds");
    nj = *count;
}

void g3setxj_(const int *address, const double xyz[3]) {
    check_initialized();
    if (*address < 0 || *address >= MAX_PARTICLES) die("g3setxj index out of bounds");
    for (int k = 0; k < 3; ++k) {
        if (!isfinite(xyz[k])) die("non-finite coordinate");
        xj[*address][k] = xyz[k];
    }
}

void g3setmj_(const int *address, const double *mass) {
    check_initialized();
    if (*address < 0 || *address >= MAX_PARTICLES) die("g3setmj index out of bounds");
    if (!isfinite(*mass) || *mass < 0) die("invalid mass");
    mj[*address] = *mass;
}

/* GRAPE-3 uses zero-based chip indices in the interface. */
void g3seth2_(const double *radius_squared, const int *chip) {
    check_initialized();
    if (*chip < 0 || *chip >= MAX_CHIPS) die("invalid chip index");
    if (!isfinite(*radius_squared) || *radius_squared < 0) die("invalid h^2");
    h2[*chip] = *radius_squared;
}

/* x_i, a_i are Fortran REAL*8 arrays (3,ni); potential is (ni). */
void g3frc_(const double *xi, double *acc, double *pot, const int *ni) {
    check_initialized();
    if (*ni < 1 || *ni > MAX_CHIPS) die("invalid number of active chips");
    ni_last = *ni;
    union_count = 0;
    unsigned char *seen = (unsigned char*)calloc((size_t)(nj > 0 ? nj : 1), 1);
    if (!seen) die("memory allocation failed");

    for (int i = 0; i < *ni; ++i) {
        double ai[3] = {0, 0, 0};
        double phi = 0.0;
        nbl_count[i] = 0;
        /* Descending address order is important for Steinmetz's overflow algorithm. */
        for (int j = nj - 1; j >= 0; --j) {
            const double dx = xj[j][0] - xi[3*i];
            const double dy = xj[j][1] - xi[3*i + 1];
            const double dz = xj[j][2] - xi[3*i + 2];
            const double r2 = dx*dx + dy*dy + dz*dz;
            if (r2 <= h2[i]) {
                nbl[i][nbl_count[i]++] = j;
                if (!seen[j]) { seen[j] = 1; ++union_count; }
            }
            /* Omit zero-separation terms, including self-potential, explicitly. */
            if (r2 == 0.0 || mj[j] == 0.0) continue;
            const double inv_r = 1.0 / sqrt(r2 + eps2);
            const double f = mj[j] * inv_r * inv_r * inv_r; /* G=1 */
            ai[0] += f * dx;
            ai[1] += f * dy;
            ai[2] += f * dz;
            phi -= mj[j] * inv_r;
        }
        for (int k = 0; k < 3; ++k) acc[3*i + k] = ai[k];
        pot[i] = phi;
    }
    free(seen);
    if (union_count > NEIGHBOUR_UNION_LIMIT)
        die("distinct-neighbour union >1022; GRAPE-3 overflow recovery NOT implemented; reduce batch/chips");
}

/* g3readnbl(0) returns number of distinct neighbours across active chips. */
int g3readnbl_(const int *ignored) {
    (void)ignored;
    check_initialized();
    return union_count;
}

/* Return one chip's (0-based) neighbours in descending address order. */
int g3getnbl_(const int *chip, int *indices) {
    check_initialized();
    if (*chip < 0 || *chip >= ni_last) die("g3getnbl chip outside previous g3frc batch");
    int n = nbl_count[*chip];
    for (int k = 0; k < n; ++k) indices[k] = nbl[*chip][k];
    return n;
}
