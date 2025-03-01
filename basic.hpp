#define cast(T) (T)
#define size_of(T) (cast(s64) sizeof(T))
#define offset_of(T, F) (cast(s64) &(cast(T*) 0)->F)
#define null nullptr
#define assert(X) do if (!(X)) __debugbreak(); while (0)

typedef signed char s8;
typedef short s16;
typedef int s32;
typedef long long s64;

typedef unsigned char u8;
typedef unsigned short u16;
typedef unsigned int u32;
typedef unsigned long long u64;

typedef float f32;
typedef double f64;

struct v2 { f32 x, y; };
struct v3 { f32 x, y, z; };
struct v4 { f32 x, y, z, w; };
