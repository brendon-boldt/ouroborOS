#pragma once

#ifdef NULL
    #undef NULL
#endif // NULL

#ifdef __cplusplus
extern "C"
{
    #endif // __cplusplus
    #define NULL    0
    #ifdef __cplusplus
}
#else
    #define NULL (void*)0
#endif // __cplusplus
