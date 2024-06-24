#ifndef __SMMTT_DEFS_H__
#define __SMMTT_DEFS_H__

/* Parameterize based on build and bitness */

#if defined(SMMTT_QEMU)

#include "linux/kvm.h"

#if defined(TARGET_RISCV32)
#define __SMMTT32
#elif defined(TARGET_RISCV64)
#define __SMMTT64
#else
#error "Unknown target for QEMU"
#endif

#elif defined(SMMTT_OPENSBI)

#include <sbi/sbi_const.h>

#if __riscv_xlen == 32
#define __SMMTT32
#elif __riscv_xlen == 64
#define __SMMTT64
#else
#error "Unknown xlen for OpenSBI"
#endif

#else
#error "Must be included from QEMU or OpenSBI"
#endif

/* SMMTT Modes */

typedef enum {
    SMMTT_BARE = 0,
#if defined(__SMMTT32)
    SMMTT_34,
    SMMTT_34_rw,
#else
    SMMTT_46,
    SMMTT_46_rw,
    SMMTT_56,
    SMMTT_56_rw,
#endif
    SMMTT_MAX
} smmtt_mode_t;

#define MTTP32_MODE   _UL(0xC0000000)
#define MTTP32_SDID   _UL(0x3F000000)
#define MTTP32_PPN    _UL(0x003FFFFF)

#define MTTP64_MODE   _ULL(0xF000000000000000)
#define MTTP64_SDID   _ULL(0x0FC0000000000000)
#define MTTP64_PPN    _ULL(0x00000FFFFFFFFFFF)

#if defined(__SMMTT32)
#define MTTP_MODE     MTTP32_MODE
#define MTTP_SDID     MTTP32_SDID
#define MTTP_PPN      MTTP32_PPN
#else
#define MTTP_MODE     MTTP64_MODE
#define MTTP_SDID     MTTP64_SDID
#define MTTP_PPN      MTTP64_PPN
#endif

/* MTT Tables */

// Masks

#define MTTL3         _ULL(0x7FE00000000000)

#define MTTL2_RW      _ULL(0x001FFFFE000000)
#define MTTL1_RW      _ULL(0x00000001FF0000)
#define MTTL0_RW      _ULL(0x0000000000F000)

#define MTTL2         _ULL(0x001FFFFC000000)
#define MTTL1         _ULL(0x00000003FE0000)
#define MTTL0         _ULL(0x0000000001F000)

#define MTTL2_2M_PAGES_SHIFT    (21) /* 2 megabytes */
#define MTTL2_1G_SHIFT          (30)
#define MTTL2_RW_PAGES          (0b11)
#define MTTL2_PAGES             (0b1)
#define MTTL2_RW_PAGES_BITS     (2)
#define MTTL2_PAGES_BITS        (1)

// Types

typedef enum {
    SMMTT_TYPE_1G_DISALLOW      = 0b00,
    SMMTT_TYPE_1G_ALLOW         = 0b01,
    SMMTT_TYPE_MTT_L1_DIR       = 0b10,
    SMMTT_TYPE_2M_PAGES         = 0b11
} smmtt_type_t;

typedef enum {
    SMMTT_TYPE_RW_1G_DISALLOW   = 0b0000,
    SMMTT_TYPE_RW_1G_ALLOW_R    = 0b0001,
    SMMTT_TYPE_RW_1G_ALLOW_RW   = 0b0011,
    SMMTT_TYPE_RW_MTT_L1_DIR    = 0b0100,
    SMMTT_TYPE_RW_2M_PAGES      = 0b0111
} smmtt_type_rw_t;

// Permissions

typedef enum {
    SMMTT_2M_PAGES_TYPE_DISALLOWED    = 0b0,
    SMMTT_2M_PAGES_TYPE_ALLOWED       = 0b1
} smmtt_2m_pages_type_t;

typedef enum {
    SMMTT_2M_PAGES_TYPE_RW_DISALLOWED = 0b00,
    SMMTT_2M_PAGES_TYPE_RW_READ       = 0b01,
    SMMTT_2M_PAGES_TYPE_RW_READ_WRITE = 0b11
} smmtt_2m_pages_type_rw_t;

// Entries

typedef struct {
    uint64_t mttl2_ppn : 44;
    uint64_t zero : 20;
} mttl3_entry_t;

typedef struct {
    uint64_t info : 44;
    uint64_t type : 4;
    uint64_t zero : 16;
} mttl2_rw_t;

typedef struct {
    uint64_t info : 44;
    uint64_t type : 2;
    uint64_t zero : 18;
} mttl2_t;

typedef union {
    mttl2_t mttl2;
    mttl2_rw_t mttl2_rw;
} mttl2_entry_t;

typedef uint64_t mttl1_entry_t;

typedef union {
    uint64_t raw;
    mttl3_entry_t mttl3;
    mttl2_entry_t mttl2;
    mttl1_entry_t mttl1;
} smmtt_mtt_entry_t;

#endif // __SMMTT_DEFS_H__