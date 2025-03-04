#define COMPILER_UNKNOWN 0
#define COMPILER_MSVC 1

#define COMPILER COMPILER_MSVC

#define CPU_UNKNOWN 0
#define CPU_X64 1

#define CPU CPU_X64

#define OS_UNKNOWN 0
#define OS_WINDOWS 1

#define OS OS_WINDOWS

#if COMPILER == COMPILER_MSVC
#define debug_break() __debugbreak()
#define noreturn_t __declspec(noreturn) void
#define align_struct(N) __declspec(align(N))

int _fltused;
#endif

#define cast(T) (T)
#define size_of(T) (cast(s64) sizeof(T))
#define offset_of(T, F) (cast(s64) &(cast(T*) 0)->F)
#define zero(POINTER) (cast(void) memset((POINTER), 0, size_of(*(POINTER))))

#if DEBUG
#define assert(X) do if (!(X)) debug_break(); while (0)
#else
#define assert(X) (cast(void) (X))
#endif

#define true (cast(bool) 1)
#define false (cast(bool) 0)
#define null (cast(void*) 0)
#define unreachable debug_break()
#define fallthrough do {} while (0)

#if CPU == CPU_X64
typedef signed char s8;
typedef short s16;
typedef int s32;
typedef long long s64;

typedef unsigned char u8;
typedef unsigned short u16;
typedef unsigned int u32;
typedef unsigned long long u64;
#endif

typedef u8 bool;

typedef float f32;
typedef double f64;

typedef struct align_struct(8) v2 { f32 x, y; } v2;
typedef struct align_struct(16) v3 { f32 x, y, z, _w; } v3;
typedef struct align_struct(16) v4 { f32 x, y, z, w; } v4;
