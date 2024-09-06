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
#else
    SMMTT_46,
    SMMTT_56,
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

#if defined(__SMMTT32)

#define SPA_PN0     _ULL(0x000007000)
#define SPA_PN1     _ULL(0x001ff8000)
#define SPA_XM_OFFS _ULL(0x001C00000)
#define SPA_PN2     _ULL(0x3fe000000)

#define SPA_

#else

#define SPA_PN0     _ULL(0x0000000000f000)
#define SPA_PN1     _ULL(0x00000001ff0000)
#define SPA_XM_OFFS _ULL(0x00000001e00000)
#define SPA_PN2     _ULL(0x003ffffe000000)
#define SPA_PN3     _ULL(0xffc00000000000)

#endif


// Types

typedef enum {
    SMMTT_TYPE_1G_DISALLOW      = 0b000,
    SMMTT_TYPE_1G_ALLOW_RX      = 0b001,
    SMMTT_TYPE_1G_ALLOW_RW      = 0b010,
    SMMTT_TYPE_1G_ALLOW_RWX     = 0b011,
    SMMTT_TYPE_MTT_L1_DIR       = 0b100,
#if defined(__SMMTT32)
    SMMTT_TYPE_4M_PAGES         = 0b101,
#else
    SMMTT_TYPE_2M_PAGES         = 0b110,
#endif
} smmtt_type_t;

// Permissions

typedef enum {
    SMMTT_PERMS_XM_PAGES_DISALLOWED = 0b00,
    SMMTT_PERMS_XM_PAGES_ALLOW_RX   = 0b01,
    SMMTT_PERMS_XM_PAGES_ALLOW_RW   = 0b10,
    SMMTT_PERMS_XM_PAGES_ALLOW_RWX  = 0b11,
} smmtt_perms_xm_pages_t;

typedef enum {
    SMMTT_PERMS_MTT_L1_DIR_DISALLOWED   = 0b00,
    SMMTT_PERMS_MTT_L1_DIR_ALLOW_RX     = 0b01,
    SMMTT_PERMS_MTT_L1_DIR_ALLOW_RW     = 0b10,
    SMMTT_PERMS_MTT_L1_DIR_ALLOW_RWX    = 0b11,
} smmtt_perms_mtt_l1_dir_t;

#define MTT_PERMS_MASK  _ULL(0b11)
#define MTT_PERMS_BITS  (2)

#define MTT_PERM_FIELD(idx) \
    MTT_PERMS_MASK << (MTT_PERMS_BITS * (idx))

// Entries

#if defined(__SMMTT32)

typedef struct {
    uint32_t info : 22;
    uint32_t type : 3;
    uint32_t zero : 7;
} mttl2_entry_t;

typedef uint32_t mttl1_entry_t;

typedef union {
    uint32_t raw;
    mttl2_entry_t mttl2;
    mttl1_entry_t mttl1;
} smmtt_mtt_entry_t;

#else

typedef struct {
    uint64_t mttl2_ppn : 44;
    uint64_t zero : 20;
} mttl3_entry_t;

typedef struct {
    uint64_t info : 44;
    uint64_t type : 3;
    uint64_t zero : 17;
} mttl2_entry_t;

typedef uint64_t mttl1_entry_t;

typedef union {
    uint64_t raw;
    mttl3_entry_t mttl3;
    mttl2_entry_t mttl2;
    mttl1_entry_t mttl1;
} smmtt_mtt_entry_t;

#endif



#endif // __SMMTT_DEFS_H__